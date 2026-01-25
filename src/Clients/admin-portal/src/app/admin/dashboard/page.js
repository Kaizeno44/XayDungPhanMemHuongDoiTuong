"use client";
import { useState, useEffect } from "react";
import axios from "axios";
import Cookies from "js-cookie";
import { Users, DollarSign, Activity, Settings, Loader2 } from "lucide-react"; 

export default function AdminDashboard() {
  const [statsData, setStatsData] = useState({
    totalRevenue: 0,
    activeOwners: 0,
    newRegistrations: 0
  });
  const [loading, setLoading] = useState(true);

  // Gọi API lấy số liệu thật
  useEffect(() => {
    const fetchStats = async () => {
      try {
        const token = Cookies.get("accessToken");
        const res = await axios.get("http://localhost:5000/api/admin/dashboard-stats", {
            headers: { Authorization: `Bearer ${token}` }
        });
        setStatsData(res.data);
      } catch (error) {
        console.error("Lỗi tải thống kê:", error);
      } finally {
        setLoading(false);
      }
    };
    fetchStats();
  }, []);

  // Cấu hình hiển thị (Mapping dữ liệu vào UI)
  const stats = [
    { 
        label: "Tổng Doanh Thu (Tháng)", 
        value: new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(statsData.totalRevenue), 
        icon: <DollarSign className="text-green-600" />, 
        change: "Ước tính" 
    },
    { 
        label: "Chủ hộ đang hoạt động", 
        value: statsData.activeOwners, 
        icon: <Users className="text-blue-600" />, 
        change: "Real-time" 
    },
    { 
        label: "Đăng ký mới (Tháng này)", 
        value: statsData.newRegistrations, 
        icon: <Activity className="text-purple-600" />, 
        change: "Tháng " + (new Date().getMonth() + 1)
    },
  ];

  return (
    <div className="p-8 bg-gray-50 min-h-screen">
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-3xl font-bold text-gray-800">📊 Tổng Quan Hệ Thống</h1>
      </div>

      {/* 1. Kế hoạch thống kê (Analytics) */}
      {loading ? (
        <div className="flex justify-center p-10"><Loader2 className="animate-spin text-blue-500"/></div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
            {stats.map((stat, idx) => (
            <div key={idx} className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 flex items-center gap-4 transition hover:shadow-md">
                <div className="p-4 bg-gray-50 rounded-full border border-gray-100">{stat.icon}</div>
                <div>
                <p className="text-gray-500 text-sm font-medium">{stat.label}</p>
                <h3 className="text-2xl font-bold text-gray-800 mt-1">{stat.value}</h3>
                <span className="text-green-600 text-xs font-semibold bg-green-50 px-2 py-1 rounded-full mt-2 inline-block">
                    {stat.change}
                </span>
                </div>
            </div>
            ))}
        </div>
      )}

      {/* 2. Menu Chức năng quản lý (Giữ nguyên code cũ của bạn) */}
      <h2 className="text-xl font-bold text-gray-700 mb-4">🔧 Quản trị & Cấu hình</h2>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        
        {/* Quản lý Owner */}
        <a href="/admin/owners" className="block group">
          <div className="bg-white p-6 rounded-xl shadow-sm border hover:border-blue-500 transition cursor-pointer h-full">
            <div className="flex items-center gap-3 mb-2">
              <div className="bg-blue-100 p-2 rounded-lg text-blue-600"><Users size={24} /></div>
              <h3 className="text-lg font-bold group-hover:text-blue-600 transition">Quản lý Chủ hộ</h3>
            </div>
            <p className="text-gray-500 text-sm">Xem danh sách, duyệt đăng ký, khóa tài khoản vi phạm.</p>
          </div>
        </a>

        {/* Quản lý Gói cước */}
        <a href="/admin/subscriptions" className="block group">
          <div className="bg-white p-6 rounded-xl shadow-sm border hover:border-green-500 transition cursor-pointer h-full">
            <div className="flex items-center gap-3 mb-2">
              <div className="bg-green-100 p-2 rounded-lg text-green-600"><DollarSign size={24} /></div>
              <h3 className="text-lg font-bold group-hover:text-green-600 transition">Quản lý Gói & Giá</h3>
            </div>
            <p className="text-gray-500 text-sm">Cập nhật giá gói Basic/Pro, tạo khuyến mãi.</p>
          </div>
        </a>

        {/* Cấu hình hệ thống */}
        <div className="bg-white p-6 rounded-xl shadow-sm border hover:border-purple-500 transition cursor-pointer h-full">
          <div className="flex items-center gap-3 mb-2">
            <div className="bg-purple-100 p-2 rounded-lg text-purple-600"><Settings size={24} /></div>
            <h3 className="text-lg font-bold">Cấu hình & AI</h3>
          </div>
          <p className="text-gray-500 text-sm">Cập nhật mẫu báo cáo TT88, cài đặt AI toàn cục.</p>
        </div>

      </div>
    </div>
  );
}