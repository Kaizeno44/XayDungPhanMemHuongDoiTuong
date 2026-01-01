"use client";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import Cookies from "js-cookie";

export default function MerchantLayout({ children }) {
  const pathname = usePathname();
  const router = useRouter();

  const handleLogout = () => {
    Cookies.remove('accessToken');
    router.push('/login');
  };

  const menuItems = [
    { name: "Tổng quan", href: "/merchant/dashboard", icon: "📊" },
    { name: "Sản phẩm", href: "/merchant/products", icon: "🏷️" }, // Sau này B làm
    { name: "Đơn hàng", href: "/merchant/orders", icon: "📦" }, // Sau này C đổ dữ liệu về
    { name: "Nhân viên", href: "/employees", icon: "👥" }, // Dùng lại trang nhân viên bạn đã làm
  ];

  return (
    <div className="flex min-h-screen bg-gray-50">
      {/* SIDEBAR MÀU CAM - DÀNH RIÊNG CHO CHỦ SHOP */}
      <aside className="w-64 bg-orange-800 text-white flex-shrink-0 flex flex-col">
        <div className="p-6 text-2xl font-bold border-b border-orange-700">
          BizFlow <span className="text-sm font-normal opacity-80 block">Merchant Portal</span>
        </div>
        
        <nav className="flex-1 mt-6">
          <ul>
            {menuItems.map((item) => (
              <li key={item.href}>
                <Link href={item.href}
                  className={`flex items-center px-6 py-4 hover:bg-orange-700 transition-colors ${
                    pathname === item.href ? "bg-orange-900 border-l-4 border-white" : ""
                  }`}
                >
                  <span className="mr-3 text-xl">{item.icon}</span>
                  {item.name}
                </Link>
              </li>
            ))}
          </ul>
        </nav>

        <div className="p-4 border-t border-orange-700">
            <button onClick={handleLogout} className="w-full py-2 bg-orange-700 hover:bg-orange-600 rounded text-sm font-bold">
                Đăng xuất
            </button>
        </div>
      </aside>

      {/* NỘI DUNG CHÍNH */}
      <main className="flex-1 p-8 overflow-y-auto">
        {children}
      </main>
    </div>
  );
}