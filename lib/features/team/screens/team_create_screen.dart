import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/team_provider.dart';

class TeamCreateScreen extends ConsumerStatefulWidget {
  const TeamCreateScreen({super.key});

  @override
  ConsumerState<TeamCreateScreen> createState() => _TeamCreateScreenState();
}

class _TeamCreateScreenState extends ConsumerState<TeamCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _createdTeamId;
  String? _createdInviteCode;

  @override
  void dispose() {
    _teamNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createTeam() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final teamService = ref.read(teamServiceProvider);
      final password = _passwordController.text.trim();
      final team = await teamService.createTeam(
        name: _teamNameController.text.trim(),
        password: password,
      );

      setState(() {
        _createdTeamId = team.id;
        _createdInviteCode = team.inviteCode;
      });

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.teamCreationSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.createFailed(e.toString())}'),
            backgroundColor: Colors.red,
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

  void _copyInviteCode() {
    if (_createdInviteCode != null) {
      Clipboard.setData(ClipboardData(text: _createdInviteCode!));
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.inviteCodeCopied)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createTeam),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.group_add,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.createNewTeam,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.teamCreationSuccess,
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                if (_createdTeamId == null) ...[
                  TextFormField(
                    controller: _teamNameController,
                    decoration: InputDecoration(
                      labelText: l10n.teamName,
                      hintText: l10n.teamNameHint,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.business),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.pleaseEnterTeamName;
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: l10n.teamPassword,
                      hintText: l10n.teamPasswordHint,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.pleaseEnterPassword;
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _createTeam,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.createTeam,
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.teamCreatedSuccessMessage,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${l10n.teamName}: ${_teamNameController.text}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          l10n.inviteCode,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: SelectableText(
                            _createdInviteCode!,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _createdInviteCode!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.inviteCodeCopied)),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          label: Text(l10n.copyInviteCode),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          l10n.teamPassword,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: SelectableText(
                            _passwordController.text,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _passwordController.text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.passwordCopied)),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          label: Text(l10n.copyPassword),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.shareTeamIdMessage,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _createdTeamId = null;
                        _teamNameController.clear();
                        _passwordController.clear();
                      });
                    },
                    child: Text(l10n.createAnotherTeam),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
