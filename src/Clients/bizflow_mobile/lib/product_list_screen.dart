import 'package:flutter/material.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  // Giả lập dữ liệu Vật Liệu Xây Dựng (Mock Data)
  final List<Map<String, dynamic>> products = const [
    {
      "name": "Xi măng Hà Tiên PCB40",
      "price": "90.000 đ / Bao",
      "icon": Icons.home_work, // Biểu tượng công trình
      "color": Colors.grey
    },
    {
      "name": "Thép cuộn Hòa Phát",
      "price": "18.500 đ / Kg",
      "icon": Icons.build, // Biểu tượng búa/kỹ thuật
      "color": Colors.blueGrey
    },
    {
      "name": "Cát vàng xây tô",
      "price": "350.000 đ / Khối",
      "icon": Icons.terrain, // Biểu tượng địa hình/cát
      "color": Colors.orangeAccent
    },
    {
      "name": "Gạch ống 4 lỗ Tuynel",
      "price": "1.200 đ / Viên",
      "icon": Icons.grid_view, // Biểu tượng giống viên gạch
      "color": Colors.redAccent
    },
    {
      "name": "Sơn Dulux Trắng Sứ",
      "price": "1.800.000 đ / Thùng",
      "icon": Icons.format_paint, // Biểu tượng lăn sơn
      "color": Colors.blue
    },
    {
      "name": "Đá xanh 1x2",
      "price": "280.000 đ / Khối",
      "icon": Icons.filter_hdr, // Biểu tượng đá núi
      "color": Colors.black54
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho VLXD'),
        centerTitle: true,
        backgroundColor: Colors.blue[800], // Màu xanh đậm chất xây dựng
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey[100], // Màu nền nhẹ cho đỡ mỏi mắt
        child: ListView.builder(
          itemCount: products.length,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, index) {
            final product = products[index];
            return Card(
              elevation: 4, // Đổ bóng cao hơn chút cho đẹp
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: product['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(product['icon'], color: product['color'], size: 30),
                ),
                title: Text(
                  product['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16,
                    color: Colors.black87
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    product['price'],
                    style: const TextStyle(
                      color: Colors.red, 
                      fontWeight: FontWeight.bold,
                      fontSize: 15
                    ),
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đang xem: ${product['name']}'),
                      duration: const Duration(milliseconds: 500),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}