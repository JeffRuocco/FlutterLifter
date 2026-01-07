import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lifter/core/theme/color_utils.dart';
import 'package:flutter_lifter/utils/icon_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/theme_extensions.dart';
import '../widgets/common/app_widgets.dart';
import '../widgets/animations/animate_on_load.dart';

const emailRegex =
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'; // Regex for email validation

/// The main screen for user login.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailPasswordFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

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

    // Start logo animation
    _logoAnimationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _logoAnimationController.dispose();
    super.dispose();
  }

  // TODO: remove fake sign in
  void _fakeSignIn() {
    setState(() {
      _isLoading = true;
    });

    HapticFeedback.mediumImpact();

    // Simulate authentication delay
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // Navigate to home screen on successful login
      context.go(AppRoutes.home);
    });
  }

  void _signInWithEmail() {
    // TODO: Implement email/password authentication logic
    if (_emailPasswordFormKey.currentState!.validate()) {
      return _fakeSignIn();
    }
  }

  void _signInWithGoogle(BuildContext context) {
    // TODO: Implement Google Sign-In logic
    showSuccessMessage(context, 'Google Sign-In clicked');
    return _fakeSignIn();
  }

  void _signInWithFacebook(BuildContext context) {
    // TODO: Implement Facebook Sign-In logic
    showSuccessMessage(context, 'Facebook Sign-In clicked');
    return _fakeSignIn();
  }

  void _signInWithApple(BuildContext context) {
    // TODO: Implement Apple Sign-In logic
    showSuccessMessage(context, 'Apple Sign-In clicked');
    return _fakeSignIn();
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
                const SizedBox(height: AppSpacing.xxl),

                // Animated App Logo and Title
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
                      _AnimatedLogo(),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'FlutterLifter',
                        style: AppTextStyles.appTitle.copyWith(
                          color: context.primaryColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Your Personal Fitness Journey',
                        style: AppTextStyles.subtitle.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Email/Password Form with staggered animations
                Form(
                  key: _emailPasswordFormKey,
                  child: Column(
                    children: [
                      SlideInWidget(
                        delay: const Duration(milliseconds: 400),
                        child: AppTextFormField(
                          controller: _emailController,
                          labelText: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: HugeIcon(
                            icon: HugeIcons.strokeRoundedMail01,
                            color: context.onSurface,
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

                      SlideInWidget(
                        delay: const Duration(milliseconds: 500),
                        child: AppTextFormField(
                          controller: _passwordController,
                          labelText: 'Password',
                          obscureText: _obscurePassword,
                          prefixIcon: HugeIcon(
                            icon: HugeIcons.strokeRoundedLockPassword,
                            color: context.onSurface,
                          ),
                          suffixIcon: IconButton(
                            icon: HugeIcon(
                              icon: _obscurePassword
                                  ? HugeIcons.strokeRoundedView
                                  : HugeIcons.strokeRoundedViewOff,
                              color: context.onSurface,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xs),

                      // Forgot Password
                      SlideInWidget(
                        delay: const Duration(milliseconds: 600),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: AppButton(
                            text: 'Forgot Password?',
                            type: AppButtonType.text,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Forgot password clicked'),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Sign In Button with gradient
                      SlideInWidget(
                        delay: const Duration(milliseconds: 700),
                        child: SizedBox(
                          width: double.infinity,
                          height: AppDimensions.buttonHeightLarge,
                          child: AppButton.gradient(
                            text: 'Sign In',
                            onPressed: _signInWithEmail,
                            isLoading: _isLoading,
                            gradientColors: context.primaryGradient,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Divider
                FadeInWidget(
                  delay: const Duration(milliseconds: 800),
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: context.outlineColor)),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Text(
                          'Or continue with',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: context.outlineColor,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: context.outlineColor)),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Social Login Buttons with staggered animations
                Column(
                  children: [
                    SlideInWidget(
                      delay: const Duration(milliseconds: 900),
                      child: _SocialLoginButton(
                        onPressed: _isLoading
                            ? null
                            : () => _signInWithGoogle(context),
                        icon: HugeIcons.strokeRoundedGoogle,
                        label: 'Google',
                        backgroundColor: AppColors.google,
                        textColor: ColorUtils.getContrastingTextColor(
                          AppColors.google,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SlideInWidget(
                      delay: const Duration(milliseconds: 1000),
                      child: _SocialLoginButton(
                        onPressed: _isLoading
                            ? null
                            : () => _signInWithFacebook(context),
                        icon: HugeIcons.strokeRoundedFacebook01,
                        label: 'Facebook',
                        backgroundColor: AppColors.facebook,
                        textColor: ColorUtils.getContrastingTextColor(
                          AppColors.facebook,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SlideInWidget(
                      delay: const Duration(milliseconds: 1100),
                      child: _SocialLoginButton(
                        onPressed: _isLoading
                            ? null
                            : () => _signInWithApple(context),
                        icon: HugeIcons.strokeRoundedApple,
                        label: 'Apple',
                        backgroundColor: AppColors.apple,
                        textColor: ColorUtils.getContrastingTextColor(
                          AppColors.apple,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // Sign Up Link
                FadeInWidget(
                  delay: const Duration(milliseconds: 1200),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: context.outlineColor,
                        ),
                      ),
                      AppButton(
                        text: 'Sign Up',
                        type: AppButtonType.text,
                        onPressed: () {
                          showSuccessMessage(context, 'Sign up clicked');
                        },
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

/// Animated logo with pulsing glow effect
class _AnimatedLogo extends StatefulWidget {
  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: AppDimensions.avatarXLarge,
          height: AppDimensions.avatarXLarge,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: context.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(
              AppDimensions.borderRadiusXLarge,
            ),
            boxShadow: [
              BoxShadow(
                color: context.primaryColor.withValues(
                  alpha: 0.3 + (_pulseAnimation.value * 0.2),
                ),
                blurRadius: 20 + (_pulseAnimation.value * 10),
                spreadRadius: _pulseAnimation.value * 2,
              ),
            ],
          ),
          child: Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedDumbbell01,
              color: ColorUtils.getContrastingTextColor(context.primaryColor),
              size: AppDimensions.iconXLarge,
            ),
          ),
        );
      },
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final HugeIconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _SocialLoginButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeightLarge,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppDimensions.borderRadiusLarge,
            ),
          ),
          elevation: 2,
        ),
        icon: HugeIcon(
          icon: icon,
          size: AppDimensions.iconMedium * 0.8,
          color: textColor,
        ),
        label: Text(label, style: AppTextStyles.buttonText),
      ),
    );
  }
}
