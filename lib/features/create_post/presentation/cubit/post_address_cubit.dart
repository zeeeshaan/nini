import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:nini/core/localization/create_post_strings.dart';

import '../../domain/models/post_options.dart';

class PostAddressState {
  const PostAddressState({
    required this.saved,
    this.selected,
    this.point,
    this.error,
  });
  final List<PostAddress> saved;
  final PostAddress? selected;
  final LatLng? point;
  final String? error;
}

class PostAddressCubit extends Cubit<PostAddressState> {
  PostAddressCubit(PostAddress? initial, List<PostAddress> saved)
    : super(
        PostAddressState(
          saved: List.unmodifiable(saved),
          selected: initial,
          point: initial == null
              ? null
              : LatLng(initial.latitude, initial.longitude),
        ),
      );
  void pin(LatLng point) => emit(
    PostAddressState(
      saved: state.saved,
      selected: state.selected,
      point: point,
    ),
  );
  void select(PostAddress address) => emit(
    PostAddressState(
      saved: state.saved,
      selected: address,
      point: LatLng(address.latitude, address.longitude),
    ),
  );
  PostAddress? save(String text) {
    if (text.trim().isEmpty || state.point == null) {
      emit(
        PostAddressState(
          saved: state.saved,
          selected: state.selected,
          point: state.point,
          error: CreatePostStrings.addressPinRequired,
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
