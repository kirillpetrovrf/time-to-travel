import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/user.dart' as app_user;
import '../../../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  app_user.UserType _selectedUserType = app_user.UserType.client;

  @override
  void initState() {
    super.initState();
    _phoneController.text = '+7 ';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Time to Travel'),
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    kToolbarHeight -
                    48, // Account for navigation bar and padding
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Добро пожаловать',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.label,
                    ),
                  ),

                  const SizedBox(height: 32),

                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: CupertinoColors.separator),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CupertinoTextField(
                      controller: _phoneController,
                      placeholder: '+7 (999) 123-45-67',
                      keyboardType: TextInputType.phone,
                      decoration: const BoxDecoration(),
                      padding: const EdgeInsets.all(16),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: CupertinoColors.separator),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        CupertinoListTile(
                          title: const Text('КЛИЕНТ'),
                          subtitle: const Text('🚗 Заказывать поездки'),
                          leading: Icon(
                            _selectedUserType == app_user.UserType.client
                                ? CupertinoIcons.check_mark_circled_solid
                                : CupertinoIcons.circle,
                            color: _selectedUserType == app_user.UserType.client
                                ? CupertinoColors.systemBlue
                                : CupertinoColors.inactiveGray,
                          ),
                          onTap: () {
                            setState(() {
                              _selectedUserType = app_user.UserType.client;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        CupertinoListTile(
                          title: const Text('ДИСПЕТЧЕР'),
                          subtitle: const Text('⚙️ Управлять системой'),
                          leading: Icon(
                            _selectedUserType == app_user.UserType.dispatcher
                                ? CupertinoIcons.check_mark_circled_solid
                                : CupertinoIcons.circle,
                            color:
                                _selectedUserType ==
                                    app_user.UserType.dispatcher
                                ? CupertinoColors.systemBlue
                                : CupertinoColors.inactiveGray,
                          ),
                          onTap: () {
                            setState(() {
                              _selectedUserType = app_user.UserType.dispatcher;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: CupertinoColors.systemBlue,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                          : const Text(
                              'Войти',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_phoneController.text.isEmpty) {
      _showErrorDialog('Введите номер телефона');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Симуляция авторизации
      await Future.delayed(const Duration(seconds: 2));

      // Сохраняем выбранный тип пользователя
      await _saveUserType();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Произошла ошибка: $e');
    }
  }

  Future<void> _saveUserType() async {
    // Сохраняем выбранный тип пользователя через AuthService
    await AuthService.instance.setUserType(_selectedUserType);
    print('🔧 Сохранен тип пользователя: $_selectedUserType');
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
