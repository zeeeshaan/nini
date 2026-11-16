import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/shared/widgets/app_textfield/app_text_field.dart';

// Open the share sheet from any post screen.
Future<void> openPostShareSheet(
  BuildContext context, {
  required String postId,
  required String postText,
  String? postUrl,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.78,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SizedBox.expand(
                child: ShareSheet(
                  postId: postId,
                  postText: postText,
                  postUrl: postUrl,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class ShareSheet extends StatefulWidget {
  const ShareSheet({
    super.key,
    required this.postId,
    required this.postText,
    this.postUrl,
  });

  final String postId;
  final String postText;
  final String? postUrl;

  @override
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet> {
  final TextEditingController _searchController = TextEditingController();

  // Demo contacts until real chat sharing is connected.
  static const List<String> _contacts = [
    'robert',
    'ali.moho',
    'reza',
    'robert',
    'ali.moho',
    'reza',
    'robert',
    'ali.moho',
    'reza',
  ];

  String get _shareText {
    final text = widget.postText.trim();
    final url = widget.postUrl?.trim();

    return [
      text.isEmpty ? "این پست را در های‌ورک ببینید!" : text,
      if (url != null && url.isNotEmpty) url,
    ].join('\n\n');
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  // Opens the device's native sharing menu.
  Future<void> _sharePost() async {
    try {
      final renderObject = context.findRenderObject();

      final origin = renderObject is RenderBox
          ? renderObject.localToGlobal(Offset.zero) & renderObject.size
          : null;

      final result = await SharePlus.instance.share(
        ShareParams(
          text: _shareText,
          subject: "پست های‌ورک",
          sharePositionOrigin: origin,
        ),
      );

      if (!mounted) return;

      if (result.status == ShareResultStatus.success) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      _showError("باز کردن گزینه‌های اشتراک‌گذاری انجام نشد.");
    }
  }

  // Opens an external app or its web sharing page.
  Future<void> _openExternal(Uri uri) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!mounted) return;

      if (opened) {
        Navigator.of(context).pop();
      } else {
        _showError("باز کردن این روش اشتراک‌گذاری انجام نشد.");
      }
    } catch (_) {
      _showError("باز کردن این روش اشتراک‌گذاری انجام نشد.");
    }
  }

  Future<void> _shareWhatsApp() {
    return _openExternal(Uri.https('wa.me', '/', {'text': _shareText}));
  }

  Future<void> _shareTelegram() {
    return _openExternal(
      Uri.https('t.me', '/share/url', {
        'url': widget.postUrl?.trim() ?? '',
        'text': widget.postText.trim(),
      }),
    );
  }

  Future<void> _shareMessages() {
    return _openExternal(
      Uri(scheme: 'sms', queryParameters: {'body': _shareText}),
    );
  }

  Future<void> _copyPost() async {
    final url = widget.postUrl?.trim();
    final hasLink = url != null && url.isNotEmpty;

    await Clipboard.setData(ClipboardData(text: hasLink ? url : _shareText));

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    Navigator.of(context).pop();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          hasLink ? "پیوند پست کپی شد" : "متن پست کپی شد",
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Light theme -> pure black.
    // Dark theme -> pure white.
    final background = isDark ? AppColors.white : AppColors.black;

    final foreground = isDark ? AppColors.black : AppColors.white;

    return Material(
      color: background,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Sheet handle.
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: foreground.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 16),

            // Search input using the existing AppTextField.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Theme(
                data: theme.copyWith(
                  colorScheme: theme.colorScheme.copyWith(
                    surface: background,
                    onSurface: foreground,
                  ),
                  inputDecorationTheme: theme.inputDecorationTheme.copyWith(
                    filled: true,
                    fillColor: foreground.withValues(alpha: 0.12),
                    hintStyle: AppTextStyles.bodyText.copyWith(
                      color: foreground.withValues(alpha: 0.55),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                child: AppTextField(
                  controller: _searchController,
                  hint: "جستجو",
                  textStyle: AppTextStyles.bodyText.copyWith(color: foreground),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  suffixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: foreground.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Searchable sample contact grid.
            Expanded(
              child: AnimatedBuilder(
                animation: _searchController,
                builder: (context, _) {
                  final query = _searchController.text.trim().toLowerCase();

                  final contacts = _contacts
                      .where((name) => name.toLowerCase().contains(query))
                      .toList();

                  if (contacts.isEmpty) {
                    return Center(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "مخاطبی یافت نشد",
                          style: AppTextStyles.bodyText.copyWith(
                            color: foreground,
                          ),
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.05,
                        ),
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: foreground.withValues(alpha: 0.85),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            contacts[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              color: foreground,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            Divider(height: 1, color: foreground.withValues(alpha: 0.2)),

            // External sharing shortcuts.
            SizedBox(
              height: 94,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                children: [
                  _shareOption(
                    label: "واتساپ",
                    icon: Icons.phone_rounded,
                    color: const Color(0xFF25D366),
                    foreground: foreground,
                    onTap: _shareWhatsApp,
                  ),
                  _shareOption(
                    label: "تلگرام",
                    icon: Icons.send_rounded,
                    color: const Color(0xFF229ED9),
                    foreground: foreground,
                    onTap: _shareTelegram,
                  ),
                  _shareOption(
                    label: "مسنجر",
                    icon: Icons.message_rounded,
                    color: const Color(0xFF168AFF),
                    foreground: foreground,
                    // Choose Messenger in the native share menu.
                    onTap: _sharePost,
                  ),
                  _shareOption(
                    label: "پیام‌ها",
                    icon: Icons.sms_rounded,
                    color: const Color(0xFF1877F2),
                    foreground: foreground,
                    onTap: _shareMessages,
                  ),
                  _shareOption(
                    label: widget.postUrl?.trim().isNotEmpty == true
                        ? "کپی پیوند"
                        : "کپی متن",
                    icon: Icons.link_rounded,
                    color: const Color(0xFF505050),
                    foreground: foreground,
                    onTap: _copyPost,
                  ),
                  _shareOption(
                    label: "بیشتر",
                    icon: Icons.more_horiz_rounded,
                    color: const Color(0xFF505050),
                    foreground: foreground,
                    onTap: _sharePost,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shareOption({
    required String label,
    required IconData icon,
    required Color color,
    required Color foreground,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 70,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color,
              child: Icon(icon, size: 22, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(color: foreground),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }
}
