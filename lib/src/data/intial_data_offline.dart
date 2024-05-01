import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const int tempMinZoom = 1;
const int tempMaxZoom = 7;

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
  LatLng(13.994575, 70.214843),
  LatLng(4.011303, 86.885141),
);
