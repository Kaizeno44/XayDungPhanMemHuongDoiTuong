"use client";
import { Check } from "lucide-react";

export default function SubscriptionsPage() {
  const plans = [
    { name: "Gói Cơ Bản (Start-up)", price: "100.000 đ", features: ["Tối đa 2 nhân viên", "Quản lý kho cơ bản", "Không có AI"], color: "bg-gray-100" },
    { name: "Gói Doanh Nghiệp (Pro)", price: "200.000 đ", features: ["Tối đa 10 nhân viên", "Báo cáo nâng cao", "Hỗ trợ AI dự đoán"], color: "bg-blue-50 border-blue-500 border-2", recommended: true },
  ];

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold text-gray-800 mb-8">💳 Quản lý Gói Dịch Vụ</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
        {plans.map((plan, idx) => (
          <div key={idx} className={`p-6 rounded-2xl shadow-sm border relative ${plan.color}`}>
            {plan.recommended && <span className="absolute top-0 right-0 bg-blue-600 text-white text-xs px-3 py-1 rounded-bl-lg rounded-tr-lg font-bold">Khuyên dùng</span>}
            <h3 className="text-xl font-bold text-gray-900">{plan.name}</h3>
            <div className="text-3xl font-bold text-blue-600 my-4">{plan.price}<span className="text-sm text-gray-500 font-normal">/tháng</span></div>
            <ul className="space-y-3 mb-6">
                {plan.features.map((f, i) => (
                    <li key={i} className="flex items-center text-sm text-gray-600"><Check size={16} className="text-green-500 mr-2"/> {f}</li>
                ))}
            </ul>
            <button className="w-full py-2 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 font-medium">Chỉnh sửa</button>
          </div>
        ))}
      </div>
    </div>
  );
}