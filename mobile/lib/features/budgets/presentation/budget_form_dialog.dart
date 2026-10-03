import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/category_icons.dart';
import '../../categories/providers/category_providers.dart';
import '../models/budget_model.dart';
import '../providers/budget_providers.dart';
import '../../expenses/providers/expense_providers.dart';

class BudgetFormDialog extends ConsumerStatefulWidget {
  final BudgetModel? budgetToEdit;

  const BudgetFormDialog({super.key, this.budgetToEdit});

  static Future<void> show(BuildContext context, {BudgetModel? budgetToEdit}) {
    return showDialog(
      context: context,
      builder: (ctx) => BudgetFormDialog(budgetToEdit: budgetToEdit),
    );
  }

  @override
  ConsumerState<BudgetFormDialog> createState() => _BudgetFormDialogState();
}

class _BudgetFormDialogState extends ConsumerState<BudgetFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  String _selectedCategory = 'comida';
  bool _isSaving = false;

  bool get isEditing => widget.budgetToEdit != null;

  @override
  void initState() {
    super.initState();
    final edit = widget.budgetToEdit;
    _amountController = TextEditingController(
      text: edit != null ? edit.budgetAmount.toStringAsFixed(edit.budgetAmount % 1 == 0 ? 0 : 2) : '',
    );
    if (edit != null) {
      _selectedCategory = edit.category.toLowerCase();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

    setState(() {
      _isSaving = true;
    });

    try {
      final repo = ref.read(budgetRepositoryProvider);
      await repo.setBudget(
        category: _selectedCategory,
        amount: amount,
      );

      ref.invalidate(budgetsListProvider);
      ref.invalidate(monthlySummaryProvider);

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Presupuesto actualizado correctamente'
                : 'Presupuesto creado correctamente',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesListProvider);

    return AlertDialog(
      title: Text(isEditing ? 'Editar Presupuesto' : 'Nuevo Presupuesto'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dropdown de Categoría
            if (!isEditing)
              categoriesAsync.when(
                data: (categories) {
                  final catNames = categories.map((c) => c.name.toLowerCase()).toList();
                  if (!catNames.contains(_selectedCategory) && catNames.isNotEmpty) {
                    _selectedCategory = catNames.first;
                  }

                  return DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: categories.map((cat) {
                      final emoji = CategoryIcons.getEmoji(cat.name, cat.icon);
                      return DropdownMenuItem<String>(
                        value: cat.name.toLowerCase(),
                        child: Row(
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(cat.name[0].toUpperCase() + cat.name.substring(1)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (err, stack) => TextFormField(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  onChanged: (val) => _selectedCategory = val,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Text(
                      CategoryIcons.getEmoji(_selectedCategory),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _selectedCategory[0].toUpperCase() + _selectedCategory.substring(1),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Monto Mensual Máximo
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto mensual límite *',
                hintText: 'Ej: 120000',
                prefixText: '\$ ',
                prefixIcon: Icon(Icons.attach_money_rounded),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Ingresá un importe para el presupuesto';
                }
                final numVal = double.tryParse(val.replaceAll(',', '.'));
                if (numVal == null || numVal <= 0) {
                  return 'El monto debe ser mayor a 0';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
