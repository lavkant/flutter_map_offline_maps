import 'package:rxdart/subjects.dart';

class MapUIBloc {
  BehaviorSubject<bool> loadingController = BehaviorSubject.seeded(false);
  bool enableBathyMetry = false;
  bool enableGrid = false;
  bool enableCustomMarkers = false;

  void toggleBathyMetry() {
    loadingController.add(true);
    enableBathyMetry = !enableBathyMetry;
    loadingController.add(false);
  }

  void toggleGrid() {
    loadingController.add(true);
    enableGrid = !enableGrid;
    loadingController.add(false);
  }

  void toggleCustomMarkers() {
    loadingController.add(true);
    enableCustomMarkers = !enableCustomMarkers;
    loadingController.add(false);
  }
}

final MapUIBloc mapUIBloc = MapUIBloc();
