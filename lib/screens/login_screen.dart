import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/theme_utils.dart';
import 'home_screen.dart';

const emailRegex =
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'; // Regex for email validation

/// The main screen for user login.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailPasswordFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // TODO: remove fake sign in
  void _fakeSignIn() {
    setState(() {
      _isLoading = true;
    });

    // Simulate authentication delay
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // Navigate to home screen on successful login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxxl),

              // App Logo and Title
              Column(
                children: [
                  Container(
                    width: AppDimensions.avatarXLarge,
                    height: AppDimensions.avatarXLarge,
                    decoration: BoxDecoration(
                      color: context.primaryColor,
                      borderRadius: BorderRadius.circular(
                          AppDimensions.borderRadiusXLarge),
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedDumbbell01,
                      color: context.onPrimary,
                      size: AppDimensions.iconXLarge,
                    ),
                  ),
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

              const SizedBox(height: AppSpacing.xxl),

              // Email/Password Form
              Form(
                key: _emailPasswordFormKey,
                child: Column(
                  children: [
                    AppTextFormField(
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

                    const SizedBox(height: AppSpacing.md),

                    AppTextFormField(
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

                    const SizedBox(height: AppSpacing.xs),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: AppButton(
                        text: 'Forgot Password?',
                        type: AppButtonType.text,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Forgot password clicked')),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Sign In Button
                    SizedBox(
                      width: double.infinity,
                      height: AppDimensions.buttonHeightLarge,
                      child: AppButton(
                        text: 'Sign In',
                        onPressed: _signInWithEmail,
                        isLoading: _isLoading,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryColor,
                          foregroundColor: context.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: context.outlineColor)),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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

              const SizedBox(height: AppSpacing.lg),

              // Social Login Buttons
              Column(
                children: [
                  _SocialLoginButton(
                    onPressed:
                        _isLoading ? null : () => _signInWithGoogle(context),
                    icon: HugeIcons.strokeRoundedGoogle,
                    label: 'Google',
                    backgroundColor: AppColors.google,
                    textColor: context.onPrimary,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _SocialLoginButton(
                    onPressed:
                        _isLoading ? null : () => _signInWithFacebook(context),
                    icon: HugeIcons.strokeRoundedFacebook01,
                    label: 'Facebook',
                    backgroundColor: AppColors.facebook,
                    textColor: context.onPrimary,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _SocialLoginButton(
                    onPressed:
                        _isLoading ? null : () => _signInWithApple(context),
                    icon: HugeIcons.strokeRoundedApple,
                    label: 'Apple',
                    backgroundColor: AppColors.apple,
                    textColor: context.onPrimary,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Sign Up Link
              Row(
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
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
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
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusLarge),
          ),
          elevation: 1,
        ),
        icon: HugeIcon(
          icon: icon,
          size: AppDimensions.iconMedium * 0.8,
          color: textColor,
        ),
        label: Text(
          label,
          style: AppTextStyles.buttonText,
        ),
      ),
    );
  }
}
