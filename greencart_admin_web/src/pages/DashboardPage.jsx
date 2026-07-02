import React, { useEffect, useState } from 'react';
import { DollarSign, ShoppingBag, Package, AlertTriangle, TrendingUp, CheckCircle2, Clock, ArrowUpRight } from 'lucide-react';
import api from '../services/api';

const DashboardPage = ({ setActiveTab }) => {
  const [orders, setOrders] = useState([]);
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);

  const fetchDashboardData = async () => {
    setLoading(true);
    try {
      const [ordersRes, productsRes] = await Promise.all([
        api.get('/admin/orders'),
        api.get('/admin/products')
      ]);
      setOrders(ordersRes.data || []);
      setProducts(productsRes.data || []);
    } catch (err) {
      console.error('Lỗi khi tải dữ liệu Dashboard:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDashboardData();
  }, []);

  // Format currency VNĐ
  const formatCurrency = (val) => {
    return new Intl.NumberFormat('vi-VN').format(Math.round(val)) + ' đ';
  };

  // Calculations
  const totalRevenue = orders
    .filter(o => o.status !== 'Cancelled')
    .reduce((sum, o) => sum + (o.totalAmount || 0), 0);

  const pendingOrdersCount = orders.filter(o => o.status === 'Pending').length;
  const shippingOrdersCount = orders.filter(o => o.status === 'Shipping').length;
  const deliveredOrdersCount = orders.filter(o => o.status === 'Delivered').length;
  const lowStockProducts = products.filter(p => p.stock < 10);

  if (loading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '60vh' }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{
            width: '48px', height: '48px', border: '4px solid #E2E8E5',
            borderTopColor: '#006A38', borderRadius: '50%',
            animation: 'spin 1s linear infinite', margin: '0 auto 16px'
          }} />
          <p style={{ color: 'var(--text-secondary)' }}>Đang tổng hợp số liệu trực tiếp từ Database...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="animate-fade-in">
      {/* Top Welcome Banner */}
      <div style={{
        background: 'linear-gradient(135deg, #0A2E1C 0%, #006A38 100%)',
        borderRadius: '24px',
        padding: '32px',
        color: 'white',
        marginBottom: '32px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        boxShadow: '0 16px 36px rgba(0, 106, 56, 0.2)'
      }}>
        <div>
          <span style={{ fontSize: '13px', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '1.5px', color: '#00E676' }}>
            Hệ thống Quản Trị Trực Tuyến
          </span>
          <h1 style={{ fontSize: '28px', fontWeight: '800', marginTop: '6px', marginBottom: '8px' }}>
            Xin chào Quản trị viên GreenCart! 👋
          </h1>
          <p style={{ opacity: 0.85, fontSize: '15px', maxWidth: '600px' }}>
            Hôm nay bạn có <strong>{pendingOrdersCount} đơn hàng chờ xác nhận</strong> và <strong>{lowStockProducts.length} sản phẩm sắp hết tồn kho</strong> cần chú ý.
          </p>
        </div>
        <button
          onClick={() => setActiveTab('orders')}
          className="btn"
          style={{
            backgroundColor: '#00E676', color: '#0A2E1C', padding: '14px 24px',
            fontSize: '15px', fontWeight: '800', borderRadius: '16px'
          }}
        >
          <span>Xử lý đơn hàng ngay</span>
          <ArrowUpRight size={20} />
        </button>
      </div>

      {/* KPI Cards Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '24px', marginBottom: '32px' }}>
        <div className="card" style={{ borderLeft: '5px solid #00C853' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '16px' }}>
            <div>
              <span style={{ fontSize: '13px', fontWeight: '600', color: 'var(--text-secondary)' }}>TỔNG DOANH THU</span>
              <h3 style={{ fontSize: '26px', fontWeight: '800', color: 'var(--primary)', marginTop: '4px' }}>
                {formatCurrency(totalRevenue)}
              </h3>
            </div>
            <div style={{ padding: '12px', backgroundColor: '#E9F5EE', borderRadius: '14px', color: '#006A38' }}>
              <DollarSign size={24} />
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '12.5px', color: '#008648', fontWeight: '600' }}>
            <TrendingUp size={16} />
            <span>Đã loại trừ các đơn hủy</span>
          </div>
        </div>

        <div className="card" style={{ borderLeft: '5px solid #3B82F6' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '16px' }}>
            <div>
              <span style={{ fontSize: '13px', fontWeight: '600', color: 'var(--text-secondary)' }}>TỔNG ĐƠN HÀNG</span>
              <h3 style={{ fontSize: '26px', fontWeight: '800', color: '#1E40AF', marginTop: '4px' }}>
                {orders.length} đơn
              </h3>
            </div>
            <div style={{ padding: '12px', backgroundColor: '#EFF6FF', borderRadius: '14px', color: '#3B82F6' }}>
              <ShoppingBag size={24} />
            </div>
          </div>
          <div style={{ display: 'flex', gap: '12px', fontSize: '12.5px', color: 'var(--text-secondary)' }}>
            <span>⏳ {pendingOrdersCount} Chờ</span>
            <span>🚚 {shippingOrdersCount} Giao</span>
            <span>✅ {deliveredOrdersCount} Xong</span>
          </div>
        </div>

        <div className="card" style={{ borderLeft: '5px solid #8B5CF6' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '16px' }}>
            <div>
              <span style={{ fontSize: '13px', fontWeight: '600', color: 'var(--text-secondary)' }}>SẢN PHẨM TRONG KHO</span>
              <h3 style={{ fontSize: '26px', fontWeight: '800', color: '#6D28D9', marginTop: '4px' }}>
                {products.length} mặt hàng
              </h3>
            </div>
            <div style={{ padding: '12px', backgroundColor: '#F5F3FF', borderRadius: '14px', color: '#8B5CF6' }}>
              <Package size={24} />
            </div>
          </div>
          <div style={{ fontSize: '12.5px', color: 'var(--text-secondary)' }}>
            Toàn bộ thực phẩm Hữu cơ & Tươi sạch
          </div>
        </div>

        <div className="card" style={{ borderLeft: '5px solid #FF9F1C' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '16px' }}>
            <div>
              <span style={{ fontSize: '13px', fontWeight: '600', color: 'var(--text-secondary)' }}>CẢNH BÁO TỒN KHO</span>
              <h3 style={{ fontSize: '26px', fontWeight: '800', color: '#D97706', marginTop: '4px' }}>
                {lowStockProducts.length} món sắp hết
              </h3>
            </div>
            <div style={{ padding: '12px', backgroundColor: '#FFFBEB', borderRadius: '14px', color: '#D97706' }}>
              <AlertTriangle size={24} />
            </div>
          </div>
          <div style={{ fontSize: '12.5px', color: '#D97706', fontWeight: '600' }}>
            Cần bổ sung nguồn hàng gấp
          </div>
        </div>
      </div>

      {/* Bottom Section: Recent Orders & Low Stock Table */}
      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '24px' }}>
        {/* Recent Orders */}
        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
            <h3 style={{ fontSize: '18px', fontWeight: '800' }}>Đơn hàng gần đây</h3>
            <button
              onClick={() => setActiveTab('orders')}
              style={{ background: 'none', border: 'none', color: 'var(--primary)', fontWeight: '700', cursor: 'pointer', fontSize: '13.5px' }}
            >
              Xem tất cả →
            </button>
          </div>

          <div className="table-container">
            <table className="admin-table">
              <thead>
                <tr>
                  <th>Mã đơn</th>
                  <th>Tổng tiền</th>
                  <th>Trạng thái</th>
                  <th>Thời gian</th>
                </tr>
              </thead>
              <tbody>
                {orders.slice(0, 5).map((order) => (
                  <tr key={order.id}>
                    <td style={{ fontWeight: '700' }}>#{order.orderNumber || order.id?.substring(0, 8)}</td>
                    <td style={{ fontWeight: '700', color: 'var(--primary)' }}>{formatCurrency(order.totalAmount || 0)}</td>
                    <td>
                      <span className={`badge ${
                        order.status === 'Delivered' ? 'badge-success' :
                        order.status === 'Cancelled' ? 'badge-danger' :
                        order.status === 'Shipping' ? 'badge-info' : 'badge-warning'
                      }`}>
                        {order.status}
                      </span>
                    </td>
                    <td style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>
                      {new Date(order.createdAt).toLocaleDateString('vi-VN')} {new Date(order.createdAt).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })}
                    </td>
                  </tr>
                ))}
                {orders.length === 0 && (
                  <tr>
                    <td colSpan="4" style={{ textAlign: 'center', padding: '32px', color: 'var(--text-secondary)' }}>
                      Chưa có đơn hàng nào trong hệ thống.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Low Stock Watchlist */}
        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
            <h3 style={{ fontSize: '18px', fontWeight: '800' }}>Sắp hết hàng</h3>
            <button
              onClick={() => setActiveTab('products')}
              style={{ background: 'none', border: 'none', color: 'var(--primary)', fontWeight: '700', cursor: 'pointer', fontSize: '13.5px' }}
            >
              Cập nhật kho →
            </button>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            {lowStockProducts.slice(0, 6).map((item) => (
              <div key={item.id} style={{
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                padding: '12px', borderRadius: '12px', backgroundColor: '#F8FAF9', border: '1px solid var(--border-color)'
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                  <img
                    src={item.imageUrl}
                    alt={item.name}
                    style={{ width: '44px', height: '44px', borderRadius: '10px', objectFit: 'cover' }}
                    onError={(e) => { e.target.src = 'https://images.unsplash.com/photo-1540420773420-3366772f4999'; }}
                  />
                  <div>
                    <div style={{ fontWeight: '700', fontSize: '14px' }}>{item.name}</div>
                    <div style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>{formatCurrency(item.price)}</div>
                  </div>
                </div>
                <div style={{
                  padding: '4px 10px', borderRadius: '8px',
                  backgroundColor: item.stock <= 3 ? '#FFEBEE' : '#FFFBEB',
                  color: item.stock <= 3 ? '#D32F2F' : '#D97706',
                  fontWeight: '800', fontSize: '13px'
                }}>
                  Còn {item.stock}
                </div>
              </div>
            ))}
            {lowStockProducts.length === 0 && (
              <div style={{ textAlign: 'center', padding: '32px', color: 'var(--text-secondary)' }}>
                🎉 Tất cả sản phẩm đều đủ tồn kho!
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default DashboardPage;
