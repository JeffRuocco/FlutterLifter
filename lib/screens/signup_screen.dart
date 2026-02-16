import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lifter/core/theme/color_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../config/auth_config.dart';
import '../core/providers/auth_providers.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/theme_extensions.dart';
import '../widgets/common/app_widgets.dart';
import '../widgets/animations/animate_on_load.dart';
import 'login_screen.dart' show emailRegex;

/// Registration screen for new users.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  late AnimationController _logoAnimationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;

  @override
  void initState() {
    super.initState();
    _logoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoRotationAnimation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _logoAnimationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _logoAnimationController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    HapticFeedback.mediumImpact();

    final result = await ref
        .read(authNotifierProvider.notifier)
        .signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          displayName: _nameController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result != AuthResult.success) {
      setState(() => _errorMessage = _getErrorMessage(result));
    }
    // Navigation handled automatically by router redirect
  }

  String _getErrorMessage(AuthResult result) {
    switch (result) {
      case AuthResult.emailAlreadyInUse:
        return 'An account with this email already exists';
      case AuthResult.weakPassword:
        return 'Password is too weak. Use at least 6 characters';
      case AuthResult.networkError:
        return 'No internet connection. Please try again';
      case AuthResult.tooManyRequests:
        return 'Too many attempts. Please try again later';
      case AuthResult.invalidCredentials:
        return 'Invalid credentials';
      case AuthResult.userNotFound:
        return 'User not found';
      case AuthResult.cancelled:
        return 'Sign-up was cancelled';
      case AuthResult.success:
        return '';
      case AuthResult.failed:
        return 'Registration failed. Please try again';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: context.isDarkMode
                ? [context.surfaceColor, context.surfaceVariant]
                : [
                    context.primaryColor.withValues(alpha: 0.05),
                    context.surfaceColor,
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xl),

                // Logo and title
                AnimatedBuilder(
                  animation: _logoAnimationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoScaleAnimation.value,
                      child: Transform.rotate(
                        angle: _logoRotationAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        width: AppDimensions.avatarLarge,
                        height: AppDimensions.avatarLarge,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: context.primaryGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.borderRadiusXLarge,
                          ),
                        ),
                        child: Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedDumbbell01,
                            color: ColorUtils.getContrastingTextColor(
                              context.primaryColor,
                            ),
                            size: AppDimensions.iconLarge,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Create Account',
                        style: AppTextStyles.appTitle.copyWith(
                          color: context.primaryColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Start your fitness journey today',
                        style: AppTextStyles.subtitle.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Error message
                if (_errorMessage != null) ...[
                  SlideInWidget(
                    delay: Duration.zero,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: context.errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.borderRadiusSmall,
                        ),
                        border: Border.all(
                          color: context.errorColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedAlert02,
                            color: context.errorColor,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: context.errorColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Registration form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Display Name
                      SlideInWidget(
                        delay: const Duration(milliseconds: 300),
                        child: AppTextFormField(
                          controller: _nameController,
                          labelText: 'Display Name',
                          keyboardType: TextInputType.name,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(
                              AppDimensions.borderRadiusMedium,
                            ),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedUser,
                              color: context.onSurface,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Email
                      SlideInWidget(
                        delay: const Duration(milliseconds: 400),
                        child: AppTextFormField(
                          controller: _emailController,
                          labelText: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(
                              AppDimensions.borderRadiusMedium,
                            ),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedMail01,
                              color: context.onSurface,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(emailRegex).hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Password
                      SlideInWidget(
                        delay: const Duration(milliseconds: 500),
                        child: AppTextFormField(
                          controller: _passwordController,
                          labelText: 'Password',
                          obscureText: _obscurePassword,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(
                              AppDimensions.borderRadiusMedium,
                            ),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedLockPassword,
                              color: context.onSurface,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: HugeIcon(
                              icon: _obscurePassword
                                  ? HugeIcons.strokeRoundedView
                                  : HugeIcons.strokeRoundedViewOff,
                              color: context.onSurface,
                              size: AppDimensions.iconSmall,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Confirm Password
                      SlideInWidget(
                        delay: const Duration(milliseconds: 600),
                        child: AppTextFormField(
                          controller: _confirmPasswordController,
                          labelText: 'Confirm Password',
                          obscureText: _obscureConfirm,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(
                              AppDimensions.borderRadiusMedium,
                            ),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedLockPassword,
                              color: context.onSurface,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: HugeIcon(
                              icon: _obscureConfirm
                                  ? HugeIcons.strokeRoundedView
                                  : HugeIcons.strokeRoundedViewOff,
                              color: context.onSurface,
                              size: AppDimensions.iconSmall,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirm = !_obscureConfirm;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Create Account button
                      SlideInWidget(
                        delay: const Duration(milliseconds: 700),
                        child: SizedBox(
                          width: double.infinity,
                          height: AppDimensions.buttonHeightLarge,
                          child: AppButton.gradient(
                            text: 'Create Account',
                            onPressed: _signUp,
                            isLoading: _isLoading,
                            gradientColors: context.primaryGradient,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Sign In link
                FadeInWidget(
                  delay: const Duration(milliseconds: 800),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: context.outlineColor,
                        ),
                      ),
                      AppButton(
                        text: 'Sign In',
                        type: AppButtonType.text,
                        onPressed: () => context.go(AppRoutes.login),
                      ),
                    ],
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
