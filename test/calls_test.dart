import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/theme/app_theme.dart';
import 'package:nini/features/calls/data/preview_call_service.dart';
import 'package:nini/features/calls/domain/models/call_session.dart';
import 'package:nini/features/calls/presentation/cubit/call_cubit.dart';
import 'package:nini/features/calls/presentation/pages/call_screen.dart';
import 'package:nini/features/chat/data/in_memory_chat_repository.dart';
import 'package:nini/features/chat/domain/models/chat_conversation.dart';
import 'package:nini/features/chat/presentation/pages/conversation_screen.dart';

import 'support/chat_fakes.dart';

ChatConversation get _contact => ChatConversation(
  id: 'call-contact',
  name: 'Dr.Manify',
  lastMessage: '',
  lastMessageAt: DateTime(2026),
);

void main() {
  test(
    'Preview starts ringing, accepts, toggles controls and ends permanently',
    () async {
      final service = PreviewCallService();
      final cubit = CallCubit(service);
      await cubit.start('contact', CallType.voice);
      expect(cubit.state.session.phase, CallPhase.ringing);
      expect(cubit.state.session.connectedAt, isNull);
      await cubit.accept();
      expect(cubit.state.session.phase, CallPhase.connected);
      await cubit.toggleMicrophone();
      await cubit.toggleSpeaker();
      expect(cubit.state.session.microphoneMuted, isTrue);
      expect(cubit.state.session.speakerEnabled, isTrue);
      await cubit.end();
      await cubit.accept();
      expect(cubit.state.session.phase, CallPhase.ended);
      await cubit.close();
    },
  );

  for (final dark in [false, true]) {
    for (final width in [320.0, 390.0]) {
      testWidgets('Call flows at width $width, dark=$dark', (tester) async {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: ConversationScreen(
              conversation: _contact,
              repository: InMemoryChatRepository.empty(),
              voiceRecorder: FakeVoiceRecorder(),
              audioPlayer: FakeChatAudioPlayer(),
              mediaStore: FakeChatMediaStore(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        // A text draft must survive returning from the call screen.
        await tester.enterText(find.byType(TextField).first, 'draft');
        await tester.tap(find.byTooltip(AppStrings.audioCall));
        await tester.pumpAndSettle();
        expect(find.byType(CallScreen), findsOneWidget);
        expect(find.text(AppStrings.incomingCall), findsOneWidget);
        expect(find.text('Dr.Manify'), findsWidgets);
        await tester.tap(find.byTooltip(AppStrings.answerCall));
        await tester.pump();
        expect(find.text(AppStrings.incomingCall), findsNothing);
        expect(find.text(AppStrings.chatTime(Duration.zero)), findsOneWidget);
        await tester.tap(find.byTooltip(AppStrings.muteCall));
        await tester.pump();
        expect(find.byTooltip(AppStrings.unmuteCall), findsOneWidget);
        await tester.tap(find.byTooltip(AppStrings.speakerOn));
        await tester.pump();
        expect(find.byTooltip(AppStrings.speakerOff), findsOneWidget);
        await tester.tap(find.byTooltip(AppStrings.endCall));
        await tester.pumpAndSettle();
        expect(find.byType(CallScreen), findsNothing);
        expect(find.text('draft'), findsOneWidget);

        await tester.tap(find.byTooltip(AppStrings.videoCall));
        await tester.pumpAndSettle();
        expect(find.byType(CallScreen), findsOneWidget);
        expect(find.text(AppStrings.frontCamera), findsOneWidget);
        await tester.tap(find.byTooltip(AppStrings.turnCameraOff));
        await tester.pump();
        expect(find.text(AppStrings.cameraOff), findsOneWidget);
        await tester.tap(find.byTooltip(AppStrings.turnCameraOn));
        await tester.pump();
        await tester.tap(find.byTooltip(AppStrings.switchCamera).first);
        await tester.pump();
        expect(find.text(AppStrings.rearCamera), findsOneWidget);
        await tester.tap(find.byTooltip(AppStrings.showCallOptions));
        await tester.pump();
        final toggle = find.byType(SwitchListTile);
        expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
        await tester.tap(toggle);
        await tester.pump();
        expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
        // Android back closes the preview and releases its timer.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(CallScreen), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      });
    }
  }

  testWidgets('Timer advances after answer and releases on end', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CallScreen(
                    conversation: _contact,
                    type: CallType.voice,
                    clock: tester.binding.clock.now,
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(AppStrings.answerCall));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(
      find.text(AppStrings.chatTime(const Duration(seconds: 2))),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip(AppStrings.endCall));
    await tester.pumpAndSettle();
  });

  testWidgets('Decline and message actions return to the conversation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      CallScreen(conversation: _contact, type: CallType.voice),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    for (final action in [AppStrings.declineCall, AppStrings.returnToChat]) {
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(action));
      await tester.pumpAndSettle();
      expect(find.byType(CallScreen), findsNothing);
    }
  });
}
