"use client";
import { Package } from "lucide-react";

export default function ProductsPage() {
  return (
    <div className="flex flex-col items-center justify-center h-[60vh] text-center">
      <div className="bg-blue-100 p-6 rounded-full mb-4">
        <Package size={48} className="text-blue-600" />
      </div>
      <h1 className="text-2xl font-bold text-gray-800">Quản lý Sản phẩm</h1>
      <p className="text-gray-500 mt-2 max-w-md">
        Module này sẽ do thành viên <b>Team Mobile (Person B)</b> chịu trách nhiệm đồng bộ dữ liệu.
      </p>
      <button className="mt-6 px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
        + Thêm sản phẩm (Demo)
      </button>
    </div>
  );
}