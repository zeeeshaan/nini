import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:nini/core/localization/create_post_strings.dart';
import 'package:nini/features/create_post/data/device_address_geocoder.dart';
import 'package:nini/features/create_post/domain/services/address_geocoder.dart';

import '../../domain/models/post_options.dart';

class PostAddressState {
  const PostAddressState({
    required this.saved,
    this.selected,
    this.point,
    this.error,
    this.resolvingAddress = false,
  });
  final List<PostAddress> saved;
  final PostAddress? selected;
  final LatLng? point;
  final String? error;
  final bool resolvingAddress;
}

class PostAddressCubit extends Cubit<PostAddressState> {
  PostAddressCubit(
    PostAddress? initial,
    List<PostAddress> saved, {
    this._geocoder = const DeviceAddressGeocoder(),
  }) : super(
         PostAddressState(
           saved: List.unmodifiable(saved),
           selected: initial,
           point: initial == null
               ? null
               : LatLng(initial.latitude, initial.longitude),
         ),
       );
  final AddressGeocoder _geocoder;
  int _lookupVersion = 0;

  void pin(LatLng point) {
    _lookupVersion++;
    emit(
      PostAddressState(
        saved: state.saved,
        selected: state.selected,
        point: point,
      ),
    );
  }

  Future<String?> resolvePin(
    LatLng point, {
    required String languageCode,
  }) async {
    final version = ++_lookupVersion;
    emit(
      PostAddressState(
        saved: state.saved,
        selected: state.selected,
        point: point,
        resolvingAddress: true,
      ),
    );
    try {
      // Only the final tap in a quick sequence needs a native lookup.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (isClosed || version != _lookupVersion) return null;
      final address = await _geocoder
          .addressFromCoordinates(
            point.latitude,
            point.longitude,
            languageCode: languageCode,
          )
          .timeout(const Duration(seconds: 12));
      if (isClosed || version != _lookupVersion) return null;
      emit(
        PostAddressState(
          saved: state.saved,
          selected: state.selected,
          point: point,
          error: address == null ? CreatePostStrings.addressLookupFailed : null,
        ),
      );
      return address;
    } catch (_) {
      if (!isClosed && version == _lookupVersion) {
        emit(
          PostAddressState(
            saved: state.saved,
            selected: state.selected,
            point: point,
            error: CreatePostStrings.addressLookupFailed,
          ),
        );
      }
      return null;
    }
  }

  void select(PostAddress address) {
    _lookupVersion++;
    emit(
      PostAddressState(
        saved: state.saved,
        selected: address,
        point: LatLng(address.latitude, address.longitude),
      ),
    );
  }

  void clearError() {
    // Manual edits take priority over any outstanding lookup response.
    _lookupVersion++;
    if (state.error == null && !state.resolvingAddress) return;
    emit(
      PostAddressState(
        saved: state.saved,
        selected: state.selected,
        point: state.point,
      ),
    );
  }

  PostAddress? save(String text) {
    if (state.resolvingAddress) return null;
    if (text.trim().isEmpty || state.point == null) {
      emit(
        PostAddressState(
          saved: state.saved,
          selected: state.selected,
          point: state.point,
          error: text.trim().isEmpty
              ? CreatePostStrings.addressRequired
              : CreatePostStrings.addressPinRequired,
        ),
      );
      return null;
    }
    final address = PostAddress(
      address: text.trim(),
      latitude: state.point!.latitude,
      longitude: state.point!.longitude,
    );
    final saved = [...state.saved];
    final index = saved.indexWhere(
      (entry) => entry.address.toLowerCase() == address.address.toLowerCase(),
    );
    if (index < 0) {
      saved.add(address);
    } else {
      saved[index] = address;
    }
    emit(
      PostAddressState(
        saved: List.unmodifiable(saved),
        selected: address,
        point: state.point,
      ),
    );
    return address;
  }
}
