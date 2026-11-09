import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Drawer de navegação global que integra todas as rotas do AgroSense Mesh.
class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.agroGreenPrimary, Color(0xFF0F3D14)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco_rounded, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 12),
                const Text(
                  'AgroSense Mesh',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Telemetria e Irrigação Offline-First',
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildItem(
                  context,
                  route: '/dashboard',
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard Geral',
                ),
                _buildItem(
                  context,
                  route: '/leituras',
                  icon: Icons.sensors_rounded,
                  title: 'Leituras de Sensores',
                ),
                _buildItem(
                  context,
                  route: '/leituras/novo',
                  icon: Icons.add_circle_outline_rounded,
                  title: 'Nova Leitura Manual',
                ),
                _buildItem(
                  context,
                  route: '/irrigacao',
                  icon: Icons.water_drop_rounded,
                  title: 'Histórico de Irrigação',
                ),
                _buildItem(
                  context,
                  route: '/irrigacao/novo',
                  icon: Icons.play_arrow_rounded,
                  title: 'Acionar Válvula Manual',
                ),
                _buildItem(
                  context,
                  route: '/zonas',
                  icon: Icons.grid_view_rounded,
                  title: 'Zonas de Plantio (A-E)',
                ),
                const Divider(),
                _buildItem(
                  context,
                  route: '/sincronizacao',
                  icon: Icons.sync_rounded,
                  title: 'Diagnóstico & Sincronização',
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Multivix • Computação Móvel 2026/2\nTema 01 — AP2B (Marco 2)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required String route,
    required IconData icon,
    required String title,
  }) {
    final isSelected = currentRoute == route;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.agroGreenPrimary : Colors.grey.shade700,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.agroGreenPrimary : AppTheme.textDark,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.agroGreenPrimary.withAlpha(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}

