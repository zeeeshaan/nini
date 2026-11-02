import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/features/search/presentation/cubit/search_cubit.dart';

import 'search_view.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.active = true});

  final bool active;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider(
      create: (_) => SearchCubit(),
      child: SearchView(active: widget.active),
    );
  }
}
