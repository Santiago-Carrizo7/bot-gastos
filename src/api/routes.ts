import { Router } from 'express';
import { createAuthMiddleware } from './middlewares/auth.middleware.js';
import { createExpenseController } from './controllers/expense.controller.js';
import { createCategoryController } from './controllers/category.controller.js';
import { createBudgetController } from './controllers/budget.controller.js';
import { ExpenseService } from '../expenses/expense.service.js';
import { CategoryService } from '../categories/category.service.js';
import { BudgetService } from '../budgets/budget.service.js';
import { UserService } from '../users/user.service.js';

export interface CreateApiRouterDeps {
  expenseService: ExpenseService;
  categoryService: CategoryService;
  budgetService: BudgetService;
  userService: UserService;
  apiSecret: string;
}

export function createApiRouter(deps: CreateApiRouterDeps): Router {
  const router = Router();
  const auth = createAuthMiddleware(deps.userService, deps.apiSecret);

  const expenseCtrl = createExpenseController(deps.expenseService);
  const categoryCtrl = createCategoryController(deps.categoryService);
  const budgetCtrl = createBudgetController(deps.budgetService);

  // Health check público
  router.get('/health', (_req, res) => {
    res.json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
    });
  });

  // Endpoints protegidos bajo /api
  const apiProtected = Router();
  apiProtected.use(auth);

  // Usuario / Perfil / Verificación de vinculación
  apiProtected.get('/me', async (req, res) => {
    const userId = (req as any).userId as string;
    const user = await deps.userService.getById(userId);
    if (!user) {
      res.status(404).json({ error: 'USER_NOT_FOUND', message: 'Usuario no encontrado' });
      return;
    }
    res.json({
      data: {
        id: user.id,
        telegramId: user.telegramId,
        createdAt: user.createdAt,
      },
    });
  });

  // Gastos
  apiProtected.get('/expenses', expenseCtrl.listExpenses);
  apiProtected.get('/expenses/:id', expenseCtrl.getExpense);
  apiProtected.post('/expenses', expenseCtrl.createExpense);
  apiProtected.put('/expenses/:id', expenseCtrl.updateExpense);
  apiProtected.delete('/expenses/:id', expenseCtrl.deleteExpense);
  apiProtected.get('/summary', expenseCtrl.getMonthlySummary);
  apiProtected.get('/analytics', expenseCtrl.getAnalytics);

  // Categorías
  apiProtected.get('/categories', categoryCtrl.listCategories);
  apiProtected.post('/categories', categoryCtrl.createCategory);
  apiProtected.put('/categories/:id', categoryCtrl.updateCategory);
  apiProtected.patch('/categories/:id/deactivate', categoryCtrl.deactivateCategory);

  // Presupuestos
  apiProtected.get('/budgets', budgetCtrl.listBudgets);
  apiProtected.post('/budgets', budgetCtrl.setBudget);
  apiProtected.delete('/budgets/:id', budgetCtrl.deleteBudget);

  router.use('/api', apiProtected);

  return router;
}
