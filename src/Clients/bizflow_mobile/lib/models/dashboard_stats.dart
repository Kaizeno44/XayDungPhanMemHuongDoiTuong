class DashboardStats {
  final double todayRevenue;
  final double totalDebt;
  final List<DailyRevenue> weeklyRevenue;

  DashboardStats({
    required this.todayRevenue,
    required this.totalDebt,
    required this.weeklyRevenue,
  });
}

class DailyRevenue {
  final String dayName; // Ví dụ: "T2", "T3"
  final double amount;

  DailyRevenue(this.dayName, this.amount);
}
