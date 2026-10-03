import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class LinkScreen extends ConsumerStatefulWidget {
  const LinkScreen({super.key});

  @override
  ConsumerState<LinkScreen> createState() => _LinkScreenState();
}

class _LinkScreenState extends ConsumerState<LinkScreen> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentUrl();
  }

  Future<void> _loadCurrentUrl() async {
    final storage = ref.read(secureStorageProvider);
    final savedUrl = await storage.getApiBaseUrl();
    if (mounted) {
      setState(() {
        _urlController.text = savedUrl ?? ApiEndpoints.defaultBaseUrl;
      });
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _tokenController.text = data.text!.trim();
        _errorMessage = null;
      });
    }
  }

  Future<void> _submitToken() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Guardar primero la URL del servidor ingresada
    var cleanUrl = _urlController.text.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    await ref.read(secureStorageProvider).saveApiBaseUrl(cleanUrl);

    final success = await ref
        .read(authNotifierProvider.notifier)
        .linkAccount(_tokenController.text.trim());

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (!success) {
      final authState = ref.read(authNotifierProvider);
      setState(() {
        _errorMessage = authState.errorMessage ??
            'No se pudo conectar con el servidor ($cleanUrl). Verificá la URL del backend y el código de vinculación.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bot de Gastos'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icono Hero
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : AppColors.primaryContainer,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 38,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Título & Subtítulo
                  Text(
                    'Conectá tu Telegram',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sincronizá los gastos que registres por voz o texto en el bot con esta aplicación en tiempo real.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Card de Instrucciones
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.telegram,
                                color: isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Pasos para vincular:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildStepItem('1', 'Ingresá la URL donde está subido tu servidor'),
                          _buildStepItem('2', 'Enviá /vincular a tu bot en Telegram'),
                          _buildStepItem('3', 'Copiá el código y pegalo aquí abajo', isLast: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Campo de URL del Servidor Remoto
                  TextFormField(
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'URL del Servidor (Backend)',
                      hintText: 'https://tu-backend.onrender.com',
                      helperText: 'Ej: https://tu-app.onrender.com o https://tu-app.up.railway.app',
                      prefixIcon: Icon(Icons.cloud_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresá la URL de tu servidor backend';
                      }
                      if (!value.trim().startsWith('http://') &&
                          !value.trim().startsWith('https://')) {
                        return 'La URL debe comenzar con https:// o http://';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo de Token
                  TextFormField(
                    controller: _tokenController,
                    maxLines: 2,
                    minLines: 1,
                    decoration: InputDecoration(
                      labelText: 'Código de Vinculación',
                      hintText: 'Pegá el código obtenido con /vincular...',
                      prefixIcon: const Icon(Icons.key_rounded),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.content_paste_rounded),
                        tooltip: 'Pegar del portapapeles',
                        onPressed: _pasteFromClipboard,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor ingresá el código de vinculación';
                      }
                      return null;
                    },
                  ),

                  // Mensaje de Error
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Botón Principal
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitToken,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Vincular Telegram',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(String number, String text, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13.5, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
