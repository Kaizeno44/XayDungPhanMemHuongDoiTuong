import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Import Provider, Model, Service
import '../providers/auth_provider.dart';
import '../models/dashboard_stats.dart';
import '../services/dashboard_service.dart';

// Import Widget biểu đồ mới tạo
import '../widgets/weekly_revenue_chart.dart';

class OwnerDashboardScreen extends ConsumerStatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  ConsumerState<OwnerDashboardScreen> createState() =>
      _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends ConsumerState<OwnerDashboardScreen> {
  bool _isLoading = true;
  DashboardStats? _stats;
  final _dashboardService = DashboardService();

  @override
  void initState() {
    super.initState();
    _fetchRealData();
  }

  Future<void> _fetchRealData() async {
    final authState = ref.read(authNotifierProvider);
    final storeId = authState.currentUser?.storeId;

    if (storeId != null) {
      final stats = await _dashboardService.getStats(storeId);
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authNotifierProvider).currentUser;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    // Dữ liệu an toàn
    final revenue = _stats?.todayRevenue ?? 0;
    final newOrders = _stats?.todayOrdersCount ?? 0;
    final lowStock = 0; // Tạm thời
    final totalDebt = _stats?.totalDebt ?? 0;

    // Lấy dữ liệu biểu đồ
    final weeklyData = _stats?.weeklyRevenue ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng quan cửa hàng'),
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchRealData();
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchRealData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header Chào hỏi
                    Text(
                      'Xin chào, ${currentUser?.fullName ?? 'Chủ cửa hàng'}! 👋',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hôm nay: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),

                    const SizedBox(height: 24),

                    // 2. Thẻ thống kê (Stats Grid)
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Doanh thu ngày',
                            value: currencyFormat.format(revenue),
                            icon: Icons.attach_money,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Đơn hàng mới',
                            value: '$newOrders',
                            icon: Icons.receipt_long,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Sản phẩm sắp hết',
                            value: '$lowStock',
                            icon: Icons.warning_amber_rounded,
                            color: Colors.orange,
                            isWarning: lowStock > 0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Khách nợ',
                            value: currencyFormat.format(totalDebt),
                            icon: Icons.person_off,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // 3. BIỂU ĐỒ DOANH THU (ĐÃ CẬP NHẬT)
                    const Text(
                      "Biểu đồ doanh thu tuần này",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      height: 300, // Chiều cao biểu đồ
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      // Gọi Widget Biểu đồ tại đây
                      child: WeeklyRevenueChart(weeklyData: weeklyData),
                    ),

                    const SizedBox(height: 50), // Khoảng trống dưới cùng
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isWarning
            ? Border.all(color: Colors.orange.withOpacity(0.5), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
