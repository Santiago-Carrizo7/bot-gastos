import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../categories/providers/category_providers.dart';
import '../models/expense_model.dart';
import '../providers/expense_providers.dart';
import 'expense_detail_sheet.dart';
import 'expense_form_screen.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    final current = ref.read(expenseFilterProvider);
    ref.read(expenseFilterProvider.notifier).state = current.copyWith(
      search: val.trim().isEmpty ? null : val.trim(),
      clearSearch: val.trim().isEmpty,
    );
  }

  void _selectCategory(String? category) {
    final current = ref.read(expenseFilterProvider);
    ref.read(expenseFilterProvider.notifier).state = current.copyWith(
      category: category,
      clearCategory: category == null,
    );
  }

  Map<String, List<ExpenseModel>> _groupExpensesByDate(List<ExpenseModel> expenses) {
    final Map<String, List<ExpenseModel>> grouped = {};

    for (final exp in expenses) {
      final key = DateFormatter.formatRelative(exp.date);
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(exp);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filter = ref.watch(expenseFilterProvider);
    final expensesAsync = ref.watch(expensesListProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ExpenseFormScreen.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Gasto'),
      ),
      body: Column(
        children: [
          // Barra de Búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar por descripción...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),

          // Chips de Categorías
          SizedBox(
            height: 48,
            child: categoriesAsync.when(
              data: (categories) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: const Text('Todos'),
                        selected: filter.category == null,
                        onSelected: (_) => _selectCategory(null),
                      ),
                    ),
                    ...categories.map((cat) {
                      final isSelected = filter.category == cat.name.toLowerCase();
                      final emoji = CategoryIcons.getEmoji(cat.name, cat.icon);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          avatar: Text(emoji, style: const TextStyle(fontSize: 14)),
                          label: Text(cat.name[0].toUpperCase() + cat.name.substring(1)),
                          selected: isSelected,
                          onSelected: (selected) {
                            _selectCategory(selected ? cat.name.toLowerCase() : null);
                          },
                        ),
                      );
                    }),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => const SizedBox.shrink(),
            ),
          ),

          const SizedBox(height: 8),

          // Listado agrupado por fecha
          Expanded(
            child: expensesAsync.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  final isFiltered = filter.category != null || filter.search != null;
                  return EmptyStateView(
                    icon: Icons.receipt_long_outlined,
                    title: isFiltered
                        ? 'No se encontraron gastos'
                        : 'Aún no registraste gastos',
                    description: isFiltered
                        ? 'Probá ajustando la búsqueda o el filtro de categoría.'
                        : 'Registrá un gasto mandando un audio en Telegram o tocando el botón de abajo.',
                    actionLabel: isFiltered ? null : 'Registrar gasto',
                    onAction: isFiltered ? null : () => ExpenseFormScreen.show(context),
                  );
                }

                final grouped = _groupExpensesByDate(expenses);

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(expensesListProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 96, top: 4),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final dateHeader = grouped.keys.elementAt(index);
                      final items = grouped[dateHeader]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cabecera de fecha
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                            child: Text(
                              dateHeader.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),

                          // Items del grupo
                          Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: items.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (ctx, itemIndex) {
                                final exp = items[itemIndex];
                                final emoji = CategoryIcons.getEmoji(exp.category);

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 4.0,
                                  ),
                                  onTap: () => ExpenseDetailSheet.show(context, exp),
                                  leading: Container(
                                    width: 42,
                                    height: 42,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.cardDark
                                          : AppColors.primaryContainer.withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(emoji, style: const TextStyle(fontSize: 20)),
                                  ),
                                  title: Text(
                                    exp.description,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '${exp.category[0].toUpperCase()}${exp.category.substring(1)}${exp.installments > 1 ? " • ${exp.installments} cuotas" : ""}',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  trailing: Text(
                                    CurrencyFormatter.format(exp.amount, currency: exp.currency),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
                );
              },
              loading: () => const LoadingView(message: 'Cargando historial de gastos...'),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(expensesListProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
