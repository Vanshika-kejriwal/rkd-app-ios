import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:device_info_plus/device_info_plus.dart'; // Add this to your pubspec.yaml

class Permitrequest {
  askLocationPermission() async {
    // await Permission.locationWhenInUse.isDenied.then((onValue) {
    //     if(onValue){
    //         Permission.locationWhenInUse.request();
    //     }

    // });
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await Geolocator.requestPermission();
    }
  }

  askNotificationPermission() async {
    await Permission.notification.isDenied.then((onValue) {
      if (onValue) {
        Permission.notification.request();
      }
    });
  }
}

Future<bool> requestStoragePermission() async {
  if (Platform.isAndroid) {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    // ANDROID 13 (API 33) AND ABOVE FIXED LOGIC:
    if (sdkInt >= 33) {
      // Android 13+ does not need ANY runtime permissions to save/write images 
      // using the scoped storage APIs utilized by the gal package.
      return true; 
    } else {
      // ANDROID 12 AND OLDER:
      // Older devices still require the standard storage permission popup dialog.
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  } else if (Platform.isIOS) {
    final status = await Permission.photos.request();
    return status.isGranted;
  }
  return false; 
}

