import 'package:flutter/material.dart';
import '../app_colors.dart';
import 'analytics_screen.dart';
import 'user_screen.dart';

/// Single service post: author, photo gallery, engagement, description,
/// feature table and a floating price / add-to-cart button.
class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  static const _features = [
    ('برند', 'اپل، سامسونگ، شیائومی'),
    ('مدل', 'آیفون ۱۵ پرو'),
    ('سال عرضه', '۲۰۲۴'),
    ('وضعیت', 'نو، کارکرده'),
    ('رنگ', 'مشکی، نقره‌ای، آبی'),
    ('جنس بدنه', 'آلومینیوم، شیشه، پلاستیک'),
    ('وزن', '۱۸۷ گرم'),
    ('ابعاد', '۱۴۶٫۶ × ۷۰٫۶ × ۷٫۸ میلی‌متر'),
    ('درجه ضدآب', 'آی‌پی ۶۸'),
    ('پردازنده', 'شش‌هسته‌ای ۳٫۷۸ گیگاهرتز'),
  ];

  bool _liked = false;
  bool _saved = false;

  void _addToCart() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('به سبد خرید اضافه شد')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const _Header(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 96),
                    children: [
                      const SizedBox(height: 18),
                      const _AuthorRow(),
                      const SizedBox(height: 10),
                      _Gallery(images: ProfileImages.works),
                      _EngagementRow(
                        liked: _liked,
                        saved: _saved,
                        onLike: () => setState(() => _liked = !_liked),
                        onSave: () => setState(() => _saved = !_saved),
                      ),
                      const _Description(),
                      const SizedBox(height: 26),
                      const _FeatureTable(rows: _features),
                    ],
                  ),
                ),
              ],
            ),
            PositionedDirectional(
              start: 18,
              bottom: 18,
              child: _PriceButton(price: '۸۵۶٬۰۰۰', onTap: _addToCart),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  static const _ink = AppColors.deepBlack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.chevron_left, color: _ink, size: 28),
          ),
          const Text(
            'پست',
            style: TextStyle(
              color: _ink,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow();

  static const _ink = AppColors.deepBlack;
  static const _muted = AppColors.midGray;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 4, 0),
      child: Row(
        children: [
          const ProfileAvatar(size: 30, ring: true),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'پایپ‌مستر',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'تهران، ایران',
                  style: TextStyle(
                    color: _muted.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<void>(
            tooltip: 'گزینه‌ها',
            color: AppColors.pureWhite,
            icon: const Icon(Icons.more_vert, color: _ink, size: 22),
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.insights_outlined, color: _ink, size: 20),
                    SizedBox(width: 10),
                    Text('آمار و تحلیل'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.images});
  final List<String> images;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1 / 1.08,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => Image.asset(
              widget.images[i],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const ColoredBox(
                color: AppColors.surfaceOnLight,
                child: Icon(
                  Icons.image_outlined,
                  color: AppColors.midGray,
                  size: 40,
                ),
              ),
            ),
          ),
          // Page indicator sits bottom-left, as in the design.
          Positioned(
            left: 12,
            bottom: 12,
            child: Row(
              textDirection: TextDirection.ltr,
              children: [
                for (var i = 0; i < widget.images.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.only(right: 4),
                    width: i == _page ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite.withValues(
                        alpha: i == _page ? 1 : 0.75,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.deepBlack.withValues(alpha: 0.25),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EngagementRow extends StatelessWidget {
  const _EngagementRow({
    required this.liked,
    required this.saved,
    required this.onLike,
    required this.onSave,
  });

  final bool liked;
  final bool saved;
  final VoidCallback onLike;
  final VoidCallback onSave;

  static const _ink = AppColors.deepBlack;
  static const _red = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Row(
        children: [
          _Stat(
            icon: liked ? Icons.favorite : Icons.favorite_border,
            color: liked ? _red : _ink,
            count: '۴۸ هزار',
            onTap: onLike,
          ),
          const _Stat(glyph: PaperPlaneIcon(size: 19), count: '۳۹۹'),
          const _Stat(icon: Icons.chat_bubble_outline, count: '۸۸۵'),
          _Stat(
            icon: saved ? Icons.bookmark : Icons.bookmark_border,
            count: saved ? '۷۸۳' : '۷۸۲',
            onTap: onSave,
          ),
          const Spacer(),
          const Text('۴٫۵', style: TextStyle(color: _ink, fontSize: 10)),
          const SizedBox(width: 2),
          const Icon(Icons.star_rounded, color: _ink, size: 22),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    this.icon,
    this.glyph,
    required this.count,
    this.color = AppColors.deepBlack,
    this.onTap,
  });

  final IconData? icon;
  final Widget? glyph;
  final String count;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: 12, top: 4, bottom: 4),
        child: Row(
          children: [
            glyph ?? Icon(icon, color: color, size: 21),
            const SizedBox(width: 3),
            Text(
              count,
              style: const TextStyle(color: AppColors.deepBlack, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _Description extends StatelessWidget {
  const _Description();

  static const _ink = AppColors.deepBlack;
  static const _body = TextStyle(color: _ink, fontSize: 12, height: 1.7);
  static const _label = TextStyle(
    color: _ink,
    fontSize: 12,
    height: 1.7,
    fontWeight: FontWeight.w700,
  );

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'عنوان: «تعمیر شیر آب چکه‌کن\nمثل یک حرفه‌ای!»',
            style: TextStyle(
              color: _ink,
              fontSize: 17,
              height: 1.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 14),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'پیشنهاد تصویر: ', style: _label),
                TextSpan(
                  text:
                      'عکسی از یک شیر آب در حال چکه کردن و یک لوله‌کش حرفه‌ای '
                      'با ابزار در دست، یا تصویر قبل و بعد از تعمیر.',
                ),
              ],
            ),
            style: _body,
          ),
          SizedBox(height: 14),
          Text('محتوا / کپشن:', style: _label),
          Text(
            '«از چکه‌ی مداوم شیر آب خسته شده‌اید؟ 💧 نگذارید نشتی‌های کوچک '
            'به مشکلات بزرگ تبدیل شوند! لوله‌کش‌های متخصص ما خدمات تعمیر '
            'شیر آب سریع، مطمئن و مقرون‌به‌صرفه را برای منازل و کسب‌وکارها '
            'ارائه می‌دهند. ما از ابزار و روش‌های حرفه‌ای استفاده می‌کنیم تا '
            'سیستم لوله‌کشی شما بی‌نقص کار کند.',
            style: _body,
          ),
          SizedBox(height: 12),
          _CheckItem('خدمات سریع و کارآمد'),
          _CheckItem('قیمت مناسب'),
          _CheckItem('لوله‌کش‌های باتجربه و دارای مجوز'),
          SizedBox(height: 12),
          Text(
            'همین امروز خدمات خود را رزرو کنید و با نشتی خداحافظی کنید! '
            'با شماره [شماره تلفن] تماس بگیرید یا از [لینک وب‌سایت] دیدن کنید.»',
            style: _body,
          ),
          SizedBox(height: 14),
          Text('هشتگ‌ها / کلیدواژه‌ها:', style: _label),
          Text(
            '#لوله_کشی #تعمیر_شیر_آب #رفع_نشتی #لوله_کش_اضطراری '
            '#تعمیر_لوله #نگهداری_منزل #لوله_کش_محلی',
            style: _body,
          ),
          SizedBox(height: 14),
          Text('دعوت به اقدام:', style: _label),
          Text(
            '«همین حالا با ما تماس بگیرید تا تعمیر شیر آب خود را زمان‌بندی '
            'کنید و از خانه‌ای بدون نشتی لذت ببرید!»',
            style: _body,
          ),
        ],
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  const _CheckItem(this.label);
  final String label;

  static const _green = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(3.5),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 12,
              color: AppColors.pureWhite,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.deepBlack, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTable extends StatelessWidget {
  const _FeatureTable({required this.rows});
  final List<(String, String)> rows;

  static const _ink = AppColors.deepBlack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ویژگی‌ها',
            style: TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          for (final (key, value) in rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      key,
                      style: const TextStyle(color: _ink, fontSize: 12.5),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(color: _ink, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PriceButton extends StatelessWidget {
  const _PriceButton({required this.price, required this.onTap});
  final String price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.deepBlack,
      borderRadius: BorderRadius.circular(999),
      elevation: 6,
      shadowColor: AppColors.deepBlack.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.pureWhite,
                size: 20,
              ),
              Container(
                width: 1,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: AppColors.pureWhite.withValues(alpha: 0.25),
              ),
              Text(
                price,
                style: const TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
