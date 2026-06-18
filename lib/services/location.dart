import 'package:geolocator/geolocator.dart';

Future<String> getLocation() async {
  Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best);
  String url =
      "https://www.google.com/maps/place/${position.latitude},${position.longitude}";
  return url;
}
