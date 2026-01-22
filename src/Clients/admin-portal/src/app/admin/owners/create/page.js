"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import axios from "axios";
import Cookies from "js-cookie";
import { ArrowLeft } from "lucide-react"; // Import icon quay lại

export default function CreateOwnerPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    fullName: "",
    email: "",
    password: "",
    confirmPassword: "",
    storeName: "" 
  });

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (formData.password !== formData.confirmPassword) {
      alert("Mật khẩu xác nhận không khớp!");
      return;
    }

    setLoading(true);
    try {
      const token = Cookies.get("accessToken");
      
      // Sửa Port về 5000 (Gateway) để thống nhất
      await axios.post(
        "http://localhost:5000/api/admin/owners", 
        {
          fullName: formData.fullName,
          email: formData.email,
          password: formData.password,
          role: "Owner", 
          storeName: formData.storeName 
        },
        {
          headers: { Authorization: `Bearer ${token}` }
        }
      );

      alert("✅ Tạo tài khoản Chủ cửa hàng thành công!");
      
      // --- SỬA QUAN TRỌNG: Quay về danh sách Owner chứ không về Dashboard ---
      router.push("/admin/owners"); 

    } catch (error) {
      console.error(error);
      alert("❌ Lỗi: " + (error.response?.data?.message || error.message));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-2xl mx-auto p-8 mt-10">
        {/* Nút quay lại */}
      <button 
        onClick={() => router.back()} 
        className="flex items-center text-gray-500 hover:text-blue-600 mb-4 transition"
      >
        <ArrowLeft size={20} className="mr-2"/> Quay lại danh sách
      </button>

      <div className="bg-white shadow-lg rounded-xl p-8">
        <h1 className="text-2xl font-bold text-gray-800 mb-6 border-b pb-4">
            🏢 Đăng Ký Hộ Kinh Doanh Mới
        </h1>
        
        <form onSubmit={handleSubmit} className="space-y-4">
            {/* Tên cửa hàng */}
            <div>
            <label className="block text-sm font-medium text-gray-700">Tên cửa hàng</label>
            <input name="storeName" required onChange={handleChange}
                className="w-full p-3 border rounded-lg focus:ring-2 focus:ring-blue-500" placeholder="Ví dụ: Cà phê Ba Tèo" />
            </div>

            {/* Họ tên chủ */}
            <div>
            <label className="block text-sm font-medium text-gray-700">Họ tên chủ shop</label>
            <input name="fullName" required onChange={handleChange}
                className="w-full p-3 border rounded-lg focus:ring-2 focus:ring-blue-500" placeholder="Nguyễn Văn A" />
            </div>

            {/* Email */}
            <div>
            <label className="block text-sm font-medium text-gray-700">Email đăng nhập</label>
            <input type="email" name="email" required onChange={handleChange}
                className="w-full p-3 border rounded-lg focus:ring-2 focus:ring-blue-500" placeholder="owner@gmail.com" />
            </div>

            {/* Mật khẩu */}
            <div className="grid grid-cols-2 gap-4">
            <div>
                <label className="block text-sm font-medium text-gray-700">Mật khẩu</label>
                <input type="password" name="password" required onChange={handleChange}
                className="w-full p-3 border rounded-lg focus:ring-2 focus:ring-blue-500" />
            </div>
            <div>
                <label className="block text-sm font-medium text-gray-700">Xác nhận mật khẩu</label>
                <input type="password" name="confirmPassword" required onChange={handleChange}
                className="w-full p-3 border rounded-lg focus:ring-2 focus:ring-blue-500" />
            </div>
            </div>

            <button type="submit" disabled={loading}
            className="w-full py-3 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-lg transition shadow-md">
            {loading ? "⏳ Đang tạo..." : "➕ Tạo Tài Khoản Owner"}
            </button>
        </form>
      </div>
    </div>
  );
}