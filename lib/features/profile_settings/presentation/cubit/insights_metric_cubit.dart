import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/local_post_insights.dart';

class InsightsMetricCubit extends Cubit<InsightMetric> {
  InsightsMetricCubit() : super(InsightMetric.posts);
  void select(InsightMetric metric) => emit(metric);
}
