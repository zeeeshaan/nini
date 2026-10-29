import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';

enum GalleryTab { photo, video, file }

enum GalleryStatus { initial, loading, ready, denied, failure }

class GalleryState {
  const GalleryState({
    this.tab = GalleryTab.photo,
    this.status = GalleryStatus.initial,
    this.assets = const [],
    this.selected = const [],
    this.loadingMore = false,
    this.hasMore = false,
    this.isPickingFiles = false,
    this.errorMessage,
  });

  final GalleryTab tab;
  final GalleryStatus status;
  final List<AssetEntity> assets;
  final List<GalleryAttachment> selected;

  final bool loadingMore;
  final bool hasMore;
  final bool isPickingFiles;
  final String? errorMessage;

  GalleryState copyWith({
    GalleryTab? tab,
    GalleryStatus? status,
    List<AssetEntity>? assets,
    List<GalleryAttachment>? selected,
    bool? loadingMore,
    bool? hasMore,
    bool? isPickingFiles,
    String? errorMessage,
  }) {
    return GalleryState(
      tab: tab ?? this.tab,
      status: status ?? this.status,
      assets: assets ?? this.assets,
      selected: selected ?? this.selected,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      isPickingFiles: isPickingFiles ?? this.isPickingFiles,
      errorMessage: errorMessage,
    );
  }
}

class GalleryCubit extends Cubit<GalleryState> {
  GalleryCubit() : super(const GalleryState());

  static const int _pageSize = 60;

  AssetPathEntity? _album;
  int _nextPage = 0;
  int _loadVersion = 0;

  Future<void> load() => changeTab(GalleryTab.photo);

  Future<void> changeTab(GalleryTab tab) async {
    final version = ++_loadVersion;

    _album = null;
    _nextPage = 0;

    if (tab == GalleryTab.file) {
      emit(
        state.copyWith(
          tab: tab,
          status: GalleryStatus.ready,
          assets: const [],
          hasMore: false,
          loadingMore: false,
        ),
      );

      // Open Android's or iOS's native document picker.
      await pickFiles();
      return;
    }

    emit(
      state.copyWith(
        tab: tab,
        status: GalleryStatus.loading,
        assets: const [],
        hasMore: false,
        loadingMore: false,
      ),
    );

    try {
      final permission = await PhotoManager.requestPermissionExtend();

      if (isClosed || version != _loadVersion) return;

      if (!permission.hasAccess) {
        emit(
          state.copyWith(
            status: GalleryStatus.denied,
            assets: const [],
            hasMore: false,
          ),
        );
        return;
      }

      final requestType = tab == GalleryTab.photo
          ? RequestType.image
          : RequestType.video;

      final albums = await PhotoManager.getAssetPathList(
        type: requestType,
        onlyAll: true,
      );

      if (isClosed || version != _loadVersion) return;

      if (albums.isEmpty) {
        emit(
          state.copyWith(
            status: GalleryStatus.ready,
            assets: const [],
            hasMore: false,
          ),
        );
        return;
      }

      _album = albums.first;

      final items = await _album!.getAssetListPaged(page: 0, size: _pageSize);

      if (isClosed || version != _loadVersion) return;

      _nextPage = 1;

      emit(
        state.copyWith(
          status: GalleryStatus.ready,
          assets: items,
          hasMore: items.length == _pageSize,
          loadingMore: false,
        ),
      );
    } catch (_) {
      if (isClosed || version != _loadVersion) return;

      emit(
        state.copyWith(
          status: GalleryStatus.failure,
          errorMessage: AppStrings.yourGalleryLoadFailed,
          hasMore: false,
        ),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.status != GalleryStatus.ready ||
        state.loadingMore ||
        !state.hasMore ||
        _album == null) {
      return;
    }

    final version = _loadVersion;
    final album = _album!;

    emit(state.copyWith(loadingMore: true));

    try {
      final items = await album.getAssetListPaged(
        page: _nextPage,
        size: _pageSize,
      );

      if (isClosed || version != _loadVersion) return;

      _nextPage++;

      emit(
        state.copyWith(
          assets: [...state.assets, ...items],
          hasMore: items.length == _pageSize,
          loadingMore: false,
        ),
      );
    } catch (_) {
      if (isClosed || version != _loadVersion) return;

      emit(state.copyWith(loadingMore: false, hasMore: false));
    }
  }

  void toggleSelection(AssetEntity asset) {
    final attachment = GalleryAttachment.fromAsset(asset);

    final updated = List<GalleryAttachment>.of(state.selected);

    final index = updated.indexWhere((item) => item.id == attachment.id);

    if (index >= 0) {
      updated.removeAt(index);
    } else {
      updated.add(attachment);
    }

    emit(state.copyWith(selected: updated));
  }

  void removeAttachment(GalleryAttachment attachment) {
    final updated = state.selected
        .where((item) => item.id != attachment.id)
        .toList();

    emit(state.copyWith(selected: updated));
  }

  Future<void> pickFiles() async {
    if (state.isPickingFiles) return;

    emit(state.copyWith(isPickingFiles: true));

    try {
      // file_picker 13.x:
      // pickFiles already supports multiple selections.
      final files = await FilePicker.pickFiles(type: FileType.any);

      if (isClosed) return;

      final updated = List<GalleryAttachment>.of(state.selected);

      for (final file in files) {
        final attachment = GalleryAttachment.fromFile(file);

        final alreadySelected = updated.any((item) => item.id == attachment.id);

        if (!alreadySelected) {
          updated.add(attachment);
        }
      }

      emit(state.copyWith(selected: updated, isPickingFiles: false));
    } catch (_) {
      if (isClosed) return;

      emit(
        state.copyWith(
          isPickingFiles: false,
          errorMessage: AppStrings.filesSelectionFailed,
        ),
      );
    }
  }
}
