"use client";
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import axios from 'axios'; 
import Cookies from 'js-cookie';
import { jwtDecode } from "jwt-decode"; 

export default function LoginPage() {
  const router = useRouter();
  
  // Tài khoản test mặc định
  const [email, setEmail] = useState('superadmin@bizflow.com');
  const [password, setPassword] = useState('admin');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      // 1. Gọi API Backend (Nhớ check kỹ port 5001 hay 5000 tùy máy bạn)
      const response = await axios.post('https://localhost:5001/api/auth/login', {
        email,
        password
      });

      const token = response.data.token;
      if (!token) throw new Error("Không nhận được Token!");

      // 2. Giải mã Token để xem ai đang đăng nhập
      const decoded = jwtDecode(token);
      
      // Lấy role (xử lý cả trường hợp role tên dài hoặc ngắn)
      const userRole = decoded["http://schemas.microsoft.com/ws/2008/06/identity/claims/role"] || decoded.role;

      // 3. ĐIỀU HƯỚNG THEO PHÂN QUYỀN (ROUTER GUARD)
      if (userRole === 'SuperAdmin') {
          Cookies.set('accessToken', token, { expires: 1 });
          router.push('/dashboard'); // Vào trang Admin hệ thống
      } 
      else if (userRole === 'Owner') {
          Cookies.set('accessToken', token, { expires: 1 });
          router.push('/merchant/dashboard'); // Vào trang Ông chủ
      } 
      // 👇 CHẶN NHÂN VIÊN TẠI ĐÂY 👇
      else if (userRole === 'Employee') {
          alert("⛔ TÀI KHOẢN NHÂN VIÊN KHÔNG ĐƯỢC PHÉP TRUY CẬP WEB!\nVui lòng tải Mobile App để bán hàng.");
          Cookies.remove('accessToken'); // Xóa token ngay lập tức
          // Không chuyển trang, giữ nguyên ở Login
      } 
      else {
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
            <label className="block text-gray-700 text-sm font-bold mb-2">Email</label>
            <input type="email" required className="w-full p-3 border rounded focus:ring-2 focus:ring-blue-500"
              value={email} onChange={(e) => setEmail(e.target.value)} />
          </div>
          <div>
            <label className="block text-gray-700 text-sm font-bold mb-2">Mật khẩu</label>
            <input type="password" required className="w-full p-3 border rounded focus:ring-2 focus:ring-blue-500"
              value={password} onChange={(e) => setPassword(e.target.value)} />
          </div>
          <button type="submit" disabled={loading}
            className={`w-full p-3 text-white font-bold rounded bg-blue-600 hover:bg-blue-700 ${loading ? 'opacity-70' : ''}`}>
            {loading ? 'Đang xử lý...' : 'Đăng Nhập'}
          </button>
        </form>
      </div>
    </div>
  );
}