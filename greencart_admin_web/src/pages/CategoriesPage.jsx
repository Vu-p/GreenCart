import React, { useEffect, useState } from 'react';
import { Plus, Edit2, Trash2, FolderTree } from 'lucide-react';
import api from '../services/api';

const CategoriesPage = () => {
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState(null);
  const [formData, setFormData] = useState({ name: '', imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999' });

  const fetchCategories = async () => {
    setLoading(true);
    try {
      const res = await api.get('/categories');
      setCategories(res.data || []);
    } catch (err) {
      console.error('Lỗi tải danh mục:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCategories();
  }, []);

  const handleOpenAdd = () => {
    setEditingCategory(null);
    setFormData({ name: '', imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999' });
    setIsModalOpen(true);
  };

  const handleOpenEdit = (cat) => {
    setEditingCategory(cat);
    setFormData({ name: cat.name || '', imageUrl: cat.imageUrl || '' });
    setIsModalOpen(true);
  };

  const handleDelete = async (id, name) => {
    if (!window.confirm(`Xóa danh mục "${name}"?`)) return;
    try {
      await api.delete(`/admin/categories/${id}`);
      setCategories(prev => prev.filter(c => c.id !== id));
    } catch (err) {
      alert(err.response?.data?.message || 'Không thể xóa danh mục này (có thể còn sản phẩm bên trong)');
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      if (editingCategory) {
        const res = await api.put(`/admin/categories/${editingCategory.id}`, formData);
        setCategories(prev => prev.map(c => c.id === editingCategory.id ? res.data : c));
      } else {
        const res = await api.post('/admin/categories', formData);
        setCategories(prev => [...prev, res.data]);
      }
      setIsModalOpen(false);
    } catch (err) {
      alert(err.response?.data?.message || 'Lỗi khi lưu danh mục');
    }
  };

  return (
    <div className="animate-fade-in">
      <div className="card" style={{ marginBottom: '24px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h3 style={{ fontSize: '18px', fontWeight: '800' }}>Phân loại danh mục</h3>
          <p style={{ fontSize: '13.5px', color: 'var(--text-secondary)' }}>Quản lý các nhóm thực phẩm trên toàn hệ thống GreenCart</p>
        </div>
        <button onClick={handleOpenAdd} className="btn btn-primary">
          <Plus size={18} />
          <span>Thêm danh mục</span>
        </button>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '20px' }}>
        {loading ? (
          <div style={{ colSpan: 3, padding: '32px' }}>Đang tải danh mục...</div>
        ) : categories.map(cat => (
          <div key={cat.id} className="card" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
              <img
                src={cat.imageUrl}
                alt={cat.name}
                style={{ width: '56px', height: '56px', borderRadius: '14px', objectFit: 'cover' }}
                onError={(e) => { e.target.src = 'https://images.unsplash.com/photo-1540420773420-3366772f4999'; }}
              />
              <div>
                <h4 style={{ fontSize: '16px', fontWeight: '800' }}>{cat.name}</h4>
                <span style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>Mã: #{cat.id?.substring(0, 6)}</span>
              </div>
            </div>
            <div style={{ display: 'flex', gap: '6px' }}>
              <button onClick={() => handleOpenEdit(cat)} className="btn btn-secondary" style={{ padding: '8px' }}>
                <Edit2 size={16} />
              </button>
              <button onClick={() => handleDelete(cat.id, cat.name)} className="btn btn-danger" style={{ padding: '8px' }}>
                <Trash2 size={16} />
              </button>
            </div>
          </div>
        ))}
      </div>

      {isModalOpen && (
        <div style={{
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
          backgroundColor: 'rgba(0,0,0,0.55)', backdropFilter: 'blur(6px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000
        }}>
          <div className="card animate-fade-in" style={{ width: '90%', maxWidth: '480px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px', borderBottom: '1px solid var(--border-color)', paddingBottom: '14px' }}>
              <h3 style={{ fontSize: '18px', fontWeight: '800' }}>{editingCategory ? 'Chỉnh sửa danh mục' : 'Thêm danh mục mới'}</h3>
              <button onClick={() => setIsModalOpen(false)} style={{ background: 'none', border: 'none', fontSize: '20px', cursor: 'pointer' }}>✕</button>
            </div>
            <form onSubmit={handleSubmit}>
              <div className="form-group">
                <label className="form-label">Tên danh mục</label>
                <input
                  type="text"
                  required
                  className="form-input"
                  value={formData.name}
                  onChange={e => setFormData({ ...formData, name: e.target.value })}
                  placeholder="Ví dụ: Hải sản tươi sống"
                />
              </div>
              <div className="form-group" style={{ marginBottom: '24px' }}>
                <label className="form-label">Hình ảnh minh họa (URL)</label>
                <input
                  type="url"
                  required
                  className="form-input"
                  value={formData.imageUrl}
                  onChange={e => setFormData({ ...formData, imageUrl: e.target.value })}
                />
              </div>
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
                <button type="button" onClick={() => setIsModalOpen(false)} className="btn btn-secondary">Hủy</button>
                <button type="submit" className="btn btn-primary">{editingCategory ? 'Cập nhật' : 'Thêm mới'}</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default CategoriesPage;
