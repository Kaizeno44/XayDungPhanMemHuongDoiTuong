"use client";
export default function AdminSettingsPage() {
  return (
    <div className="p-8 max-w-2xl">
      <h1 className="text-2xl font-bold text-gray-800 mb-6">⚙️ Cấu hình Hệ thống</h1>
      <div className="bg-white p-6 rounded-xl shadow-sm border space-y-6">
        <div>
            <label className="block text-sm font-medium mb-1">Tên Hệ Thống</label>
            <input type="text" value="BizFlow Platform" disabled className="w-full p-2 border rounded bg-gray-100" />
        </div>
        <div className="flex items-center justify-between">
            <span className="font-medium">Chế độ bảo trì</span>
            <input type="checkbox" className="toggle" />
        </div>
        <div className="pt-4 border-t">
            <button className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700">Lưu thay đổi</button>
        </div>
      </div>
    </div>
  );
}