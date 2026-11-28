import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/localization/strings/profile_post_strings.dart';
import 'package:hywork/features/create_post/cubit/create_post_cubit.dart';
import 'package:hywork/shared/models/post/post_attributes.dart';

import '../../helpers/post_editor_validation.dart';

class PostEditorLocationFields extends StatefulWidget {
  const PostEditorLocationFields({super.key});
  @override
  State<PostEditorLocationFields> createState() =>
      _PostEditorLocationFieldsState();
}

class _PostEditorLocationFieldsState extends State<PostEditorLocationFields> {
  late final _address = TextEditingController(
    text: context.read<CreatePostCubit>().state.address?.address ?? '',
  );
  late final _latitude = TextEditingController(
    text: _coordinate(context.read<CreatePostCubit>().state.address?.latitude),
  );
  late final _longitude = TextEditingController(
    text: _coordinate(context.read<CreatePostCubit>().state.address?.longitude),
  );
  late final String _initialAddress;
  late final String _initialLatitude;
  late final String _initialLongitude;
  @override
  void initState() {
    super.initState();
    _initialAddress = _address.text;
    _initialLatitude = _latitude.text;
    _initialLongitude = _longitude.text;
  }

  String _coordinate(double? value) =>
      value == null ? '' : AppStrings.persianDigits(value);
  bool get _empty => [
    _address,
    _latitude,
    _longitude,
  ].every((controller) => controller.text.trim().isEmpty);
  @override
  void dispose() {
    _address.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  String? _validate(String? _) {
    if (_empty) return null;
    if (_address.text.trim().isNotEmpty &&
        _latitude.text.trim().isEmpty &&
        _longitude.text.trim().isEmpty) {
      return null;
    }
    final latitude = PostEditorValidation.number(_latitude.text);
    final longitude = PostEditorValidation.number(_longitude.text);
    return _address.text.trim().isEmpty ||
            latitude == null ||
            !latitude.isFinite ||
            latitude < -90 ||
            latitude > 90 ||
            longitude == null ||
            !longitude.isFinite ||
            longitude < -180 ||
            longitude > 180
        ? ProfilePostStrings.invalidLocation
        : null;
  }

  void _save(String? _) {
    if (_address.text == _initialAddress &&
        _latitude.text == _initialLatitude &&
        _longitude.text == _initialLongitude)
      return;
    if (_validate(null) != null) {
      throw const FormatException('Enter a valid location.');
    }
    context.read<CreatePostCubit>().updateAddress(
      _empty
          ? null
          : PostAddress(
              address: _address.text.trim(),
              latitude: PostEditorValidation.number(_latitude.text),
              longitude: PostEditorValidation.number(_longitude.text),
              city: context.read<CreatePostCubit>().state.address?.city ?? '',
              province:
                  context.read<CreatePostCubit>().state.address?.province ?? '',
              postalCode:
                  context.read<CreatePostCubit>().state.address?.postalCode ??
                  '',
              buildingNumber:
                  context
                      .read<CreatePostCubit>()
                      .state
                      .address
                      ?.buildingNumber ??
                  '',
              unitNumber:
                  context.read<CreatePostCubit>().state.address?.unitNumber ??
                  '',
            ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Directionality(
        textDirection: TextDirection.rtl,
        child: TextFormField(
          controller: _address,
          decoration: const InputDecoration(
            labelText: ProfilePostStrings.address,
          ),
          validator: _validate,
          onSaved: _save,
          textAlign: TextAlign.right,
          textDirection: TextDirection.ltr,
        ),
      ),
      const SizedBox(height: 16),
      Directionality(
        textDirection: TextDirection.rtl,
        child: TextFormField(
          controller: _latitude,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          decoration: const InputDecoration(
            labelText: ProfilePostStrings.latitude,
          ),
          textAlign: TextAlign.right,
          textDirection: TextDirection.ltr,
        ),
      ),
      const SizedBox(height: 16),
      Directionality(
        textDirection: TextDirection.rtl,
        child: TextFormField(
          controller: _longitude,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          decoration: const InputDecoration(
            labelText: ProfilePostStrings.longitude,
          ),
          textAlign: TextAlign.right,
          textDirection: TextDirection.ltr,
        ),
      ),
    ],
  );
}
