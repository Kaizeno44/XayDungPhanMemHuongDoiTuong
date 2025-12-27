"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Cookies from "js-cookie";
import Link from "next/link";

export default function Dashboard() {
  const router = useRouter();
  const [user, setUser] = useState({ name: "Super Admin" });
  const [tenants, setTenants] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const token = Cookies.get("accessToken");

    // 1. Check Auth
    if (!token) {
      router.push("/login");
      return;
    }

    // 2. Gọi API lấy danh sách Tenant (Hộ kinh doanh)
    const fetchTenants = async () => {
      try {
        // Lưu ý: Đổi URL thành cổng API thật của bạn (ví dụ 5001)
        const response = await fetch("https://localhost:5001/api/admin/tenants", {
          method: "GET",
          headers: {
            "Authorization": `Bearer ${token}`,
            "Content-Type": "application/json",
          },
        });

        if (!response.ok) {
          throw new Error("Không thể tải dữ liệu.");
        }

        const data = await response.json();
        setTenants(data);
      } catch (err) {
        console.error(err);
        setError("Không kết nối được với Server (Hãy kiểm tra HTTPS/Port).");
      } finally {
        setLoading(false);
      }
    };

    fetchTenants();
  }, [router]);

  const handleLogout = () => {
    Cookies.remove("accessToken");
    router.push("/login");
  };

  return (
    <div className="min-h-screen bg-gray-50 font-sans text-gray-800">
      {/* --- Header --- */}
      <header className="bg-white border-b border-gray-200 sticky top-0 z-10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex justify-between items-center">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center text-white font-bold text-lg">
              B
            </div>
            <h1 className="text-xl font-bold text-gray-900 tracking-tight">
              BizFlow <span className="text-blue-600 font-normal">Admin</span>
            </h1>
          </div>

          <div className="flex items-center gap-4">
            <div className="text-right hidden sm:block">
              <p className="text-sm font-medium text-gray-900">{user?.name}</p>
              <p className="text-xs text-green-600 font-medium">● Online</p>
            </div>
            <button
              onClick={handleLogout}
              className="bg-gray-100 hover:bg-gray-200 text-gray-700 px-4 py-2 rounded-lg text-sm font-medium transition-colors"
            >
              Đăng Xuất
            </button>
          </div>
        </div>
      </header>

      {/* --- Main Content --- */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        
        {/* Section 1: Quick Actions (Các thẻ điều hướng cũ của bạn) */}
        <div className="mb-8">
          <h2 className="text-lg font-bold text-gray-800 mb-4">Lối tắt quản lý</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <QuickActionCard 
              href="/employees"
              color="blue"
              icon="👤"
              title="Quản lý Nhân sự"
              desc="Tạo tài khoản cho Person B & C"
            />
            <QuickActionCard 
              href="/reports"
              color="green"
              icon="📊"
              title="Báo cáo Tổng hợp"
              desc="Xem doanh thu toàn hệ thống"
            />
            <QuickActionCard 
              href="/settings"
              color="purple"
              icon="⚙️"
              title="Cấu hình Hệ thống"
              desc="Thiết lập gói cước & tham số"
            />
          </div>
        </div>

        {/* Section 2: Danh sách Tenant (Dữ liệu thật từ Database) */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          <div className="p-6 border-b border-gray-100 flex justify-between items-center">
            <div>
              <h2 className="text-lg font-bold text-gray-900">Danh sách Hộ Kinh Doanh</h2>
              <p className="text-sm text-gray-500 mt-1">Quản lý các cửa hàng đang sử dụng nền tảng BizFlow</p>
            </div>
            <span className="bg-blue-50 text-blue-700 text-xs font-bold px-3 py-1 rounded-full">
              Tổng: {tenants.length} cửa hàng
            </span>
          </div>
          
          <div className="overflow-x-auto">
            {loading ? (
              <div className="p-8 text-center text-gray-500">⏳ Đang tải dữ liệu từ Server...</div>
            ) : error ? (
              <div className="p-8 text-center text-red-500 bg-red-50">⚠️ {error}</div>
            ) : (
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-gray-50 text-gray-600 text-sm uppercase tracking-wider">
                    <th className="p-4 font-semibold border-b">Tên Cửa Hàng</th>
                    <th className="p-4 font-semibold border-b">Chủ Sở Hữu</th>
                    <th className="p-4 font-semibold border-b">Gói Cước</th>
                    <th className="p-4 font-semibold border-b text-center">Nhân sự</th>
                    <th className="p-4 font-semibold border-b text-right">Trạng thái</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {tenants.map((shop) => (
                    <tr key={shop.storeId} className="hover:bg-gray-50 transition-colors">
                      <td className="p-4">
                        <p className="font-semibold text-gray-900">{shop.storeName}</p>
                        <p className="text-xs text-gray-500">{shop.phone}</p>
                      </td>
                      <td className="p-4 text-gray-700">
                        {shop.ownerName}
                      </td>
                      <td className="p-4">
                        <span className={`px-2 py-1 rounded text-xs font-bold ${
                          shop.planName?.includes("Pro") 
                            ? "bg-indigo-100 text-indigo-700" 
                            : "bg-gray-100 text-gray-600"
                        }`}>
                          {shop.planName}
                        </span>
                      </td>
                      <td className="p-4 text-center text-gray-600 font-medium">
                        {shop.userCount}
                      </td>
                      <td className="p-4 text-right">
                         <span className="text-green-600 text-sm font-medium">Active</span>
                      </td>
                    </tr>
                  ))}
                  {tenants.length === 0 && (
                     <tr>
                        <td colSpan="5" className="p-8 text-center text-gray-400">Chưa có dữ liệu cửa hàng nào.</td>
                     </tr>
                  )}
                </tbody>
              </table>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}

// Component con để render thẻ Card cho gọn code
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