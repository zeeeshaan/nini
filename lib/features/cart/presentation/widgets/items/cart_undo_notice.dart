// dart format width=100
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/strings/cart_strings.dart';
import 'package:nini/shared/cubits/countdown_cubit.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:nini/core/theme/app_text_styles.dart';

import '../../../domain/models/cart_removal.dart';
import '../../cubit/cart_cubit.dart';

class CartUndoNotice extends StatelessWidget {
  const CartUndoNotice({super.key, required this.removal});

  final CartRemoval removal;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final remaining = (removal.expiresAt.difference(DateTime.now()).inMilliseconds / 1000)
        .ceil()
        .clamp(1, CartCubit.undoDuration.inSeconds);
    return BlocProvider(
      create: (_) => CountdownCubit(remaining, startImmediately: true),
      child: Material(
        color: colors.inverseSurface,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: AppResponsiveBuilder(
            builder: (context, responsive) {
              final information = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    removal.item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.bodyEmphasis.copyWith(color: colors.onInverseSurface),
                    textDirection: TextDirection.ltr,
                  ),
                  Text(
                    CartStrings.removed,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.helper.copyWith(color: colors.onInverseSurface),
                    textDirection: TextDirection.ltr,
                  ),
                ],
              );
              final actions = Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => context.read<CartCubit>().undoRemove(removal.item.id),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.onInverseSurface,
                      textStyle: AppTextStyles.button.copyWith(
                        fontFamily: AppTextStyles.fontFamily,
                      ),
                    ),
                    child: const Text(
                      CartStrings.undo,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  BlocBuilder<CountdownCubit, CountdownState>(
                    builder: (context, state) => Text(
                      CartStrings.undoCountdown(state.seconds),
                      style: AppTextStyles.labelEmphasis.copyWith(color: colors.onInverseSurface),
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              );
              if (responsive.width < 320 || MediaQuery.textScalerOf(context).scale(16) > 20) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [information, const SizedBox(height: 4), actions],
                );
              }
              return Row(
                children: [
                  actions,
                  const SizedBox(width: 12),
                  Expanded(child: information),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
