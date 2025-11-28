import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Imports de tu proyecto
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/cart_provider.dart';
import '../../common/widgets/mini_player.dart';

// Pantallas
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

  // --- PANTALLAS Y NAVEGACIÓN ---

  List<Widget> _buildScreens(AuthProvider authProvider) {
    final isAuthenticated = authProvider.isAuthenticated;
    final userRole = authProvider.currentUser?.role;

    return [
      const HomeScreen(), // 0
      const StoreScreen(), // 1
      if (isAuthenticated) const LibraryScreen(), // 2
      const CartScreen(), // 3 (o 2 si no auth)
      if (isAuthenticated && userRole == 'ARTIST')
        const StudioDashboardScreen(),
      if (isAuthenticated && userRole == 'ADMIN') const AdminDashboardScreen(),
      if (isAuthenticated) const ProfileScreen(),
    ];
  }

  List<_NavItem> _buildNavItems(AuthProvider authProvider) {
    final isAuthenticated = authProvider.isAuthenticated;
    final userRole = authProvider.currentUser?.role;

    return [
      _NavItem(
          icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Inicio'),
      _NavItem(
          icon: Icons.store_outlined, activeIcon: Icons.store, label: 'Tienda'),
      if (isAuthenticated)
        _NavItem(
            icon: Icons.library_music_outlined,
            activeIcon: Icons.library_music,
            label: 'Biblio'),
      _NavItem(
          icon: Icons.shopping_cart_outlined,
          activeIcon: Icons.shopping_cart,
          label: 'Carrito'),
      if (isAuthenticated && userRole == 'ARTIST')
        _NavItem(
            icon: Icons.mic_none_outlined,
            activeIcon: Icons.mic,
            label: 'Studio'),
      if (isAuthenticated && userRole == 'ADMIN')
        _NavItem(
            icon: Icons.admin_panel_settings_outlined,
            activeIcon: Icons.admin_panel_settings,
            label: 'Admin'),
      if (isAuthenticated)
        _NavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Perfil'),
    ];
  }

  void _onDestinationSelected(int index, AuthProvider authProvider) {
    setState(() {
      _currentIndex = index;
    });

    if (authProvider.isAuthenticated) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.loadCart(authProvider.currentUser!.id);
    }
  }

  // --- BUILD PRINCIPAL ---

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final screens = _buildScreens(authProvider);
        final navItems = _buildNavItems(authProvider);
        final isAuthenticated = authProvider.isAuthenticated;

        // Protección contra índice fuera de rango (logout crash fix)
        if (_currentIndex >= screens.length) {
          _currentIndex = 0;
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundBlack,
          body: Stack(
            children: [
              // CAPA 1: CONTENIDO DE LA APP
              Column(
                children: [
                  // A. HEADER GLOBAL Y BANNER
                  Container(
                    color: AppTheme.backgroundBlack,
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // SIEMPRE MOSTRAMOS EL HEADER CON LOS BOTONES
                          _buildGlobalHeader(context),
                          if (!isAuthenticated) _buildLoginBanner(context),
                        ],
                      ),
                    ),
                  ),

                  // B. PANTALLAS
                  Expanded(
                    child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
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
                        child: screens[_currentIndex],
                      ),
                    ),
                  ),
                ],
              ),

              // CAPA 2: UI FLOTANTE (Abajo)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const MiniPlayer(bottomPadding: 12),
                      _buildFloatingNavBar(navItems, authProvider),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- WIDGETS VISUALES ---

  Widget _buildGlobalHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: Row(
        children: [
          // Logo Branding
          const Icon(Icons.graphic_eq, color: AppTheme.primaryBlue, size: 28),
          const SizedBox(width: 10),
          const Text(
            'AUDIRA',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 3,
              color: Colors.white,
            ),
          ),

          const Spacer(),

          // --- ACCIONES RÁPIDAS (AQUÍ ESTÁN LOS BOTONES) ---

          // 1. Búsqueda
          _buildHeaderIcon(context,
              icon: Icons.search_rounded,
              onTap: () => Navigator.pushNamed(context, '/search')),
          const SizedBox(width: 4), // Espacio pequeño entre iconos

          // 2. FAQs (Preguntas Frecuentes)
          _buildHeaderIcon(context,
              icon: Icons.help_outline_rounded,
              onTap: () => Navigator.pushNamed(context, '/faq')),
          const SizedBox(width: 4),

          // 3. Contacto (Soporte)
          _buildHeaderIcon(context,
              icon: Icons.support_agent_rounded,
              onTap: () => Navigator.pushNamed(context, '/contact')),
          const SizedBox(width: 4),

          // 4. Notificaciones + Carrito
          _buildNotificationIcon(context),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(BuildContext context,
      {required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: AppTheme.textGrey, size: 24),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _buildHeaderIcon(context,
                icon: Icons.notifications_none_rounded,
                onTap: () => Navigator.pushNamed(context, '/notifications')),
            if (cartProvider.itemCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.errorRed,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${cartProvider.itemCount}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ).animate().scale(duration: 200.ms, curve: Curves.elasticOut),
              ),
          ],
        );
      },
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
            AppTheme.darkBlue
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
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_open_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acceso Limitado',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                Text(
                  'Inicia sesión para comprar y guardar.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryBlue,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size(0, 36),
            ),
            child: const Text('Entrar',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.5);
  }

  Widget _buildFloatingNavBar(List<_NavItem> items, AuthProvider authProvider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      height: 65,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == _currentIndex;

              return GestureDetector(
                onTap: () => _onDestinationSelected(index, authProvider),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 50,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryBlue.withValues(alpha: 0.2)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color:
                              isSelected ? AppTheme.primaryBlue : Colors.grey,
                          size: 24,
                        ).animate(target: isSelected ? 1 : 0).scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.15, 1.15),
                            duration: 200.ms),
                      ),
                      if (isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                        ).animate().fadeIn().scale(),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    )
        .animate()
        .slideY(begin: 1, end: 0, duration: 500.ms, curve: Curves.easeOutQuart);
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
