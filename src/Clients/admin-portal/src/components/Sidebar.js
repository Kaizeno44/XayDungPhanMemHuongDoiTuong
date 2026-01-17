"use client";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import Cookies from "js-cookie";
// Nếu bạn chưa cài icon, có thể dùng text hoặc cài thư viện lucide-react
import { LayoutDashboard, ShoppingBag, ClipboardList, LogOut, Settings, User } from "lucide-react"; 

export default function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();

  const menuItems = [
    { name: "Tổng quan", href: "/merchant/dashboard", icon: LayoutDashboard },
    { name: "Sản phẩm", href: "/merchant/products", icon: ShoppingBag },
    { name: "Đơn hàng", href: "/merchant/orders", icon: ClipboardList },
  ];

  const handleLogout = () => {
    // Xóa cookie và đẩy về trang login
    Cookies.remove("accessToken");
    router.push("/login");
  };

  return (
    <aside className="w-64 bg-white border-r border-gray-200 h-screen flex flex-col fixed left-0 top-0 shadow-sm z-50">
      
      {/* --- PHẦN 1: LOGO & MENU (Nằm ở trên) --- */}
      
      {/* Logo */}
      <div className="h-16 flex items-center justify-center border-b border-gray-100">
        <h1 className="text-2xl font-bold text-blue-600">BizFlow</h1>
      </div>

      {/* Menu List - Dùng flex-1 để nó chiếm hết khoảng trống */}
      <nav className="flex-1 overflow-y-auto py-4 px-3 space-y-1">
        {menuItems.map((item) => {
          const isActive = pathname === item.href;
          const Icon = item.icon;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center px-4 py-3 text-sm font-medium rounded-lg transition-colors ${
                isActive
                  ? "bg-blue-50 text-blue-700"
                  : "text-gray-600 hover:bg-gray-50 hover:text-gray-900"
              }`}
            >
              <Icon className="w-5 h-5 mr-3" />
              {item.name}
            </Link>
          );
        })}
      </nav>

      {/* --- PHẦN 2: FOOTER (Cài đặt & Đăng xuất - Nằm cố định ở đáy) --- */}
      
      <div className="p-3 border-t border-gray-200 bg-gray-50">
        <div className="space-y-1">
          {/* Nút Cài đặt */}
          <Link
            href="/merchant/settings"
            className="flex items-center px-4 py-2 text-sm font-medium text-gray-600 rounded-lg hover:bg-gray-200 transition-colors"
          >
            <Settings className="w-5 h-5 mr-3" />
            Cài đặt
          </Link>

          {/* Nút Đăng xuất */}
          <button
            onClick={handleLogout}
            className="w-full flex items-center px-4 py-2 text-sm font-medium text-red-600 rounded-lg hover:bg-red-50 transition-colors"
          >
            <LogOut className="w-5 h-5 mr-3" />
            Đăng xuất
          </button>
        </div>

        {/* Thông tin User tóm tắt (Optional) */}
        <div className="mt-4 flex items-center px-4 pt-4 border-t border-gray-200">
          <div className="bg-blue-100 p-2 rounded-full">
            <User className="w-4 h-4 text-blue-600" />
          </div>
          <div className="ml-3">
            <p className="text-sm font-medium text-gray-700">Chủ cửa hàng</p>
            <p className="text-xs text-gray-500">Merchant</p>
          </div>
        </div>
      </div>

    </aside>
  );
}