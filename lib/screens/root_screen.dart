import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../data/post_store.dart';
import 'home_screen.dart';
import 'cart_screen.dart';
import 'create_post_screen.dart';
import 'post_details_screen.dart';
import 'search_screen.dart';
import 'user_screen.dart';
import '../utils/fa.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    CartScreen(),
    SearchScreen(),
    UserScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: SafeArea(child: _screens[_index]),
      bottomNavigationBar: _BottomBar(
        index: _index,
        onSelect: (i) => setState(() => _index = i),
        onCreate: _createPost,
      ),
    );
  }

  /// Publishes the new post to the in-memory [PostStore] and jumps to the
  /// profile, where it appears first in the grid.
  Future<void> _createPost() async {
    final messenger = ScaffoldMessenger.of(context);
    final draft = await Navigator.of(context).push<PostDraft>(
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
    if (draft == null || !mounted) return;
    PostStore.add(draft);
    setState(() => _index = 3);
    final at = draft.scheduledAt;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          at == null
              ? 'پست منتشر شد'
              : 'پست برای ${faDateLong(at)} زمان‌بندی شد',
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.index,
    required this.onSelect,
    required this.onCreate,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            textDirection: TextDirection.ltr,
            children: [
              _NavIcon(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                selected: index == 0,
                onTap: () => onSelect(0),
              ),
              _CartNavIcon(selected: index == 1, onTap: () => onSelect(1)),
              _NavIcon(
                icon: Icons.add,
                selectedIcon: Icons.add,
                selected: false,
                onTap: onCreate,
              ),
              _NavIcon(
                icon: Icons.search,
                selectedIcon: Icons.search,
                selected: index == 2,
                onTap: () => onSelect(2),
              ),
              _AvatarNavIcon(selected: index == 3, onTap: () => onSelect(3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  static const _ink = AppColors.deepBlack;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Icon(selected ? selectedIcon : icon, color: _ink, size: 25),
      ),
    );
  }
}

class _CartNavIcon extends StatelessWidget {
  const _CartNavIcon({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  static const _ink = AppColors.deepBlack;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                selected ? Icons.shopping_cart : Icons.shopping_cart_outlined,
                color: _ink,
                size: 24,
              ),
              const Positioned(top: -3, right: -5, child: CountBadge(count: 2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarNavIcon extends StatelessWidget {
  const _AvatarNavIcon({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.deepBlack : Colors.transparent,
                width: 1.4,
              ),
            ),
            child: const ProfileAvatar(size: 26),
          ),
        ),
      ),
    );
  }
}
