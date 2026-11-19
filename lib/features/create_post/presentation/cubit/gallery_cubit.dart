import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/features/create_post/data/gallery_media_preparer.dart';
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
    this.isPreparing = false,
    this.errorMessage,
    this.permission,
    this.loadMoreFailed = false,
  });

  final GalleryTab tab;
  final GalleryStatus status;
  final List<AssetEntity> assets;
  final List<GalleryAttachment> selected;

  final bool loadingMore;
  final bool hasMore;
  final bool isPickingFiles;
  final bool isPreparing;
  final String? errorMessage;
  final PermissionState? permission;
  final bool loadMoreFailed;
  bool get limitedAccess =>
      tab != GalleryTab.file && permission == PermissionState.limited;

  GalleryState copyWith({
    GalleryTab? tab,
    GalleryStatus? status,
    List<AssetEntity>? assets,
    List<GalleryAttachment>? selected,
    bool? loadingMore,
    bool? hasMore,
    bool? isPickingFiles,
    bool? isPreparing,
    String? errorMessage,
    PermissionState? permission,
    bool? loadMoreFailed,
  }) {
    return GalleryState(
      tab: tab ?? this.tab,
      status: status ?? this.status,
      assets: assets ?? this.assets,
      selected: selected ?? this.selected,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      isPickingFiles: isPickingFiles ?? this.isPickingFiles,
      isPreparing: isPreparing ?? this.isPreparing,
      errorMessage: errorMessage,
      permission: permission ?? this.permission,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    );
  }
}

class GalleryCubit extends Cubit<GalleryState> {
  GalleryCubit({
    GalleryMediaPreparer? mediaPreparer,
    Future<List<PlatformFile>> Function()? filePicker,
    Future<void> Function(RequestType)? limitedPicker,
  }) : _mediaPreparer = mediaPreparer ?? GalleryMediaPreparer(),
       _filePicker = filePicker ?? _pickDeviceFiles,
       _limitedPicker = limitedPicker ?? _presentLimited,
       super(const GalleryState());
  final Future<List<PlatformFile>> Function() _filePicker;
  final GalleryMediaPreparer _mediaPreparer;

  Future<List<GalleryAttachment>?> prepareSelection({
    bool forPost = false,
  }) async {
    if (state.isPreparing || state.isPickingFiles || state.selected.isEmpty) {
      return null;
    }
    emit(state.copyWith(isPreparing: true));
    try {
      final prepared = await _mediaPreparer.prepare(
        state.selected,
        forPost: forPost,
      );
      if (isClosed) return null;
      emit(state.copyWith(selected: prepared, isPreparing: false));
      return prepared;
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isPreparing: false,
            errorMessage: AppStrings.mediaUnavailable,
          ),
        );
      }
      return null;
    }
  }

  final Future<void> Function(RequestType) _limitedPicker;
  static Future<void> _presentLimited(RequestType type) =>
      PhotoManager.presentLimited(type: type);
  static Future<List<PlatformFile>> _pickDeviceFiles() =>
      FilePicker.pickFiles(type: FileType.any);

  static const int _pageSize = 60;

  AssetPathEntity? _album;
  int _nextPage = 0;
  int _totalAssets = 0;
  int _loadVersion = 0;
  bool _managingAccess = false, _refreshPending = false;

  RequestType _type(GalleryTab tab) =>
      tab == GalleryTab.video ? RequestType.video : RequestType.image;
  PermissionRequestOption _permissionOption(GalleryTab tab) =>
      PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: _type(tab),
          mediaLocation: false,
        ),
      );

  /// Returning from Settings must refresh without opening a permission dialog
  /// again. Files use their own picker and must never reopen on app resume.
  Future<void> refresh() async {
    if (isClosed || state.tab == GalleryTab.file || state.isPickingFiles) {
      return;
    }
    if (_managingAccess || state.status == GalleryStatus.loading) {
      _refreshPending = true;
      return;
    }
    await changeTab(state.tab, requestPermission: false);
  }

  Future<void> manageAccess() async {
    if (isClosed ||
        _managingAccess ||
        !state.limitedAccess ||
        state.status == GalleryStatus.loading) {
      return;
    }
    final tab = state.tab, version = _loadVersion;
    _managingAccess = true;
    try {
      await _limitedPicker(_type(tab));
    } catch (_) {
      if (!isClosed && version == _loadVersion) {
        emit(state.copyWith(errorMessage: AppStrings.galleryLoadFailed));
      }
    } finally {
      _managingAccess = false;
    }
    if (!isClosed && version == _loadVersion) await refresh();
  }

  Future<void> load() => changeTab(GalleryTab.photo);

  Future<void> changeTab(
    GalleryTab tab, {
    bool requestPermission = true,
  }) async {
    final version = ++_loadVersion;
    _refreshPending = false;

    _album = null;
    _nextPage = 0;
    _totalAssets = 0;

    if (tab == GalleryTab.file) {
      emit(
        state.copyWith(
          tab: tab,
          status: GalleryStatus.ready,
          assets: const [],
          hasMore: false,
          loadingMore: false,
          loadMoreFailed: false,
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
        loadMoreFailed: false,
      ),
    );

    try {
      final option = _permissionOption(tab);
      final permission = requestPermission
          ? await PhotoManager.requestPermissionExtend(requestOption: option)
          : await PhotoManager.getPermissionState(requestOption: option);

      if (isClosed || version != _loadVersion) return;

      emit(state.copyWith(permission: permission));

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

      final requestType = _type(tab);

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

      final album = _album!;
      final total = await album.assetCountAsync;
      if (isClosed || version != _loadVersion) return;
      final items = await album.getAssetListPaged(page: 0, size: _pageSize);

      if (isClosed || version != _loadVersion) return;

      _nextPage = 1;
      _totalAssets = total;

      emit(
        state.copyWith(
          status: GalleryStatus.ready,
          assets: items,
          hasMore: _nextPage * _pageSize < _totalAssets,
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
    } finally {
      if (!isClosed && version == _loadVersion && _refreshPending) {
        _refreshPending = false;
        await refresh();
      }
    }
  }

  Future<void> loadMore({bool retry = false}) async {
    if (state.status != GalleryStatus.ready ||
        state.loadingMore ||
        !state.hasMore ||
        (state.loadMoreFailed && !retry) ||
        _album == null) {
      return;
    }

    final version = _loadVersion;
    final album = _album!;

    emit(state.copyWith(loadingMore: true, loadMoreFailed: false));

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
          hasMore: _nextPage * _pageSize < _totalAssets,
          loadingMore: false,
        ),
      );
    } catch (_) {
      if (isClosed || version != _loadVersion) return;

      emit(state.copyWith(loadingMore: false, loadMoreFailed: true));
    }
  }

  void toggleSelection(AssetEntity asset) {
    if (state.isPreparing) return;
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
    if (state.isPreparing) return;
    final updated = state.selected
        .where((item) => item.id != attachment.id)
        .toList();

    emit(state.copyWith(selected: updated));
  }

  Future<void> pickFiles() async {
    if (state.isPickingFiles || state.isPreparing) return;

    emit(state.copyWith(isPickingFiles: true));

    try {
      // file_picker 13.x:
      // pickFiles already supports multiple selections.
      final files = await _filePicker();

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
