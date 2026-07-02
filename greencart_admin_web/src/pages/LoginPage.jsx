import React, { useState } from 'react';
import { Shield, Lock, Mail, ArrowRight, AlertCircle, CheckCircle } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

const LoginPage = () => {
  const { login, loading, error } = useAuth();
  const [email, setEmail] = useState('admin@example.local');
  const [password, setPassword] = useState('admin123!');
  const [customError, setCustomError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setCustomError('');
    if (!email || !password) {
      setCustomError('Vui lòng nhập đầy đủ email và mật khẩu.');
      return;
    }
    await login(email, password);
  };

  return (
    <div style={{
      minHeight: '100vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      background: 'linear-gradient(135deg, #0A2E1C 0%, #006A38 50%, #003B1F 100%)',
      padding: '24px',
      position: 'relative',
      overflow: 'hidden'
    }}>
      {/* Decorative blurred background circles */}
      <div style={{
        position: 'absolute', width: '450px', height: '450px', borderRadius: '50%',
        background: 'rgba(0, 230, 118, 0.15)', filter: 'blur(80px)', top: '-10%', left: '-10%'
      }} />
      <div style={{
        position: 'absolute', width: '500px', height: '500px', borderRadius: '50%',
        background: 'rgba(255, 159, 28, 0.1)', filter: 'blur(100px)', bottom: '-10%', right: '-10%'
      }} />

      <div className="animate-fade-in" style={{
        width: '100%',
        maxWidth: '460px',
        backgroundColor: 'rgba(255, 255, 255, 0.95)',
        backdropFilter: 'blur(20px)',
        borderRadius: '24px',
        padding: '40px',
        boxShadow: '0 25px 60px rgba(0, 0, 0, 0.35)',
        border: '1px solid rgba(255, 255, 255, 0.4)',
        position: 'relative',
        zIndex: 10
      }}>
        {/* Header Icon */}
        <div style={{ textAlign: 'center', marginBottom: '32px' }}>
          <div style={{
            width: '64px', height: '64px', borderRadius: '20px',
            background: 'linear-gradient(135deg, #00C853, #006A38)',
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
            color: 'white', boxShadow: '0 10px 25px rgba(0, 200, 83, 0.4)',
            marginBottom: '16px'
          }}>
            <Shield size={32} />
          </div>
          <h1 style={{ fontSize: '26px', fontWeight: '800', color: '#1A1C1B', marginBottom: '8px' }}>
            GreenCart Admin
          </h1>
          <p style={{ fontSize: '14px', color: '#6E7A6F' }}>
            Đăng nhập vào cổng điều hành hệ thống thời gian thực
          </p>
        </div>

        {/* Default Account Tip */}
        <div style={{
          backgroundColor: '#E9F5EE', borderLeft: '4px solid #00C853',
          padding: '14px', borderRadius: '8px', marginBottom: '24px',
          display: 'flex', gap: '10px', alignItems: 'flex-start'
        }}>
          <CheckCircle size={18} color="#00C853" style={{ flexShrink: 0, marginTop: '2px' }} />
          <div style={{ fontSize: '13px', color: '#006A38' }}>
            <strong>Tài khoản cấu hình sẵn (Seeded):</strong><br />
            Email: <code>admin@example.local</code><br />
            Mật khẩu: <code>admin123!</code>
          </div>
        </div>

        {/* Error Display */}
        {(error || customError) && (
          <div style={{
            backgroundColor: '#FFEBEE', color: '#D32F2F', padding: '12px 16px',
            borderRadius: '10px', fontSize: '13.5px', marginBottom: '20px',
            display: 'flex', alignItems: 'center', gap: '10px'
          }}>
            <AlertCircle size={18} />
            <span>{error || customError}</span>
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label className="form-label" style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
              <Mail size={16} color="#6E7A6F" />
              <span>Email Quản Trị</span>
            </label>
            <input
              type="email"
              className="form-input"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@example.local"
              required
            />
          </div>

          <div className="form-group" style={{ marginBottom: '28px' }}>
            <label className="form-label" style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
              <Lock size={16} color="#6E7A6F" />
              <span>Mật khẩu</span>
            </label>
            <input
              type="password"
              className="form-input"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              required
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="btn btn-primary"
            style={{ width: '100%', padding: '15px', fontSize: '16px', borderRadius: '12px' }}
          >
            <span>{loading ? 'Đang kiểm tra quyền...' : 'Đăng nhập vào Hệ thống'}</span>
            {!loading && <ArrowRight size={18} />}
          </button>
        </form>

        <div style={{ textAlign: 'center', marginTop: '28px', fontSize: '12.5px', color: '#95A397' }}>
          Được bảo mật bởi GreenCart API (.NET Core 8 & JWT Auth)
        </div>
      </div>
    </div>
  );
};

export default LoginPage;
