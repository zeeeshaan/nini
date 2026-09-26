import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../utils/fa.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartItem {
  _CartItem({required this.title, required this.price});
  final String title;
  final int price;
  int quantity = 1;
}

class _CartScreenState extends State<CartScreen> {
  int _tab = 0;

  final List<_CartItem> _items = List.generate(
    5,
    (_) => _CartItem(title: 'جلسه تمرین خصوصی', price: 582000),
  );

  void _removeAt(int index) {
    final removed = _items.removeAt(index);
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('«${removed.title}» حذف شد')));
  }

  void _clearCart() {
    setState(_items.clear);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onClear: _clearCart),
            _TabBar(tab: _tab, onChanged: (t) => setState(() => _tab = t)),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_tab) {
      case 0:
        return _items.isEmpty
            ? const _EmptyState(label: 'سبد خرید شما خالی است')
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _CartRow(
                  item: _items[i],
                  onDelete: () => _removeAt(i),
                  onAdd: () => setState(() => _items[i].quantity++),
                ),
              );
      case 1:
        return const _EmptyState(label: 'هنوز سفارشی ثبت نشده است');
      default:
        return const _EmptyState(label: 'هنوز فروشی نداشته‌اید');
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClear});
  final VoidCallback onClear;

  static const _ink = AppColors.deepBlack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 10, 10, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.chevron_left, color: _ink, size: 30),
          ),
          const Text(
            'سبد خرید',
            style: TextStyle(
              color: _ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: _ink, size: 22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (v) {
              if (v == 'clear') onClear();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'clear', child: Text('خالی کردن سبد')),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.tab, required this.onChanged});
  final int tab;
  final ValueChanged<int> onChanged;

  static const _labels = ['سبد خرید', 'تاریخچه سفارش‌ها', 'فروش‌ها'];
  static const _ink = AppColors.deepBlack;
  static const _muted = AppColors.midGray;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 26),
              child: InkWell(
                onTap: () => onChanged(i),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _labels[i],
                      style: TextStyle(
                        color: i == tab ? _ink : _muted,
                        fontSize: 14,
                        fontWeight: i == tab
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 2.5,
                      width: 26,
                      color: i == tab ? _ink : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({
    required this.item,
    required this.onDelete,
    required this.onAdd,
  });
  final _CartItem item;
  final VoidCallback onDelete;
  final VoidCallback onAdd;

  static const _ink = AppColors.deepBlack;
  static const _muted = AppColors.midGray;

  @override
  Widget build(BuildContext context) {
    final formatted = '${faAmount(item.price)} تومان';

    return Dismissible(
      key: ObjectKey(item),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 22),
        decoration: BoxDecoration(
          color: AppColors.deepBlack,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.pureWhite),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 56,
                height: 56,
                color: AppColors.surfaceOnLight,
                child: const Icon(
                  Icons.fitness_center,
                  size: 22,
                  color: _muted,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatted,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: onAdd,
              customBorder: const CircleBorder(),
              child: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _ink,
                ),
                child: const Icon(
                  Icons.add,
                  size: 16,
                  color: AppColors.pureWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label});
  final String label;

  static const _muted = AppColors.midGray;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: TextStyle(
          color: _muted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
