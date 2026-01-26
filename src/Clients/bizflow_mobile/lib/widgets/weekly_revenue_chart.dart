import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/dashboard_stats.dart';

class WeeklyRevenueChart extends StatelessWidget {
  final List<DailyRevenue> weeklyData;

  const WeeklyRevenueChart({super.key, required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    // 1. Kiểm tra dữ liệu rỗng
    if (weeklyData.isEmpty) {
      return const Center(child: Text("Chưa có dữ liệu doanh thu tuần này"));
    }

    // --- [LOGIC MỚI] CẮT LẤY 7 NGÀY CUỐI CÙNG ---
    List<DailyRevenue> chartData = weeklyData;

    // Nếu dữ liệu nhiều hơn 7 ngày, chỉ lấy 7 phần tử cuối (Mới nhất)
    if (weeklyData.length > 7) {
      chartData = weeklyData.sublist(weeklyData.length - 7);
    }
    // ----------------------------------------------

    // 2. Tìm giá trị Max Y dựa trên dữ liệu ĐÃ LỌC (chartData)
    double maxY = 0;
    for (var item in chartData) {
      if (item.amount > maxY) maxY = item.amount;
    }
    if (maxY == 0) maxY = 1000000;
    maxY = maxY * 1.2; // Thêm khoảng trống phía trên

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,

        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),

        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),

          // Trục dưới (Ngày)
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                // Kiểm tra index dựa trên danh sách ĐÃ LỌC
                if (index < 0 || index >= chartData.length)
                  return const SizedBox();

                String text = chartData[index].dayName;
                // Rút gọn tên ngày
                if (!text.contains('/') && text.length > 3) {
                  text = text.substring(0, 3);
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),

          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),

        // Vẽ cột dựa trên danh sách ĐÃ LỌC (chartData)
        barGroups: chartData.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: item.amount,
                color: Colors.orange[800],
                width:
                    20, // Tăng độ rộng cột lên 20 cho dễ nhìn (vì giờ chỉ có 7 cột)
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: Colors.grey[100],
                ),
              ),
            ],
            showingTooltipIndicators: [0],
          );
        }).toList(),

        barTouchData: BarTouchData(
          enabled: false,
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding: const EdgeInsets.only(bottom: -4),
            tooltipMargin: 4,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                _formatCurrency(rod.toY),
                const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              );
            },
            getTooltipColor: (_) => Colors.transparent,
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      double res = value / 1000000;
      return '${res.toStringAsFixed(res % 1 == 0 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      double res = value / 1000;
      return '${res.toStringAsFixed(res % 1 == 0 ? 0 : 1)}K';
    }
    return value.toStringAsFixed(0);
  }
}
