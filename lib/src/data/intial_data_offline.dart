import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const int tempMinZoom = 3;
const int tempMaxZoom = 10;

String _access_token = const String.fromEnvironment("ACCESS_TOKEN");
String _url = "https://api.mapbox.com/v4/captainfreshin.af8ixn72/1/0/0@2x.jpg90";
// String finalUrlForDownload = "https://api.mapbox.com/v4/captainfreshin.af8ixn72";
String finalUrlForDownload =
    "https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{y}/{x}?access_token=$_access_token";

getFinalUrl({required String url}) {
  return "$url?access_token=$_access_token";
  // return url;
}
// const name = "Temp";
// const estimatedTiles = 4000;

final LatLngBounds tempBound = LatLngBounds(
  // OLD REGION
  // LatLng(13.994575, 70.214843),
  // LatLng(4.011303, 86.885141),
  // NEW REGION
  // LatLng(2.6244, 63.4435),
  // LatLng(21.9238, 92.585),

  // TESTING MULTIPLE BASEMAP
  LatLng(3.8539, 52.006),
  LatLng(31.0418, 102.1124),

  //
  //
);

final LatLngBounds tempBound2 = LatLngBounds(
  // OLD REGION
  // LatLng(13.994575, 70.214843),
  // LatLng(4.011303, 86.885141),
  // NEW REGION
  // LatLng(2.6244, 63.4435),
  // LatLng(21.9238, 92.585),

  // TESTING FOR MULTIPLE BASEMAP

  LatLng(5.5124, 76.286),
  LatLng(10.0083, 82.1572),
);
