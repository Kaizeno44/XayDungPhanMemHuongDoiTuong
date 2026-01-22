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

  // 3. State cho Top 5 và Cảnh báo tồn kho
  const [topProducts, setTopProducts] = useState([]);
  const [lowStockProducts, setLowStockProducts] = useState([]);
  
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
        const [productRes, dashboardStatsRes, lowStockRes] = await Promise.allSettled([
          // 1. API Sản phẩm (Tổng số lượng)
          axios.get("http://localhost:5000/api/products/count", {
             headers: { Authorization: `Bearer ${token}` }
          }),
          // 2. API Dashboard Stats (Doanh thu, Đơn hàng, Biểu đồ, Top 5)
          axios.get("http://localhost:5000/api/Dashboard/stats", {
             headers: { Authorization: `Bearer ${token}` }
          }),
          // 3. API Low Stock (Cảnh báo tồn kho)
          axios.get("http://localhost:5000/api/Products/low-stock", {
             headers: { Authorization: `Bearer ${token}` }
          })
        ]);

        // --- XỬ LÝ DỮ LIỆU ---
        
        // 1. Xử lý Số liệu tổng quan & Biểu đồ & Top 5
        if (dashboardStatsRes.status === 'fulfilled') {
          const data = dashboardStatsRes.value.data;
          setRevenueData(data.weeklyRevenue || []);
          setTopProducts(data.topProducts || []);
          setSummaryStats(prev => ({
            ...prev,
            orders: data.todayOrdersCount || 0,
            todayRevenue: data.todayRevenue || 0,
            debt: data.totalDebt || 0
          }));
        }

        // 2. Xử lý Tổng số sản phẩm
        if (productRes.status === 'fulfilled') {
          setSummaryStats(prev => ({
            ...prev,
            products: productRes.value.data.count || 0
          }));
        }

        // 3. Xử lý Cảnh báo tồn kho
        if (lowStockRes.status === 'fulfilled') {
          setLowStockProducts(lowStockRes.value.data || []);
        }

      } catch (err) {
        console.error("Lỗi tải dữ liệu Dashboard:", err);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [router]);

  // Cập nhật số liệu vào UI
  const stats = [
    { 
      title: "Doanh thu hôm nay", 
      value: new Intl.NumberFormat('vi-VN').format(summaryStats.todayRevenue || 0) + " ₫", 
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

      {/* THÊM PHẦN TOP 5 VÀ CẢNH BÁO TỒN KHO */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        {/* Top 5 Bán Chạy */}
        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200">
          <h2 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
            <span>🏆</span> Top 5 Bán Chạy (Tháng này)
          </h2>
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="border-b text-gray-500">
                  <th className="pb-2">Sản phẩm ID</th>
                  <th className="pb-2 text-right">Số lượng</th>
                  <th className="pb-2 text-right">Doanh thu</th>
                </tr>
              </thead>
              <tbody>
                {topProducts.length > 0 ? (
                  topProducts.map((p, idx) => (
                    <tr key={idx} className="border-b last:border-0">
                      <td className="py-3 font-medium">#{p.productId}</td>
                      <td className="py-3 text-right">{p.totalQuantity}</td>
                      <td className="py-3 text-right text-green-600 font-semibold">
                        {new Intl.NumberFormat('vi-VN').format(p.totalRevenue)} đ
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan="3" className="py-4 text-center text-gray-400">Chưa có dữ liệu bán hàng</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Cảnh báo tồn kho */}
        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200">
          <h2 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2 text-red-600">
            <span>⚠️</span> Cảnh báo tồn kho (Sắp hết)
          </h2>
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="border-b text-gray-500">
                  <th className="pb-2">Sản phẩm</th>
                  <th className="pb-2">SKU</th>
                  <th className="pb-2 text-right">Tồn kho</th>
                </tr>
              </thead>
              <tbody>
                {lowStockProducts.length > 0 ? (
                  lowStockProducts.map((p, idx) => (
                    <tr key={idx} className="border-b last:border-0">
                      <td className="py-3 font-medium">{p.name}</td>
                      <td className="py-3 text-gray-500">{p.sku}</td>
                      <td className="py-3 text-right text-red-600 font-bold">{p.currentStock}</td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan="3" className="py-4 text-center text-gray-400">Kho hàng ổn định</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
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
                <XAxis dataKey="dayName" />
                <YAxis tickFormatter={(value) => `${(value / 1000000).toFixed(1)}M`} />
                <Tooltip 
                  formatter={(value) => [new Intl.NumberFormat('vi-VN').format(value) + ' đ', 'Doanh thu']}
                />
                <Legend />
                <Bar dataKey="amount" name="Doanh thu" fill="#3b82f6" radius={[4, 4, 0, 0]} />
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
