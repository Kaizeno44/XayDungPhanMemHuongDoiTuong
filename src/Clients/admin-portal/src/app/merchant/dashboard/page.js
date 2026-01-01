export default function MerchantDashboard() {
  // Dữ liệu giả lập (Sau này Person E sẽ call API GetRevenueStats ở đây)
  const stats = [
    { title: "Doanh thu hôm nay", value: "0 ₫", desc: "Chưa có đơn hàng", color: "text-green-600" },
    { title: "Đơn hàng mới", value: "0", desc: "Đang chờ nhân viên...", color: "text-blue-600" },
    { title: "Khách nợ", value: "15.000.000 ₫", desc: "Cần thu hồi gấp", color: "text-red-600" },
  ];

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-800 mb-6">Xin chào, Chủ Cửa Hàng 👋</h1>
      
      {/* 1. KHU VỰC THỐNG KÊ NHANH */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        {stats.map((stat, idx) => (
          <div key={idx} className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <h3 className="text-gray-500 text-sm font-semibold uppercase">{stat.title}</h3>
            <div className={`text-3xl font-bold mt-2 ${stat.color}`}>{stat.value}</div>
            <p className="text-gray-400 text-xs mt-1">{stat.desc}</p>
          </div>
        ))}
      </div>

      {/* 2. KHU VỰC BIỂU ĐỒ (Đất diễn của Person E) */}
      <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200 h-96 flex items-center justify-center bg-gray-50">
        <div className="text-center">
            <p className="text-gray-400 text-lg mb-2">📊 Khu vực Biểu đồ Doanh thu</p>
            <p className="text-sm text-gray-500 italic">
                (Phần này @Person E sẽ tích hợp thư viện Chart.js vào tuần sau)
            </p>
        </div>
      </div>
    </div>
  );
}