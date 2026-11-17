import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/features/profile_settings/presentation/cubit/user_profile_cubit.dart';
import 'package:nini/features/home/data/home_post_data.dart';
import 'package:nini/shared/models/post/post_item.dart';

import 'home_post_navigation.dart';

void openPublishedHomePost(
  BuildContext context,
  PostItem post, {
  VoidCallback? onOwnProfilePressed,
}) => openHomePost(
  context,
  post,
  context.read<UserProfileCubit?>()?.seller ?? localPostSeller,
  onOwnProfilePressed: onOwnProfilePressed,
);

void openPublishedHomeSeller(BuildContext context, PostItem post) =>
    openHomeSeller(
      context,
      post,
      context.read<UserProfileCubit?>()?.seller ?? localPostSeller,
    );
