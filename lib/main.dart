import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/admin_provider.dart';
import 'utils/theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const LycansAdmin());
}

class LycansAdmin extends StatelessWidget {
  const LycansAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminProvider()..initialize()),
      ],
      child: MaterialApp(
        title: 'Lycans Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AdminAuthGate(),
      ),
    );
  }
}

class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
        ),
      );
    }

    if (provider.isAuthenticated) {
      return const MainShell();
    }

    return const LoginScreen();
  }
}