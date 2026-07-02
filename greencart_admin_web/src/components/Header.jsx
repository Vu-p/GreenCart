import React from 'react';
import { Bell, Search, Activity, RefreshCw } from 'lucide-react';

const Header = ({ activeTab, onRefresh }) => {
  const getTitle = () => {
    switch (activeTab) {
      case 'dashboard': return 'Bảng điều khiển tổng quan';
      case 'orders': return 'Quản lý Đơn hàng hệ thống';
      case 'products': return 'Danh sách Sản phẩm & Kho hàng';
      case 'categories': return 'Quản lý Danh mục sản phẩm';
      case 'users': return 'Quản lý Khách hàng & Tài khoản';
      case 'meal-plans': return 'Quản lý Thực đơn & Kế hoạch (Meal Planner)';
      default: return 'Admin Portal';
    }
  };

  return (
    <header style={{
      height: '80px',
      backgroundColor: 'rgba(255, 255, 255, 0.85)',
      backdropFilter: 'blur(12px)',
      borderBottom: '1px solid var(--border-color)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: '0 32px',
      position: 'sticky',
      top: 0,
      zIndex: 50
    }}>
      <div>
        <h2 style={{ fontSize: '22px', fontWeight: '800', color: 'var(--text-primary)', margin: 0 }}>
          {getTitle()}
        </h2>
        <span style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>
          Theo dõi và quản lý dữ liệu thời gian thực từ GreenCart API (.NET Core)
        </span>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
        {/* Backend Status indicator */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: '8px',
          padding: '8px 14px', borderRadius: '20px',
          backgroundColor: '#E9F5EE', color: '#006A38',
          fontSize: '13px', fontWeight: '600'
        }}>
          <Activity size={16} color="#00C853" />
          <span>API Connected</span>
        </div>

        {/* Refresh button */}
        {onRefresh && (
          <button
            onClick={onRefresh}
            className="btn btn-secondary"
            style={{ padding: '10px 16px' }}
            title="Tải lại dữ liệu mới nhất"
          >
            <RefreshCw size={16} />
            <span>Làm mới</span>
          </button>
        )}
      </div>
    </header>
  );
};

export default Header;
