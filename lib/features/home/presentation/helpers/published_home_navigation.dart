import 'package:flutter/material.dart';
import 'package:nini/features/home/data/home_post_data.dart';
import 'package:nini/shared/models/post/post_item.dart';

import 'home_post_navigation.dart';

void openPublishedHomePost(BuildContext context, PostItem post) =>
    openHomePost(context, post, localPostSeller);

void openPublishedHomeSeller(BuildContext context, PostItem post) =>
    openHomeSeller(context, post, localPostSeller);
