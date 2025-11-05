import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/cart_provider.dart';
import 'core/providers/audio_provider.dart';
import 'core/providers/library_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/main_layout.dart';

void main() {
  runApp(const AudiraApp());
}

class AudiraApp extends StatelessWidget {
  const AudiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
      ],
      child: MaterialApp(
        title: 'Audira',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        onGenerateRoute: AppRoutes.generateRoute,
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (authProvider.isLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (authProvider.isAuthenticated) {
              return const MainLayout();
            }

            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
