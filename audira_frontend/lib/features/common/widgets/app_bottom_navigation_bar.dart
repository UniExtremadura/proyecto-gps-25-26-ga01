import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Imports de tu proyecto
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';

class AppBottomNavigationBar extends StatelessWidget {
  final int? selectedIndex;

  const AppBottomNavigationBar({
    super.key,
    this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthenticated = authProvider.isAuthenticated;
    final userRole = authProvider.currentUser?.role;

    // Definimos los items dinámicamente según el rol
    final List<_NavItem> items = [
      _NavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: 'Inicio'),
      _NavItem(
          icon: Icons.store_outlined,
          activeIcon: Icons.store_rounded,
          label: 'Tienda'),
      if (isAuthenticated)
        _NavItem(
            icon: Icons.library_music_outlined,
            activeIcon: Icons.library_music_rounded,
            label: 'Biblioteca'),
      _NavItem(
          icon: Icons.shopping_cart_outlined,
          activeIcon: Icons.shopping_cart_rounded,
          label: 'Carrito'),
      if (isAuthenticated && userRole == 'ARTIST')
        _NavItem(
            icon: Icons.mic_none_outlined,
            activeIcon: Icons.mic_rounded,
            label: 'Studio'),
      if (isAuthenticated && userRole == 'ADMIN')
        _NavItem(
            icon: Icons.admin_panel_settings_outlined,
            activeIcon: Icons.admin_panel_settings_rounded,
            label: 'Admin'),
      if (isAuthenticated)
        _NavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person_rounded,
            label: 'Perfil'),
    ];

    // Calculamos el índice seguro (si selectedIndex es null, no marcamos nada o marcamos el 0)
    final currentIndex = selectedIndex ?? 0;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Efecto Blur
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E)
                  .withValues(alpha: 0.85), // Fondo semitransparente
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isSelected =
                    index == currentIndex && selectedIndex != null;

                return _buildNavItem(
                  context,
                  item: item,
                  isSelected: isSelected,
                  onTap: () {
                    if (index == currentIndex) return;
                    // Navegación conservando la lógica original
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (route) => false,
                      arguments: index,
                    );
                  },
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required _NavItem item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 50, // Zona táctil fija
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono Animado
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryBlue.withValues(alpha: 0.2)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                color: isSelected ? AppTheme.primaryBlue : Colors.grey,
                size: 24,
              ).animate(target: isSelected ? 1 : 0).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 200.ms),
            ),

            // Indicador de punto o etiqueta pequeña (opcional)
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
  }
}

// Clase auxiliar privada para organizar los datos
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
