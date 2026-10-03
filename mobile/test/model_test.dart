import 'package:flutter_test/flutter_test.dart';
import 'package:bot_gastos/core/utils/currency_formatter.dart';
import 'package:bot_gastos/core/utils/category_icons.dart';
import 'package:bot_gastos/features/expenses/models/expense_model.dart';
import 'package:bot_gastos/features/categories/models/category_model.dart';
import 'package:bot_gastos/features/budgets/models/budget_model.dart';
import 'package:bot_gastos/features/expenses/models/summary_model.dart';

void main() {
  group('Pruebas unitarias de utilidades y modelos', () {
    test('CurrencyFormatter formatea montos en ARS correctamente', () {
      final formatted = CurrencyFormatter.format(5000);
      expect(formatted, contains('5.000'));
    });

    test('CategoryIcons devuelve emojis esperados', () {
      expect(CategoryIcons.getEmoji('comida'), '🍔');
      expect(CategoryIcons.getEmoji('transporte'), '🚌');
      expect(CategoryIcons.getEmoji('desconocida'), '🏷️');
    });

    test('ExpenseModel deserializa JSON correctamente', () {
      final json = {
        'id': 'exp-123',
        'userId': 'user-1',
        'amount': 15000.50,
        'description': 'Supermercado',
        'category': 'comida',
        'date': '2026-09-30T12:00:00.000Z',
        'installments': 1,
        'currency': 'ARS',
        'createdAt': '2026-09-30T12:00:00.000Z',
      };

      final expense = ExpenseModel.fromJson(json);
      expect(expense.id, 'exp-123');
      expect(expense.amount, 15000.50);
      expect(expense.category, 'comida');
      expect(expense.installments, 1);
    });

    test('CategoryModel deserializa JSON correctamente', () {
      final json = {
        'id': 'cat-1',
        'name': 'gimnasio',
        'icon': '🏋️',
        'isSystem': false,
        'userId': 'user-1',
        'isActive': true,
      };

      final category = CategoryModel.fromJson(json);
      expect(category.name, 'gimnasio');
      expect(category.icon, '🏋️');
      expect(category.isSystem, false);
    });

    test('BudgetModel calcula progreso correctamente', () {
      final json = {
        'id': 'b-1',
        'category': 'comida',
        'budgetAmount': 100000,
        'spentAmount': 60000,
        'remainingAmount': 40000,
        'percentageUsed': 60,
        'isExceeded': false,
        'currency': 'ARS',
      };

      final budget = BudgetModel.fromJson(json);
      expect(budget.budgetAmount, 100000);
      expect(budget.spentAmount, 60000);
      expect(budget.percentageUsed, 60);
      expect(budget.isExceeded, false);
    });

    test('MonthlySummaryModel deserializa mapa de categorías', () {
      final json = {
        'year': 2026,
        'month': 10,
        'monthName': 'Octubre',
        'total': 85000,
        'count': 5,
        'categories': {
          'comida': {'total': 50000, 'count': 3},
          'transporte': {'total': 35000, 'count': 2},
        },
      };

      final summary = MonthlySummaryModel.fromJson(json);
      expect(summary.total, 85000);
      expect(summary.count, 5);
      expect(summary.categories['comida']?.total, 50000);
      expect(summary.categories['transporte']?.count, 2);
    });
  });
}
