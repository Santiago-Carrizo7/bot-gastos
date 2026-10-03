import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../expenses/providers/expense_providers.dart';
import '../models/budget_model.dart';
import '../providers/budget_providers.dart';
import 'budget_form_dialog.dart';

class BudgetListScreen extends ConsumerWidget {
  const BudgetListScreen({super.key});

  void _confirmDelete(BuildContext context, WidgetRef ref, BudgetModel budget) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Presupuesto'),
        content: Text(
          '¿Estás seguro de que querés eliminar el presupuesto mensual de "${budget.category}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final repo = ref.read(budgetRepositoryProvider);
                await repo.deleteBudget(budget.id);
                ref.invalidate(budgetsListProvider);
                ref.invalidate(monthlySummaryProvider);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Presupuesto eliminado'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar: $e'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final budgetsAsync = ref.watch(budgetsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presupuestos'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => BudgetFormDialog.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Presupuesto'),
      ),
      body: budgetsAsync.when(
        data: (budgets) {
          if (budgets.isEmpty) {
            return EmptyStateView(
              icon: Icons.pie_chart_outline_rounded,
              title: 'Sin presupuestos mensuales',
              description:
                  'Definí topes de gasto mensual por categoría para mantener tus finanzas bajo control.',
              actionLabel: 'Fijar presupuesto',
              onAction: () => BudgetFormDialog.show(context),
            );
          }

          // Métricas globales acumuladas
          double totalBudgeted = 0;
          double totalSpent = 0;
          for (final b in budgets) {
            totalBudgeted += b.budgetAmount;
            totalSpent += b.spentAmount;
          }
          final globalRemaining = totalBudgeted - totalSpent;
          final globalPercentage =
              totalBudgeted > 0 ? ((totalSpent / totalBudgeted) * 100).round() : 0;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(budgetsListProvider);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              children: [
                // Resumen Global
                Card(
                  child: Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                AppColors.surfaceDark,
                                AppColors.cardDark,
                              ]
                            : [
                                Colors.white,
                                AppColors.primaryContainer.withValues(alpha: 0.3),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL PRESUPUESTADO',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: AppColors.primary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: (globalPercentage >= 100
                                        ? AppColors.error
                                        : globalPercentage >= 80
                                            ? AppColors.warning
                                            : AppColors.success)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$globalPercentage% usado',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: globalPercentage >= 100
                                      ? AppColors.error
                                      : globalPercentage >= 80
                                          ? AppColors.warning
                                          : AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${CurrencyFormatter.format(totalSpent)} / ${CurrencyFormatter.format(totalBudgeted)}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: totalBudgeted > 0
                                ? (totalSpent / totalBudgeted).clamp(0.0, 1.0)
                                : 0.0,
                            minHeight: 10,
                            backgroundColor: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                            color: globalPercentage >= 100
                                ? AppColors.error
                                : globalPercentage >= 80
                                    ? AppColors.warning
                                    : AppColors.success,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              globalRemaining >= 0
                                  ? 'Disponible en total:'
                                  : 'Excedido en total:',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(globalRemaining.abs()),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: globalRemaining >= 0
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Por Categoría',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),

                // Lista de Categorías
                ...budgets.map((b) {
                  final emoji = CategoryIcons.getEmoji(b.category);
                  final progressClamped = b.budgetAmount > 0
                      ? (b.spentAmount / b.budgetAmount).clamp(0.0, 1.0)
                      : 0.0;
                  final statusColor = b.isExceeded
                      ? AppColors.error
                      : b.percentageUsed >= 80
                          ? AppColors.warning
                          : AppColors.success;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.cardDark
                                      : AppColors.primaryContainer.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(emoji, style: const TextStyle(fontSize: 18)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  b.category[0].toUpperCase() + b.category.substring(1),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 19),
                                tooltip: 'Editar presupuesto',
                                onPressed: () => BudgetFormDialog.show(
                                  context,
                                  budgetToEdit: b,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 19, color: AppColors.error),
                                tooltip: 'Eliminar presupuesto',
                                onPressed: () => _confirmDelete(context, ref, b),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${CurrencyFormatter.format(b.spentAmount, currency: b.currency)} / ${CurrencyFormatter.format(b.budgetAmount, currency: b.currency)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${b.percentageUsed}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progressClamped,
                              minHeight: 8,
                              backgroundColor: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              b.isExceeded
                                  ? '❗ Excedido por ${CurrencyFormatter.format(b.remainingAmount.abs(), currency: b.currency)}'
                                  : 'Disponible: ${CurrencyFormatter.format(b.remainingAmount, currency: b.currency)}',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
        loading: () => const LoadingView(message: 'Cargando presupuestos...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(budgetsListProvider),
        ),
      ),
    );
  }
}
