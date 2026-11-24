import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/services.dart';
import '../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  /// Aviso opcional (por ejemplo: "Tu sesión expiró").
  final String? notice;
  const LoginScreen({super.key, this.notice});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _hidePassword = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _error = widget.notice;
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // 1) Validación del lado del cliente (no sustituye la del servidor).
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Nunca se imprimen ni registran las credenciales.
      await Services.auth.login(_userCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      _passCtrl.clear();
      setState(() {
        _loading = false;
        _error = e.message; // mensaje genérico, sin detalles técnicos
      });
    } catch (_) {
      if (!mounted) return;
      _passCtrl.clear();
      setState(() {
        _loading = false;
        _error = ApiClient.msgNoLogin;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.notifications_active,
                        size: 56, color: theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text('Alertas TI',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Inicia sesión para continuar',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _userCtrl,
                      enabled: !_loading,
                      maxLength: Validators.maxUsuario,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                      validator: Validators.usuario,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passCtrl,
                      enabled: !_loading,
                      obscureText: _hidePassword, // oculta los caracteres
                      maxLength: Validators.maxClave,
                      autocorrect: false,
                      enableSuggestions: false,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        counterText: '',
                        suffixIcon: IconButton(
                          tooltip: _hidePassword ? 'Mostrar' : 'Ocultar',
                          icon: Icon(_hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                        ),
                      ),
                      validator: Validators.clave,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(
                              color: theme.colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Iniciar sesión'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
