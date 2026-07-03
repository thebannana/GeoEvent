import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event_directions_request.dart';

final pendingDirectionsProvider =
    StateProvider<EventDirectionsRequest?>((ref) => null);

final activeNavigationProvider =
    StateProvider<EventDirectionsRequest?>((ref) => null);