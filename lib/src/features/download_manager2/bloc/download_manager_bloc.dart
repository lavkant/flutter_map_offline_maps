import 'package:flutter_map_offline_poc/src/core/bloc/base_bloc.dart';
import 'package:rxdart/rxdart.dart';

class DownloadManger2Bloc extends BaseBloc {
  // INITIALIZERS
  BehaviorSubject<bool> loadingController = BehaviorSubject.seeded(false);

  // METHODS

  // GETTER

  // SETTERS

  // DISPOSE

  @override
  dispose() {
    loadingController.close();
  }
}
