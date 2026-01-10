"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Cookies from "js-cookie";
import Link from "next/link";
import { 
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer
} from "recharts";
import axios from "axios";
import * as signalR from "@microsoft/signalr";
import { notification } from "antd";

export default function MerchantDashboard() {
  const router = useRouter();
  const [revenueData, setRevenueData] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = Cookies.get("accessToken");
    if (!token) {
      router.push("/login");
      return;
    }

    const fetchRevenue = async () => {
      try {
        const response = await axios.get("http://localhost:5000/api/Accounting/revenue-stats", {
          headers: { Authorization: `Bearer ${token}` }
        });
        setRevenueData(response.data);
      } catch (err) {
        console.error("Lỗi tải doanh thu:", err);
      } finally {
        setLoading(false);
      }
    };

    fetchRevenue();

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
      fetchRevenue();
    });

    return () => {
      connection.stop();
    };
  }, [router]);

  const stats = [
    { title: "Doanh thu hôm nay", value: revenueData.length > 0 ? new Intl.NumberFormat('vi-VN').format(revenueData[revenueData.length - 1].revenue) + " ₫" : "0 ₫", desc: "Cập nhật mới nhất", color: "text-green-600" },
    { title: "Đơn hàng mới", value: "3", desc: "Đang chờ xử lý", color: "text-blue-600" },
    { title: "Khách nợ", value: "15.000.000 ₫", desc: "Cần thu hồi gấp", color: "text-red-600" },
  ];

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold text-gray-800 mb-6">Xin chào, Chủ Cửa Hàng 👋</h1>
      
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        {stats.map((stat, idx) => (
          <div key={idx} className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <h3 className="text-gray-500 text-sm font-semibold uppercase">{stat.title}</h3>
            <div className={`text-3xl font-bold mt-2 ${stat.color}`}>{stat.value}</div>
            <p className="text-gray-400 text-xs mt-1">{stat.desc}</p>
          </div>
        ))}
      </div>

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
        <QuickActionCard 
          href="http://localhost:15672"
          color="purple"
          icon="🐰"
          title="RabbitMQ"
          desc="Quản lý hàng đợi tin nhắn"
          external
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
