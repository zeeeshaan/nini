import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../app_colors.dart';
import 'post_details_screen.dart';

/// One thing the user picked for a new post: either an asset from the
/// device gallery or a file chosen through the system file picker.
class PickedMedia {
  PickedMedia.asset(AssetEntity this.asset) : file = null;
  PickedMedia.file(PlatformFile this.file) : asset = null;

  final AssetEntity? asset;
  final PlatformFile? file;

  String get id => asset != null ? 'a:${asset!.id}' : 'f:${file!.uri}';

  bool get isVideo => asset?.type == AssetType.video;

  /// Contents of a picked file, read once. On the web picked files have no
  /// path, so images are drawn from these bytes instead.
  late final Future<Uint8List> bytes = file!.xFile.readAsBytes();

  /// Picked files that are pictures can be previewed like gallery photos.
  bool get isImageFile =>
      file != null &&
      const {
        'jpg',
        'jpeg',
        'png',
        'webp',
        'gif',
        'heic',
      }.contains(file!.extension?.toLowerCase());

  @override
  bool operator ==(Object other) => other is PickedMedia && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

enum _Source { photo, video, file }

/// "Upload photo & video": a large preview on top, the device gallery as a
/// grid below and a floating Photo / Video / File switcher. The stacked-
/// squares button toggles multi-select; with several items picked the
/// preview becomes a grid of the selection.
/// "Next" opens [PostDetailsScreen]; the finished [PostDraft] is popped
/// back to the caller.
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  static const _pageSize = 60;

  /// The device gallery (photo_manager) only exists on mobile; in a browser
  /// everything comes through the system file picker.
  static const _hasGallery = !kIsWeb;

  _Source _source = _hasGallery ? _Source.photo : _Source.file;
  bool _multi = false;
  PermissionState? _permission;

  // Gallery paging for the current photo / video tab.
  AssetPathEntity? _album;
  final List<AssetEntity> _assets = [];
  int _page = 0;
  bool _loading = false;
  bool _hasMore = true;

  // Files added through the system picker (the "File" tab).
  final List<PickedMedia> _files = [];

  final List<PickedMedia> _selected = [];
  PickedMedia? _focused;

  @override
  void initState() {
    super.initState();
    _requestAccess();
  }

  Future<void> _requestAccess() async {
    if (!_hasGallery) return;
    final state = await PhotoManager.requestPermissionExtend();
    if (!mounted) return;
    setState(() => _permission = state);
    if (state.hasAccess) _reloadGallery();
  }

  Future<void> _reloadGallery() async {
    _assets.clear();
    _page = 0;
    _hasMore = true;
    _album = null;
    if (_source == _Source.file || !_hasGallery) {
      setState(() {});
      return;
    }
    final paths = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: _source == _Source.photo ? RequestType.image : RequestType.video,
    );
    if (!mounted) return;
    _album = paths.isEmpty ? null : paths.first;
    _hasMore = _album != null;
    await _loadMore();
  }

  Future<void> _loadMore() async {
    final album = _album;
    if (album == null || _loading || !_hasMore) return;
    setState(() => _loading = true);
    final source = _source;
    final page = await album.getAssetListPaged(page: _page, size: _pageSize);
    if (!mounted || source != _source || album != _album) return;
    setState(() {
      _assets.addAll(page);
      _page++;
      _hasMore = page.length == _pageSize;
      _loading = false;
      // Show the newest item in the preview until the user picks one.
      if (_focused == null && _assets.isNotEmpty && _selected.isEmpty) {
        _focused = PickedMedia.asset(_assets.first);
      }
    });
  }

  void _switchSource(_Source source) {
    if (source == _source) return;
    setState(() {
      _source = source;
      _loading = false;
    });
    if (_permission?.hasAccess ?? false) _reloadGallery();
  }

  void _toggleMulti() {
    setState(() {
      _multi = !_multi;
      if (!_multi && _selected.length > 1) {
        // Back to single-select: keep only the item in the preview.
        final keep = _focused != null && _selected.contains(_focused)
            ? _focused!
            : _selected.last;
        _selected
          ..clear()
          ..add(keep);
        _focused = keep;
      }
    });
  }

  void _onTileTap(PickedMedia item) {
    setState(() {
      if (!_multi) {
        _selected
          ..clear()
          ..add(item);
        _focused = item;
        return;
      }
      if (_selected.contains(item)) {
        _selected.remove(item);
        if (_focused == item) {
          _focused = _selected.isEmpty ? null : _selected.last;
        }
      } else {
        _selected.add(item);
        _focused = item;
      }
    });
  }

  /// First grid tile: opens the system picker filtered to the current tab.
  Future<void> _openSystemPicker() async {
    final picked = await FilePicker.pickFiles(
      type: switch (_source) {
        _Source.photo => FileType.image,
        _Source.video => FileType.video,
        _Source.file => FileType.any,
      },
    );
    if (!mounted || picked.isEmpty) return;
    final items = picked.map(PickedMedia.file).toList();
    setState(() {
      for (final item in items) {
        if (!_files.contains(item)) _files.insert(0, item);
      }
      // Picking several files at once switches to multi-select.
      if (items.length > 1) _multi = true;
      if (!_multi) _selected.clear();
      for (final item in items) {
        if (!_selected.contains(item)) _selected.add(item);
      }
      _focused = items.last;
    });
  }

  Future<void> _next() async {
    if (_selected.isEmpty) return;
    final draft = await Navigator.of(context).push<PostDraft>(
      MaterialPageRoute(
        builder: (_) => PostDetailsScreen(media: List.of(_selected)),
      ),
    );
    if (draft != null && mounted) Navigator.of(context).pop(draft);
  }

  List<PickedMedia> get _gridItems => _source == _Source.file || !_hasGallery
      ? _files
      : [for (final a in _assets) PickedMedia.asset(a)];

  @override
  Widget build(BuildContext context) {
    final showSelectionGrid = _multi && _selected.length > 1;
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(enabled: _selected.isNotEmpty, onNext: _next),
            Expanded(
              flex: 11,
              child: showSelectionGrid
                  ? _SelectionGrid(items: _selected)
                  : _Preview(item: _focused),
            ),
            Expanded(
              flex: 9,
              child: ColoredBox(
                color: AppColors.surfaceOnLight,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        _GridToolbar(multi: _multi, onToggle: _toggleMulti),
                        Expanded(child: _buildGrid()),
                      ],
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 14,
                      child: Center(
                        child: _SourceSwitcher(
                          value: _source,
                          onChanged: _switchSource,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final permission = _permission;
    if (_source != _Source.file && _hasGallery) {
      if (permission == null) {
        return const Center(child: _Spinner());
      }
      if (!permission.hasAccess) {
        return _NoAccess(onOpenSettings: PhotoManager.openSetting);
      }
    }

    final items = _gridItems;
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels > n.metrics.maxScrollExtent - 400) _loadMore();
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: 72),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 1,
          crossAxisSpacing: 1,
        ),
        itemCount: items.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) return _PickerTile(onTap: _openSystemPicker);
          final item = items[i - 1];
          return _MediaTile(
            item: item,
            selected: _selected.contains(item),
            focused: _focused == item,
            onTap: () => _onTileTap(item),
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.enabled, required this.onNext});

  final bool enabled;
  final VoidCallback onNext;

  static const _ink = AppColors.deepBlack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close, color: _ink, size: 24),
          ),
          const Spacer(),
          TextButton(
            onPressed: enabled ? onNext : null,
            style: TextButton.styleFrom(
              foregroundColor: _ink,
              disabledForegroundColor: AppColors.midGray,
            ),
            child: const Text(
              'بعدی',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Large view of the focused item, or a placeholder when nothing is picked.
class _Preview extends StatelessWidget {
  const _Preview({required this.item});

  final PickedMedia? item;

  @override
  Widget build(BuildContext context) {
    final item = this.item;
    if (item == null) {
      return const Center(
        child: Icon(
          Icons.photo_library_outlined,
          size: 120,
          color: AppColors.divider,
        ),
      );
    }
    return ColoredBox(
      color: AppColors.pureWhite,
      child: PickedMediaView(item: item, size: 1080, fit: BoxFit.contain),
    );
  }
}

/// Multi-select preview: every selected item as a 3-column grid.
class _SelectionGrid extends StatelessWidget {
  const _SelectionGrid({required this.items});

  final List<PickedMedia> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => ColoredBox(
        color: AppColors.surfaceOnLight,
        child: PickedMediaView(item: items[i], size: 360, fit: BoxFit.cover),
      ),
    );
  }
}

class _GridToolbar extends StatelessWidget {
  const _GridToolbar({required this.multi, required this.onToggle});

  final bool multi;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: InkResponse(
            onTap: onToggle,
            radius: 18,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: multi ? AppColors.deepBlack : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.filter_none,
                size: 13,
                color: multi ? AppColors.pureWhite : AppColors.deepBlack,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceOnLight,
      child: InkWell(
        onTap: onTap,
        child: const Center(
          child: Icon(
            Icons.add_photo_alternate_outlined,
            color: AppColors.midGray,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.item,
    required this.selected,
    required this.focused,
    required this.onTap,
  });

  final PickedMedia item;
  final bool selected;
  final bool focused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: AppColors.pureWhite,
            child: PickedMediaView(item: item, size: 240, fit: BoxFit.cover),
          ),
          if (focused)
            ColoredBox(color: AppColors.pureWhite.withValues(alpha: 0.35)),
          if (item.isVideo)
            PositionedDirectional(
              start: 4,
              bottom: 3,
              child: _Duration(seconds: item.asset!.duration),
            ),
          if (selected)
            const PositionedDirectional(top: 5, end: 5, child: _CheckBadge()),
        ],
      ),
    );
  }
}

class _CheckBadge extends StatelessWidget {
  const _CheckBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        color: AppColors.deepBlack,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, color: AppColors.pureWhite, size: 12),
    );
  }
}

class _Duration extends StatelessWidget {
  const _Duration({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return Text(
      '$m:$s',
      textDirection: TextDirection.ltr,
      style: const TextStyle(
        color: AppColors.pureWhite,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        shadows: [Shadow(blurRadius: 3, color: Color(0x99000000))],
      ),
    );
  }
}

/// Draws any [PickedMedia]: gallery thumbnails, picked image files, or a
/// document tile with the file extension for everything else.
class PickedMediaView extends StatelessWidget {
  const PickedMediaView({
    super.key,
    required this.item,
    required this.size,
    required this.fit,
  });

  final PickedMedia item;
  final int size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final asset = item.asset;
    if (asset != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _AssetThumb(asset: asset, size: size, fit: fit),
          if (asset.type == AssetType.video && size > 300)
            const Center(child: _PlayBadge()),
        ],
      );
    }
    final path = item.file!.path;
    final badge = _FileBadge(extension: item.file!.extension);
    if (item.isImageFile && path != null) {
      return Image.file(
        File(path),
        fit: fit,
        cacheWidth: size,
        errorBuilder: (_, _, _) => badge,
      );
    }
    if (item.isImageFile) {
      return FutureBuilder<Uint8List>(
        future: item.bytes,
        builder: (_, snap) {
          final data = snap.data;
          if (snap.hasError) return badge;
          if (data == null) {
            return const ColoredBox(color: AppColors.surfaceOnLight);
          }
          return Image.memory(
            data,
            fit: fit,
            cacheWidth: size,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => badge,
          );
        },
      );
    }
    return _FileBadge(extension: item.file!.extension);
  }
}

class _AssetThumb extends StatefulWidget {
  const _AssetThumb({
    required this.asset,
    required this.size,
    required this.fit,
  });

  final AssetEntity asset;
  final int size;
  final BoxFit fit;

  @override
  State<_AssetThumb> createState() => _AssetThumbState();
}

class _AssetThumbState extends State<_AssetThumb> {
  late Future<Uint8List?> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = _load();
  }

  @override
  void didUpdateWidget(_AssetThumb old) {
    super.didUpdateWidget(old);
    if (old.asset.id != widget.asset.id || old.size != widget.size) {
      _bytes = _load();
    }
  }

  Future<Uint8List?> _load() => widget.asset.thumbnailDataWithSize(
    ThumbnailSize.square(widget.size),
    quality: 85,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _bytes,
      builder: (_, snap) {
        final data = snap.data;
        if (data == null) {
          return const ColoredBox(color: AppColors.surfaceOnLight);
        }
        return Image.memory(data, fit: widget.fit, gaplessPlayback: true);
      },
    );
  }
}

class _PlayBadge extends StatelessWidget {
  const _PlayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.deepBlack.withValues(alpha: 0.55),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.play_arrow_rounded,
        color: AppColors.pureWhite,
        size: 34,
      ),
    );
  }
}

class _FileBadge extends StatelessWidget {
  const _FileBadge({required this.extension});

  final String? extension;

  /// File-type icons are the one place the design uses color: purple for
  /// video files, red for PDFs. Everything else stays black.
  static Color _colorFor(String? ext) => switch (ext?.toLowerCase()) {
    'mkv' ||
    'mp4' ||
    'mov' ||
    'avi' ||
    'webm' ||
    'm4v' => const Color(0xFFB45CE0),
    'pdf' => const Color(0xFFE5484D),
    _ => AppColors.deepBlack,
  };

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.pureWhite,
      child: Center(
        child: SizedBox(
          width: 44,
          height: 54,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.insert_drive_file,
                color: _colorFor(extension),
                size: 54,
              ),
              Positioned(
                bottom: 12,
                child: Text(
                  (extension ?? 'FILE').toUpperCase(),
                  maxLines: 1,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoAccess extends StatelessWidget {
  const _NoAccess({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'برای انتخاب عکس و ویدیو، دسترسی به گالری را فعال کنید.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.deepBlack, fontSize: 13),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onOpenSettings,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.deepBlack,
              side: const BorderSide(color: AppColors.deepBlack),
            ),
            child: const Text('باز کردن تنظیمات'),
          ),
        ],
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppColors.deepBlack,
      ),
    );
  }
}

/// Floating black pill: Photo / Video / File.
class _SourceSwitcher extends StatelessWidget {
  const _SourceSwitcher({required this.value, required this.onChanged});

  final _Source value;
  final ValueChanged<_Source> onChanged;

  static const _labels = {
    _Source.photo: 'عکس',
    _Source.video: 'ویدیو',
    _Source.file: 'فایل',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.deepBlack,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in _labels.entries)
            InkWell(
              onTap: () => onChanged(entry.key),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Center(
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: entry.key == value
                          ? AppColors.pureWhite
                          : AppColors.midGray,
                      fontSize: 13,
                      fontWeight: entry.key == value
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
