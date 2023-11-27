import 'package:flutter_map_offline_poc/src/core/bloc/base_bloc.dart';
import 'package:rxdart/rxdart.dart';

class OfflineMapBloc extends BaseBloc {
  // INITIALIZERS
  final BehaviorSubject<bool> _loadingController = BehaviorSubject<bool>.seeded(false);

  // GETTERS
  BehaviorSubject get loadingController => _loadingController;

  @override
  dispose() {
    // TODO: implement dispose

  }
}
