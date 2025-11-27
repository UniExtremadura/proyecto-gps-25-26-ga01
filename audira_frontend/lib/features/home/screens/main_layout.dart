import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Asegúrate de tener esto importado
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/cart_provider.dart';
import '../../common/widgets/mini_player.dart';
import 'home_screen.dart';
import '../../store/screens/store_screen.dart';
import '../../library/screens/library_screen.dart';
import '../../cart/screens/cart_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../studio/screens/studio_dashboard_screen.dart';
import '../../admin/screens/admin_dashboard_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // Mantenemos la lógica exacta de pantallas
  List<Widget> get _screens {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthenticated = authProvider.isAuthenticated;
    final userRole = authProvider.currentUser?.role;

    return [
      const HomeScreen(),
      const StoreScreen(),
      if (isAuthenticated) const LibraryScreen(),
      const CartScreen(),
      if (isAuthenticated && userRole == 'ARTIST')
        const StudioDashboardScreen(),
      if (isAuthenticated && userRole == 'ADMIN') const AdminDashboardScreen(),
      if (isAuthenticated) const ProfileScreen(),
    ];
  }

  // Mantenemos la lógica exacta de destinos
  List<NavigationDestination> get _destinations {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthenticated = authProvider.isAuthenticated;
    final userRole = authProvider.currentUser?.role;

    return [
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Inicio',
      ),
      const NavigationDestination(
        icon: Icon(Icons.store_outlined),
        selectedIcon: Icon(Icons.store),
        label: 'Tienda',
      ),
      if (isAuthenticated)
        const NavigationDestination(
          icon: Icon(Icons.library_music_outlined),
          selectedIcon: Icon(Icons.library_music),
          label: 'Biblioteca',
        ),
      const NavigationDestination(
        icon: Icon(Icons.shopping_cart_outlined),
        selectedIcon: Icon(Icons.shopping_cart),
        label: 'Carrito',
      ),
      if (isAuthenticated && userRole == 'ARTIST')
        const NavigationDestination(
          icon: Icon(Icons.mic_outlined),
          selectedIcon: Icon(Icons.mic),
          label: 'Studio',
        ),
      if (isAuthenticated && userRole == 'ADMIN')
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      if (isAuthenticated)
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
    ];
  }

  void _onDestinationSelected(int index) async {
    setState(() {
      _currentIndex = index;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (_isCartTab(index) && authProvider.currentUser != null) {
      debugPrint('=== Cart tab selected, reloading cart ===');
      await cartProvider.loadCart(authProvider.currentUser!.id);
    }
  }

  bool _isCartTab(int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.isAuthenticated ? index == 3 : index == 2;
  }

  @override
  Widget build(BuildContext context) {
    // Usamos el Consumer para obtener el estado de autenticación y redibujar si cambia
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundBlack,
          // Eliminamos el AppBar por defecto para usar uno personalizado
          body: SafeArea(
            child: Column(
              children: [
                // 1. GLOBAL HEADER PERSONALIZADO
                _buildGlobalHeader(context),

                // 2. BANNER DE LOGIN (Si no está autenticado)
                if (!authProvider.isAuthenticated) _buildLoginBanner(context),

                // 3. CONTENIDO DE PANTALLAS
                Expanded(
                  child: PageTransitionSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder:
                        (child, primaryAnimation, secondaryAnimation) {
                      return FadeThroughTransition(
                        animation: primaryAnimation,
                        secondaryAnimation: secondaryAnimation,
                        fillColor: AppTheme.backgroundBlack,
                        child: child,
                      );
                    },
                    child: _screens[_currentIndex],
                  ),
                ),

                // 4. MINI PLAYER (Siempre visible si hay audio)
                const MiniPlayer(),
              ],
            ),
          ),

          // 5. BOTTOM NAVIGATION BAR REFINADO
          bottomNavigationBar: _buildBottomNavBar(),
        );
      },
    );
  }

  // --- WIDGETS PERSONALIZADOS ---

  Widget _buildGlobalHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundBlack,
        border: Border(bottom: BorderSide(color: AppTheme.surfaceBlack)),
      ),
      child: Row(
        children: [
          // Logo / Título
          const Icon(Icons.graphic_eq, color: AppTheme.primaryBlue, size: 24),
          const SizedBox(width: 8),
          const Text(
            'AUDIRA',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 2,
              color: Colors.white,
            ),
          ),

          const Spacer(),

          // Acciones Globales
          _buildHeaderAction(
            icon: Icons.search,
            onTap: () => Navigator.pushNamed(context, '/search'),
          ),
          _buildHeaderAction(
            icon: Icons.help_outline,
            onTap: () => Navigator.pushNamed(context, '/faq'),
          ),
          _buildHeaderAction(
            icon: Icons.support_agent,
            onTap: () => Navigator.pushNamed(context, '/contact'),
          ),

          // Carrito con Badge
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildHeaderAction(
                    icon: Icons.notifications_outlined,
                    onTap: () => Navigator.pushNamed(context, '/notifications'),
                  ),
                  if (cartProvider.itemCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.errorRed,
                          shape: BoxShape.circle,
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${cartProvider.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                          .animate()
                          .scale(duration: 200.ms, curve: Curves.easeOutBack),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(
      {required IconData icon, required VoidCallback onTap}) {
    return IconButton(
      icon: Icon(icon, color: AppTheme.textGrey, size: 22),
      onPressed: onTap,
      splashRadius: 20,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildLoginBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.8),
            AppTheme.darkBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_open_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Acceso Limitado',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Inicia sesión para desbloquear todo',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryBlue,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size(0, 32),
            ),
            child: const Text('Entrar',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ).animate().slideY(begin: -0.5, duration: 400.ms).fadeIn();
  }

  Widget _buildBottomNavBar() {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textWhite,
                fontFamily: 'Poppins');
          }
          return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.normal,
              color: AppTheme.textGrey,
              fontFamily: 'Poppins');
        }),
        indicatorColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppTheme.primaryBlue);
          }
          return const IconThemeData(color: AppTheme.textGrey);
        }),
      ),
      child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: _destinations,
        backgroundColor: AppTheme.surfaceBlack,
        elevation: 0,
        height: 65,
        animationDuration: const Duration(milliseconds: 500),
      ),
    );
  }
}
