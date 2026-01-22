"use client";
import Link from "next/link";
import { Users, DollarSign, Settings, LogOut, LayoutDashboard } from "lucide-react";
import Cookies from "js-cookie";
import { useRouter, usePathname } from "next/navigation";

export default function AdminLayout({ children }) {
  const router = useRouter();
  const pathname = usePathname(); // Lấy đường dẫn hiện tại để so sánh

  const handleLogout = () => {
    Cookies.remove("accessToken");
    router.push("/login");
  };

  // Danh sách Menu Admin
  const menuItems = [
    { name: "Tổng quan", href: "/admin/dashboard", icon: <LayoutDashboard size={20} /> },
    { name: "Quản lý Chủ hộ", href: "/admin/owners", icon: <Users size={20} /> },
    { name: "Gói Dịch Vụ", href: "/admin/subscriptions", icon: <DollarSign size={20} /> },
    { name: "Cấu hình", href: "/admin/settings", icon: <Settings size={20} /> },
  ];

  return (
    <div className="flex h-screen bg-gray-100">
      {/* SIDEBAR */}
      <aside className="w-64 bg-slate-900 text-white flex flex-col">
        <div className="p-6 text-2xl font-bold text-red-500 border-b border-gray-700">
          Super Admin 🛡️
        </div>
        
        <nav className="flex-1 p-4 space-y-2">
          {menuItems.map((item) => {
            // Kiểm tra xem trang hiện tại có trùng với menu này không
            // Dùng startsWith để khi vào trang con (ví dụ /admin/owners/create) thì menu cha vẫn sáng
            const isActive = pathname.startsWith(item.href);

            return (
              <Link 
                key={item.href} 
                href={item.href} 
                className={`flex items-center gap-3 p-3 rounded transition-all ${
                  isActive 
                    ? "bg-blue-600 text-white shadow-lg font-bold" // Active: Màu xanh, chữ đậm
                    : "hover:bg-slate-800 text-gray-400"           // Inactive: Màu xám
                }`}
              >
                {item.icon}
                {item.name}
              </Link>
            );
          })}
        </nav>

        <div className="p-4 border-t border-gray-700">
          <button onClick={handleLogout} className="flex items-center gap-3 text-gray-400 hover:text-white w-full p-2 hover:bg-slate-800 rounded">
            <LogOut size={20} /> Đăng xuất
          </button>
        </div>
      </aside>

      {/* MAIN CONTENT */}
      <main className="flex-1 overflow-auto p-4">
        {children}
      </main>
    </div>
  );
}