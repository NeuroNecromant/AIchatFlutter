import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/stats_provider.dart';
import '../providers/settings_provider.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'daily';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsProvider>().refreshStats();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text(
          'Расходы',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF262626),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              context.read<StatsProvider>().refreshStats();
            },
            tooltip: 'Обновить',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'По дням'),
            Tab(text: 'По месяцам'),
          ],
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await context.read<StatsProvider>().refreshStats();
          },
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDailyExpensesTab(),
              _buildMonthlyExpensesTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyExpensesTab() {
    return Consumer2<StatsProvider, SettingsProvider>(
      builder: (context, statsProvider, settingsProvider, child) {
        if (statsProvider.dailyExpenses.isEmpty) {
          return _buildEmptyState('Нет данных о ежедневных расходах');
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Информация о провайдере
              _buildProviderInfoCard(settingsProvider),
              
              const SizedBox(height: 20),
              
              // Общая статистика по дням
              _buildDailySummaryCard(statsProvider),
              
              const SizedBox(height: 20),
              
              // График расходов по дням
              _buildDailyExpensesChart(statsProvider),
              
              const SizedBox(height: 20),
              
              // Детальный список расходов по дням
              _buildDailyExpensesList(statsProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthlyExpensesTab() {
    return Consumer2<StatsProvider, SettingsProvider>(
      builder: (context, statsProvider, settingsProvider, child) {
        if (statsProvider.monthlyExpenses.isEmpty) {
          return _buildEmptyState('Нет данных о ежемесячных расходах');
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Информация о провайдере
              _buildProviderInfoCard(settingsProvider),
              
              const SizedBox(height: 20),
              
              // Общая статистика по месяцам
              _buildMonthlySummaryCard(statsProvider),
              
              const SizedBox(height: 20),
              
              // График расходов по месяцам
              _buildMonthlyExpensesChart(statsProvider),
              
              const SizedBox(height: 20),
              
              // Детальный список расходов по месяцам
              _buildMonthlyExpensesList(statsProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              color: Colors.white54,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Отправьте несколько сообщений, чтобы увидеть график расходов',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderInfoCard(SettingsProvider settingsProvider) {
    return Card(
      elevation: 4,
      color: const Color(0xFF333333),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.cloud,
                color: Colors.purple,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Провайдер: ${settingsProvider.provider}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Валюта: ${settingsProvider.provider == 'VSEGPT' ? '₽' : '\$'}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummaryCard(StatsProvider statsProvider) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final totalCost = statsProvider.dailyExpenses.fold<double>(
          0.0, (sum, day) => sum + (day['cost'] as double)
        );
        final avgCost = totalCost / statsProvider.dailyExpenses.length;
        final maxCost = statsProvider.dailyExpenses.fold<double>(
          0.0, (max, day) => (day['cost'] as double) > max ? (day['cost'] as double) : max
        );

        return Card(
          elevation: 4,
          color: const Color(0xFF333333),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Colors.blue,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Ежедневные расходы',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        'Общие расходы',
                        statsProvider.formatCost(totalCost, settingsProvider.provider),
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        'Средние расходы',
                        statsProvider.formatCost(avgCost, settingsProvider.provider),
                        Icons.trending_up,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        'Макс. расходы',
                        statsProvider.formatCost(maxCost, settingsProvider.provider),
                        Icons.arrow_upward,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthlySummaryCard(StatsProvider statsProvider) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final totalCost = statsProvider.monthlyExpenses.fold<double>(
          0.0, (sum, month) => sum + (month['cost'] as double)
        );
        final avgCost = totalCost / statsProvider.monthlyExpenses.length;
        final maxCost = statsProvider.monthlyExpenses.fold<double>(
          0.0, (max, month) => (month['cost'] as double) > max ? (month['cost'] as double) : max
        );

        return Card(
          elevation: 4,
          color: const Color(0xFF333333),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: Colors.purple,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Ежемесячные расходы',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        'Общие расходы',
                        statsProvider.formatCost(totalCost, settingsProvider.provider),
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        'Средние расходы',
                        statsProvider.formatCost(avgCost, settingsProvider.provider),
                        Icons.trending_up,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        'Макс. расходы',
                        statsProvider.formatCost(maxCost, settingsProvider.provider),
                        Icons.arrow_upward,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDailyExpensesChart(StatsProvider statsProvider) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return Card(
          elevation: 4,
          color: const Color(0xFF333333),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'График расходов по дням',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 1,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.white24,
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Colors.white24,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              if (value.toInt() < statsProvider.dailyExpenses.length) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    statsProvider.dailyExpenses[value.toInt()]['formattedDate'],
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 40,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return Text(
                                statsProvider.formatCost(value, settingsProvider.provider),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.white24),
                      ),
                      minX: 0,
                      maxX: (statsProvider.dailyExpenses.length - 1).toDouble(),
                      minY: 0,
                      maxY: statsProvider.dailyExpenses.fold<double>(
                        0.0, (max, day) => (day['cost'] as double) > max ? (day['cost'] as double) : max
                      ) * 1.1,
                      lineBarsData: [
                        LineChartBarData(
                          spots: statsProvider.dailyExpenses.asMap().entries.map((entry) {
                            return FlSpot(entry.key.toDouble(), entry.value['cost'] as double);
                          }).toList(),
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: [Colors.blue, Colors.green],
                          ),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Colors.blue,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.withOpacity(0.3),
                                Colors.green.withOpacity(0.1),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthlyExpensesChart(StatsProvider statsProvider) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return Card(
          elevation: 4,
          color: const Color(0xFF333333),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'График расходов по месяцам',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: statsProvider.monthlyExpenses.fold<double>(
                        0.0, (max, month) => (month['cost'] as double) > max ? (month['cost'] as double) : max
                      ) * 1.1,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              if (value.toInt() < statsProvider.monthlyExpenses.length) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    statsProvider.monthlyExpenses[value.toInt()]['formattedMonth'],
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return Text(
                                statsProvider.formatCost(value, settingsProvider.provider),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.white24),
                      ),
                      barGroups: statsProvider.monthlyExpenses.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value['cost'] as double,
                              gradient: LinearGradient(
                                colors: [Colors.purple, Colors.blue],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              width: 20,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.white24,
                            strokeWidth: 1,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDailyExpensesList(StatsProvider statsProvider) {
    return Card(
      elevation: 4,
      color: const Color(0xFF333333),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Детальный список расходов по дням',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...statsProvider.dailyExpenses.map((day) => 
              _buildExpenseListItem(
                day['formattedDate'] as String,
                day['cost'] as double,
                Icons.calendar_today,
                Colors.blue,
              )
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyExpensesList(StatsProvider statsProvider) {
    return Card(
      elevation: 4,
      color: const Color(0xFF333333),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Детальный список расходов по месяцам',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...statsProvider.monthlyExpenses.map((month) => 
              _buildExpenseListItem(
                month['formattedMonth'] as String,
                month['cost'] as double,
                Icons.calendar_month,
                Colors.purple,
              )
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseListItem(
    String period,
    double cost,
    IconData icon,
    Color color,
  ) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white24,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      period,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Расходы за период',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Consumer<StatsProvider>(
                builder: (context, statsProvider, child) {
                  return Text(
                    statsProvider.formatCost(cost, settingsProvider.provider),
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
