"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import api from "@/utils/api";

export default function CreateEmployeePage() {
  const router = useRouter();
  
  // 1. Xóa bỏ field 'role' trong state, chỉ giữ lại cái cần thiết
  const [formData, setFormData] = useState({
    email: "",
    password: "",
    fullName: "",
  });
  
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      // 2. Gửi API (Backend sẽ tự mặc định role = Employee)
      await api.post("/users", formData);
      
      alert("Tạo nhân viên thành công!");
      router.push("/employees"); 
    } catch (error) {
      console.error(error);
      // Xử lý thông báo lỗi hiển thị đẹp hơn chút
      const errorMessage = error.response?.data?.message || error.message || "Có lỗi xảy ra";
      alert("Lỗi: " + errorMessage);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 p-8 flex justify-center">
      <div className="bg-white p-8 rounded shadow w-full max-w-md h-fit">
        <h2 className="text-2xl font-bold mb-6 text-gray-800 text-center">Thêm Nhân viên Bán hàng</h2>
        
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">Họ và Tên</label>
            <input
              type="text"
              required
              className="mt-1 block w-full border border-gray-300 rounded-md p-2 focus:ring-blue-500 focus:border-blue-500"
              value={formData.fullName}
              onChange={(e) => setFormData({...formData, fullName: e.target.value})}
              placeholder="Ví dụ: Nguyễn Văn A"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">Email (Tên đăng nhập)</label>
            <input
              type="email"
              required
              className="mt-1 block w-full border border-gray-300 rounded-md p-2 focus:ring-blue-500 focus:border-blue-500"
              value={formData.email}
              onChange={(e) => setFormData({...formData, email: e.target.value})}
              placeholder="nhanvien@bizflow.com"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">Mật khẩu</label>
            <input
              type="password"
              required
              className="mt-1 block w-full border border-gray-300 rounded-md p-2 focus:ring-blue-500 focus:border-blue-500"
              value={formData.password}
              onChange={(e) => setFormData({...formData, password: e.target.value})}
              placeholder="******"
            />
          </div>

          {/* ĐÃ XÓA PHẦN CHỌN VAI TRÒ Ở ĐÂY */}

          <div className="pt-4 space-y-2">
            <button
                type="submit"
                disabled={loading}
                className={`w-full text-white p-2 rounded font-bold transition ${loading ? 'bg-blue-400 cursor-not-allowed' : 'bg-blue-600 hover:bg-blue-700'}`}
            >
                {loading ? "Đang xử lý..." : "Tạo Tài Khoản"}
            </button>

            <button
                type="button"
                onClick={() => router.back()}
                className="w-full bg-gray-200 text-gray-700 p-2 rounded hover:bg-gray-300"
            >
                Hủy
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}