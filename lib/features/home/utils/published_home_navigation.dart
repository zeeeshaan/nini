import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/features/profile_settings/presentation/cubit/user_profile_cubit.dart';
import 'package:hywork/features/home/data/home_post_data.dart';
import 'package:hywork/shared/models/post/post_item.dart';
import 'package:hywork/features/search/data/search_catalog.dart';

import 'home_post_navigation.dart';

void openPublishedHomePost(
  BuildContext context,
  PostItem post, {
  VoidCallback? onOwnProfilePressed,
}) => openHomePost(
  context,
  post,
  SearchCatalog.sellerFor(post) ??
      context.read<UserProfileCubit?>()?.seller ??
      localPostSeller,
  onOwnProfilePressed: onOwnProfilePressed,
);

void openPublishedHomeSeller(
  BuildContext context,
  PostItem post, {
  VoidCallback? onOwnProfilePressed,
}) => openHomeSeller(
  context,
  post,
  SearchCatalog.sellerFor(post) ??
      context.read<UserProfileCubit?>()?.seller ??
      localPostSeller,
  onOwnProfilePressed: onOwnProfilePressed,
);
