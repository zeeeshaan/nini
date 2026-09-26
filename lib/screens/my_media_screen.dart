import 'package:flutter/material.dart';
import '../app_colors.dart';

class MyMediaScreen extends StatefulWidget {
  const MyMediaScreen({super.key});

  @override
  State<MyMediaScreen> createState() => _MyMediaScreenState();
}

class _MyMediaScreenState extends State<MyMediaScreen> {
  final _search = TextEditingController();
  final List<int> _items = List.generate(12, (i) => i);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openActions(int index) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _MediaActionsSheet(),
    );
    if (action == null || !mounted) return;
    if (action == 'حذف') {
      setState(() => _items.remove(index));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(action)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: 'رسانه‌های من',
              onSave: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('رسانه‌ها به‌روزرسانی شد')),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
              child: _SearchField(controller: _search),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.9,
                ),
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final id = _items[i];
                  return _MediaTile(onLongPress: () => _openActions(id));
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
          Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});
  final TextEditingController controller;

  static const _ink = AppColors.deepBlack;
  static const _muted = AppColors.midGray;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceOnLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: _ink,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'جستجوی رسانه',
          hintStyle: TextStyle(
            color: _muted.withValues(alpha: 0.85),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(Icons.search, color: _muted, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.onLongPress});
  final VoidCallback onLongPress;

  static const _muted = AppColors.midGray;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: onLongPress,
      onTap: onLongPress,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceOnLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          Icons.image_outlined,
          size: 24,
          color: _muted.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _MediaActionsSheet extends StatelessWidget {
  const _MediaActionsSheet();

  static const _ink = AppColors.deepBlack;
  static const _red = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.edit_outlined,
            label: 'تغییر نام',
            color: _ink,
          ),
          _ActionTile(
            icon: Icons.drive_file_move_outline,
            label: 'انتقال',
            color: _ink,
          ),
          _ActionTile(icon: Icons.delete_outline, label: 'حذف', color: _red),
          _ActionTile(icon: Icons.copy_outlined, label: 'تکثیر', color: _ink),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () => Navigator.of(context).pop(label),
    );
  }
}
