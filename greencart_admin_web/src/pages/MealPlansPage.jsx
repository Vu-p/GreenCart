import React, { useEffect, useState } from 'react';
import { Plus, Search, Edit2, Trash2, Utensils, Clock, Users, Sparkles, PlusCircle, MinusCircle } from 'lucide-react';
import api from '../services/api';

const MealPlansPage = () => {
  const [plans, setPlans] = useState([]);
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingPlan, setEditingPlan] = useState(null);

  // Form state
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    instructions: '',
    prepMinutes: 15,
    cookMinutes: 25,
    servings: 4,
    difficulty: 'Dễ (Easy)',
    imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
    isFeatured: true,
    ingredients: []
  });

  const fetchData = async () => {
    setLoading(true);
    try {
      const [plansRes, prodsRes] = await Promise.all([
        api.get('/admin/meal-plans'),
        api.get('/admin/products')
      ]);
      setPlans(plansRes.data || []);
      setProducts(prodsRes.data || []);
    } catch (err) {
      console.error('Lỗi khi tải dữ liệu Thực đơn:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleOpenAdd = () => {
    setEditingPlan(null);
    setFormData({
      title: '',
      description: 'Gợi ý bữa cơm dinh dưỡng đầy đủ chất xanh hữu cơ',
      instructions: '1. Rửa sạch nguyên liệu với nước muối loãng.\n2. Chế biến nhanh ở nhiệt độ vừa phải để giữ vitamin.\n3. Trình bày ra đĩa và thưởng thức khi còn ấm.',
      prepMinutes: 15,
      cookMinutes: 20,
      servings: 3,
      difficulty: 'Dễ (Easy)',
      imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
      isFeatured: true,
      ingredients: products.length > 0 ? [{ productId: products[0].id, quantityText: '300g', isOptional: false, sortOrder: 1 }] : []
    });
    setIsModalOpen(true);
  };

  const handleOpenEdit = (plan) => {
    setEditingPlan(plan);
    setFormData({
      title: plan.title || '',
      description: plan.description || '',
      instructions: plan.instructions || '',
      prepMinutes: plan.prepMinutes || 15,
      cookMinutes: plan.cookMinutes || 20,
      servings: plan.servings || 4,
      difficulty: plan.difficulty || 'Dễ (Easy)',
      imageUrl: plan.imageUrl || '',
      isFeatured: plan.isFeatured ?? true,
      ingredients: (plan.ingredients || []).map((i, idx) => ({
        productId: i.productId,
        quantityText: i.quantityText || '1 gói',
        isOptional: i.isOptional || false,
        sortOrder: idx + 1
      }))
    });
    setIsModalOpen(true);
  };

  const handleDelete = async (id, title) => {
    if (!window.confirm(`Xóa thực đơn gợi ý "${title}"?`)) return;
    try {
      await api.delete(`/admin/meal-plans/${id}`);
      setPlans(prev => prev.filter(p => p.id !== id));
    } catch (err) {
      alert(err.response?.data?.message || 'Không thể xóa thực đơn này');
    }
  };

  const handleAddIngredientRow = () => {
    if (products.length === 0) return;
    setFormData(prev => ({
      ...prev,
      ingredients: [
        ...prev.ingredients,
        { productId: products[0].id, quantityText: '200g', isOptional: false, sortOrder: prev.ingredients.length + 1 }
      ]
    }));
  };

  const handleRemoveIngredientRow = (index) => {
    setFormData(prev => ({
      ...prev,
      ingredients: prev.ingredients.filter((_, idx) => idx !== index)
    }));
  };

  const handleIngredientChange = (index, field, value) => {
    setFormData(prev => ({
      ...prev,
      ingredients: prev.ingredients.map((ing, idx) => idx === index ? { ...ing, [field]: value } : ing)
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      if (editingPlan) {
        await api.put(`/admin/meal-plans/${editingPlan.id}`, formData);
      } else {
        await api.post('/admin/meal-plans', formData);
      }
      setIsModalOpen(false);
      fetchData();
    } catch (err) {
      alert(err.response?.data?.message || 'Lỗi khi lưu Kế hoạch bữa ăn');
    }
  };

  const filteredPlans = plans.filter(p =>
    (p.title || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
    (p.description || '').toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="animate-fade-in">
      <div className="card" style={{ marginBottom: '24px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h3 style={{ fontSize: '18px', fontWeight: '800' }}>Quản lý Thực đơn & Kế hoạch ăn uống (Meal Planner)</h3>
          <p style={{ fontSize: '13.5px', color: 'var(--text-secondary)' }}>
            Quản trị các công thức nấu ăn, định lượng nguyên liệu cho khách hàng chọn mua trọn bộ trên Mobile App
          </p>
        </div>

        <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
          <div style={{ position: 'relative', width: '280px' }}>
            <Search size={18} color="var(--text-muted)" style={{ position: 'absolute', left: '14px', top: '14px' }} />
            <input
              type="text"
              placeholder="Tìm theo tên món ăn..."
              className="form-input"
              style={{ paddingLeft: '40px' }}
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>

          <button onClick={handleOpenAdd} className="btn btn-primary">
            <Plus size={18} />
            <span>Thêm Thực đơn mới</span>
          </button>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(340px, 1fr))', gap: '24px' }}>
        {loading ? (
          <div style={{ colSpan: 3, padding: '32px' }}>Đang tải danh sách Kế hoạch Bữa ăn...</div>
        ) : filteredPlans.length === 0 ? (
          <div style={{ colSpan: 3, padding: '48px', textAlign: 'center', color: 'var(--text-secondary)' }}>
            Chưa có thực đơn nào trong hệ thống. Hãy thêm mới!
          </div>
        ) : (
          filteredPlans.map(p => (
            <div key={p.id} className="card" style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
              <div>
                <div style={{ position: 'relative', marginBottom: '16px' }}>
                  <img
                    src={p.imageUrl}
                    alt={p.title}
                    style={{ width: '100%', height: '180px', borderRadius: '16px', objectFit: 'cover' }}
                    onError={(e) => { e.target.src = 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c'; }}
                  />
                  {p.isFeatured && (
                    <span className="badge badge-success" style={{ position: 'absolute', top: '12px', right: '12px', backgroundColor: '#006A38', color: 'white' }}>
                      ✨ Nổi bật
                    </span>
                  )}
                </div>

                <h4 style={{ fontSize: '18px', fontWeight: '800', color: 'var(--text-primary)', marginBottom: '6px' }}>
                  {p.title}
                </h4>
                <p style={{ fontSize: '13.5px', color: 'var(--text-secondary)', marginBottom: '16px' }}>
                  {p.description}
                </p>

                <div style={{ display: 'flex', gap: '16px', fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '16px', backgroundColor: '#F8FAF9', padding: '10px 14px', borderRadius: '12px' }}>
                  <span style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <Clock size={16} color="var(--primary)" />
                    {p.prepMinutes + p.cookMinutes} phút
                  </span>
                  <span style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <Users size={16} color="var(--primary)" />
                    {p.servings} người ăn
                  </span>
                  <span style={{ fontWeight: '700', color: '#D97706' }}>
                    ⚡ {p.difficulty}
                  </span>
                </div>

                <div style={{ marginBottom: '16px' }}>
                  <div style={{ fontSize: '13px', fontWeight: '700', marginBottom: '6px', color: 'var(--primary)' }}>
                    🥗 Nguyên liệu cấu thành ({p.ingredients?.length || 0} món):
                  </div>
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px' }}>
                    {(p.ingredients || []).slice(0, 5).map((ing, idx) => (
                      <span key={idx} style={{ fontSize: '12px', backgroundColor: '#E9F5EE', color: '#006A38', padding: '4px 10px', borderRadius: '8px', fontWeight: '600' }}>
                        {ing.productName} ({ing.quantityText})
                      </span>
                    ))}
                    {(p.ingredients?.length || 0) > 5 && (
                      <span style={{ fontSize: '12px', color: 'var(--text-muted)', alignSelf: 'center' }}>
                        +{p.ingredients.length - 5} khác
                      </span>
                    )}
                  </div>
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px', borderTop: '1px solid var(--border-color)', paddingTop: '16px' }}>
                <button onClick={() => handleOpenEdit(p)} className="btn btn-secondary" style={{ padding: '8px 16px' }}>
                  <Edit2 size={16} />
                  <span>Chỉnh sửa</span>
                </button>
                <button onClick={() => handleDelete(p.id, p.title)} className="btn btn-danger" style={{ padding: '8px 12px' }}>
                  <Trash2 size={16} />
                </button>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Modal */}
      {isModalOpen && (
        <div style={{
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
          backgroundColor: 'rgba(0,0,0,0.55)', backdropFilter: 'blur(6px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000
        }}>
          <div className="card animate-fade-in" style={{ width: '90%', maxWidth: '720px', maxHeight: '90vh', overflowY: 'auto' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px', borderBottom: '1px solid var(--border-color)', paddingBottom: '14px' }}>
              <h3 style={{ fontSize: '20px', fontWeight: '800' }}>
                {editingPlan ? 'Chỉnh sửa Thực đơn' : 'Thêm Thực đơn mới'}
              </h3>
              <button onClick={() => setIsModalOpen(false)} style={{ background: 'none', border: 'none', fontSize: '20px', cursor: 'pointer', fontWeight: '700' }}>✕</button>
            </div>

            <form onSubmit={handleSubmit}>
              <div className="form-group">
                <label className="form-label">Tên bộ Thực đơn / Bữa ăn</label>
                <input
                  type="text"
                  required
                  className="form-input"
                  value={formData.title}
                  onChange={e => setFormData({ ...formData, title: e.target.value })}
                  placeholder="Ví dụ: Bữa Cơm Gia Đình Khỏe Mạnh 4 Món Hữu Cơ"
                />
              </div>

              <div className="form-group">
                <label className="form-label">Mô tả ngắn gọn</label>
                <input
                  type="text"
                  required
                  className="form-input"
                  value={formData.description}
                  onChange={e => setFormData({ ...formData, description: e.target.value })}
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '14px' }}>
                <div className="form-group">
                  <label className="form-label">Thời gian chuẩn bị (phút)</label>
                  <input
                    type="number"
                    required
                    className="form-input"
                    value={formData.prepMinutes}
                    onChange={e => setFormData({ ...formData, prepMinutes: Number(e.target.value) })}
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">Thời gian nấu (phút)</label>
                  <input
                    type="number"
                    required
                    className="form-input"
                    value={formData.cookMinutes}
                    onChange={e => setFormData({ ...formData, cookMinutes: Number(e.target.value) })}
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">Khẩu phần (Số người)</label>
                  <input
                    type="number"
                    required
                    className="form-input"
                    value={formData.servings}
                    onChange={e => setFormData({ ...formData, servings: Number(e.target.value) })}
                  />
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
                <div className="form-group">
                  <label className="form-label">Độ khó chế biến</label>
                  <select
                    className="form-select"
                    value={formData.difficulty}
                    onChange={e => setFormData({ ...formData, difficulty: e.target.value })}
                  >
                    <option value="Dễ (Easy)">Dễ (Easy)</option>
                    <option value="Trung bình (Medium)">Trung bình (Medium)</option>
                    <option value="Nâng cao (Advanced)">Nâng cao (Advanced)</option>
                  </select>
                </div>
                <div className="form-group">
                  <label className="form-label">Hình ảnh minh họa (URL)</label>
                  <input
                    type="url"
                    required
                    className="form-input"
                    value={formData.imageUrl}
                    onChange={e => setFormData({ ...formData, imageUrl: e.target.value })}
                  />
                </div>
              </div>

              <div className="form-group">
                <label className="form-label">Các bước thực hiện nấu (mỗi bước 1 dòng)</label>
                <textarea
                  rows="4"
                  className="form-input"
                  value={formData.instructions}
                  onChange={e => setFormData({ ...formData, instructions: e.target.value })}
                />
              </div>

              {/* Ingredients List Builder */}
              <div style={{ marginBottom: '24px', backgroundColor: '#F8FAF9', padding: '16px', borderRadius: '14px', border: '1px solid var(--border-color)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
                  <span style={{ fontWeight: '800', fontSize: '14.5px', color: 'var(--primary)' }}>
                    🥗 Danh sách thực phẩm cấu thành ({formData.ingredients.length} món):
                  </span>
                  <button type="button" onClick={handleAddIngredientRow} className="btn btn-secondary" style={{ padding: '6px 12px', fontSize: '12.5px' }}>
                    <PlusCircle size={16} />
                    <span>Thêm nguyên liệu</span>
                  </button>
                </div>

                <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                  {formData.ingredients.map((ing, idx) => (
                    <div key={idx} style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
                      <select
                        className="form-select"
                        style={{ flex: 2 }}
                        value={ing.productId}
                        onChange={e => handleIngredientChange(idx, 'productId', e.target.value)}
                      >
                        {products.map(p => (
                          <option key={p.id} value={p.id}>{p.name} - ({new Intl.NumberFormat('vi-VN').format(p.price)} đ)</option>
                        ))}
                      </select>
                      <input
                        type="text"
                        className="form-input"
                        style={{ flex: 1 }}
                        placeholder="Định lượng (VD: 300g)"
                        value={ing.quantityText}
                        onChange={e => handleIngredientChange(idx, 'quantityText', e.target.value)}
                      />
                      <button
                        type="button"
                        onClick={() => handleRemoveIngredientRow(idx)}
                        style={{ background: 'none', border: 'none', color: '#D32F2F', cursor: 'pointer', padding: '6px' }}
                      >
                        <MinusCircle size={20} />
                      </button>
                    </div>
                  ))}
                </div>
              </div>

              <div style={{ display: 'flex', gap: '24px', marginBottom: '24px' }}>
                <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer', fontWeight: '700' }}>
                  <input
                    type="checkbox"
                    checked={formData.isFeatured}
                    onChange={e => setFormData({ ...formData, isFeatured: e.target.checked })}
                    style={{ width: '18px', height: '18px' }}
                  />
                  <span>✨ Đánh dấu là Thực đơn Nổi bật (Featured)</span>
                </label>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
                <button type="button" onClick={() => setIsModalOpen(false)} className="btn btn-secondary">Hủy</button>
                <button type="submit" className="btn btn-primary">{editingPlan ? 'Cập nhật Thực đơn' : 'Tạo mới ngay'}</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default MealPlansPage;
