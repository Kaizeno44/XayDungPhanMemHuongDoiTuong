"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Cookies from "js-cookie";
import Link from "next/link";
import { 
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer
} from "recharts";
import axios from "axios";
import * as signalR from "@microsoft/signalr";
import { notification } from "antd";
import { jwtDecode } from "jwt-decode";

export default function MerchantDashboard() {
  const router = useRouter();
  
  // 1. State cho biểu đồ
  const [revenueData, setRevenueData] = useState([]);
  
  // 2. State cho số liệu tổng quan
  const [summaryStats, setSummaryStats] = useState({
    products: 0,
    orders: 0,
    todayRevenue: 0,
    debt: 0
  });

  // 3. State cho Top 5 và Cảnh báo tồn kho
  const [topProducts, setTopProducts] = useState([]);
  const [lowStockProducts, setLowStockProducts] = useState([]);
  
  const [loading, setLoading] = useState(true);

  const fetchData = async () => {
    const token = Cookies.get("accessToken");
    if (!token) return;

    let storeId = "";
    try {
      const decoded = jwtDecode(token);
      storeId = decoded.StoreId || decoded.storeId || "";
    } catch (e) {}

    try {
      // --- GỌI SONG SONG CÁC API ---
      const [productRes, dashboardStatsRes, lowStockRes, ordersRes] = await Promise.allSettled([
        // 1. API Sản phẩm (Tổng số lượng)
        axios.get("http://localhost:5000/api/products/count", {
           headers: { Authorization: `Bearer ${token}` }
        }),
        // 2. API Dashboard Stats (Doanh thu, Đơn hàng, Biểu đồ, Top 5)
        axios.get(`http://localhost:5000/api/Dashboard/stats?storeId=${storeId}`, {
           headers: { Authorization: `Bearer ${token}` }
        }),
        // 3. API Low Stock (Cảnh báo tồn kho)
        axios.get("http://localhost:5000/api/Products/low-stock", {
           headers: { Authorization: `Bearer ${token}` }
        }),
        // 4. API Lấy toàn bộ đơn hàng để tính doanh thu tháng
        axios.get("http://localhost:5000/api/orders", {
           headers: { Authorization: `Bearer ${token}` }
        })
      ]);

      // --- XỬ LÝ DỮ LIỆU ---
      
      // 1. Xử lý Số liệu tổng quan & Biểu đồ & Top 5
      if (dashboardStatsRes.status === 'fulfilled') {
        const data = dashboardStatsRes.value.data;
        console.log("Dashboard Stats Data:", data);
        
        // Chuẩn hóa dữ liệu biểu đồ
        const rawRevenue = data.weeklyRevenue || data.WeeklyRevenue || [];
        const normalizedRevenue = rawRevenue.map(item => ({
          dayName: item.dayName || item.DayName,
          amount: Number(item.amount || item.Amount || 0)
        }));

        // Chuẩn hóa Top Products và lấy tên thật từ ProductAPI
        const rawTopProducts = data.topProducts || data.TopProducts || [];
        const normalizedTopProducts = await Promise.all(rawTopProducts.map(async (p) => {
          const pid = p.productId || p.ProductId;
          let name = p.productName || p.ProductName;
          
          // Nếu tên là mặc định (Sản phẩm #ID), thử lấy tên thật
          if (!name || name.startsWith("Sản phẩm #")) {
            try {
              const pRes = await axios.get(`http://localhost:5000/api/products/${pid}`, {
                headers: { Authorization: `Bearer ${token}` }
              });
              name = pRes.data.name;
            } catch (e) {}
          }

          return {
            productId: pid,
            productName: name,
            totalSold: p.totalQuantity || p.TotalQuantity || p.totalSold || p.TotalSold || 0,
            totalRevenue: p.totalRevenue || p.TotalRevenue || 0
          };
        }));

        setRevenueData(normalizedRevenue);
        setTopProducts(normalizedTopProducts);
        setSummaryStats(prev => ({
          ...prev,
          debt: data.totalDebt || data.TotalDebt || 0
        }));
      }

      // 1.1 Xử lý Doanh thu tháng từ danh sách đơn hàng (Lọc Confirmed)
      if (ordersRes.status === 'fulfilled') {
        const allOrders = ordersRes.value.data || [];
        const now = new Date();
        const currentMonth = now.getMonth();
        const currentYear = now.getFullYear();

        const confirmedOrdersInMonth = allOrders.filter(o => {
          const orderDate = new Date(o.orderDate || o.OrderDate);
          return (o.status === "Confirmed" || o.Status === "Confirmed") &&
                 orderDate.getMonth() === currentMonth &&
                 orderDate.getFullYear() === currentYear;
        });

        const totalRevenue = confirmedOrdersInMonth.reduce((sum, o) => sum + (o.totalAmount || o.TotalAmount || 0), 0);
        
        setSummaryStats(prev => ({
          ...prev,
          orders: confirmedOrdersInMonth.length,
          todayRevenue: totalRevenue
        }));

        // Cập nhật lại biểu đồ nếu cần (Ở đây ta giữ nguyên biểu đồ từ API DashboardStats vì nó đã có logic theo ngày)
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

  useEffect(() => {
    const token = Cookies.get("accessToken");
    if (!token) {
      router.push("/login");
      return;
    }

    fetchData();

    // --- CẤU HÌNH SIGNALR ---
    const connection = new signalR.HubConnectionBuilder()
      .withUrl("http://localhost:5000/hubs/notifications", {
        accessTokenFactory: () => token
      })
      .withAutomaticReconnect()
      .build();

    connection.start()
      .then(() => {
        console.log("Connected to SignalR Hub");
        connection.invoke("JoinAdminGroup");
      })
      .catch(err => console.error("SignalR Connection Error: ", err));

    connection.on("ReceiveNotification", (data) => {
      notification.success({
        message: data.title,
        description: data.message,
        placement: "topRight",
        duration: 5
      });
      // Refresh data khi có đơn mới
      fetchData();
    });

    return () => {
      connection.stop();
    };
  }, [router]);

  // Cập nhật số liệu vào UI
  const stats = [
    { 
      title: "Doanh thu tháng này", 
      value: new Intl.NumberFormat('vi-VN').format(summaryStats.todayRevenue || 0) + " ₫", 
      desc: "Tổng cộng trong tháng", 
      color: "text-green-600" 
    },
    { 
      title: "Đơn hàng trong tháng", 
      value: summaryStats.orders, 
      desc: "Tổng số đơn đã tạo", 
      color: "text-blue-600" 
    },
    { 
      title: "Tổng sản phẩm", 
      value: summaryStats.products, 
      desc: "Trong kho hàng", 
      color: "text-purple-600" 
    },
  ];

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold text-gray-800 mb-6">Xin chào, Chủ Cửa Hàng 👋</h1>
      
      {/* KHỐI THỐNG KÊ */}
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
                  <th className="pb-2">Sản phẩm</th>
                  <th className="pb-2 text-right">Số lượng</th>
                  <th className="pb-2 text-right">Doanh thu</th>
                </tr>
              </thead>
              <tbody>
                {topProducts.length > 0 ? (
                  topProducts.map((p, idx) => (
                    <tr key={idx} className="border-b last:border-0">
                      <td className="py-3 font-medium">{p.productName}</td>
                      <td className="py-3 text-right">{p.totalSold}</td>
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

      {/* BIỂU ĐỒ DOANH THU */}
      <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200 mb-8">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-lg font-bold text-gray-900">Biểu đồ Doanh thu (Tháng {new Date().getMonth() + 1}/{new Date().getFullYear()})</h2>
          <div className="text-sm text-gray-500">
            Tổng doanh thu: <span className="font-bold text-blue-600">
              {new Intl.NumberFormat('vi-VN').format(revenueData.reduce((sum, item) => sum + item.amount, 0))} đ
            </span>
          </div>
        </div>
        <div className="h-80 w-full">
          {loading ? (
            <div className="flex items-center justify-center h-full text-gray-500">Đang tải dữ liệu...</div>
          ) : (
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={revenueData}>
                <defs>
                  <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.8}/>
                    <stop offset="95%" stopColor="#3b82f6" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f0f0f0" />
                <XAxis 
                  dataKey="dayName" 
                  axisLine={false}
                  tickLine={false}
                  tick={{fill: '#9ca3af', fontSize: 12}}
                  interval={Math.floor(revenueData.length / 10)}
                />
                <YAxis 
                  axisLine={false}
                  tickLine={false}
                  tick={{fill: '#9ca3af', fontSize: 12}}
                  tickFormatter={(value) => value >= 1000000 ? `${(value / 1000000).toFixed(1)}M` : new Intl.NumberFormat('vi-VN').format(value)} 
                />
                <Tooltip 
                  contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
                  formatter={(value) => [new Intl.NumberFormat('vi-VN').format(value) + ' đ', 'Doanh thu']}
                />
                <Area 
                  type="monotone" 
                  dataKey="amount" 
                  name="Doanh thu" 
                  stroke="#3b82f6" 
                  strokeWidth={3}
                  fillOpacity={1} 
                  fill="url(#colorRevenue)" 
                />
              </AreaChart>
            </ResponsiveContainer>
          )}
        </div>
      </div>

      {/* CÁC NÚT TẮT */}
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

function QuickActionCard({ href, color, icon, title, desc, external }) {
  const colorClasses = {
    blue: "border-blue-500 hover:shadow-blue-100",
    green: "border-green-500 hover:shadow-green-100",
    purple: "border-purple-500 hover:shadow-purple-100",
  };

  const content = (
    <div className={`bg-white p-5 rounded-xl border border-gray-100 border-l-4 shadow-sm hover:shadow-lg transition-all cursor-pointer group ${colorClasses[color]}`}>
      <div className="flex items-center gap-3 mb-2">
        <span className="text-2xl group-hover:scale-110 transition-transform">{icon}</span>
        <h3 className="text-lg font-bold text-gray-800">{title}</h3>
      </div>
      <p className="text-gray-500 text-sm pl-9">{desc}</p>
    </div>
  );

  if (external) {
    return <a href={href} target="_blank" rel="noopener noreferrer">{content}</a>;
  }

  return (
    <Link href={href}>
      {content}
    </Link>
  );
}
