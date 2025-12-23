"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import api from "@/utils/api";

export default function CreateEmployeePage() {
  const router = useRouter();
  const [formData, setFormData] = useState({
    email: "",
    password: "",
    fullName: "",
    role: "Staff", // Mặc định là Staff
  });
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      // Gọi API tạo User
      await api.post("/users", formData);
      alert("Tạo nhân viên thành công!");
      router.push("/employees"); // Quay về danh sách
    } catch (error) {
      console.error(error);
      alert("Lỗi: " + (error.response?.data?.[0]?.description || "Có lỗi xảy ra"));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 p-8 flex justify-center">
      <div className="bg-white p-8 rounded shadow w-full max-w-md">
        <h2 className="text-2xl font-bold mb-6 text-gray-800">Thêm Nhân viên Mới</h2>
        
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">Họ và Tên</label>
            <input
              type="text"
              required
              className="mt-1 block w-full border border-gray-300 rounded-md p-2"
              value={formData.fullName}
              onChange={(e) => setFormData({...formData, fullName: e.target.value})}
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">Email (Tên đăng nhập)</label>
            <input
              type="email"
              required
              className="mt-1 block w-full border border-gray-300 rounded-md p-2"
              value={formData.email}
              onChange={(e) => setFormData({...formData, email: e.target.value})}
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">Mật khẩu</label>
            <input
              type="password"
              required
              className="mt-1 block w-full border border-gray-300 rounded-md p-2"
              value={formData.password}
              onChange={(e) => setFormData({...formData, password: e.target.value})}
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">Vai trò</label>
            <select
              className="mt-1 block w-full border border-gray-300 rounded-md p-2"
              value={formData.role}
              onChange={(e) => setFormData({...formData, role: e.target.value})}
            >
              <option value="Staff">Nhân viên (Staff)</option>
              <option value="Manager">Quản lý (Manager)</option>
              <option value="Shipper">Giao hàng</option>
            </select>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-blue-600 text-white p-2 rounded hover:bg-blue-700 font-bold transition"
          >
            {loading ? "Đang xử lý..." : "Tạo Tài Khoản"}
          </button>

          <button
            type="button"
            onClick={() => router.back()}
            className="w-full bg-gray-200 text-gray-700 p-2 rounded hover:bg-gray-300 mt-2"
          >
            Hủy
          </button>
        </form>
      </div>
    </div>
  );
}