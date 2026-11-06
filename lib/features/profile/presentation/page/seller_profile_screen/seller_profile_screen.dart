import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/animation/screen_entrance.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/profile/presentation/cubit/seller_profile_cubit.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/features/profile/presentation/widgets/seller_profile_screen_widgets/seller_profile_content/seller_profile_content.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/models/post/post_seller.dart';

class SellerProfileScreen extends StatelessWidget {
  const SellerProfileScreen({
    super.key,
    required this.seller,
    required this.posts,
    required this.onPostTap,
  });

  final PostSeller seller;
  final List<PostItem> posts;
  final ValueChanged<PostItem> onPostTap;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => SellerProfileCubit(),
    child: ScreenEntrance(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: AppStrings.back,
            onPressed: () => Navigator.of(context).pop(),
            icon: const AppIcon(AppIcons.back),
          ),
          title: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              seller.name,
              textAlign: TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.username,
            ),
          ),
          centerTitle: false,
        ),
        body: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                child: SellerProfileContent(
                  seller: seller,
                  posts: posts,
                  onPostTap: onPostTap,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
