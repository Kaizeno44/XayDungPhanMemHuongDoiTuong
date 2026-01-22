"use client";
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import axios from 'axios'; 
import Cookies from 'js-cookie';
import { jwtDecode } from "jwt-decode"; 

export default function LoginPage() {
  const router = useRouter();
  
  const [email, setEmail] = useState('bateo@bizflow.com');
  const [password, setPassword] = useState('123456');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const response = await axios.post('http://localhost:5000/api/auth/login', {
        email: email,
        password
      });

      const token = response.data.token;
      if (!token) throw new Error("Không nhận được Token!");

      const decoded = jwtDecode(token);
      const userRole = decoded["http://schemas.microsoft.com/ws/2008/06/identity/claims/role"] || decoded.role;

      Cookies.set('accessToken', token, { expires: 1 });

      // --- SỬA ĐOẠN NÀY ---
      console.log("Vai trò đăng nhập:", userRole); // Log ra để kiểm tra

      if (userRole === 'SuperAdmin') {
          // 1. Nếu là Admin -> Cho sang trang quản trị hệ thống
          router.push('/admin/dashboard'); 
      } else if (userRole === 'Owner') {
          // 2. Nếu là Chủ shop -> Cho sang trang bán hàng
          router.push('/merchant/dashboard');
      } else if (userRole === 'Employee') {
          alert("⛔ TÀI KHOẢN NHÂN VIÊN KHÔNG ĐƯỢC PHÉP TRUY CẬP WEB!");
          Cookies.remove('accessToken');
      } else {
          setError("Tài khoản không có quyền truy cập hợp lệ!");
      }

    } catch (err) {
      console.error(err);
      const msg = err.response?.data?.message || err.message;
      setError(msg || 'Đăng nhập thất bại!');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100 font-sans">
      <div className="bg-white p-8 rounded-xl shadow-xl max-w-md w-full border border-gray-100">
        <h1 className="text-3xl font-bold text-center text-blue-600 mb-2">BizFlow</h1>
        <p className="text-center text-gray-500 mb-6">Đăng nhập hệ thống</p>
        
        {error && <div className="bg-red-50 text-red-600 p-3 rounded mb-4 text-sm text-center">⚠️ {error}</div>}

        <form onSubmit={handleLogin} className="space-y-4">
          <div>
            <label className="block text-gray-800 text-sm font-bold mb-2">Email</label>
            <input type="email" required className="w-full p-3 border border-gray-300 rounded text-gray-900 focus:ring-2 focus:ring-blue-500"
              value={email} onChange={(e) => setEmail(e.target.value)} />
          </div>
          <div>
            <label className="block text-gray-800 text-sm font-bold mb-2">Mật khẩu</label>
            <input type="password" required className="w-full p-3 border border-gray-300 rounded text-gray-900 focus:ring-2 focus:ring-blue-500"
              value={password} onChange={(e) => setPassword(e.target.value)} />
          </div>
          <button type="submit" disabled={loading}
            className={`w-full p-3 text-white font-bold rounded bg-blue-600 hover:bg-blue-700 transition-colors ${loading ? 'opacity-70' : ''}`}>
            {loading ? 'Đang xử lý...' : 'Đăng Nhập'}
          </button>
        </form>
      </div>
    </div>
  );
}
