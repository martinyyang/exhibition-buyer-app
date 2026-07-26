import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/auth_provider.dart';
import '../../team/providers/team_provider.dart';

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
  final _teamNameController = TextEditingController();
  String _selectedRole = 'buyer';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _teamNameController.dispose();
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

      // 1. 先注册用户（不关联团队）
      final authService = ref.read(authServiceProvider);
      await authService.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        role: _selectedRole,
        teamId: null, // 暂时不关联团队
      );

      // 2. 用户创建成功后，创建团队（现在有认证上下文）
      final teamService = ref.read(teamServiceProvider);
      final team = await teamService.createTeam(name: _teamNameController.text);

      // 3. 更新用户的 team_id
      final userId = authService.currentUserId;
      if (userId != null) {
        await teamService.updateUserTeam(userId, team.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.registerSuccess)),
        );
        // 注册成功后直接进入事件选择页面
        context.go('/event-selection');
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        String errorMessage;

        // 根据错误类型提供更明确的错误信息
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('no host') || errorString.contains('socketexception')) {
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _teamNameController,
                  decoration: InputDecoration(
                    labelText: l10n.teamName,
                    hintText: l10n.teamNameHint,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.group),
                  ),
                  validator: _validateTeamName,
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
