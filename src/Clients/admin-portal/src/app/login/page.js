"use client";
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import axios from 'axios'; 
import Cookies from 'js-cookie';

export default function LoginPage() {
  const router = useRouter();
  // Điền sẵn thông tin chuẩn trong Database để đỡ phải gõ lại nhiều lần khi test
  const [email, setEmail] = useState('superadmin@bizflow.com');
  const [password, setPassword] = useState('admin');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      // Gọi API Identity chạy trên HTTPS 5001
      const response = await axios.post('https://localhost:5001/api/auth/login', {
        email,
        password
      });

      // Lấy token từ response (API trả về { token: "...", user: {...} })
      const token = response.data.token;

      if (!token) {
        throw new Error("Không tìm thấy token trong phản hồi!");
      }

      // 1. QUAN TRỌNG: Đặt tên cookie là "accessToken" để khớp với Dashboard
      Cookies.set('accessToken', token, { expires: 1 }); // Hết hạn sau 1 ngày

      // 2. Chuyển hướng thẳng vào Dashboard (thay vì trang chủ /)
      router.push('/dashboard'); 

    } catch (err) {
      console.error(err);
      // Kiểm tra lỗi chi tiết từ server trả về (nếu có)
      const serverMessage = err.response?.data?.message || err.response?.data;
      setError(serverMessage || 'Đăng nhập thất bại! Kiểm tra lại Backend (5001) hoặc mật khẩu.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100 font-sans">
      <div className="bg-white p-8 rounded-xl shadow-xl max-w-md w-full border border-gray-100">
        <div className="text-center mb-8">
            <h1 className="text-3xl font-bold text-blue-600">BizFlow</h1>
            <p className="text-gray-500 mt-2">Đăng nhập quản trị viên</p>
        </div>
        
        {error && (
          <div className="bg-red-50 text-red-600 p-3 rounded-lg mb-6 text-sm text-center border border-red-100">
            ⚠️ {error}
          </div>
        )}

        <form onSubmit={handleLogin} className="space-y-5">
          <div>
            <label className="block text-gray-700 text-sm font-semibold mb-2">Email</label>
            <input
              type="email"
              required
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-gray-900 transition-all"
              placeholder="superadmin@bizflow.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
          </div>

          <div>
            <label className="block text-gray-700 text-sm font-semibold mb-2">Mật khẩu</label>
            <input
              type="password"
              required
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-gray-900 transition-all"
              placeholder="••••••"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className={`w-full py-3 px-4 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-lg transition-all shadow-md hover:shadow-lg transform active:scale-95 ${loading ? 'opacity-70 cursor-wait' : ''}`}
          >
            {loading ? '⏳ Đang kết nối...' : 'Đăng Nhập'}
          </button>
        </form>
      </div>
    </div>
  );
}