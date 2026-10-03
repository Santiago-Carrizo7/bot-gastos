import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../expenses/models/summary_model.dart';
import '../../expenses/providers/expense_providers.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _touchedPieIndex = -1;
  String? _selectedCategoryForDetail;

  void _previousMonth() {
    final current = ref.read(selectedDateProvider);
    ref.read(selectedDateProvider.notifier).state = DateTime(
      current.year,
      current.month - 1,
      1,
    );
  }

  void _nextMonth() {
    final current = ref.read(selectedDateProvider);
    ref.read(selectedDateProvider.notifier).state = DateTime(
      current.year,
      current.month + 1,
      1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedDate = ref.watch(selectedDateProvider);
    final analyticsAsync = ref.watch(analyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
      ),
      body: analyticsAsync.when(
        data: (analytics) {
          final summary = analytics.current;
          final history = analytics.monthlyHistory;

          final sortedCategories = summary.categories.entries.toList()
            ..sort((a, b) => b.value.total.compareTo(a.value.total));

          final avgPerExpense =
              summary.count > 0 ? (summary.total / summary.count) : 0.0;
          final topCategory =
              sortedCategories.isNotEmpty ? sortedCategories.first : null;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(analyticsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              children: [
                // Selector Temporal
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        tooltip: 'Mes anterior',
                        onPressed: _previousMonth,
                      ),
                      Text(
                        DateFormatter.formatMonthYear(
                          selectedDate.year,
                          selectedDate.month,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        tooltip: 'Mes siguiente',
                        onPressed: _nextMonth,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tarjetas de Métricas Clave (2x2)
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total gastado',
                        value: CurrencyFormatter.format(summary.total),
                        icon: Icons.payments_outlined,
                        color: AppColors.primary,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Promedio / gasto',
                        value: CurrencyFormatter.format(avgPerExpense),
                        icon: Icons.calculate_outlined,
                        color: AppColors.info,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Categoría top',
                        value: topCategory != null
                            ? '${CategoryIcons.getEmoji(topCategory.key)} ${topCategory.key[0].toUpperCase()}${topCategory.key.substring(1)}'
                            : '—',
                        subtitle: topCategory != null
                            ? CurrencyFormatter.format(topCategory.value.total)
                            : null,
                        icon: Icons.star_outline_rounded,
                        color: AppColors.warning,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Transacciones',
                        value: '${summary.count}',
                        subtitle: summary.count == 1 ? 'registro' : 'registros',
                        icon: Icons.receipt_long_outlined,
                        color: AppColors.secondary,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (summary.total == 0) ...[
                  const EmptyStateView(
                    icon: Icons.bar_chart_rounded,
                    title: 'Sin datos para este mes',
                    description: 'No se encontraron registros de gastos en el período seleccionado.',
                  ),
                ] else ...[
                  // Gráfico 1: Donut Chart de Distribución
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Distribución por Categoría',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback: (event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection == null) {
                                        _touchedPieIndex = -1;
                                        return;
                                      }
                                      _touchedPieIndex = pieTouchResponse
                                          .touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                sectionsSpace: 2,
                                centerSpaceRadius: 46,
                                sections: List.generate(sortedCategories.length, (i) {
                                  final isTouched = i == _touchedPieIndex;
                                  final entry = sortedCategories[i];
                                  final amount = entry.value.total;
                                  final percentage = summary.total > 0
                                      ? (amount / summary.total) * 100
                                      : 0.0;
                                  final radius = isTouched ? 48.0 : 40.0;
                                  final color = CategoryIcons.getColorForCategory(entry.key);

                                  return PieChartSectionData(
                                    color: color,
                                    value: amount,
                                    title: '${percentage.round()}%',
                                    radius: radius,
                                    titleStyle: TextStyle(
                                      fontSize: isTouched ? 13 : 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Leyenda de categorías
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: sortedCategories.map((entry) {
                              final color = CategoryIcons.getColorForCategory(entry.key);
                              final emoji = CategoryIcons.getEmoji(entry.key);
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$emoji ${entry.key}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Gráfico 2: Evolución Mensual de los Últimos Meses (Bar Chart)
                if (history.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Evolución Últimos Meses',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 180,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: _calculateMaxY(history),
                                barTouchData: BarTouchData(
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      final item = history[group.x.toInt()];
                                      return BarTooltipItem(
                                        '${item.monthName}\n${CurrencyFormatter.format(item.total)}',
                                        const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (val, meta) {
                                        final idx = val.toInt();
                                        if (idx >= 0 && idx < history.length) {
                                          final name = history[idx].monthName;
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              name.length >= 3 ? name.substring(0, 3) : name,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? AppColors.textTertiaryDark
                                                    : AppColors.textSecondaryLight,
                                              ),
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ),
                                ),
                                gridData: const FlGridData(show: false),
                                borderData: FlBorderData(show: false),
                                barGroups: List.generate(history.length, (i) {
                                  final item = history[i];
                                  final isCurrentMonth = item.year == selectedDate.year &&
                                      item.month == selectedDate.month;

                                  return BarChartGroupData(
                                    x: i,
                                    barRods: [
                                      BarChartRodData(
                                        toY: item.total,
                                        color: isCurrentMonth
                                            ? AppColors.primary
                                            : (isDark
                                                ? AppColors.primaryDark.withValues(alpha: 0.4)
                                                : AppColors.primaryLight.withValues(alpha: 0.4)),
                                        width: 18,
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(6),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Desglose de Categorías con Evolución al Tocar
                if (sortedCategories.isNotEmpty) ...[
                  const Text(
                    'Detalle por Categoría',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Card(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedCategories.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final entry = sortedCategories[i];
                        final catName = entry.key;
                        final amount = entry.value.total;
                        final count = entry.value.count;
                        final percentage = summary.total > 0
                            ? ((amount / summary.total) * 100).round()
                            : 0;
                        final emoji = CategoryIcons.getEmoji(catName);

                        return ListTile(
                          onTap: () {
                            setState(() {
                              _selectedCategoryForDetail =
                                  _selectedCategoryForDetail == catName ? null : catName;
                            });
                          },
                          leading: Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: CategoryIcons.getColorForCategory(catName)
                                  .withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Text(emoji, style: const TextStyle(fontSize: 18)),
                          ),
                          title: Text(
                            catName[0].toUpperCase() + catName.substring(1),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '$count ${count == 1 ? "gasto" : "gastos"} • $percentage% del mes',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          trailing: Text(
                            CurrencyFormatter.format(amount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const LoadingView(message: 'Cargando análisis estadístico...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(analyticsProvider),
        ),
      ),
    );
  }

  double _calculateMaxY(List<MonthHistoryItem> history) {
    double max = 0;
    for (final item in history) {
      if (item.total > max) max = item.total;
    }
    return max == 0 ? 100 : max * 1.25;
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                Icon(icon, size: 18, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
