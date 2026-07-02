import React, { useState, Suspense } from 'react';
import { Routes, Route, Navigate, useNavigate, useLocation } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import AdminLayout from './components/AdminLayout';
import LoginPage from './pages/LoginPage';

// Code splitting / Lazy Loading từng trang để tối ưu tối đa RAM & tốc độ
const DashboardPage = React.lazy(() => import('./pages/DashboardPage'));
const OrdersPage = React.lazy(() => import('./pages/OrdersPage'));
const ProductsPage = React.lazy(() => import('./pages/ProductsPage'));
const CategoriesPage = React.lazy(() => import('./pages/CategoriesPage'));
const UsersPage = React.lazy(() => import('./pages/UsersPage'));
const MealPlansPage = React.lazy(() => import('./pages/MealPlansPage'));

const PageLoader = () => (
  <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '60vh' }}>
    <div style={{ textAlign: 'center' }}>
      <div style={{
        width: '44px', height: '44px', border: '4px solid #E2E8E5',
        borderTopColor: '#006A38', borderRadius: '50%',
        animation: 'spin 1s linear infinite', margin: '0 auto 16px'
      }} />
      <p style={{ color: 'var(--text-secondary)' }}>Đang tải trang...</p>
    </div>
  </div>
);

const AppContent = () => {
  const { isAuthenticated } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [refreshKey, setRefreshKey] = useState(0);

  if (!isAuthenticated) {
    return <LoginPage />;
  }

  const activeTab = location.pathname.replace('/', '') || 'dashboard';

  const handleTabChange = (tabId) => {
    navigate(`/${tabId}`);
  };

  const handleRefresh = () => {
    setRefreshKey(prev => prev + 1);
  };

  return (
    <AdminLayout
      activeTab={activeTab}
      setActiveTab={handleTabChange}
      onRefresh={handleRefresh}
    >
      <Suspense fallback={<PageLoader />}>
        <Routes>
          <Route path="/dashboard" element={<DashboardPage key={refreshKey} setActiveTab={handleTabChange} />} />
          <Route path="/orders" element={<OrdersPage key={refreshKey} />} />
          <Route path="/products" element={<ProductsPage key={refreshKey} />} />
          <Route path="/categories" element={<CategoriesPage key={refreshKey} />} />
          <Route path="/users" element={<UsersPage key={refreshKey} />} />
          <Route path="/meal-plans" element={<MealPlansPage key={refreshKey} />} />
          <Route path="*" element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </Suspense>
    </AdminLayout>
  );
};

const App = () => {
  return (
    <AuthProvider>
      <AppContent />
    </AuthProvider>
  );
};

export default App;
