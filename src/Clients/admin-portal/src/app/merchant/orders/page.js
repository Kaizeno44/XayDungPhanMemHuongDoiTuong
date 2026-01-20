"use client";
import { ShoppingCart } from "lucide-react";

export default function OrdersPage() {
  return (
    <div className="flex flex-col items-center justify-center h-[60vh] text-center">
      <div className="bg-orange-100 p-6 rounded-full mb-4">
        <ShoppingCart size={48} className="text-orange-600" />
      </div>
      <h1 className="text-2xl font-bold text-gray-800">Quản lý Đơn hàng</h1>
      <p className="text-gray-500 mt-2 max-w-md">
        Dữ liệu đơn hàng sẽ được đổ về từ <b>App POS (Person C)</b>.
      </p>
    </div>
  );
}