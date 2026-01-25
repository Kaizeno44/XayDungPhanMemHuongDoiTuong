"use client";
import { useState, useEffect } from "react";
import axios from "axios";
import Cookies from "js-cookie";
import { Check, Loader2 } from "lucide-react"; // Thêm icon Loader

export default function SubscriptionsPage() {
  const [plans, setPlans] = useState([]);
  const [loading, setLoading] = useState(true);

  // 1. Gọi API lấy danh sách gói thật từ Database
  useEffect(() => {
    const fetchPlans = async () => {
      try {
        const token = Cookies.get("accessToken");
        const res = await axios.get("http://localhost:5000/api/admin/subscription-plans", {
          headers: { Authorization: `Bearer ${token}` }
        });
        setPlans(res.data);
      } catch (error) {
        console.error("Lỗi tải gói dịch vụ:", error);
      } finally {
        setLoading(false);
      }
    };
    fetchPlans();
  }, []);

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-2xl font-bold text-gray-800">💳 Quản lý Gói Dịch Vụ</h1>
        {/* Nút thêm gói (để sẵn sau này làm chức năng thêm) */}
        
      </div>

      {loading ? (
        <div className="flex justify-center items-center h-64">
           <Loader2 className="animate-spin text-blue-500" size={32} />
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {plans.map((plan, idx) => {
            // Logic tự động xác định gói VIP để tô màu (Ví dụ giá > 150k là VIP)
            const isPro = plan.price > 150000; 

            return (
              <div 
                key={plan.id} 
                className={`p-6 rounded-2xl shadow-sm border relative transition hover:shadow-md ${
                    isPro ? "bg-blue-50 border-blue-500 border-2" : "bg-white border-gray-200"
                }`}
              >
                {/* Nhãn khuyên dùng nếu là gói Pro */}
                {isPro && (
                    <span className="absolute top-0 right-0 bg-blue-600 text-white text-xs px-3 py-1 rounded-bl-lg rounded-tr-lg font-bold">
                        Phổ biến nhất
                    </span>
                )}

                <h3 className="text-xl font-bold text-gray-900">{plan.name}</h3>
                
                {/* Format giá tiền tự động */}
                <div className="text-3xl font-bold text-blue-600 my-4">
                    {new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(plan.price)}
                    <span className="text-sm text-gray-500 font-normal">/tháng</span>
                </div>

                {/* Tự động tạo danh sách tính năng từ dữ liệu DB */}
                <ul className="space-y-3 mb-6">
                    {/* Tính năng 1: Số nhân viên */}
                    <li className="flex items-center text-sm text-gray-600">
                        <Check size={16} className="text-green-500 mr-2"/> 
                        <span>
                            Tối đa <b>{plan.maxEmployees || "Không giới hạn"}</b> nhân viên
                        </span>
                    </li>
                    
                    {/* Tính năng 2: Hỗ trợ AI */}
                    <li className="flex items-center text-sm text-gray-600">
                        <Check size={16} className={`mr-2 ${plan.allowAI ? "text-green-500" : "text-gray-300"}`}/> 
                        {plan.allowAI ? "Hỗ trợ trợ lý ảo AI" : "Không hỗ trợ AI"}
                    </li>

                    {/* Tính năng 3: Thời hạn (lấy từ Duration) */}
                    <li className="flex items-center text-sm text-gray-600">
                        <Check size={16} className="text-green-500 mr-2"/> 
                        Gia hạn {plan.durationInMonths || 1} tháng/lần
                    </li>
                </ul>

                
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}