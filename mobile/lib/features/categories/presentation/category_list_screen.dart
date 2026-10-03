import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/category_icons.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../models/category_model.dart';
import '../providers/category_providers.dart';
import 'category_form_dialog.dart';

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  void _confirmDeactivate(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desactivar Categoría'),
        content: Text(
          '¿Estás seguro de que querés desactivar "${category.name}"? Ya no aparecerá para nuevos gastos.',
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
                final repo = ref.read(categoryRepositoryProvider);
                await repo.deactivateCategory(category.id);
                ref.invalidate(categoriesListProvider);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Categoría desactivada'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CategoryFormDialog.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Categoría'),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          final systemCategories = categories.filter((c) => c.isSystem).toList();
          final customCategories = categories.filter((c) => !c.isSystem).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(categoriesListProvider);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              children: [
                // Sección: Categorías Personalizadas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mis Categorías Personalizadas',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => CategoryFormDialog.show(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Nueva'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                if (customCategories.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.dashboard_customize_outlined,
                            size: 36,
                            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No creaste categorías personalizadas todavía',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Podés agregar categorías específicas para tus necesidades.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Card(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: customCategories.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final cat = customCategories[i];
                        final emoji = CategoryIcons.getEmoji(cat.name, cat.icon);

                        return ListTile(
                          leading: Text(emoji, style: const TextStyle(fontSize: 22)),
                          title: Text(
                            cat.name[0].toUpperCase() + cat.name.substring(1),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text(
                            'Personalizada',
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 19),
                                tooltip: 'Editar',
                                onPressed: () => CategoryFormDialog.show(
                                  context,
                                  categoryToEdit: cat,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 19, color: AppColors.error),
                                tooltip: 'Desactivar',
                                onPressed: () => _confirmDeactivate(context, ref, cat),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 28),

                // Sección: Categorías del Sistema
                const Text(
                  'Categorías Generales (Sistema)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),

                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: systemCategories.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final cat = systemCategories[i];
                      final emoji = CategoryIcons.getEmoji(cat.name, cat.icon);

                      return ListTile(
                        leading: Text(emoji, style: const TextStyle(fontSize: 22)),
                        title: Text(
                          cat.name[0].toUpperCase() + cat.name.substring(1),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: const Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
        loading: () => const LoadingView(message: 'Cargando categorías...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(categoriesListProvider),
        ),
      ),
    );
  }
}

extension _IterableFilter<T> on Iterable<T> {
  Iterable<T> filter(bool Function(T) test) => where(test);
}
