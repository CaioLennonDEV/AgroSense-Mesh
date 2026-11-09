import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Drawer de navegação global que integra todas as rotas do AgroSense Mesh.
class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 54, left: 20, right: 20, bottom: 24),
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withAlpha(60), width: 1),
                      ),
                      child: const Icon(Icons.eco_rounded, size: 30, color: Colors.white),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: Color(0xFF34D399)),
                          SizedBox(width: 6),
                          Text(
                            'Mesh Ativo',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'AgroSense Mesh',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Telemetria & Irrigação Autônoma',
                  style: TextStyle(
                    color: Colors.white.withAlpha(210),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
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
                  icon: Icons.play_circle_outline_rounded,
                  title: 'Acionar Válvula Manual',
                ),
                _buildItem(
                  context,
                  route: '/zonas',
                  icon: Icons.grid_view_rounded,
                  title: 'Zonas de Plantio (A-E)',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  child: Divider(color: Colors.grey.shade200, height: 1),
                ),
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
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_outlined, size: 20, color: AppTheme.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Multivix • Computação Móvel\nTema 01 — AP2B (Marco 2)',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.3),
                  ),
                ),
              ],
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.agroGreenPrimary.withAlpha(20) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: AppTheme.agroGreenPrimary.withAlpha(60), width: 1)
            : null,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          size: 22,
          color: isSelected ? AppTheme.agroGreenPrimary : Colors.grey.shade600,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppTheme.agroGreenPrimary : AppTheme.textDark,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        onTap: () {
          Navigator.pop(context);
          if (!isSelected) {
            Navigator.pushNamed(context, route);
          }
        },
      ),
    );
  }
}
