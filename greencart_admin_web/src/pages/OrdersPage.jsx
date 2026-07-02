import React, { useEffect, useState } from 'react';
import { Search, Filter, CheckCircle, Truck, XCircle, Clock, Eye, AlertCircle, Sparkles, Download } from 'lucide-react';
import confetti from 'canvas-confetti';
import api from '../services/api';

const OrdersPage = () => {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeFilter, setActiveFilter] = useState('All');
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedOrder, setSelectedOrder] = useState(null);
  const [updatingId, setUpdatingId] = useState(null);
  const [aiLoading, setAiLoading] = useState(false);

  const triggerAiAutoSubstitute = async (orderId) => {
    setAiLoading(true);
    try {
      const res = await api.post(`/admin/orders/${orderId}/ai-auto-substitute`);
      alert(res.data?.message || '🤖 AI đã xử lý đề xuất thay thế!');
    } catch (err) {
      alert(err.response?.data?.message || 'Lỗi khi chạy AI tự động đề xuất');
    } finally {
      setAiLoading(false);
    }
  };

  const triggerAiSubstituteItem = async (orderId, itemId) => {
    setAiLoading(true);
    try {
      await api.post(`/admin/orders/${orderId}/items/${itemId}/ai-substitute`);
      alert('🤖 AI GreenCart đã tạo đề xuất thay thế tối ưu và gửi thông báo tới khách hàng!');
    } catch (err) {
      alert(err.response?.data?.message || 'Lỗi khi tạo đề xuất AI');
    } finally {
      setAiLoading(false);
    }
  };

  const fetchOrders = async () => {
    setLoading(true);
    try {
      const res = await api.get('/admin/orders');
      setOrders(res.data || []);
    } catch (err) {
      console.error('Lỗi khi tải danh sách đơn hàng:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOrders();
  }, []);

  const formatCurrency = (val) => {
    return new Intl.NumberFormat('vi-VN').format(Math.round(val)) + ' đ';
  };

  const updateOrderStatus = async (orderId, newStatus) => {
    setUpdatingId(orderId);
    try {
      await api.put(`/admin/orders/${orderId}/status`, { status: newStatus });
      
      // Update local state
      setOrders(prev => prev.map(o => o.id === orderId ? { ...o, status: newStatus, updatedAt: new Date().toISOString() } : o));
      if (selectedOrder && selectedOrder.id === orderId) {
        setSelectedOrder(prev => ({ ...prev, status: newStatus }));
      }

      if (newStatus === 'Completed' || newStatus === 'Delivered') {
        confetti({ particleCount: 80, spread: 60, origin: { y: 0.6 } });
      }
    } catch (err) {
      alert(err.response?.data?.message || 'Không thể cập nhật trạng thái đơn hàng');
    } finally {
      setUpdatingId(null);
    }
  };

  const filteredOrders = orders.filter(o => {
    const matchesTab = activeFilter === 'All' || o.status === activeFilter ||
      (activeFilter === 'Delivering' && o.status === 'Shipping') ||
      (activeFilter === 'Completed' && o.status === 'Delivered');
    const matchesSearch = (o.orderNumber || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
                          (o.id || '').toLowerCase().includes(searchTerm.toLowerCase());
    return matchesTab && matchesSearch;
  });

  const filterTabs = [
    { id: 'All', label: 'Tất cả đơn' },
    { id: 'Pending', label: '⏳ Chờ xác nhận' },
    { id: 'Confirmed', label: '📦 Đã xác nhận' },
    { id: 'Delivering', label: '🚚 Đang giao' },
    { id: 'Completed', label: '✅ Hoàn thành' },
    { id: 'Cancelled', label: '❌ Đã hủy' },
  ];

  const exportOrdersCSV = () => {
    const formatCurrencyPlain = (val) => new Intl.NumberFormat('vi-VN').format(Math.round(val));
    const header = ['Mã đơn hàng', 'Khách hàng', 'Số điện thoại', 'Địa chỉ giao hàng', 'Tổng tiền (VNĐ)', 'Trạng thái', 'Phương thức thanh toán', 'Ngày đặt'];
    const rows = filteredOrders.map(o => [
      o.orderNumber || o.id?.substring(0, 8),
      o.userName || o.userId || 'N/A',
      o.userPhone || 'N/A',
      (o.shippingAddress || 'N/A').replace(/,/g, ' -'),
      formatCurrencyPlain(o.total || o.totalAmount || 0),
      o.status || 'N/A',
      o.paymentMethod || 'N/A',
      o.createdAt ? new Date(o.createdAt).toLocaleDateString('vi-VN') : 'N/A'
    ]);

    const csvContent = [header, ...rows].map(row => row.map(cell => `"${cell}"`).join(',')).join('\n');
    // UTF-8 BOM for Excel Vietnamese support
    const BOM = '\uFEFF';
    const blob = new Blob([BOM + csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `GreenCart_DonHang_${new Date().toISOString().slice(0, 10)}.csv`;
    link.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="animate-fade-in">
      {/* Top Filter Bar */}
      <div className="card" style={{ marginBottom: '24px' }}>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '16px', alignItems: 'center', justifyContent: 'space-between' }}>
          {/* Search Box */}
          <div style={{ position: 'relative', minWidth: '280px', flex: 1 }}>
            <Search size={18} color="var(--text-muted)" style={{ position: 'absolute', left: '14px', top: '14px' }} />
            <input
              type="text"
              placeholder="Tìm theo mã đơn hàng (#ORD...)..."
              className="form-input"
              style={{ paddingLeft: '40px' }}
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>

          {/* Export Button */}
          <button
            onClick={exportOrdersCSV}
            className="btn"
            style={{
              backgroundColor: '#006A38', color: 'white', padding: '10px 18px',
              fontSize: '13.5px', fontWeight: '700', borderRadius: '12px',
              display: 'flex', alignItems: 'center', gap: '8px', whiteSpace: 'nowrap'
            }}
          >
            <Download size={16} />
            📥 Xuất Excel/CSV
          </button>

          {/* Status Tabs */}
          <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
            {filterTabs.map(tab => (
              <button
                key={tab.id}
                onClick={() => setActiveFilter(tab.id)}
                style={{
                  padding: '10px 16px',
                  borderRadius: '12px',
                  border: 'none',
                  backgroundColor: activeFilter === tab.id ? 'var(--primary)' : '#F0F3F1',
                  color: activeFilter === tab.id ? 'white' : 'var(--text-secondary)',
                  fontWeight: activeFilter === tab.id ? '700' : '600',
                  fontSize: '13.5px',
                  cursor: 'pointer',
                  transition: 'all 0.2s'
                }}
              >
                {tab.label}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Orders Table */}
      <div className="card" style={{ padding: '0' }}>
        <div className="table-container">
          <table className="admin-table">
            <thead>
              <tr>
                <th>Mã đơn hàng</th>
                <th>Thời gian đặt</th>
                <th>Số lượng món</th>
                <th>Tổng thanh toán</th>
                <th>Trạng thái hiện tại</th>
                <th>Chuyển trạng thái nhanh</th>
                <th>Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan="7" style={{ textAlign: 'center', padding: '48px' }}>
                    Đang tải dữ liệu đơn hàng...
                  </td>
                </tr>
              ) : filteredOrders.length === 0 ? (
                <tr>
                  <td colSpan="7" style={{ textAlign: 'center', padding: '48px', color: 'var(--text-secondary)' }}>
                    Không tìm thấy đơn hàng nào phù hợp bộ lọc.
                  </td>
                </tr>
              ) : (
                filteredOrders.map((order) => (
                  <tr key={order.id}>
                    <td style={{ fontWeight: '800', color: 'var(--primary)' }}>
                      #{order.orderNumber || order.id?.substring(0, 8)}
                    </td>
                    <td style={{ fontSize: '13.5px', color: 'var(--text-secondary)' }}>
                      {new Date(order.createdAt).toLocaleDateString('vi-VN')} {new Date(order.createdAt).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })}
                    </td>
                    <td style={{ fontWeight: '600' }}>
                      {order.items?.length || 0} sản phẩm
                    </td>
                    <td style={{ fontWeight: '800', fontSize: '15px', color: '#1A1C1B' }}>
                      {formatCurrency(order.total || order.totalAmount || 0)}
                    </td>
                    <td>
                      <span className={`badge ${
                        (order.status === 'Completed' || order.status === 'Delivered') ? 'badge-success' :
                        order.status === 'Cancelled' ? 'badge-danger' :
                        (order.status === 'Delivering' || order.status === 'Shipping') ? 'badge-info' : 'badge-warning'
                      }`}>
                        {order.status === 'Delivering' ? 'Đang giao' : order.status === 'Completed' ? 'Hoàn thành' : order.status}
                      </span>
                    </td>
                    <td>
                      <div style={{ display: 'flex', gap: '6px' }}>
                        {order.status === 'Pending' && (
                          <button
                            disabled={updatingId === order.id}
                            onClick={() => updateOrderStatus(order.id, 'Confirmed')}
                            className="btn btn-primary"
                            style={{ padding: '6px 12px', fontSize: '12px' }}
                          >
                            Duyệt đơn
                          </button>
                        )}
                        {order.status === 'Confirmed' && (
                          <button
                            disabled={updatingId === order.id}
                            onClick={() => updateOrderStatus(order.id, 'Delivering')}
                            className="btn btn-secondary"
                            style={{ padding: '6px 12px', fontSize: '12px', background: '#DBEAFE', color: '#1E40AF' }}
                          >
                            🚚 Giao hàng
                          </button>
                        )}
                        {(order.status === 'Delivering' || order.status === 'Shipping') && (
                          <button
                            disabled={updatingId === order.id}
                            onClick={() => updateOrderStatus(order.id, 'Completed')}
                            className="btn btn-primary"
                            style={{ padding: '6px 12px', fontSize: '12px', background: '#00C853' }}
                          >
                            ✅ Hoàn tất
                          </button>
                        )}
                        {order.status !== 'Completed' && order.status !== 'Delivered' && order.status !== 'Cancelled' && (
                          <button
                            disabled={updatingId === order.id}
                            onClick={() => updateOrderStatus(order.id, 'Cancelled')}
                            className="btn btn-danger"
                            style={{ padding: '6px 10px', fontSize: '12px' }}
                            title="Hủy đơn hàng"
                          >
                            Hủy
                          </button>
                        )}
                      </div>
                    </td>
                    <td>
                      <button
                        onClick={() => setSelectedOrder(order)}
                        className="btn btn-secondary"
                        style={{ padding: '8px 14px' }}
                      >
                        <Eye size={16} />
                        <span>Chi tiết</span>
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Order Detail Modal */}
      {selectedOrder && (
        <div style={{
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
          backgroundColor: 'rgba(0, 0, 0, 0.55)', backdropFilter: 'blur(6px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000
        }}>
          <div className="card animate-fade-in" style={{ width: '90%', maxWidth: '650px', maxHeight: '85vh', overflowY: 'auto' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px', borderBottom: '1px solid var(--border-color)', paddingBottom: '16px' }}>
              <div>
                <h3 style={{ fontSize: '20px', fontWeight: '800' }}>
                  Chi tiết đơn #{selectedOrder.orderNumber || selectedOrder.id}
                </h3>
                <span style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>
                  Ngày đặt: {new Date(selectedOrder.createdAt).toLocaleString('vi-VN')}
                </span>
              </div>
              <button onClick={() => setSelectedOrder(null)} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: '20px', fontWeight: '700' }}>✕</button>
            </div>

            {/* Items List */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
              <h4 style={{ fontSize: '15px', fontWeight: '700', margin: 0 }}>Danh sách món đặt ({selectedOrder.items?.length || 0})</h4>
              <button
                disabled={aiLoading || selectedOrder.status === 'Completed' || selectedOrder.status === 'Cancelled'}
                onClick={() => triggerAiAutoSubstitute(selectedOrder.id)}
                className="btn btn-secondary"
                style={{ padding: '6px 12px', fontSize: '12px', background: '#E0F2FE', color: '#0369A1', border: 'none', borderRadius: '8px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '6px', fontWeight: '700' }}
              >
                <Sparkles size={14} />
                <span>{aiLoading ? 'AI đang xử lý...' : '✨ AI Đề xuất tối ưu (Rẻ hơn & Tốt hơn)'}</span>
              </button>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', marginBottom: '24px' }}>
              {(selectedOrder.items || []).map((item, idx) => (
                <div key={idx} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px', backgroundColor: '#F8FAF9', borderRadius: '12px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <div style={{ width: '40px', height: '40px', borderRadius: '8px', background: '#E2E8E5', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: '700', color: 'var(--primary)' }}>
                      {item.quantity}x
                    </div>
                    <div>
                      <div style={{ fontWeight: '700' }}>{item.productName || `Món hàng #${idx+1}`}</div>
                      <div style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>Đơn giá: {formatCurrency(item.price || 0)}</div>
                    </div>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                    {selectedOrder.status !== 'Completed' && selectedOrder.status !== 'Cancelled' && (
                      <button
                        disabled={aiLoading}
                        onClick={() => triggerAiSubstituteItem(selectedOrder.id, item.id)}
                        style={{ padding: '4px 8px', fontSize: '11px', background: '#FEF3C7', color: '#B45309', border: '1px solid #FDE68A', borderRadius: '6px', cursor: 'pointer', fontWeight: '700' }}
                      >
                        🤖 AI Tối ưu món rẻ hơn
                      </button>
                    )}
                    <div style={{ fontWeight: '800', color: 'var(--primary)' }}>
                      {formatCurrency((item.price || 0) * (item.quantity || 1))}
                    </div>
                  </div>
                </div>
              ))}
            </div>

            {/* Total Summary */}
            <div style={{ padding: '16px', backgroundColor: '#E9F5EE', borderRadius: '14px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontSize: '16px', fontWeight: '700', color: '#006A38' }}>TỔNG THANH TOÁN:</span>
              <span style={{ fontSize: '22px', fontWeight: '800', color: '#006A38' }}>
                {formatCurrency(selectedOrder.totalAmount || 0)}
              </span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default OrdersPage;
