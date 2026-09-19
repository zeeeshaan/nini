import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text('Profile', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.person, size: 44, color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(height: 12),
              Text('Ali Rahman', style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                'etmam.tech123@gmail.com',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Card(
          child: Column(
            children: [
              _SettingsTile(icon: Icons.notifications_outlined, label: 'Notifications'),
              _Divider(),
              _SettingsTile(icon: Icons.lock_outline, label: 'Privacy & security'),
              _Divider(),
              _SettingsTile(icon: Icons.palette_outlined, label: 'Appearance'),
              _Divider(),
              _SettingsTile(icon: Icons.help_outline, label: 'Help & support'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: _SettingsTile(
            icon: Icons.logout,
            label: 'Log out',
            destructive: true,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        indent: 56,
        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
      );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = destructive ? theme.colorScheme.error : theme.colorScheme.onSurface;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      trailing: destructive ? null : const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}
