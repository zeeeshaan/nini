import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hywork/features/post_analytics/data/post_analytics_repository.dart';
import 'package:hywork/features/post_analytics/domain/post_analytics.dart';

class PostAnalyticsState {
  const PostAnalyticsState({
    this.events = const [],
    this.storageError = false,
    this.loading = false,
  });
  final List<PostAnalyticsEvent> events;
  final bool storageError;
  final bool loading;
}

class PostAnalyticsCubit extends Cubit<PostAnalyticsState> {
  PostAnalyticsCubit(this.repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(const PostAnalyticsState());
  final PostAnalyticsRepository repository;
  final DateTime Function() _clock;
  Future<void>? _ready;
  Future<void> _queue = Future.value();
  int _sequence = 0;
  bool _historyReadable = true;
  Future<void> load() => _ready ??= _load();
  Future<void> _load() async {
    emit(
      PostAnalyticsState(
        events: state.events,
        storageError: state.storageError,
        loading: true,
      ),
    );
    try {
      final saved = await repository.load();
      if (!isClosed) emit(PostAnalyticsState(events: List.unmodifiable(saved)));
    } catch (_) {
      _historyReadable = false;
      if (!isClosed) {
        emit(PostAnalyticsState(events: state.events, storageError: true));
      }
    }
  }

  Future<void> record(
    String postId,
    AnalyticsEventType type, {
    double value = 1,
    String source = 'other',
  }) {
    final at = _clock();
    final event = PostAnalyticsEvent(
      id: '${at.microsecondsSinceEpoch}_${_sequence++}',
      postId: postId,
      type: type,
      at: at,
      value: value,
      source: source,
    );
    _queue = _queue.then((_) async {
      await load();
      if (isClosed) return;
      final events = List<PostAnalyticsEvent>.unmodifiable([
        ...state.events,
        event,
      ]);
      emit(
        PostAnalyticsState(events: events, storageError: state.storageError),
      );
      // Never overwrite an unreadable history with a new empty history.
      if (!_historyReadable) return;
      try {
        await repository.save(events);
        if (!isClosed && state.storageError) {
          emit(PostAnalyticsState(events: state.events));
        }
      } catch (_) {
        if (!isClosed) {
          emit(PostAnalyticsState(events: state.events, storageError: true));
        }
      }
    });
    return _queue;
  }

  List<PostAnalyticsEvent> eventsFor(String postId) =>
      state.events.where((event) => event.postId == postId).toList();
  Future<void> get pendingWrites => _queue;
}
