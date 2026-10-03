import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../budgets/providers/budget_providers.dart';
import '../../expenses/presentation/expense_detail_sheet.dart';
import '../../expenses/presentation/expense_form_screen.dart';
import '../../expenses/providers/expense_providers.dart';

class HomeScreen extends ConsumerWidget {
  final void Function(int tabIndex)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  void _previousMonth(WidgetRef ref) {
    final current = ref.read(selectedDateProvider);
    ref.read(selectedDateProvider.notifier).state = DateTime(
      current.year,
      current.month - 1,
      1,
    );
  }

  void _nextMonth(WidgetRef ref) {
    final current = ref.read(selectedDateProvider);
    ref.read(selectedDateProvider.notifier).state = DateTime(
      current.year,
      current.month + 1,
      1,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedDate = ref.watch(selectedDateProvider);
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final recentExpensesAsync = ref.watch(recentExpensesProvider);
    final budgetsAsync = ref.watch(budgetsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Nuevo Gasto',
            onPressed: () => ExpenseFormScreen.show(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          refreshAllExpenseData(ref);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: [
            // Selector de Mes
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
                    onPressed: () => _previousMonth(ref),
                  ),
                  Text(
                    DateFormatter.formatMonthYear(
                      selectedDate.year,
                      selectedDate.month,
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    tooltip: 'Mes siguiente',
                    onPressed: () => _nextMonth(ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card Resumen del Mes
            summaryAsync.when(
              data: (summary) {
                // Cálculo de presupuesto total
                double totalBudget = 0.0;
                budgetsAsync.whenData((budgets) {
                  for (final b in budgets) {
                    totalBudget += b.budgetAmount;
                  }
                });

                final remaining = totalBudget > 0 ? totalBudget - summary.total : null;

                return Card(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                AppColors.primaryDark.withValues(alpha: 0.35),
                                AppColors.surfaceDark,
                              ]
                            : [
                                AppColors.primaryContainer.withValues(alpha: 0.6),
                                Colors.white,
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TOTAL GASTADO',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primaryDark,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: (isDark
                                        ? AppColors.primaryDark
                                        : AppColors.primary)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${summary.count} ${summary.count == 1 ? "gasto" : "gastos"}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.primaryLight
                                      : AppColors.primaryDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.format(summary.total),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (totalBudget > 0) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Presupuesto fijado',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    CurrencyFormatter.format(totalBudget),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              if (remaining != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      remaining >= 0 ? 'Disponible' : 'Excedido por',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      CurrencyFormatter.format(remaining.abs()),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: remaining >= 0
                                            ? AppColors.success
                                            : AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: LoadingView(message: 'Cargando balance mensual...'),
                ),
              ),
              error: (err, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ErrorView(
                    message: err.toString(),
                    onRetry: () => ref.invalidate(monthlySummaryProvider),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Principales Categorías del Mes
            summaryAsync.when(
              data: (summary) {
                if (summary.categories.isEmpty) {
                  return const SizedBox.shrink();
                }

                final sorted = summary.categories.entries.toList()
                  ..sort((a, b) => b.value.total.compareTo(a.value.total));
                final topCategories = sorted.take(4).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Principales Categorías',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (onNavigateTab != null)
                          TextButton(
                            onPressed: () => onNavigateTab!(2), // Ir a Estadísticas
                            child: const Text('Ver más'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: topCategories.map((entry) {
                            final catName = entry.key;
                            final amount = entry.value.total;
                            final percentage = summary.total > 0
                                ? (amount / summary.total)
                                : 0.0;
                            final emoji = CategoryIcons.getEmoji(catName);

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Text(emoji, style: const TextStyle(fontSize: 16)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          catName[0].toUpperCase() + catName.substring(1),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        CurrencyFormatter.format(amount),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  LinearProgressIndicator(
                                    value: percentage,
                                    backgroundColor: isDark
                                        ? AppColors.cardDark
                                        : AppColors.backgroundLight,
                                    color: CategoryIcons.getColorForCategory(catName),
                                    borderRadius: BorderRadius.circular(4),
                                    minHeight: 6,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => const SizedBox.shrink(),
            ),

            // Gastos Recientes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gastos Recientes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                if (onNavigateTab != null)
                  TextButton(
                    onPressed: () => onNavigateTab!(1), // Ir a Gastos
                    child: const Text('Historial'),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            recentExpensesAsync.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.receipt_long_outlined,
                    title: 'Sin gastos registrados',
                    description: 'Comenzá a registrar tus gastos desde Telegram o agregalos manualmente.',
                    actionLabel: 'Nuevo gasto',
                    onAction: () => ExpenseFormScreen.show(context),
                  );
                }

                return Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: expenses.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final exp = expenses[index];
                      final emoji = CategoryIcons.getEmoji(exp.category);

                      return ListTile(
                        onTap: () => ExpenseDetailSheet.show(context, exp),
                        leading: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.cardDark
                                : AppColors.primaryContainer.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Text(emoji, style: const TextStyle(fontSize: 18)),
                        ),
                        title: Text(
                          exp.description,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          DateFormatter.formatRelative(exp.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        trailing: Text(
                          CurrencyFormatter.format(exp.amount, currency: exp.currency),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const LoadingView(message: 'Cargando gastos recientes...'),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(recentExpensesProvider),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
