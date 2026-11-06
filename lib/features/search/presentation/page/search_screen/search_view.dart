import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/search_strings.dart';

import 'package:nini/features/search/presentation/cubit/search_cubit.dart';
import 'package:nini/features/search/presentation/widgets/search_screen_widgets/search_content/search_content.dart';
import 'package:nini/features/search/presentation/widgets/search_screen_widgets/search_header/search_header.dart';

/// Connects the header's buttons to search state. The lists live in SearchContent.
class SearchView extends StatefulWidget {
  const SearchView({super.key, required this.active});

  final bool active;

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  SearchCubit get _search => context.read<SearchCubit>();

  @override
  void initState() {
    super.initState();
    _controller.text = SearchStrings.display(_search.state.query);
  }

  @override
  void didUpdateWidget(covariant SearchView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active) _focusNode.unfocus();
  }

  void _updateField(String query) {
    final text = SearchStrings.display(query);
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _submit(String query) {
    _search.submit(query);
    _updateField(_search.state.query);
    _focusNode.unfocus();
  }

  void _submitField() {
    _submit(_controller.text);
  }

  void _clearQuery() {
    _controller.clear();
    _search.editQuery('');
  }

  void _closeSearch() {
    _focusNode.unfocus();
    _search.closePanel();
    _updateField(_search.state.query);
  }

  void _selectCity(String city) {
    _search.selectCity(city);
    _updateField(_search.state.query);
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
                      onChanged: _search.editQuery,
                      onTap: _search.showSuggestions,
                      onSearch: _submitField,
                      onClear: _clearQuery,
                      onCityPressed: _toggleCities,
                    ),
                    Expanded(
                      child: SearchContent(
                        state: state,
                        onCitySelected: _selectCity,
                        onQuerySelected: _submit,
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
