import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../utils/fa.dart';

class ProfileSettingScreen extends StatefulWidget {
  const ProfileSettingScreen({super.key});

  @override
  State<ProfileSettingScreen> createState() => _ProfileSettingScreenState();
}

class _ProfileSettingScreenState extends State<ProfileSettingScreen> {
  static const _ink = AppColors.deepBlack;
  static const _muted = AppColors.midGray;
  static const _outline = AppColors.divider;

  final _name = TextEditingController();
  final _lname = TextEditingController();
  final _nationality = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _bio = TextEditingController();

  DateTime? _birth;
  String? _gender;

  @override
  void dispose() {
    _name.dispose();
    _lname.dispose();
    _nationality.dispose();
    _username.dispose();
    _email.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1930),
      lastDate: now,
      helpText: 'انتخاب تاریخ تولد',
      cancelText: 'انصراف',
      confirmText: 'تأیید',
    );
    if (picked != null) setState(() => _birth = picked);
  }

  Future<void> _pickGender() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _outline,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 8),
            for (final g in const ['مرد', 'زن', 'سایر'])
              ListTile(
                title: Text(
                  g,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(g),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (result != null) setState(() => _gender = result);
  }

  void _save() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('پروفایل ذخیره شد')));
  }

  @override
  Widget build(BuildContext context) {
    final birthLabel = _birth == null ? null : faDateLong(_birth!);

    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            _Header(title: 'تنظیمات پروفایل', onSave: _save),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Center(child: _buildAvatar()),
                  const SizedBox(height: 28),
                  _FieldBox(controller: _name, hint: 'نام'),
                  const SizedBox(height: 14),
                  _FieldBox(controller: _lname, hint: 'نام خانوادگی'),
                  const SizedBox(height: 14),
                  _FieldBox(controller: _nationality, hint: 'ملیت'),
                  const SizedBox(height: 14),
                  _FieldBox(controller: _username, hint: 'نام کاربری'),
                  const SizedBox(height: 14),
                  _FieldBox(
                    controller: _email,
                    hint: 'ایمیل',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  _TapBox(
                    label: birthLabel ?? 'تاریخ تولد',
                    trailingIcon: Icons.calendar_today_outlined,
                    onTap: _pickBirth,
                  ),
                  const SizedBox(height: 14),
                  _TapBox(
                    label: _gender ?? 'جنسیت',
                    trailingIcon: Icons.keyboard_arrow_down,
                    onTap: _pickGender,
                  ),
                  const SizedBox(height: 14),
                  _FieldBox(controller: _bio, hint: 'درباره من', maxLines: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceOnLight,
              border: Border.all(color: _outline, width: 1.6),
            ),
            child: Icon(
              Icons.person_outline,
              size: 36,
              color: _muted.withValues(alpha: 0.6),
            ),
          ),
          PositionedDirectional(
            end: 0,
            bottom: 0,
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _ink,
                border: Border.all(color: AppColors.pureWhite, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 13,
                color: AppColors.pureWhite,
              ),
            ),
          ),
        ],
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
      padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.chevron_left, color: _ink, size: 26),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          InkWell(
            onTap: onSave,
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.check, color: _ink, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldBox extends StatelessWidget {
  const _FieldBox({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;

  static const _ink = AppColors.deepBlack;
  static const _muted = AppColors.midGray;
  static const _outline = AppColors.divider;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textAlign: TextAlign.start,
      style: const TextStyle(
        color: _ink,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: _muted.withValues(alpha: 0.9),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AppColors.pureWhite,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 14 : 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _ink, width: 1.4),
        ),
      ),
    );
  }
}

class _TapBox extends StatelessWidget {
  const _TapBox({
    required this.label,
    required this.trailingIcon,
    required this.onTap,
  });

  final String label;
  final IconData trailingIcon;
  final VoidCallback onTap;

  static const _ink = AppColors.deepBlack;
  static const _outline = AppColors.divider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _outline),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(trailingIcon, size: 18, color: _ink.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}
