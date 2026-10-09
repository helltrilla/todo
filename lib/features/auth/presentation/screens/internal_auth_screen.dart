import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/features/auth/presentation/controllers/auth_controller.dart';

/// Screen for internal (offline/local) registration and sign-in.
/// Features a pill toggle styled after the Listodo UI Kit category chips.
class InternalAuthScreen extends StatefulWidget {
  const InternalAuthScreen({super.key});

  @override
  State<InternalAuthScreen> createState() => _InternalAuthScreenState();
}

class _InternalAuthScreenState extends State<InternalAuthScreen> {
  final _nameController = TextEditingController();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegisterMode = true;

  @override
  void dispose() {
    _nameController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red[700]),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final login = _loginController.text.trim();
    final password = _passwordController.text;

    if (_isRegisterMode && name.isEmpty) {
      _showError('Введите ваше имя');
      return;
    }
    if (login.isEmpty) {
      _showError('Введите логин или почту');
      return;
    }
    if (password.length < 4) {
      _showError('Пароль должен содержать минимум 4 символа');
      return;
    }

    final auth = context.read<AuthController>();
    final ok = _isRegisterMode
        ? await auth.registerInternal(
            name: name,
            login: login,
            password: password,
          )
        : await auth.signInInternal(login: login, password: password);

    if (!mounted) return;
    if (!ok && auth.error != null) {
      _showError(auth.error!);
      auth.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthController>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.bgmain,
      appBar: AppBar(
        backgroundColor: AppColors.bgmain,
        iconTheme: IconThemeData(color: AppColors.icons),
        title: Text(
          'Внутренний профиль',
          style: TextStyle(color: AppColors.maintext, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _ModePill(
                    label: 'Регистрация',
                    isActive: _isRegisterMode,
                    onTap: () => setState(() => _isRegisterMode = true),
                  ),
                  const SizedBox(width: 12),
                  _ModePill(
                    label: 'Вход',
                    isActive: !_isRegisterMode,
                    onTap: () => setState(() => _isRegisterMode = false),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                _isRegisterMode
                    ? 'Создать локальный аккаунт'
                    : 'Войти в локальный аккаунт',
                style: TextStyle(
                  color: AppColors.maintext,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isRegisterMode
                    ? 'Данные сохраняются на устройстве. Быстро и без интернета.'
                    : 'Введите логин и пароль от вашего локального профиля.',
                style: TextStyle(
                  color: AppColors.labeltext,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              if (_isRegisterMode) ...[
                _InputBox(
                  controller: _nameController,
                  label: 'Имя (отображается в шапке)',
                  hint: 'Vasudev Krishna',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 16),
              ],
              _InputBox(
                controller: _loginController,
                label: 'Логин или Email',
                hint: 'user123',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _InputBox(
                controller: _passwordController,
                label: 'Пароль',
                hint: '••••••',
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentYellow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        _isRegisterMode ? 'Зарегистрироваться' : 'Войти',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentYellow : AppColors.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? AppColors.accentYellow : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : AppColors.labeltext,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  const _InputBox({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: AppColors.maintext),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: AppColors.labeltext),
        hintStyle: TextStyle(color: AppColors.labeltext.withValues(alpha: 0.6)),
        prefixIcon: Icon(icon, color: AppColors.labeltext),
        filled: true,
        fillColor: AppColors.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.accentYellow,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
