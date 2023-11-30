import 'package:rxdart/subjects.dart';

class MapUIBloc {
  BehaviorSubject<bool> loadingController = BehaviorSubject.seeded(false);
  bool enableBathyMetry = false;

  void toggleBathyMetry() {
    loadingController.add(true);
    enableBathyMetry = !enableBathyMetry;
    loadingController.add(false);
  }
}

final MapUIBloc mapUIBloc = MapUIBloc();
