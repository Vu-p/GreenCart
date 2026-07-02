import React, { useEffect, useState } from 'react';
import { Search, Shield, UserCheck, UserX, Trash2, Mail, Phone, Calendar } from 'lucide-react';
import api from '../services/api';

const UsersPage = () => {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [updatingId, setUpdatingId] = useState(null);

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const res = await api.get('/admin/users');
      setUsers(res.data || []);
    } catch (err) {
      console.error('Lỗi tải danh sách người dùng:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const handleToggleRole = async (userId, currentRole, userName) => {
    const newRole = currentRole === 'Admin' ? 'Customer' : 'Admin';
    if (!window.confirm(`Chuyển vai trò của tài khoản "${userName}" sang ${newRole}?`)) return;
    
    setUpdatingId(userId);
    try {
      await api.put(`/admin/users/${userId}/role`, { role: newRole });
      setUsers(prev => prev.map(u => u.id === userId ? { ...u, role: newRole } : u));
    } catch (err) {
      alert(err.response?.data?.message || 'Không thể cập nhật quyền tài khoản này');
    } finally {
      setUpdatingId(null);
    }
  };

  const handleDeleteUser = async (userId, userName) => {
    if (!window.confirm(`CẢNH BÁO: Xóa vĩnh viễn tài khoản "${userName}"? Thao tác này không thể khôi phục!`)) return;
    try {
      await api.delete(`/admin/users/${userId}`);
      setUsers(prev => prev.filter(u => u.id !== userId));
    } catch (err) {
      alert(err.response?.data?.message || 'Không thể xóa người dùng này');
    }
  };

  const filteredUsers = users.filter(u =>
    (u.name || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
    (u.email || '').toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="animate-fade-in">
      <div className="card" style={{ marginBottom: '24px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h3 style={{ fontSize: '18px', fontWeight: '800' }}>Quản lý Khách hàng & Tài khoản</h3>
          <p style={{ fontSize: '13.5px', color: 'var(--text-secondary)' }}>
            Theo dõi, phân quyền Quản trị viên hoặc xử lý vi phạm tài khoản trên toàn hệ thống
          </p>
        </div>

        <div style={{ position: 'relative', width: '320px' }}>
          <Search size={18} color="var(--text-muted)" style={{ position: 'absolute', left: '14px', top: '14px' }} />
          <input
            type="text"
            placeholder="Tìm theo tên hoặc email tài khoản..."
            className="form-input"
            style={{ paddingLeft: '40px' }}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
      </div>

      <div className="card" style={{ padding: 0 }}>
        <div className="table-container">
          <table className="admin-table">
            <thead>
              <tr>
                <th>Thành viên</th>
                <th>Email liên hệ</th>
                <th>Số điện thoại</th>
                <th>Vai trò (Role)</th>
                <th>Ngày gia nhập</th>
                <th>Phân quyền</th>
                <th>Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan="7" style={{ textAlign: 'center', padding: '48px' }}>Đang tải danh sách tài khoản...</td>
                </tr>
              ) : filteredUsers.length === 0 ? (
                <tr>
                  <td colSpan="7" style={{ textAlign: 'center', padding: '48px', color: 'var(--text-secondary)' }}>Không tìm thấy tài khoản người dùng nào.</td>
                </tr>
              ) : (
                filteredUsers.map(u => (
                  <tr key={u.id}>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                        <div style={{
                          width: '40px', height: '40px', borderRadius: '50%',
                          backgroundColor: u.role === 'Admin' ? '#006A38' : '#E9F5EE',
                          color: u.role === 'Admin' ? 'white' : '#006A38',
                          display: 'flex', alignItems: 'center', justifyContent: 'center',
                          fontWeight: '800', fontSize: '16px'
                        }}>
                          {u.name?.[0]?.toUpperCase() || 'U'}
                        </div>
                        <div>
                          <div style={{ fontWeight: '700', fontSize: '15px' }}>{u.name || 'Người dùng'}</div>
                          <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>ID: #{u.id?.substring(0, 8)}</div>
                        </div>
                      </div>
                    </td>
                    <td style={{ fontSize: '14px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <Mail size={14} color="var(--text-muted)" />
                        <span>{u.email}</span>
                      </div>
                    </td>
                    <td style={{ fontSize: '14px', color: u.phone ? 'inherit' : 'var(--text-muted)' }}>
                      {u.phone || 'Chưa cập nhật'}
                    </td>
                    <td>
                      <span className={`badge ${u.role === 'Admin' ? 'badge-success' : 'badge-info'}`}>
                        {u.role === 'Admin' ? '🛡 Quản trị viên (Admin)' : '👤 Khách hàng (Customer)'}
                      </span>
                    </td>
                    <td style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>
                      {new Date(u.createdAt).toLocaleDateString('vi-VN')}
                    </td>
                    <td>
                      <button
                        disabled={updatingId === u.id}
                        onClick={() => handleToggleRole(u.id, u.role, u.name)}
                        className={`btn ${u.role === 'Admin' ? 'btn-secondary' : 'btn-primary'}`}
                        style={{ padding: '6px 12px', fontSize: '12.5px' }}
                      >
                        {u.role === 'Admin' ? 'Giáng xuống Customer' : '🛡 Cấp quyền Admin'}
                      </button>
                    </td>
                    <td>
                      <button
                        onClick={() => handleDeleteUser(u.id, u.name)}
                        className="btn btn-danger"
                        style={{ padding: '8px' }}
                        title="Xóa tài khoản"
                      >
                        <Trash2 size={16} />
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default UsersPage;
