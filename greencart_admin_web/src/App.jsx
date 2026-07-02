import React, { useState } from 'react';
import { AuthProvider, useAuth } from './context/AuthContext';
import AdminLayout from './components/AdminLayout';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import OrdersPage from './pages/OrdersPage';
import ProductsPage from './pages/ProductsPage';
import CategoriesPage from './pages/CategoriesPage';
import UsersPage from './pages/UsersPage';
import MealPlansPage from './pages/MealPlansPage';

const AppContent = () => {
  const { isAuthenticated } = useAuth();
  const [activeTab, setActiveTab] = useState('dashboard');
  const [refreshKey, setRefreshKey] = useState(0);

  if (!isAuthenticated) {
    return <LoginPage />;
  }

  const handleRefresh = () => {
    setRefreshKey(prev => prev + 1);
  };

  const renderContent = () => {
    switch (activeTab) {
      case 'dashboard':
        return <DashboardPage key={refreshKey} setActiveTab={setActiveTab} />;
      case 'orders':
        return <OrdersPage key={refreshKey} />;
      case 'products':
        return <ProductsPage key={refreshKey} />;
      case 'categories':
        return <CategoriesPage key={refreshKey} />;
      case 'users':
        return <UsersPage key={refreshKey} />;
      case 'meal-plans':
        return <MealPlansPage key={refreshKey} />;
      default:
        return <DashboardPage key={refreshKey} setActiveTab={setActiveTab} />;
    }
  };

  return (
    <AdminLayout
      activeTab={activeTab}
      setActiveTab={setActiveTab}
      onRefresh={handleRefresh}
    >
      {renderContent()}
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
