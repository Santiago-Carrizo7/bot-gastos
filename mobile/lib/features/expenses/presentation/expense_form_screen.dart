import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../../categories/providers/category_providers.dart';
import '../models/expense_model.dart';
import '../providers/expense_providers.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  final ExpenseModel? expenseToEdit;

  const ExpenseFormScreen({super.key, this.expenseToEdit});

  static Future<void> show(BuildContext context, {ExpenseModel? expenseToEdit}) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ExpenseFormScreen(expenseToEdit: expenseToEdit),
      ),
    );
  }

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _installmentsController;

  String _selectedCategory = 'comida';
  DateTime _selectedDate = DateTime.now();
  String _selectedCurrency = 'ARS';
  bool _isSaving = false;

  bool get isEditing => widget.expenseToEdit != null;

  @override
  void initState() {
    super.initState();
    final edit = widget.expenseToEdit;

    _amountController = TextEditingController(
      text: edit != null ? edit.amount.toStringAsFixed(edit.amount % 1 == 0 ? 0 : 2) : '',
    );
    _descriptionController = TextEditingController(text: edit?.description ?? '');
    _installmentsController = TextEditingController(
      text: edit != null ? edit.installments.toString() : '1',
    );

    if (edit != null) {
      _selectedCategory = edit.category.toLowerCase();
      _selectedDate = edit.date;
      _selectedCurrency = edit.currency;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _installmentsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    final installments = int.tryParse(_installmentsController.text) ?? 1;

    setState(() {
      _isSaving = true;
    });

    try {
      final repo = ref.read(expenseRepositoryProvider);

      if (isEditing) {
        await repo.updateExpense(
          widget.expenseToEdit!.id,
          amount: amount,
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          date: _selectedDate,
          installments: installments,
          currency: _selectedCurrency,
        );
      } else {
        await repo.createExpense(
          amount: amount,
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          date: _selectedDate,
          installments: installments,
          currency: _selectedCurrency,
        );
      }

      refreshAllExpenseData(ref);

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing ? 'Gasto modificado exitosamente' : 'Gasto registrado exitosamente',
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
          content: Text('Error al guardar: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Gasto' : 'Nuevo Gasto'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Campo de Monto Destacado
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Importe *',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              _selectedCurrency == 'ARS' ? '\$ ' : 'US\$ ',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primaryDark,
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _amountController,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: const InputDecoration(
                                  hintText: '0',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  filled: false,
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Ingresá un importe';
                                  }
                                  final numVal = double.tryParse(val.replaceAll(',', '.'));
                                  if (numVal == null || numVal <= 0) {
                                    return 'El importe debe ser mayor a 0';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Descripción
                TextFormField(
                  controller: _descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Descripción *',
                    hintText: 'Ej: Supermercado, Almuerzo, Nafta...',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Ingresá una descripción';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Selector de Categoría
                categoriesAsync.when(
                  data: (categories) {
                    final catNames = categories.map((c) => c.name.toLowerCase()).toList();
                    if (!catNames.contains(_selectedCategory) && catNames.isNotEmpty) {
                      _selectedCategory = catNames.first;
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoría *',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: categories.map((cat) {
                        final emoji = CategoryIcons.getEmoji(cat.name, cat.icon);
                        return DropdownMenuItem<String>(
                          value: cat.name.toLowerCase(),
                          child: Row(
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 10),
                              Text(
                                cat.name[0].toUpperCase() + cat.name.substring(1),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        }
                      },
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (err, stack) => DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'otros', child: Text('📦 Otros')),
                      DropdownMenuItem(value: 'comida', child: Text('🍔 Comida')),
                      DropdownMenuItem(value: 'transporte', child: Text('🚌 Transporte')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Selector de Fecha
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    child: Text(
                      DateFormatter.formatFull(_selectedDate),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Cuotas y Moneda
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _installmentsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cuotas',
                          hintText: '1',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        validator: (val) {
                          if (val != null && val.isNotEmpty) {
                            final parsed = int.tryParse(val);
                            if (parsed == null || parsed < 1) {
                              return 'Mínimo 1 cuota';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCurrency,
                        decoration: const InputDecoration(
                          labelText: 'Moneda',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'ARS', child: Text(r'ARS ($)')),
                          DropdownMenuItem(value: 'USD', child: Text(r'USD (US$)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCurrency = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Botón Guardar
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveExpense,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEditing ? 'Guardar Cambios' : 'Registrar Gasto',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
