import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Config & Routes
import 'config/theme.dart';
import 'config/routes.dart';

// Providers
import 'core/providers/auth_provider.dart';
import 'core/providers/cart_provider.dart';
import 'core/providers/audio_provider.dart';
import 'core/providers/library_provider.dart';
import 'core/providers/download_provider.dart';

// Services
import 'core/api/services/local_notification_service.dart';

// UI
import 'features/home/screens/main_layout.dart';

void main() {
  // Aseguramos la inicialización de bindings para evitar errores de arranque
  WidgetsFlutterBinding.ensureInitialized();

  // Opcional: Forzar modo vertical y barra de estado transparente para look inmersivo
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

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
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
      ],
      child: const _AudiraOrchestrator(),
    );
  }
}

/// Widget orquestador que maneja la lógica de sesión y el enrutamiento
class _AudiraOrchestrator extends StatefulWidget {
  const _AudiraOrchestrator();

  @override
  State<_AudiraOrchestrator> createState() => _AudiraOrchestratorState();
}

class _AudiraOrchestratorState extends State<_AudiraOrchestrator> {
  int? _lastUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncUserData();
  }

  /// Sincroniza los carritos y librerías cuando cambia el usuario
  void _syncUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: true);
    // Listen: false para evitar reconstrucciones innecesarias aquí
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final libraryProvider =
        Provider.of<LibraryProvider>(context, listen: false);
    final downloadProvider =
        Provider.of<DownloadProvider>(context, listen: false);

    if (authProvider.isAuthenticated && authProvider.currentUser != null) {
      final currentUserId = authProvider.currentUser!.id;

      // Detectar login o cambio de usuario
      if (_lastUserId != currentUserId) {
        _lastUserId = currentUserId;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          debugPrint("🔄 Sincronizando datos para usuario ID: $currentUserId");
          await Future.wait([
            cartProvider.loadCart(currentUserId),
            libraryProvider.loadLibrary(currentUserId),
            downloadProvider.initialize(),
          ]);
        });
      }
    } else if (_lastUserId != null) {
      // Detectar logout
      final userIdToRemove = _lastUserId!;
      _lastUserId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        debugPrint("🧹 Limpiando sesión local...");
        await Future.wait([
          cartProvider.clearCart(userIdToRemove),
          libraryProvider.clearLibrary(userId: userIdToRemove),
          downloadProvider.initialize(),
        ]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audira',
      theme: AppTheme.darkTheme, // Tu tema oscuro personalizado
      debugShowCheckedModeBanner: false,
      navigatorKey: LocalNotificationService.navigatorKey, // Add navigation key for notifications
      onGenerateRoute: AppRoutes.generateRoute,
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Si está cargando la sesión, mostramos el Splash Screen Épico
          if (authProvider.isLoading) {
            return const _EpicSplashScreen();
          }

          // Si terminó de cargar, vamos al Layout Principal
          return const MainLayout();
        },
      ),
    );
  }
}

/// Pantalla de carga personalizada con estilo de marca
class _EpicSplashScreen extends StatelessWidget {
  const _EpicSplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Animado (Simulado con Icono)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryBlue.withValues(alpha: 0.2),
                      Colors.black,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    )
                  ]),
              child: const Icon(Icons.graphic_eq,
                  size: 64, color: AppTheme.primaryBlue),
            )
                .animate()
                .scale(duration: 800.ms, curve: Curves.easeOutBack)
                .shimmer(delay: 500.ms, color: Colors.white24),

            const SizedBox(height: 32),

            // Texto de Marca
            const Text(
              "A U D I R A",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w900,
                fontSize: 24,
                letterSpacing: 6,
                color: Colors.white,
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

            const SizedBox(height: 48),

            // Indicador de carga estilizado
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
