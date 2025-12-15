"use client";
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import api from '@/utils/api';
import Cookies from 'js-cookie';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      // 1. Gọi API đăng nhập sang Gateway
      // Đường dẫn sẽ là: https://localhost:5000/api/auth/login
      const response = await api.post('/auth/login', {
        email,
        password
      });

      // 2. Nếu thành công, Server trả về Token
      const { token } = response.data;

      // 3. Lưu Token vào Cookie (để dùng cho các lần sau)
      Cookies.set('token', token, { expires: 1 }); // Hết hạn sau 1 ngày

      // 4. Chuyển hướng về trang chủ
      alert("Đăng nhập thành công! 🚀");
      router.push('/');

    } catch (err) {
      console.error(err);
      setError('Đăng nhập thất bại! Kiểm tra lại email hoặc mật khẩu.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100">
      <div className="bg-white p-8 rounded-lg shadow-lg max-w-md w-full">
        <h2 className="text-2xl font-bold text-center text-blue-600 mb-6">Đăng Nhập Hệ Thống</h2>
        
        {error && (
          <div className="bg-red-100 text-red-700 p-3 rounded mb-4 text-sm text-center">
            {error}
          </div>
        )}

        <form onSubmit={handleLogin} className="space-y-4">
          <div>
            <label className="block text-gray-700 text-sm font-bold mb-2">Email</label>
            <input
              type="email"
              required
              className="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 text-black"
              placeholder="admin@bizflow.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
          </div>

          <div>
            <label className="block text-gray-700 text-sm font-bold mb-2">Mật khẩu</label>
            <input
              type="password"
              required
              className="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 text-black"
              placeholder="••••••"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className={`w-full py-2 px-4 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded transition duration-200 ${loading ? 'opacity-50 cursor-not-allowed' : ''}`}
          >
            {loading ? 'Đang xử lý...' : 'Đăng Nhập'}
          </button>
        </form>
      </div>
    </div>
  );
}