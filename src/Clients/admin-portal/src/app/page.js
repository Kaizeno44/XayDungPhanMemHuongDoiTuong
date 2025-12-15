"use client"; // Bắt buộc: để dùng được React trong Next.js mới

import { useEffect, useState } from 'react';
import api from '@/utils/api'; // Import cái file cầu nối vừa tạo

export default function HomePage() {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    // Hàm gọi API lấy danh sách sản phẩm
    const fetchProducts = async () => {
      try {
        // Gọi sang Gateway: https://localhost:5000/api/products
        const response = await api.get('/products');
        setProducts(response.data); // Lưu dữ liệu vào biến
      } catch (err) {
        console.error("Lỗi:", err);
        setError("Không thể kết nối đến Server Gateway!");
      } finally {
        setLoading(false);
      }
    };

    fetchProducts();
  }, []);

  return (
    <div className="min-h-screen bg-gray-100 p-10">
      <h1 className="text-3xl font-bold text-blue-600 mb-6 text-center">
        Demo Kết nối Backend .NET 8 🚀
      </h1>

      {/* Hiển thị khi đang tải */}
      {loading && <p className="text-center text-gray-500">Đang tải dữ liệu từ kho...</p>}
      
      {/* Hiển thị khi có lỗi */}
      {error && <p className="text-center text-red-500 font-bold">{error}</p>}

      {/* Hiển thị danh sách sản phẩm khi tải xong */}
      {!loading && !error && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 max-w-6xl mx-auto">
          {products.map((product) => (
            <div key={product.id} className="bg-white p-6 rounded-lg shadow-md hover:shadow-lg transition">
              <div className="text-xl font-bold text-gray-800">{product.name}</div>
              <div className="text-green-600 font-semibold mt-2">
                {product.price.toLocaleString()} VNĐ
              </div>
              <div className="text-gray-500 text-sm mt-1">
                Đơn vị: {product.unit}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}