import 'package:flutter/material.dart';

import '../widgets/rounded_sheet_body.dart';
import 'about_screen.dart';
import 'guide_screen.dart';
import 'legal_screen.dart';

class InfosScreen extends StatelessWidget {
  const InfosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Infos'),
        centerTitle: true,
      ),
      body: RoundedSheetBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            _InfosTile(
              icon: Icons.menu_book_outlined,
              color: const Color(0xFF2E7D32),
              title: 'Guide',
              subtitle: 'Comment utiliser l\'application',
              onTap: () => _open(context, const GuideScreen()),
            ),
            const SizedBox(height: 12),
            _InfosTile(
              icon: Icons.info_outline,
              color: const Color(0xFF1565C0),
              title: 'À propos',
              subtitle: 'NotiWaste et ses fonctionnalités',
              onTap: () => _open(context, const AboutScreen()),
            ),
            const SizedBox(height: 12),
            _InfosTile(
              icon: Icons.gavel_outlined,
              color: const Color(0xFF546E7A),
              title: 'Mentions légales',
              subtitle: 'Éditeur, données et sources',
              onTap: () => _open(context, const LegalScreen()),
            ),
          ],
        ),
      ),
    );
  }

  static void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }
}

class _InfosTile extends StatelessWidget {
  const _InfosTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          foregroundColor: color,
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
