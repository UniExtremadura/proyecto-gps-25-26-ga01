import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Usuario no disponible'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile Header
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.primaryBlue,
                child: user.profileImageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          user.profileImageUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person,
                            size: 50,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      ),
              ).animate().fadeIn().scale(),
              const SizedBox(height: 16),
              Text(
                user.fullName,
                style: Theme.of(context).textTheme.headlineLarge,
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 4),
              Text(
                '@${user.username}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textGrey,
                    ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 8),
              Chip(
                label: Text(
                  user.role,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: AppTheme.primaryBlue,
              ).animate().fadeIn(delay: 300.ms),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Profile Info
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email'),
                subtitle: Text(user.email),
              ),
              if (user.bio != null) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Bio'),
                  subtitle: Text(user.bio!),
                ),
              ],
              if (user.location != null) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Ubicación'),
                  subtitle: Text(user.location!),
                ),
              ],
              if (user.website != null) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.link_outlined),
                  title: const Text('Sitio web'),
                  subtitle: Text(user.website!),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Stats
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  'Seguidores',
                  '${user.followerIds.length}',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppTheme.textDarkGrey,
                ),
                _buildStatItem(
                  context,
                  'Siguiendo',
                  '${user.followingIds.length}',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Actions
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Editar perfil'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pushNamed(context, '/profile/edit');
          },
        ),

        ListTile(
          leading: const Icon(Icons.bar_chart_outlined),
          title: const Text('Estadísticas'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pushNamed(context, '/stats');
          },
        ),

        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text('Configuración'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Settings - Coming soon'),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Logout
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primaryBlue,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textGrey,
              ),
        ),
      ],
    );
  }
}
