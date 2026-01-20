"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Cookies from "js-cookie";
import Link from "next/link";
import { 
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer
} from "recharts";
import axios from "axios";

export default function MerchantDashboard() {
  const router = useRouter();
  
  // 1. State cho biểu đồ (Cũ)
  const [revenueData, setRevenueData] = useState([]);
  
  // 2. State cho số liệu tổng quan (Mới - Của B và C)
  const [summaryStats, setSummaryStats] = useState({
    products: 0,
    orders: 0,
    debt: 15000000 // Giả định khách nợ lấy từ Accounting
  });
  
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = Cookies.get("accessToken");
    if (!token) {
      router.push("/login");
      return;
    }

    const fetchData = async () => {
      try {
        // --- GỌI SONG SONG CÁC API ---
        const [revenueRes, productRes, orderRes] = await Promise.allSettled([
          // 1. API Doanh thu (Của bạn A)
          axios.get("http://localhost:5000/api/Accounting/revenue-stats", {
             headers: { Authorization: `Bearer ${token}` }
          }),
          // 2. API Sản phẩm (Của bạn B) - Nếu chưa xong thì thôi
          axios.get("http://localhost:5000/api/products/count", {
             headers: { Authorization: `Bearer ${token}` }
          }),
          // 3. API Đơn hàng (Của bạn C)
          axios.get("http://localhost:5000/api/orders/stats/today", {
             headers: { Authorization: `Bearer ${token}` }
          })
        ]);

        // --- XỬ LÝ DỮ LIỆU ---
        
        // A. Xử lý Doanh thu
        if (revenueRes.status === 'fulfilled') {
          setRevenueData(revenueRes.value.data);
        }

        // B. Xử lý Số liệu tổng quan
        setSummaryStats(prev => ({
          ...prev,
          // Nếu B gọi thành công thì lấy số, thất bại (do chưa code xong) thì để 0
          products: productRes.status === 'fulfilled' ? productRes.value.data.count : 0,
          orders: orderRes.status === 'fulfilled' ? orderRes.value.data.totalOrders : 0
        }));

      } catch (err) {
        console.error("Lỗi tải dữ liệu Dashboard:", err);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [router]);

  // Tính doanh thu hôm nay từ dữ liệu biểu đồ (Lấy ngày cuối cùng)
  const todayRevenue = revenueData.length > 0 
    ? revenueData[revenueData.length - 1].revenue 
    : 0;

  // Cập nhật số liệu vào UI
  const stats = [
    { 
      title: "Doanh thu hôm nay", 
      value: new Intl.NumberFormat('vi-VN').format(todayRevenue) + " ₫", 
      desc: "Cập nhật mới nhất", 
      color: "text-green-600" 
    },
    { 
      title: "Đơn hàng mới", 
      value: summaryStats.orders, // <-- Dữ liệu thật từ C
      desc: "Đang chờ xử lý", 
      color: "text-blue-600" 
    },
    { 
      title: "Tổng sản phẩm", // <-- Thêm cái này cho xịn
      value: summaryStats.products, // <-- Dữ liệu thật từ B
      desc: "Trong kho hàng", 
      color: "text-purple-600" 
    },
  ];

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold text-gray-800 mb-6">Xin chào, Chủ Cửa Hàng 👋</h1>
      
      {/* KHỐI THỐNG KÊ (Đã cập nhật dữ liệu thật) */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        {stats.map((stat, idx) => (
          <div key={idx} className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <h3 className="text-gray-500 text-sm font-semibold uppercase">{stat.title}</h3>
            <div className={`text-3xl font-bold mt-2 ${stat.color}`}>{stat.value}</div>
            <p className="text-gray-400 text-xs mt-1">{stat.desc}</p>
          </div>
        ))}
      </div>

      {/* BIỂU ĐỒ DOANH THU (Giữ nguyên code cũ của bạn) */}
      <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200 mb-8">
        <h2 className="text-lg font-bold text-gray-900 mb-6">Biểu đồ Doanh thu (7 ngày gần nhất)</h2>
        <div className="h-80 w-full">
          {loading ? (
            <div className="flex items-center justify-center h-full text-gray-500">Đang tải dữ liệu...</div>
          ) : (
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={revenueData}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} />
                <XAxis dataKey="date" />
                <YAxis tickFormatter={(value) => `${(value / 1000000).toFixed(1)}M`} />
                <Tooltip 
                  formatter={(value) => [new Intl.NumberFormat('vi-VN').format(value) + ' đ', 'Doanh thu']}
                />
                <Legend />
                <Bar dataKey="revenue" name="Doanh thu" fill="#3b82f6" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          )}
        </div>
      </div>

      {/* CÁC NÚT TẮT (Giữ nguyên) */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <QuickActionCard 
          href="/reports"
          color="green"
          icon="📊"
          title="Sổ Quỹ & Báo Cáo"
          desc="Xem chi tiết thu chi và xuất PDF"
        />
        <QuickActionCard 
          href="/employees"
          color="blue"
          icon="👤"
          title="Quản lý Nhân sự"
          desc="Tạo tài khoản nhân viên"
        />
        <QuickActionCard 
          href="/merchant/products"
          color="blue"
          icon="📦"
          title="Quản lý Sản phẩm"
          desc="Cập nhật kho và giá bán"
        />
        <QuickActionCard 
          href="/merchant/orders"
          color="purple"
          icon="🛒"
          title="Đơn hàng"
          desc="Lịch sử bán hàng"
        />
      </div>
    </div>
  );
}

function QuickActionCard({ href, color, icon, title, desc }) {
  const colorClasses = {
    blue: "border-blue-500 hover:shadow-blue-100",
    green: "border-green-500 hover:shadow-green-100",
    purple: "border-purple-500 hover:shadow-purple-100",
  };

  return (
    <Link href={href}>
      <div className={`bg-white p-5 rounded-xl border border-gray-100 border-l-4 shadow-sm hover:shadow-lg transition-all cursor-pointer group ${colorClasses[color]}`}>
        <div className="flex items-center gap-3 mb-2">
          <span className="text-2xl group-hover:scale-110 transition-transform">{icon}</span>
          <h3 className="text-lg font-bold text-gray-800">{title}</h3>
        </div>
        <p className="text-gray-500 text-sm pl-9">{desc}</p>
      </div>
    </Link>
  );
}