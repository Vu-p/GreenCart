import React from 'react';
import { LayoutDashboard, ShoppingBag, Package, FolderTree, LogOut, ShieldAlert } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

const Sidebar = ({ activeTab, setActiveTab }) => {
  const { logout, user } = useAuth();

  const navItems = [
    { id: 'dashboard', label: 'Tổng quan (Dashboard)', icon: LayoutDashboard },
    { id: 'orders', label: 'Quản lý Đơn hàng', icon: ShoppingBag },
    { id: 'products', label: 'Sản phẩm & Kho', icon: Package },
    { id: 'categories', label: 'Danh mục', icon: FolderTree },
  ];

  return (
    <aside style={{
      width: '270px',
      height: '100vh',
      backgroundColor: '#0A2E1C',
      color: 'white',
      display: 'flex',
      flexDirection: 'column',
      position: 'fixed',
      left: 0,
      top: 0,
      zIndex: 100,
      boxShadow: '4px 0 24px rgba(0,0,0,0.12)'
    }}>
      {/* Brand Logo */}
      <div style={{ padding: '28px 24px', borderBottom: '1px solid rgba(255,255,255,0.1)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <div style={{
            width: '40px', height: '40px', borderRadius: '12px',
            background: 'linear-gradient(135deg, #00C853, #008648)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: '20px', fontWeight: '800', color: 'white',
            boxShadow: '0 4px 12px rgba(0, 200, 83, 0.4)'
          }}>
            G
          </div>
          <div>
            <h1 style={{ fontSize: '18px', fontWeight: '800', letterSpacing: '-0.3px', margin: 0 }}>GreenCart Web</h1>
            <span style={{ fontSize: '11px', opacity: 0.7, fontWeight: '500', textTransform: 'uppercase', letterSpacing: '1px' }}>Admin Portal</span>
          </div>
        </div>
      </div>

      {/* Navigation */}
      <div style={{ flex: 1, padding: '24px 16px', display: 'flex', flexDirection: 'column', gap: '8px' }}>
        <div style={{ fontSize: '11px', fontWeight: '700', color: 'rgba(255,255,255,0.4)', textTransform: 'uppercase', letterSpacing: '1px', padding: '0 12px', marginBottom: '8px' }}>
          Menu Quản Trị
        </div>
        {navItems.map((item) => {
          const Icon = item.icon;
          const isActive = activeTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => setActiveTab(item.id)}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '14px',
                padding: '14px 16px',
                borderRadius: '14px',
                border: 'none',
                backgroundColor: isActive ? 'rgba(255, 255, 255, 0.15)' : 'transparent',
                color: isActive ? '#00E676' : 'rgba(255, 255, 255, 0.75)',
                fontWeight: isActive ? '700' : '500',
                fontSize: '14.5px',
                cursor: 'pointer',
                transition: 'all 0.2s ease',
                textAlign: 'left'
              }}
            >
              <Icon size={20} color={isActive ? '#00E676' : 'currentColor'} />
              <span>{item.label}</span>
            </button>
          );
        })}
      </div>

      {/* Admin User Info Footer */}
      <div style={{ padding: '20px', borderTop: '1px solid rgba(255,255,255,0.1)', background: 'rgba(0,0,0,0.2)' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div style={{
              width: '36px', height: '36px', borderRadius: '50%',
              backgroundColor: 'rgba(255,255,255,0.15)', display: 'flex',
              alignItems: 'center', justifyContent: 'center', fontWeight: '700'
            }}>
              {user?.name?.[0]?.toUpperCase() || 'A'}
            </div>
            <div>
              <div style={{ fontSize: '13.5px', fontWeight: '600' }}>{user?.name || 'Admin'}</div>
              <div style={{ fontSize: '11.5px', color: '#00E676' }}>Quyền Quản Trị</div>
            </div>
          </div>
          <button
            onClick={logout}
            title="Đăng xuất"
            style={{
              background: 'rgba(255,82,82,0.15)', border: 'none', color: '#FF5252',
              padding: '8px', borderRadius: '8px', cursor: 'pointer', transition: 'all 0.2s'
            }}
          >
            <LogOut size={18} />
          </button>
        </div>
      </div>
    </aside>
  );
};

export default Sidebar;
