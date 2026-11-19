import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/strings/search_strings.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/models/post/post_seller.dart';

import 'package:nini/features/search/presentation/cubit/search_cubit.dart';
import 'package:nini/features/search/presentation/widgets/common/search_content.dart';
import 'package:nini/features/search/presentation/widgets/header/search_header.dart';
import 'package:nini/features/posts/data/api_posts_repository.dart';
import 'package:nini/features/posts/presentation/cubit/backend_posts_cubit.dart';

/// Connects the header's buttons to search state. The lists live in SearchContent.
class SearchView extends StatefulWidget {
  const SearchView({
    super.key,
    required this.active,
    this.publishedServiceId,
    this.onPostSelected,
    this.emptyStateTextAlign = TextAlign.right,
  });

  final bool active;
  final TextAlign emptyStateTextAlign;
  final String? publishedServiceId;
  final void Function(PostItem post, PostSeller seller)? onPostSelected;

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  String? _requestedQuery;

  SearchCubit get _search => context.read<SearchCubit>();

  @override
  void initState() {
    super.initState();
    if (widget.publishedServiceId != null) _search.submit('');
    _controller.text = SearchStrings.display(_search.state.query);
    if (widget.active) _request(_search.state.submittedQuery);
  }

  @override
  void didUpdateWidget(covariant SearchView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.publishedServiceId != null &&
        widget.publishedServiceId != oldWidget.publishedServiceId) {
      _submit('');
    }
    if (!widget.active) {
      _focusNode.unfocus();
      _debounce?.cancel();
    }
    if (!oldWidget.active && widget.active)
      _request(_search.state.submittedQuery, refresh: true);
  }

  void _request(String query, {bool refresh = false}) {
    final results = context.read<BackendPostsCubit?>();
    final repository = context.read<ApiPostsRepository?>();
    final city = _search.state.citySelected ? _search.state.city : '';
    final searchQuery = [
      query.trim(),
      city,
    ].where((part) => part.isNotEmpty).join(' ');
    if (results == null ||
        repository == null ||
        (_requestedQuery == searchQuery && (!refresh || results.state.loading)))
      return;
    final preserve = refresh && _requestedQuery == searchQuery;
    _requestedQuery = searchQuery;
    results.refresh(
      preserve: preserve,
      load: (page) => searchQuery.isEmpty
          ? repository.loadFeed(page: page)
          : repository.search(query: searchQuery, page: page),
    );
  }

  void _editQuery(String query) {
    _search.editQuery(query);
    _debounce?.cancel();
    _requestedQuery = null;
    context.read<BackendPostsCubit?>()?.invalidate();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _request(query.trim());
    });
  }

  void _updateField(String query) {
    final text = SearchStrings.display(query);
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _submit(String query) {
    _debounce?.cancel();
    _search.submit(query);
    _request(_search.state.submittedQuery);
    _updateField(_search.state.query);
    _focusNode.unfocus();
  }

  void _submitField() {
    _submit(_controller.text);
  }

  void _clearQuery() {
    _controller.clear();
    _editQuery('');
  }

  void _closeSearch() {
    _focusNode.unfocus();
    _search.closePanel();
    _updateField(_search.state.query);
    _debounce?.cancel();
    _request(_search.state.submittedQuery);
  }

  void _selectCity(String city) {
    _debounce?.cancel();
    _search.selectCity(city);
    _updateField(_search.state.query);
    _request(_search.state.submittedQuery);
  }

  void _toggleCities() {
    _focusNode.unfocus();
    _search.toggleCities();
    if (_search.state.panel == SearchPanel.results) {
      _updateField(_search.state.query);
    }
  }

  void _onBack(bool didPop, Object? result) {
    if (!didPop && widget.active) _closeSearch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        final panelIsOpen = state.panel != SearchPanel.results;
        return PopScope(
          canPop: !widget.active || !panelIsOpen,
          onPopInvokedWithResult: _onBack,
          child: ColoredBox(
            color: Theme.of(context).colorScheme.surface,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  children: [
                    SearchHeader(
                      controller: _controller,
                      focusNode: _focusNode,
                      city: state.city,
                      showClose: panelIsOpen,
                      onClose: _closeSearch,
                      showClear:
                          state.panel == SearchPanel.suggestions &&
                          state.query.isNotEmpty,
                      onChanged: _editQuery,
                      onTap: _search.showSuggestions,
                      onSearch: _submitField,
                      onClear: _clearQuery,
                      onCityPressed: _toggleCities,
                    ),
                    Expanded(
                      child: SearchContent(
                        key: ValueKey(widget.publishedServiceId),
                        state: state,
                        onCitySelected: _selectCity,
                        onQuerySelected: _submit,
                        onPostSelected: widget.onPostSelected,
                        emptyStateTextAlign: widget.emptyStateTextAlign,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
