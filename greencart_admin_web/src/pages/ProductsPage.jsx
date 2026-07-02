import React, { useEffect, useState } from 'react';
import { Plus, Search, Edit2, Trash2, Tag, Check, X } from 'lucide-react';
import api from '../services/api';

const ProductsPage = () => {
  const [products, setProducts] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState(null);

  // Form State
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    price: 35000,
    stock: 50,
    imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999',
    categoryId: '',
    isOrganic: true,
    isDeal: false
  });

  const fetchData = async () => {
    setLoading(true);
    try {
      const [prodRes, catRes] = await Promise.all([
        api.get('/admin/products'),
        api.get('/categories')
      ]);
      const cats = catRes.data || [];
      setCategories(cats);
      setProducts(prodRes.data || []);
      if (cats.length > 0 && !formData.categoryId) {
        setFormData(prev => ({ ...prev, categoryId: cats[0].id }));
      }
    } catch (err) {
      console.error('Lỗi khi tải dữ liệu sản phẩm:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const formatCurrency = (val) => {
    return new Intl.NumberFormat('vi-VN').format(Math.round(val)) + ' đ';
  };

  const handleOpenAdd = () => {
    setEditingProduct(null);
    setFormData({
      name: '',
      description: 'Thực phẩm sạch đạt chuẩn VietGAP',
      price: 45000,
      stock: 30,
      imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999',
      categoryId: categories[0]?.id || '',
      isOrganic: true,
      isDeal: false
    });
    setIsModalOpen(true);
  };

  const handleOpenEdit = (prod) => {
    setEditingProduct(prod);
    setFormData({
      name: prod.name || '',
      description: prod.description || '',
      price: prod.price || 0,
      stock: prod.stock || 0,
      imageUrl: prod.imageUrl || '',
      categoryId: prod.categoryId || (categories[0]?.id || ''),
      isOrganic: prod.isOrganic ?? true,
      isDeal: prod.isDeal ?? false
    });
    setIsModalOpen(true);
  };

  const handleDelete = async (id, name) => {
    if (!window.confirm(`Bạn có chắc chắn muốn xóa sản phẩm "${name}" khỏi hệ thống?`)) return;
    try {
      await api.delete(`/admin/products/${id}`);
      setProducts(prev => prev.filter(p => p.id !== id));
    } catch (err) {
      alert(err.response?.data?.message || 'Không thể xóa sản phẩm này');
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      if (editingProduct) {
        const res = await api.put(`/admin/products/${editingProduct.id}`, formData);
        setProducts(prev => prev.map(p => p.id === editingProduct.id ? res.data : p));
      } else {
        const res = await api.post('/admin/products', formData);
        setProducts(prev => [res.data, ...prev]);
      }
      setIsModalOpen(false);
    } catch (err) {
      alert(err.response?.data?.message || 'Lỗi khi lưu sản phẩm');
    }
  };

  const filteredProducts = products.filter(p =>
    (p.name || '').toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="animate-fade-in">
      {/* Action Bar */}
      <div className="card" style={{ marginBottom: '24px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '16px' }}>
        <div style={{ position: 'relative', width: '320px' }}>
          <Search size={18} color="var(--text-muted)" style={{ position: 'absolute', left: '14px', top: '14px' }} />
          <input
            type="text"
            placeholder="Tìm kiếm theo tên món hàng..."
            className="form-input"
            style={{ paddingLeft: '40px' }}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>

        <button onClick={handleOpenAdd} className="btn btn-primary">
          <Plus size={18} />
          <span>Thêm sản phẩm mới</span>
        </button>
      </div>

      {/* Table */}
      <div className="card" style={{ padding: 0 }}>
        <div className="table-container">
          <table className="admin-table">
            <thead>
              <tr>
                <th>Sản phẩm</th>
                <th>Danh mục</th>
                <th>Đơn giá (VNĐ)</th>
                <th>Tồn kho</th>
                <th>Phân loại</th>
                <th>Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan="6" style={{ textAlign: 'center', padding: '48px' }}>Đang tải dữ liệu kho hàng...</td>
                </tr>
              ) : filteredProducts.length === 0 ? (
                <tr>
                  <td colSpan="6" style={{ textAlign: 'center', padding: '48px', color: 'var(--text-secondary)' }}>Không tìm thấy sản phẩm nào.</td>
                </tr>
              ) : (
                filteredProducts.map(p => (
                  <tr key={p.id}>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                        <img
                          src={p.imageUrl}
                          alt={p.name}
                          style={{ width: '48px', height: '48px', borderRadius: '12px', objectFit: 'cover' }}
                          onError={(e) => { e.target.src = 'https://images.unsplash.com/photo-1540420773420-3366772f4999'; }}
                        />
                        <div>
                          <div style={{ fontWeight: '700', fontSize: '15px' }}>{p.name}</div>
                          <div style={{ fontSize: '12.5px', color: 'var(--text-secondary)' }}>{p.description?.substring(0, 45)}...</div>
                        </div>
                      </div>
                    </td>
                    <td>
                      <span className="badge badge-info">{p.categoryName || 'Thực phẩm'}</span>
                    </td>
                    <td style={{ fontWeight: '800', color: 'var(--primary)', fontSize: '15.5px' }}>
                      {formatCurrency(p.price)}
                    </td>
                    <td>
                      <span style={{
                        fontWeight: '800',
                        color: p.stock < 10 ? '#D32F2F' : 'inherit'
                      }}>
                        {p.stock} sản phẩm
                      </span>
                    </td>
                    <td>
                      <div style={{ display: 'flex', gap: '6px' }}>
                        {p.isOrganic && <span className="badge badge-success">🌿 Hữu cơ</span>}
                        {p.isDeal && <span className="badge badge-warning">🔥 Giảm giá</span>}
                      </div>
                    </td>
                    <td>
                      <div style={{ display: 'flex', gap: '8px' }}>
                        <button onClick={() => handleOpenEdit(p)} className="btn btn-secondary" style={{ padding: '8px' }} title="Chỉnh sửa">
                          <Edit2 size={16} />
                        </button>
                        <button onClick={() => handleDelete(p.id, p.name)} className="btn btn-danger" style={{ padding: '8px' }} title="Xóa">
                          <Trash2 size={16} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal Add / Edit */}
      {isModalOpen && (
        <div style={{
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
          backgroundColor: 'rgba(0,0,0,0.55)', backdropFilter: 'blur(6px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000
        }}>
          <div className="card animate-fade-in" style={{ width: '90%', maxWidth: '580px', maxHeight: '90vh', overflowY: 'auto' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px', borderBottom: '1px solid var(--border-color)', paddingBottom: '14px' }}>
              <h3 style={{ fontSize: '20px', fontWeight: '800' }}>
                {editingProduct ? 'Chỉnh sửa sản phẩm' : 'Thêm sản phẩm mới'}
              </h3>
              <button onClick={() => setIsModalOpen(false)} style={{ background: 'none', border: 'none', fontSize: '20px', cursor: 'pointer', fontWeight: '700' }}>✕</button>
            </div>

            <form onSubmit={handleSubmit}>
              <div className="form-group">
                <label className="form-label">Tên sản phẩm</label>
                <input
                  type="text"
                  required
                  className="form-input"
                  value={formData.name}
                  onChange={e => setFormData({ ...formData, name: e.target.value })}
                  placeholder="Ví dụ: Rau Cải Bó Xôi Hữu Cơ Đà Lạt"
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                <div className="form-group">
                  <label className="form-label">Đơn giá (VNĐ)</label>
                  <input
                    type="number"
                    required
                    className="form-input"
                    value={formData.price}
                    onChange={e => setFormData({ ...formData, price: Number(e.target.value) })}
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">Tồn kho</label>
                  <input
                    type="number"
                    required
                    className="form-input"
                    value={formData.stock}
                    onChange={e => setFormData({ ...formData, stock: Number(e.target.value) })}
                  />
                </div>
              </div>

              <div className="form-group">
                <label className="form-label">Danh mục sản phẩm</label>
                <select
                  className="form-select"
                  value={formData.categoryId}
                  onChange={e => setFormData({ ...formData, categoryId: e.target.value })}
                  required
                >
                  <option value="">-- Chọn danh mục --</option>
                  {categories.map(c => (
                    <option key={c.id} value={c.id}>{c.name}</option>
                  ))}
                </select>
              </div>

              <div className="form-group">
                <label className="form-label">Link hình ảnh (Image URL)</label>
                <input
                  type="url"
                  required
                  className="form-input"
                  value={formData.imageUrl}
                  onChange={e => setFormData({ ...formData, imageUrl: e.target.value })}
                />
              </div>

              <div className="form-group">
                <label className="form-label">Mô tả chi tiết</label>
                <textarea
                  rows="3"
                  className="form-input"
                  value={formData.description}
                  onChange={e => setFormData({ ...formData, description: e.target.value })}
                />
              </div>

              <div style={{ display: 'flex', gap: '24px', marginBottom: '24px' }}>
                <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer', fontWeight: '600' }}>
                  <input
                    type="checkbox"
                    checked={formData.isOrganic}
                    onChange={e => setFormData({ ...formData, isOrganic: e.target.checked })}
                    style={{ width: '18px', height: '18px' }}
                  />
                  <span>🌿 Đạt chuẩn Hữu cơ (Organic)</span>
                </label>

                <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer', fontWeight: '600' }}>
                  <input
                    type="checkbox"
                    checked={formData.isDeal}
                    onChange={e => setFormData({ ...formData, isDeal: e.target.checked })}
                    style={{ width: '18px', height: '18px' }}
                  />
                  <span>🔥 Nằm trong mục Giảm giá (Deals)</span>
                </label>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
                <button type="button" onClick={() => setIsModalOpen(false)} className="btn btn-secondary">Hủy</button>
                <button type="submit" className="btn btn-primary">{editingProduct ? 'Cập nhật' : 'Thêm mới'}</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default ProductsPage;
