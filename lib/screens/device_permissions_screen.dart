import 'package:flutter/material.dart';
import '../app_colors.dart';

class DevicePermissionsScreen extends StatefulWidget {
  const DevicePermissionsScreen({super.key});

  @override
  State<DevicePermissionsScreen> createState() =>
      _DevicePermissionsScreenState();
}

class _DevicePermissionsScreenState extends State<DevicePermissionsScreen> {
  final Map<String, bool> _permissions = {
    'دوربین': true,
    'مخاطبین': true,
    'خدمات موقعیت مکانی': true,
    'میکروفون': true,
    'اعلان‌ها': true,
    'عکس‌ها و ویدیوها': true,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: 'مجوزهای دستگاه',
              onSave: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('مجوزها ذخیره شد'))),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                itemCount: _permissions.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (_, i) {
                  final key = _permissions.keys.elementAt(i);
                  return _PermissionRow(
                    name: key,
                    allowed: _permissions[key]!,
                    onTap: () =>
                        setState(() => _permissions[key] = !_permissions[key]!),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onSave});
  final String title;
  final VoidCallback onSave;

  static const _ink = AppColors.deepBlack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 10, 18, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.chevron_left, color: _ink, size: 30),
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          InkWell(
            onTap: onSave,
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.check, color: _ink, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.name,
    required this.allowed,
    required this.onTap,
  });
  final String name;
  final bool allowed;
  final VoidCallback onTap;

  static const _ink = AppColors.deepBlack;
  static const _muted = AppColors.midGray;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Text(
              name,
              style: const TextStyle(
                color: _ink,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsetsDirectional.only(end: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: allowed ? _ink : _muted.withValues(alpha: 0.5),
              ),
            ),
            Text(
              allowed ? 'مجاز' : 'غیرمجاز',
              style: TextStyle(
                color: allowed ? _ink : _muted,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
