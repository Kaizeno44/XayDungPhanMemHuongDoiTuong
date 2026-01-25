"use client";
import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import axios from "axios";
import Cookies from "js-cookie";
import { ArrowLeft, CheckCircle } from "lucide-react"; // Nhớ import thêm CheckCircle

export default function CreateOwnerPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [plans, setPlans] = useState([]);

  // 1. Gọi API lấy danh sách gói
  useEffect(() => {
    const fetchPlans = async () => {
        try {
            const token = Cookies.get("accessToken");
            const response = await axios.get(
                "http://localhost:5000/api/admin/subscription-plans", 
                { headers: { Authorization: `Bearer ${token}` } }
            );
            setPlans(response.data);
        } catch (error) {
            console.error("Lỗi tải gói cước:", error);
            // Fallback nếu lỗi
            setPlans([
                { id: "d5093c85-64e6-42c2-8098-902341270123", name: "Gói Cơ Bản (Offline)", price: 100000, description: "Loading failed..." },
                { id: "60350d5e-d225-4676-9051-512686851234", name: "Gói Pro (Offline)", price: 200000, description: "Loading failed..." }
            ]);
        }
    };
    fetchPlans();
  }, []);

  const [formData, setFormData] = useState({
    fullName: "",
    email: "",
    password: "",
    confirmPassword: "",
    storeName: "",
    subscriptionPlanId: "" // Đã có trường này
  });

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  // Hàm chọn gói
  const handleSelectPlan = (planId) => {
    setFormData({ ...formData, subscriptionPlanId: planId });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (formData.password !== formData.confirmPassword) {
      alert("Mật khẩu xác nhận không khớp!");
      return;
    }
    // 👇 Kiểm tra xem đã chọn gói chưa
    if (!formData.subscriptionPlanId) {
        alert("Vui lòng chọn gói dịch vụ!");
        return;
    }

    setLoading(true);
    try {
      const token = Cookies.get("accessToken");
      
      await axios.post(
        "http://localhost:5000/api/admin/owners", 
        {
          fullName: formData.fullName,
          email: formData.email,
          password: formData.password,
          storeName: formData.storeName,
          // 👇 QUAN TRỌNG: Gửi ID gói xuống Backend
          subscriptionPlanId: formData.subscriptionPlanId 
        },
        {
          headers: { Authorization: `Bearer ${token}` }
        }
      );

      alert("✅ Tạo tài khoản Chủ cửa hàng thành công!");
      router.push("/admin/owners"); 

    } catch (error) {
      console.error(error);
      alert("❌ Lỗi: " + (error.response?.data?.message || error.message));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-4xl mx-auto p-8 mt-10"> {/* Mở rộng chiều ngang thành 4xl cho đẹp */}
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
        
        <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-8">
            {/* CỘT TRÁI: NHẬP THÔNG TIN */}
            <div className="space-y-4">
                <h3 className="font-semibold text-gray-700">1. Thông tin cửa hàng</h3>
                <div>
                    <label className="block text-sm font-medium text-gray-700">Tên cửa hàng</label>
                    <input name="storeName" required onChange={handleChange}
                        className="w-full p-3 border rounded-lg focus:ring-2 focus:ring-blue-500" placeholder="Ví dụ: Cà phê Ba Tèo" />
                </div>
                <div>
                    <label className="block text-sm font-medium text-gray-700">Họ tên chủ shop</label>
                    <input name="fullName" required onChange={handleChange}
                        className="w-full p-3 border rounded-lg focus:ring-2 focus:ring-blue-500" placeholder="Nguyễn Văn A" />
                </div>
                <div>
                    <label className="block text-sm font-medium text-gray-700">Email đăng nhập</label>
                    <input type="email" name="email" required onChange={handleChange}
                        className="w-full p-3 border rounded-lg focus:ring-2 focus:ring-blue-500" placeholder="owner@gmail.com" />
                </div>
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

            {/* CỘT PHẢI: CHỌN GÓI CƯỚC */}
            <div className="space-y-4">
                <h3 className="font-semibold text-gray-700">2. Chọn gói dịch vụ</h3>
                <div className="space-y-3">
                    {plans.map((plan) => (
                        <div 
                            key={plan.id}
                            onClick={() => handleSelectPlan(plan.id)}
                            className={`p-4 border rounded-xl cursor-pointer transition flex justify-between items-center ${
                                formData.subscriptionPlanId === plan.id 
                                ? "border-blue-500 bg-blue-50 ring-2 ring-blue-200" 
                                : "border-gray-200 hover:border-blue-300 hover:bg-gray-50"
                            }`}
                        >
                            <div>
                                <h3 className="font-bold text-gray-800">{plan.name}</h3>
                                <p className="text-sm text-gray-500">{plan.description}</p>
                                <p className="text-blue-600 font-semibold mt-1">
                                    {new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(plan.price)}
                                </p>
                            </div>
                            {/* Icon check xanh khi được chọn */}
                            {formData.subscriptionPlanId === plan.id && <CheckCircle className="text-blue-600" size={24} />}
                        </div>
                    ))}
                </div>
                
                {/* Nút Submit nằm bên phải luôn cho gọn */}
                <button type="submit" disabled={loading}
                    className="w-full py-4 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-lg transition shadow-md mt-6">
                    {loading ? "⏳ Đang xử lý..." : "➕ Hoàn Tất Đăng Ký"}
                </button>
            </div>
        </form>
      </div>
    </div>
  );
}