import 'package:erptask/features/auth/presentation/pages/login_page.dart';
import 'package:erptask/features/auth/presentation/pages/register_page.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool showLoginPage = true;

  // switch between pages
  void switchPages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(switchPages: switchPages);
    } else {
      return RegisterPage(switchPages: switchPages);
    }
  }
}
