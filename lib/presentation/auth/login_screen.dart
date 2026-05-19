import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/asset_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../shared/widgets/app_button.dart';
import '../shared/widgets/app_text_field.dart';
import 'cubit/auth_cubit.dart';
import 'cubit/auth_state.dart';

/// Login screen — email + password sign in.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    String? emailErr;
    String? passwordErr;

    if (email.isEmpty || !email.contains('@')) {
      emailErr = AppStrings.enterEmail;
    }
    if (password.isEmpty) {
      passwordErr = AppStrings.enterPassword;
    }

    if (emailErr != null || passwordErr != null) {
      setState(() {
        _emailError = emailErr;
        _passwordError = passwordErr;
      });
      return;
    }

    setState(() {
      _emailError = null;
      _passwordError = null;
    });
    context.read<AuthCubit>().login(email, password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.statusOverdue,
              ),
            );
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Image.asset(AssetPaths.logo, width: 160),
                const SizedBox(height: 16),
                Text(
                  AppStrings.appName,
                  style: AppTypography.h2.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.loginSubtitle,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                AppTextField(
                  label: AppStrings.email,
                  hint: AppStrings.emailHint,
                  controller: _emailController,
                  errorText: _emailError,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: AppStrings.password,
                  hint: AppStrings.enterPassword,
                  controller: _passwordController,
                  errorText: _passwordError,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: _onLogin,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 24),
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    return AppPrimaryButton(
                      label: AppStrings.signIn,
                      isLoading: state is AuthLoading,
                      onPressed: _onLogin,
                    );
                  },
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
