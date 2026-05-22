import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_strings.dart';
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
      backgroundColor: AppColors.background,
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxHeight < 600;
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: isSmall ? 32 : 56),
                        // Logo mark
                        Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.local_florist,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppStrings.appName,
                          textAlign: TextAlign.center,
                          style:
                              AppTypography.h2.copyWith(color: AppColors.primary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppStrings.loginSubtitle,
                          textAlign: TextAlign.center,
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: isSmall ? 28 : 44),
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
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
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
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
