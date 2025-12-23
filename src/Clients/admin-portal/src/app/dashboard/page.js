"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Cookies from "js-cookie";
import Link from "next/link"; // 👈 [QUAN TRỌNG] Thêm dòng này để dùng Link

export default function Dashboard() {
  const router = useRouter();
  const [user, setUser] = useState(null);

  // Kiểm tra xem có Token không, không có thì đá về Login
  useEffect(() => {
    const token = Cookies.get("accessToken");
    if (!token) {
      router.push("/"); // Đá về trang login
    } else {
        setUser({ name: "Admin (Person A)" }); 
    }
  }, [router]);

  const handleLogout = () => {
    Cookies.remove("accessToken");
    router.push("/");
  };

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      {/* Navbar */}
      <header className="bg-white shadow p-4 flex justify-between items-center">
        <h1 className="text-xl font-bold text-blue-600">BizFlow Admin</h1>
        <div className="flex items-center gap-4">
            <span className="text-gray-600">Xin chào, {user?.name}</span>
            <button 
                onClick={handleLogout}
                className="bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600 text-sm"
            >
                Đăng Xuất
            </button>
        </div>
      </header>

      {/* Content */}
      <main className="flex-1 p-8">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            
            {/* Card 1: Quản lý Nhân viên (ĐÃ GẮN LINK) */}
            <Link href="/employees"> {/* 👈 Bấm vào đây sẽ nhảy sang trang Nhân viên */}
                <div className="bg-white p-6 rounded shadow hover:shadow-lg cursor-pointer border-l-4 border-blue-500 h-full">
                    <h3 className="text-lg font-bold mb-2">👤 Quản lý Nhân viên</h3>
                    <p className="text-gray-500 text-sm">Tạo tài khoản cho Person B và C</p>
                </div>
            </Link>

            {/* Card 2: Báo cáo Doanh thu (Ví dụ gắn link sau này) */}
            <Link href="/reports">
                <div className="bg-white p-6 rounded shadow hover:shadow-lg cursor-pointer border-l-4 border-green-500 h-full">
                    <h3 className="text-lg font-bold mb-2">💰 Báo cáo (Person E)</h3>
                    <p className="text-gray-500 text-sm">Xem biểu đồ doanh thu & xuất PDF</p>
                </div>
            </Link>

            {/* Card 3: Cấu hình */}
            <Link href="/settings">
                <div className="bg-white p-6 rounded shadow hover:shadow-lg cursor-pointer border-l-4 border-purple-500 h-full">
                    <h3 className="text-lg font-bold mb-2">⚙️ Cấu hình</h3>
                    <p className="text-gray-500 text-sm">Thiết lập chung cho hệ thống</p>
                </div>
            </Link>
            
        </div>
      </main>
    </div>
  );
}