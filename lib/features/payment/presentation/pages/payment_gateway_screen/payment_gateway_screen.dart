import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

/// The supplied gateway design is an empty handoff page, not a bank form.
class PaymentGatewayScreen extends StatelessWidget {
  const PaymentGatewayScreen({super.key});

  @override
  Widget build(BuildContext context) => Localizations.override(
    context: context,
    locale: const Locale('en'),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            icon: const AppIcon(AppIcons.back, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const SafeArea(child: Center(child: Text('Payment Gateway'))),
      ),
    ),
  );
}
