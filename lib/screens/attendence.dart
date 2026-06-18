import 'dart:convert';
import 'dart:io';

// import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:business_app/constants.dart';
import 'package:business_app/services/location.dart';
import 'package:business_app/widgets/input_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:business_app/widgets/background.dart';
// import 'package:image_picker/image_picker.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class Attendence extends StatefulWidget {
  const Attendence({super.key});

  @override
  State<Attendence> createState() => _AttendenceState();
}

class _AttendenceState extends State<Attendence> with TickerProviderStateMixin {
  final _commentcontroller = TextEditingController();
  final _formkey = GlobalKey<FormState>();
  final TextEditingController _kmController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    TabController tabController = TabController(length: 2, vsync: this);
    return Background(
      appbaractions: const [],
      appbar: true,
      appbartitle: const Text("Attendence"),
      childs: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(
                child: Text("Present"),
              ),
              Tab(
                child: Text("Absent"),
              ),
            ],
            controller: tabController,
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (_isLoading)
                        const Center(
                            child:
                                CircularProgressIndicator(color: Colors.brown)),
                      ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : (() async {
                                  var sharedpref =
                                      await SharedPreferences.getInstance();
                                  var loggedinmob =
                                      sharedpref.getString("Mobile");
                                  var loggedinname =
                                      sharedpref.getString("NAME");
                                  await openDialog(
                                      "Checkin KM Detail", "Enter KM Value");
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  if (kDebugMode) {
                                    print(_selectedImage);
                                  }
                                  if (kDebugMode) {
                                    print(_kmController.text);
                                  }
                                  var request = http.MultipartRequest(
                                      "POST",
                                      Uri.parse(
                                          '$baseuri/api/present-checkin/'));
                                  request.fields["NAME"] = loggedinname!;
                                  request.fields["MOBILE"] = loggedinmob!;
                                  request.fields["P_A"] = "P";
                                  request.fields["CHECKIN_LOCA"] =
                                      await getLocation();
                                  request.fields["CHECKIN_KM"] =
                                      _kmController.text;
                                  if (_selectedImage != null) {
                                    var multipart =
                                        await http.MultipartFile.fromPath(
                                            "KM_PIC", _selectedImage!.path,
                                            filename: p.basename(
                                                _selectedImage!.path));
                                    request.files.add(multipart);
                                  }
                                  final resp = await request.send();
                                  if (resp.statusCode == 200 ||
                                      resp.statusCode == 201) {
                                    QuickAlert.show(
                              context: context,
                              type: QuickAlertType.success,
                            title: "Attendence Checkin marked",
                            text: "Your Attendence has been marked as Present");
                                  } else {
                                    if (resp.statusCode ==409) {
                                      final respbody = await resp.stream.bytesToString();
                                      final body = json.decode(respbody);
                                    //   AwesomeDialog(
                                    //   context: context,
                                    //   dialogType: DialogType.info,
                                    //   animType: AnimType.rightSlide,
                                    //   headerAnimationLoop: false,
                                    //   title: 'Checkin Not Marked',
                                    //   desc:
                                    //       'You have already checked in at ${body['checkin_time'].toString()}',
                                    //   btnOkOnPress: () {},
                                    //   btnOkIcon: Icons.cancel,
                                    //   btnOkColor: Colors.blue,
                                    // ).show();
                                    QuickAlert.show(
                              context: context,
                              type: QuickAlertType.info,
                            title: "Checkin Not Marked",
                            text: "You have already checked in at ${body['checkin_time'].toString()}");
                                    }else{
                                    QuickAlert.show(
                              context: context,
                              type: QuickAlertType.error,
                            title: "Attendence Not Marked",
                            text: "Something went wrong. Please try again.");
                                    }
                                  }
                                  setState(() {
                                    _isLoading = false;
                                    _selectedImage = null;
                                    _kmController.text = '';
                                  });
                                }),
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromRGBO(252, 101, 8, 1),
                              foregroundColor: Colors.white),
                          child: const Text("Check In")),
                      ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : (() async {
                                  var sharedpref =
                                      await SharedPreferences.getInstance();
                                  var loggedinmob =
                                      sharedpref.getString("Mobile");
                                  var loggedinname =
                                      sharedpref.getString("NAME");
                                  await openDialog(
                                      "Checkout KM Detail", "Enter KM Value");
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  if (kDebugMode) {
                                    print(_selectedImage);
                                  }
                                  if (kDebugMode) {
                                    print(_kmController.text);
                                  }
                                  var request = http.MultipartRequest(
                                      "POST",
                                      Uri.parse(
                                          '$baseuri/api/present-checkout/'));
                                  request.fields["NAME"] = loggedinname!;
                                  request.fields["MOBILE"] = loggedinmob!;
                                  // request.fields["P_A"] = "P";
                                  request.fields["CHECKOUT_LOCA"] =
                                      await getLocation();
                                  request.fields["CHECKOUT_KM"] =
                                      _kmController.text;
                                  if (_selectedImage != null) {
                                    var multipart =
                                        await http.MultipartFile.fromPath(
                                            "KM_PIC", _selectedImage!.path,
                                            filename: p.basename(
                                                _selectedImage!.path));
                                    request.files.add(multipart);
                                  }
                                  final resp = await request.send();
                                  // print(resp.statusCode);
                                  if (resp.statusCode == 200 ||
                                      resp.statusCode == 201) {
                                    QuickAlert.show(
                              context: context,
                              type: QuickAlertType.success,
                            title: "Attendence Checkout Marked",
                            text: "Your Attendence has been marked as Present");
                                  } else {
                                    if(resp.statusCode==404){
                                     QuickAlert.show(
                              context: context,
                              type: QuickAlertType.info,
                            title: "Checkout Not Marked",
                            text: "You have not checked in. Please checkin first");
                                    }else{
                                      QuickAlert.show(
                              context: context,
                              type: QuickAlertType.error,
                            title: "Checkout Not Marked",
                            text: "Something went wrong. Please try again.");
                                    }
                                  }
                                  setState(() {
                                    _isLoading = false;
                                    _selectedImage = null;
                                    _kmController.text = '';
                                  });
                                }),
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromRGBO(252, 101, 8, 1),
                              foregroundColor: Colors.white),
                          child: const Text("Check Out"))
                    ],
                  ),
                ),
                Form(
                  key: _formkey,
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          InputField(
                            controller: _commentcontroller,
                            label: "Reason",
                            maxlines: 10,
                            minlines: 1,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Please Give Reason";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          if (_isLoading)
                            const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.brown)),
                          const SizedBox(
                            height: 10,
                          ),
                          ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : (() async {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      var sharedpref =
                                          await SharedPreferences.getInstance();
                                      var loggedinmob =
                                          sharedpref.getString("Mobile");
                                      var loggedinname =
                                          sharedpref.getString("NAME");
                                      final Map<String, dynamic> data = {
                                        "NAME": loggedinname,
                                        "MOBILE": loggedinmob,
                                        "P_A": "A",
                                        "CHECKIN_LOCA": await getLocation(),
                                        "CHECKIN_KMPIC_LINK":
                                            _commentcontroller.text
                                      };
                                      final resp = await http.post(
                                          Uri.parse(
                                              '$baseuri/api/mark-absent/'),
                                          body: data);
                                      if (resp.statusCode == 200 ||
                                          resp.statusCode == 201) {
                                        QuickAlert.show(
                              context: context,
                              type: QuickAlertType.success,
                            title: "Attendence Marked",
                            text: "Your Attendence has been marked as Absent.");
                                      } else {
                                        QuickAlert.show(
                              context: context,
                              type: QuickAlertType.info,
                            title: "Attendence Not Marked",
                            text: "Something went wrong. Please try again.");
                                      }
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    }),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromRGBO(252, 101, 8, 1),
                                  foregroundColor: Colors.white),
                              child: const Text("Submit")),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> openDialog(title, lablel) async {
    // _selectedImage = null;
    // _kmController.text = '';
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(builder: (context, setstate) {
        // Future<void> pickImage() async {
        //   final picker = ImagePicker();
        //   final pickedFile = await picker.pickImage(
        //       source: ImageSource.camera,
        //       imageQuality: 5); // Or ImageSource.camera

        //   if (pickedFile != null) {
        //     setstate(() {
        //       _selectedImage = File(pickedFile.path);
        //     });
        //   }
        // }

        return AlertDialog(
          title: Text(title),

          // content: InputField(label: lablel, controller: _emailotpcontroller),
          content: SingleChildScrollView(
            // Use SingleChildScrollView for scrollability if content gets long
            child: Column(
              mainAxisSize: MainAxisSize.min, // Make column wrap its content
              children: [
                InputField(label: lablel, controller: _kmController),
                const SizedBox(height: 20),
                // ElevatedButton.icon(
                //   onPressed: pickImage,
                //   icon: const Icon(Icons.image),
                //   label: const Text('Pick Image'),
                // ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // setstate(() {
                //   _selectedImage = null;
                //   _kmController.text = '';
                // });
                Navigator.of(context).pop(null); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final String enteredText = _kmController.text;
                // _selectedImage contains the File object

                // Example of how to return data
                Navigator.of(context).pop({
                  'km': enteredText,
                  'image': _selectedImage, // Pass the File object
                });
              },
              child: const Text('Submit'),
            ),
          ],
        );
      }),
    );
    if (kDebugMode) {
      print(result);
    }
    if (result != null) {
      // THIS IS WHERE THE PROCESSING HAPPENS IMMEDIATELY
      setState(() {
        // <-- This rebuilds the HomePage with the new data
        _kmController.text = result['km'] ?? '';
        _selectedImage = result['image'] as File?;
      });
    } else {
      setState(() {
        // <-- This rebuilds the HomePage with the new data
        _kmController.text = '';
        _selectedImage = null;
      });
    }
  }
}
