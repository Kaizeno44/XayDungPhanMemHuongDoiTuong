// lib/screens/owner_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../services/report_service.dart';
import '../models/dashboard_stats.dart';
import '../product_list_screen.dart';
import '../providers/auth_provider.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final ReportService _reportService = ReportService();
  late Future<DashboardStats> _statsFuture;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _statsFuture = _reportService.getOwnerDashboardStats();
    });
  }

  // Hàm điều hướng thông minh
  void _navigateToPos() async {
    // 1. Chờ cho đến khi người dùng quay lại từ màn hình bán hàng
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProductListScreen()),
    );

    // 2. Sau khi quay lại, tự động tải lại dữ liệu mới nhất
    if (mounted) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tổng quan"),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0, // Phẳng, hiện đại hơn
        // NÚT ĐĂNG XUẤT (Góc trái)
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.red),
          tooltip: 'Đăng xuất',
          onPressed: () async {
            // Xác nhận trước khi đăng xuất (Optional - UX tốt hơn)
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("Đăng xuất?"),
                content: const Text("Bạn có chắc muốn thoát tài khoản không?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("Hủy"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(
                      "Đồng ý",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );

            if (confirm == true && mounted) {
              await Provider.of<AuthProvider>(context, listen: false).logout();
            }
          },
        ),

        actions: [
          // NÚT "BÁN HÀNG" (Góc phải)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: FilledButton.icon(
              onPressed: _navigateToPos,
              icon: const Icon(Icons.store, size: 18),
              label: const Text("Bán hàng"),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),

          // Nút Refresh thủ công
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            tooltip: 'Làm mới',
            onPressed: _loadData,
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: FutureBuilder<DashboardStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    "Lỗi tải dữ liệu",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: _loadData,
                    child: const Text("Thử lại"),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(child: Text("Không có dữ liệu"));
          }

          final stats = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hàng thẻ thống kê
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: "Doanh thu hôm nay",
                          amount: stats.todayRevenue,
                          color: Colors.blue.shade700,
                          icon: Icons.attach_money,
                          isDebt: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: "Tổng nợ khách",
                          amount: stats.totalDebt,
                          color: Colors.red.shade700,
                          icon: Icons.warning_amber_rounded,
                          isDebt: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Tiêu đề biểu đồ
                  Text(
                    "Biểu đồ 7 ngày qua",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Biểu đồ
                  Container(
                    height: 300,
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildBarChart(stats.weeklyRevenue),
                  ),

                  // Khoảng trắng dưới cùng để scroll không bị cấn
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget thẻ số liệu (Card)
  Widget _buildStatCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    required bool isDebt,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDebt
            ? Border.all(color: Colors.red.shade100, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Widget Biểu đồ
  Widget _buildBarChart(List<DailyRevenue> data) {
    if (data.isEmpty) return const Center(child: Text("Chưa có dữ liệu"));

    // Tìm giá trị max để scale biểu đồ đẹp hơn
    double maxY = 0;
    for (var e in data) {
      if (e.amount > maxY) maxY = e.amount;
    }
    maxY = maxY == 0 ? 1000000 : maxY * 1.2; // Tăng đỉnh thêm 20% cho thoáng

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                currencyFormat.format(rod.toY),
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                const style = TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                );
                if (value.toInt() >= 0 && value.toInt() < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(data[value.toInt()].dayName, style: style),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: item.amount,
                color: item.amount > 0 ? Colors.blue : Colors.grey.shade300,
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: Colors.grey.shade100,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
