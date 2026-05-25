import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class RefereeNav extends StatelessWidget {
  final String active; // 'queue' | 'tables'
  const RefereeNav({super.key, required this.active});

  void _go(BuildContext context, String route) {
    if (ModalRoute.of(context)?.settings.name == route) return;
    Navigator.of(context).pushReplacementNamed(route);
  }

  Future<void> _logout(BuildContext context) async {
    final api = await ApiService.create();
    await api.logout();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: C8P.ink2,
        border: Border(top: BorderSide(color: C8P.line)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _item(context, Icons.calendar_today_outlined, 'MATCHS', active == 'queue', () => _go(context, '/queue')),
          _item(context, Icons.grid_view_outlined, 'TABLES', active == 'tables', () => _go(context, '/tables')),
          _item(context, Icons.logout_outlined, 'DÉCO.', false, () => _logout(context)),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String label, bool isActive, VoidCallback onTap) {
    final color = isActive ? C8P.felt2 : C8P.mute;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 4),
              Text(label, style: C8PTypo.mono(size: 10, color: color, letterSpacing: 0.12)),
            ],
          ),
        ),
      ),
    );
  }
}
