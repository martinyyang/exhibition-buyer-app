import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/auth_provider.dart';
import '../../team/providers/team_provider.dart';

import '../../../shared/widgets/safe_back_button.dart';
import '../../../core/providers/onboarding_provider.dart';
import '../../../shared/widgets/onboarding_dialog.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'buyer';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showOnboardingIfNeeded();
    });
  }

  Future<void> _showOnboardingIfNeeded() async {
    final onboardingService = ref.read(onboardingServiceProvider);
    final hasSeenOnboarding =
        await onboardingService.hasSeenOnboarding('register');

    if (!hasSeenOnboarding && mounted) {
      await _showOnboarding(markAsSeen: true);
    }
  }

  Future<void> _showOnboarding({bool markAsSeen = false}) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog(
      context: context,
      builder: (context) => OnboardingDialog(
        title: l10n.onboardingTitleRegister,
        tips: [
          OnboardingTip(
            icon: Icons.email,
            title: l10n.onboardingRegisterTip1Title,
            description: l10n.onboardingRegisterTip1Desc,
          ),
          OnboardingTip(
            icon: Icons.lock,
            title: l10n.onboardingRegisterTip2Title,
            description: l10n.onboardingRegisterTip2Desc,
          ),
          OnboardingTip(
            icon: Icons.people,
            title: l10n.onboardingRegisterTip3Title,
            description: l10n.onboardingRegisterTip3Desc,
          ),
        ],
        onDismiss: () {
          if (markAsSeen) {
            ref.read(onboardingServiceProvider).markOnboardingSeen('register');
          }
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.pleaseEnterEmail;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return l10n.pleaseEnterValidEmail;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.pleaseEnterPassword;
    }
    if (value.length < 8) {
      return l10n.passwordComplexityError;
    }
    // Check for at least one uppercase, one lowercase, and one number
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$').hasMatch(value)) {
      return l10n.passwordComplexityError;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.pleaseConfirmPassword;
    }
    if (value != _passwordController.text) {
      return l10n.passwordsDoNotMatch;
    }
    return null;
  }

  String? _validateTeamName(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.pleaseEnterTeamName;
    }
    final trimmedValue = value.trim();
    if (trimmedValue.length < 2 || trimmedValue.length > 50) {
      return l10n.teamNameLength;
    }
    return null;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final l10n = AppLocalizations.of(context)!;

      // 注册用户（不指定 teamId）
      final authService = ref.read(authServiceProvider);
      await authService.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        role: _selectedRole,
        teamId: null, // 注册时不分配团队
      );

      // 刷新全局当前用户状态 Provider
      ref.invalidate(currentUserDataProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.registerSuccess)),
        );
        // 注册成功后跳转到团队选择页面
        context.go('/team-selection');
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        String errorMessage;

        // 根据错误类型提供更明确的错误信息
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('no host') ||
            errorString.contains('socketexception')) {
          errorMessage = l10n.networkError;
        } else if (errorString.contains('timeout')) {
          errorMessage = l10n.timeoutError;
        } else if (errorString.contains('email')) {
          errorMessage = l10n.emailError;
        } else if (errorString.contains('password')) {
          errorMessage = l10n.passwordError;
        } else {
          errorMessage = l10n.registerFailed(e.toString());
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: l10n.viewDetails,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.errorDetails),
                    content: Text(e.toString()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.close),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.registerAccount),
        leading: const SafeBackButton(fallbackPath: '/login'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showOnboarding(markAsSeen: false),
            tooltip: l10n.helpGuide,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: _validateEmail,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: _validatePassword,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: l10n.confirmPassword,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: _validateConfirmPassword,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.role,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  title: Text(l10n.buyer),
                  subtitle: Text(l10n.buyerDescription),
                  value: 'buyer',
                  groupValue: _selectedRole,
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                ),
                RadioListTile<String>(
                  title: Text(l10n.remote),
                  subtitle: Text(l10n.remoteDescription),
                  value: 'remote',
                  groupValue: _selectedRole,
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(child: LoadingIndicator())
                else
                  ElevatedButton(
                    onPressed: _handleRegister,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      l10n.register,
                      style: const TextStyle(fontSize: 16),
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
