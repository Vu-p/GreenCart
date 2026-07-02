import React from 'react';
import Sidebar from './Sidebar';
import Header from './Header';

const AdminLayout = ({ activeTab, setActiveTab, children, onRefresh }) => {
  return (
    <div style={{ display: 'flex', minHeight: '100vh', backgroundColor: 'var(--bg-main)' }}>
      <Sidebar activeTab={activeTab} setActiveTab={setActiveTab} />
      <div style={{ flex: 1, marginLeft: '270px', display: 'flex', flexDirection: 'column' }}>
        <Header activeTab={activeTab} onRefresh={onRefresh} />
        <main style={{ flex: 1, padding: '32px' }}>
          {children}
        </main>
      </div>
    </div>
  );
};

export default AdminLayout;
