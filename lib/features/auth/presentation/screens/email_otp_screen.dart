import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/features/auth/presentation/controllers/auth_controller.dart';

/// Screen for Supabase Email OTP authentication.
/// Step 1: Enter Email (and optional Name) -> sends 6-digit OTP to email.
/// Step 2: Enter the 6-digit code received in the email -> verifies and logs in.
class EmailOtpScreen extends StatefulWidget {
  const EmailOtpScreen({super.key});

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  bool _codeSent = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : AppColors.active,
      ),
    );
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnack('Введите корректный Email адрес', isError: true);
      return;
    }

    final auth = context.read<AuthController>();
    final ok = await auth.sendEmailOtp(
      email: email,
      name: _nameController.text.trim(),
    );

    if (!mounted) return;
    if (ok) {
      setState(() => _codeSent = true);
      _showSnack('Код отправлен на $email! Проверьте почту (и папку Спам).');
    } else if (auth.error != null) {
      _showSnack(auth.error!, isError: true);
      auth.clearError();
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      _showSnack('Введите код из письма (обычно 6 цифр)', isError: true);
      return;
    }

    final auth = context.read<AuthController>();
    final ok = await auth.verifyEmailOtp(
      email: _emailController.text.trim(),
      code: code,
      name: _nameController.text.trim(),
    );

    if (!mounted) return;
    if (!ok && auth.error != null) {
      _showSnack(auth.error!, isError: true);
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
        iconTheme: const IconThemeData(color: AppColors.white),
        title: const Text(
          'Вход по Почте',
          style: TextStyle(color: AppColors.maintext, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _codeSent
                    ? 'Введите код из письма'
                    : 'Получите одноразовый код',
                style: const TextStyle(
                  color: AppColors.maintext,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _codeSent
                    ? 'Мы отправили код подтверждения на ${_emailController.text.trim()}'
                    : 'Укажите вашу почту. Supabase отправит на неё письмо с кодом для входа.',
                style: const TextStyle(
                  color: AppColors.labeltext,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              if (!_codeSent) ...[
                _AuthTextField(
                  controller: _nameController,
                  label: 'Ваше имя (для шапки профиля)',
                  hint: 'Например, Даниил',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _AuthTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'you@example.com',
                  icon: Icons.alternate_email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: isLoading ? null : _sendCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.active,
                    foregroundColor: AppColors.white,
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
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Отправить код на почту',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ] else ...[
                _AuthTextField(
                  controller: _codeController,
                  label: 'Код подтверждения из письма (6–8 цифр)',
                  hint: '12345678',
                  icon: Icons.lock_clock_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: isLoading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.active,
                    foregroundColor: AppColors.white,
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
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Подтвердить и войти',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => setState(() {
                          _codeSent = false;
                          _codeController.clear();
                        }),
                  child: const Text(
                    'Изменить Email или отправить заново',
                    style: TextStyle(color: AppColors.accentYellow),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.maintext),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.labeltext),
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: AppColors.labeltext),
        filled: true,
        fillColor: AppColors.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.active, width: 1.5),
        ),
      ),
    );
  }
}
