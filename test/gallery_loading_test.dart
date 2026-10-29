import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/theme/app_theme.dart';
import 'package:nini/features/chat/data/device_chat_camera.dart';
import 'package:nini/features/create_post/presentation/cubit/gallery_cubit.dart';
import 'package:nini/features/create_post/presentation/widgets/gallery_grid/gallery_grid.dart';
import 'package:image_picker/image_picker.dart';

const _channel = MethodChannel('com.fluttercandies/photo_manager');
Map<String, Object> _asset(int id, {int type = 1}) => {
  'id': '$type-$id',
  'type': type,
  'width': 100,
  'height': 100,
  'title': 'test.jpg',
};
Map<String, Object> _album(int count) => {
  'data': [
    {
      'id': 'all',
      'name': 'All',
      'isAll': true,
      'assetCount': count,
      'darwinAssetCollectionType': 2,
      'darwinAssetCollectionSubtype': 209,
    },
  ],
};

class _VisibleGallery extends GalleryCubit {
  int refreshes = 0, manages = 0;
  _VisibleGallery() {
    emit(
      const GalleryState(
        status: GalleryStatus.ready,
        permission: PermissionState.limited,
      ),
    );
  }
  @override
  Future<void> refresh() async {
    refreshes++;
  }

  @override
  Future<void> manageAccess() async {
    manages++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(_channel, null));

  test(
    'Photo permission does not require video permission on Android',
    () async {
      final requests = <int>[];
      messenger.setMockMethodCallHandler(_channel, (call) async {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        switch (call.method) {
          case 'requestPermissionExtend':
            final type = (args['androidPermission'] as Map)['type'] as int;
            requests.add(type);
            return (type == RequestType.image.value
                    ? PermissionState.authorized
                    : PermissionState.denied)
                .index;
          case 'getAssetPathList':
            expect(args['type'], RequestType.image.value);
            expect(args['onlyAll'], isTrue);
            return _album(1);
          case 'getAssetCountFromPath':
            return 1;
          case 'getAssetListPaged':
            return {
              'data': [_asset(0)],
            };
        }
        return null;
      });
      final cubit = GalleryCubit();
      await cubit.load();
      expect(cubit.state.assets.single.type, AssetType.image);
      cubit.toggleSelection(cubit.state.assets.single);
      await cubit.changeTab(GalleryTab.video);
      expect(cubit.state.status, GalleryStatus.denied);
      expect(cubit.state.selected, hasLength(1));
      expect(requests, [RequestType.image.value, RequestType.video.value]);
      await cubit.close();
    },
  );

  for (final permission in [
    PermissionState.authorized,
    PermissionState.limited,
  ]) {
    test('Video query uses only videos with $permission access', () async {
      messenger.setMockMethodCallHandler(_channel, (call) async {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        if (call.method == 'requestPermissionExtend') {
          expect(
            (args['androidPermission'] as Map)['type'],
            RequestType.video.value,
          );
          expect(args['iosAccessLevel'], IosAccessLevel.readWrite.index + 1);
          return permission.index;
        }
        if (call.method == 'getAssetPathList') {
          expect(args['type'], RequestType.video.value);
          return _album(1);
        }
        if (call.method == 'getAssetCountFromPath') return 1;
        if (call.method == 'getAssetListPaged') {
          expect(args['type'], RequestType.video.value);
          return {
            'data': [_asset(0, type: 2)],
          };
        }
        return null;
      });
      final cubit = GalleryCubit();
      await cubit.changeTab(GalleryTab.video);
      expect(cubit.state.assets.single.type, AssetType.video);
      expect(cubit.state.limitedAccess, permission == PermissionState.limited);
      await cubit.close();
    });
  }

  test('Limited empty selection can be managed and refreshed without another prompt', () async {
    var requests = 0, presents = 0, count = 0;
    messenger.setMockMethodCallHandler(_channel, (call) async {
      switch (call.method) {
        case 'requestPermissionExtend':
          requests++;
          return PermissionState.limited.index;
        case 'getPermissionState':
          return PermissionState.limited.index;
        case 'presentLimited':
          expect((call.arguments as Map)['type'], RequestType.image.value);
          presents++;
          count = 1;
          return null;
        case 'getAssetPathList':
          return _album(count);
        case 'getAssetCountFromPath':
          return count;
        case 'getAssetListPaged':
          return {
            'data': [_asset(0)],
          };
      }
      return null;
    });
    final cubit = GalleryCubit(
      limitedPicker: (type) async {
        expect(type, RequestType.image);
        presents++;
        count = 1;
      },
    );
    await cubit.load();
    expect(cubit.state.assets, isEmpty);
    expect(cubit.state.status, GalleryStatus.ready);
    expect(cubit.state.limitedAccess, isTrue);
    await cubit.manageAccess();
    expect(cubit.state.assets, hasLength(1));
    expect(requests, 1);
    expect(presents, 1);
    await cubit.close();
  });

  test(
    'Settings refresh observes new permission without prompting again',
    () async {
      var requests = 0;
      messenger.setMockMethodCallHandler(_channel, (call) async {
        switch (call.method) {
          case 'requestPermissionExtend':
            requests++;
            return PermissionState.denied.index;
          case 'getPermissionState':
            return PermissionState.authorized.index;
          case 'getAssetPathList':
            return _album(1);
          case 'getAssetCountFromPath':
            return 1;
          case 'getAssetListPaged':
            return {
              'data': [_asset(0)],
            };
        }
        return null;
      });
      final cubit = GalleryCubit();
      await cubit.load();
      expect(cubit.state.status, GalleryStatus.denied);
      await cubit.refresh();
      expect(cubit.state.assets, hasLength(1));
      expect(requests, 1);
      await cubit.close();
    },
  );

  test(
    'Permission changes during an in-flight load are refreshed afterwards',
    () async {
      final pending = Completer<int>();
      messenger.setMockMethodCallHandler(_channel, (call) async {
        switch (call.method) {
          case 'requestPermissionExtend':
            return pending.future;
          case 'getPermissionState':
            return PermissionState.authorized.index;
          case 'getAssetPathList':
            return _album(1);
          case 'getAssetCountFromPath':
            return 1;
          case 'getAssetListPaged':
            return {
              'data': [_asset(0)],
            };
        }
        return null;
      });
      final cubit = GalleryCubit();
      final loading = cubit.load();
      await cubit.refresh();
      pending.complete(PermissionState.denied.index);
      await loading;
      expect(cubit.state.status, GalleryStatus.ready);
      expect(cubit.state.assets, hasLength(1));
      await cubit.close();
    },
  );

  test(
    'Short pages do not hide remaining media; failed pagination can retry',
    () async {
      var fail = true, reads = 0;
      messenger.setMockMethodCallHandler(_channel, (call) async {
        switch (call.method) {
          case 'requestPermissionExtend':
            return PermissionState.authorized.index;
          case 'getAssetPathList':
            return _album(121);
          case 'getAssetCountFromPath':
            return 121;
          case 'getAssetListPaged':
            reads++;
            final page = (call.arguments as Map)['page'] as int;
            if (page == 1 && fail) {
              fail = false;
              throw PlatformException(code: 'temporary');
            }
            return {
              'data': List.generate(
                page == 0
                    ? 59
                    : page == 1
                    ? 60
                    : 1,
                (i) => _asset(page * 60 + i),
              ),
            };
        }
        return null;
      });
      final cubit = GalleryCubit();
      await cubit.load();
      expect(cubit.state.hasMore, isTrue);
      await cubit.loadMore();
      expect(cubit.state.loadMoreFailed, isTrue);
      final failedReads = reads;
      await cubit.loadMore();
      expect(reads, failedReads);
      await cubit.loadMore(retry: true);
      await cubit.loadMore();
      expect(cubit.state.assets, hasLength(120));
      expect(cubit.state.hasMore, isFalse);
      expect(cubit.state.loadMoreFailed, isFalse);
      await cubit.close();
    },
  );

  test('Late photo permission result cannot overwrite the video tab', () async {
    final pending = Completer<int>();
    messenger.setMockMethodCallHandler(_channel, (call) async {
      if (call.method == 'requestPermissionExtend') {
        final type =
            ((call.arguments as Map)['androidPermission'] as Map)['type'];
        return type == RequestType.image.value
            ? pending.future
            : PermissionState.authorized.index;
      }
      if (call.method == 'getAssetPathList') return _album(1);
      if (call.method == 'getAssetCountFromPath') return 1;
      if (call.method == 'getAssetListPaged') {
        return {
          'data': [_asset(0, type: 2)],
        };
      }
      return null;
    });
    final cubit = GalleryCubit();
    final photo = cubit.load();
    await cubit.changeTab(GalleryTab.video);
    pending.complete(PermissionState.authorized.index);
    await photo;
    expect(cubit.state.tab, GalleryTab.video);
    expect(cubit.state.assets.single.type, AssetType.video);
    await cubit.close();
  });

  test('File tab opens the file picker without photo permission and does not reopen on resume', () async {
    var calls = 0;
    final cubit = GalleryCubit(
      filePicker: () async {
        calls++;
        return calls == 1 ? [CameraPhotoFile(XFile('/tmp/example.pdf'))] : [];
      },
    );
    await cubit.changeTab(GalleryTab.file);
    await cubit.refresh();
    expect(calls, 1);
    expect(cubit.state.selected.single.file!.name, 'example.pdf');
    await cubit.pickFiles();
    expect(cubit.state.selected, hasLength(1));
    expect(cubit.state.isPickingFiles, isFalse);
    await cubit.close();
  });

  testWidgets(
    'File grid does not start native photo-library permission or notification calls',
    (tester) async {
      final calls = <String>[];
      messenger.setMockMethodCallHandler(_channel, (call) async {
        calls.add(call.method);
        return null;
      });
      final cubit = GalleryCubit(filePicker: () async => []);
      await cubit.changeTab(GalleryTab.file);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<GalleryCubit>.value(
            value: cubit,
            child: const Scaffold(body: GalleryGrid()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.filesPickerHelp), findsOneWidget);
      expect(calls, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await cubit.close();
    },
  );

  testWidgets(
    'Limited-access actions and automatic resume refresh appear in both gallery contexts',
    (tester) async {
      for (final compact in [false, true]) {
        final cubit = _VisibleGallery();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: BlocProvider<GalleryCubit>.value(
              value: cubit,
              child: Scaffold(
                body: SizedBox(
                  height: 350,
                  child: GalleryGrid(compact: compact),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.limitedGalleryAccess), findsOneWidget);
        await tester.tap(find.text(AppStrings.selectMoreMedia));
        await tester.pump();
        expect(cubit.manages, 1);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expect(cubit.refreshes, 1);
        await tester.pumpWidget(const SizedBox.shrink());
        await cubit.close();
      }
    },
  );
}
