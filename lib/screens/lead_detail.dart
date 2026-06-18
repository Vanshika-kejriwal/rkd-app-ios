import 'dart:async';
import 'dart:convert';
import 'dart:io';
// import 'dart:nativewrappers/_internal/vm/lib/core_patch.dart';
// import 'dart:nativewrappers/_internal/vm/lib/core_patch.dart';
// import 'dart:core';
import 'package:business_app/constants.dart';
import 'package:business_app/models/leads.dart';
import 'package:business_app/models/utils.dart';
import 'package:business_app/services/location.dart';
import 'package:business_app/services/network_provider.dart';
import 'package:business_app/services/notification_service.dart';
// import 'package:business_app/services/send_notification_service.dart';
import 'package:business_app/widgets/background.dart';
import 'package:business_app/widgets/gallery.dart';
import 'package:business_app/widgets/input_field.dart';
import 'package:business_app/widgets/progressive_multipartrequest.dart';
import 'package:business_app/widgets/servicecheckout.dart';
import 'package:business_app/widgets/videopreview.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
// Removed go_router import
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:http_parser/http_parser.dart'; // Used to set accurate file MIME types
import 'package:video_compress/video_compress.dart';

class LeadDetail extends StatefulWidget {
  final Lead? currentlead;
  final String? pjc;
  final String? pname;
  const LeadDetail({super.key, this.currentlead, this.pjc, this.pname});

  @override
  State<LeadDetail> createState() => _LeadDetailState();
}

class _LeadDetailState extends State<LeadDetail> {
  // Place helper functions at the top so they're available everywhere

  Widget _buildInfoRow(String label1, String value1, String label2,
      String value2, String label3, String value3, bool isAdmin, String loca) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start, // Align to top if text wraps
      children: [
        // Label 1 (fixed width or flexible)
        SizedBox(
          width: 60, // Keep a fixed width for the first label for alignment
          child: Text(
            label1,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
                text: value1,
                style: const TextStyle(fontSize: 10, color: Colors.black),
                children: [
                  if (isAdmin &&
                      (label1 == "Checkin" || label1 == "Checkout") &&
                      loca != "")
                    TextSpan(
                        text: " CheckLoca",
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                            decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            launchUrl(Uri.parse(loca));
                          }),
                ]),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 25,
          child: Text(
            label2,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
          ),
        ),
        Expanded(
          child: Text(
            value2,
            style: const TextStyle(fontSize: 10),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 45,
          child: Text(
            label3,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
          ),
        ),
        Expanded(
          child: Text(
            value3,
            style: const TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }

  bool ischeckedin = false;
  String _checkin = '';
  String _checkinloca = '';
  String _checkoutloca = '';
  String _pjc = '';
  String _name = '';
  String _ownermobile = '';
  String _add1 = '';
  String _add2 = '';
  // Removed unused _pin field
  String _state = '';
  String _city = '';
  String _district = '';
  String _mobile1 = '';
  String _mobile2 = '';
  String _pin = '';
  String _gstno = '';
  String _selectedstatus = '';
  String _selectedgst = '';
  String _selectedcategory = '';
  String _pname = '';
  bool _isLoading = false;
  bool _isAdmin = false;
  bool _resendotp = false;
  bool _isRightPerson = false;
  bool _allProductsDone = false;
  final _commentcontroller = TextEditingController();
  final _nextfudatecontroller = TextEditingController();
  String? _selectedfollowupby;
  String? _selectedinsbyour;
  String? _selectedleadtype;
  List<Product> _selectedfollowupproduct = [];
  int _leadstat = 1;
  int? ino;
  bool _isdataLoaded = false;
  List<Meeting> meeting = [];
  List<Product> products = [];
  List<Product> filterproducts = [];
  List<InvItem> _selectedinstallationitems = [];
  final List<String> _category = [];
  final _sparepartnamecontroller = TextEditingController();
  final _sparepartcostcontroller = TextEditingController();
  final _servicechargecontroller = TextEditingController();
  final _sparechargecontroller = TextEditingController();
  final _otherchargecontroller = TextEditingController();
  final _gstamountcontroller = TextEditingController();
  final _installdatecontroller = TextEditingController();
  final _amcdatecontroller = TextEditingController();
  final _mobforotpcontroller = TextEditingController();
  final _jcccontroller = TextEditingController();
  final _instcontpnamecontroller = TextEditingController();
  String? _selectedPhoneNumber;
  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();
  final ImagePicker _picker = ImagePicker();
  final List<String> _selectedImage = [];
  NotificationService notificationService = NotificationService();
  Timer? _reloadTimer;
  late Future<List<String>> _leadtypes;

  double _charge1 = 0.0;
  double _charge2 = 0.0;
  double _charge3 = 0.0;
  double _gstPercent = 18.0; // Default GST
  double _uploadProgress = 0.0; // New state variable for upload progress
  // Calculated field
  double _gstAmount = 0.0;

  void _calculateGstAmount() {
    // 1. Calculate the total charge
    double totalCharge = _charge1 + _charge2 + _charge3;

    // 2. Calculate the GST amount
    double newGstAmount = totalCharge * (_gstPercent / 100.0);

    // 3. Update the state
    setState(() {
      _gstAmount = newGstAmount;
      // Update the TextEditingController with the result
      _gstamountcontroller.text = _gstAmount.round().toStringAsFixed(2);
    });
  }

  Future<void> openReportOnDemand(Meeting targetMeeting) async {
    if (targetMeeting.reportlink == null) return;

    // setState(() => _isFetchingAsset = true);

    try {
      final response = await http.post(
        Uri.parse('$baseuri/api/dropbox-links/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fetch_type": "report",
          "report_file_info": targetMeeting.reportlink,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String reportUrl = data['url'];

        // Open the URL via url_launcher or pass to a webview
        debugPrint("Success! Open this link: $reportUrl");
        launchUrl(Uri.parse(reportUrl));
      } else {
        debugPrint("Failed to acquire link from server.");
      }
    } catch (e) {
      debugPrint("Error fetching asset link: $e");
    } finally {
      // setState(() => _isFetchingAsset = false);
    }
  }

  Future<void> fetchImagesOnDemand(Meeting targetMeeting) async {
    // Guard check: Only fetch if the backend indicated images exist
    if (!targetMeeting.imagelink!) {
      debugPrint("No images available for this lead.");
      return;
    }

    // setState(() {
    //   _isFetchingImages = true;
    //   _loadedImages = []; // Clear any previously loaded images
    // });

    try {
      final response = await http.post(
        Uri.parse('$baseuri/api/dropbox-links/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fetch_type": "images",
          "lead_id": targetMeeting.leadid,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Extract the list of raw URLs from the response
        if (data['urls'] != null) {
          // setState(() {
          //   _loadedImages = List<String>.from(data['urls']);
          // });

          if (data['urls'].isEmpty) {
            debugPrint(
                "The folder exists but no actual image files were found.");
          } else {
            debugPrint("Successfully fetched ${data['urls'].length} images.");
            // TODO: Open your image viewer dialog or bottom sheet here
            // _showImageGalleryContext();
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => CompleteGalleryScreen(
                          mediaItems: data['urls']
                              .map<Map<String, dynamic>>(
                                  (url) => {"url_or_path": url.trim()})
                              .toList(),
                        )));
          }
        }
      } else {
        debugPrint(
            "Failed to fetch image URLs from server. Status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching image assets: $e");
    } finally {
      // setState(() => _isFetchingImages = false);
    }
  }

  Future<void> checkin() async {
    // setState(() => _isLoading = true); // Optional: show a loader

    try {
      // 1. Await the location first
      String locaurl = await getLocation();

      // 2. Capture the timestamp immediately in a local variable
      String currentTime = DateTime.now().toIso8601String();

      // 3. Update the UI state
      if (mounted) {
        setState(() {
          _checkin = currentTime;
          _checkinloca = locaurl;
          ischeckedin = true;
        });
      }

      // 4. Build the map using the local variables (NOT the global ones)
      Map<String, dynamic> checkindata = {
        "checkin_time": currentTime,
        "checkin_loca": locaurl,
        "pjc": _pjc
      };

      // 5. Await the saving process
      var sp = await SharedPreferences.getInstance();
      await sp.setString("checkindata_$_pjc", json.encode(checkindata));

      debugPrint("Check-in saved successfully for $_pjc");
    } catch (e) {
      debugPrint("Error during check-in: $e");
      // Handle error (e.g., show a SnackBar)
    }
  }

  Future<List<String>> getnames() async {
    final response = await http.get(Uri.parse('$baseuri/api/leadnames/'));
    final body = json.decode(response.body);
    List<String> names = [];
    if (response.statusCode == 200) {
      for (var c in body) {
        names.add(c["NAME"]);
      }
    }
    return names;
  }

  Future<List<Product>> getproducts() async {
    final Map<String, dynamic> query = {'PJC': _pjc};
    final response =
        await http.post(Uri.parse('$baseuri/api/leadproducts/'), body: query);
    final body = json.decode(response.body);
    List<Product> product = [];
    if (response.statusCode == 200) {
      for (var c in body) {
        product.add(Product(
            leadid: c["LEAD_ID"],
            product: c["LEADFORP"],
            leadtype: c["LEAD_TYPE"]));
      }
    }
    return product;
  }

  Future<void> fetchcheckoutdetail(selectedproducts, ss) async {
    ss(() {
      _isLoading = true;
    });
    String queryparam =
        selectedproducts.map((item) => "leadid=${item.leadid}").join("&");
    final response =
        await http.get(Uri.parse('$baseuri/api/checkoutdetail/?$queryparam'));

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      ss(() {
        _selectedstatus = body["STATUS"];
        _selectedcategory = body["CATEGORY"];
        _commentcontroller.text = body["COMMENTS"];
        // _selectedfollowupby = body["NEXT_FUBY"];
        // _nextfudatecontroller.text = body["NEXT_FUDATE"];
        if ((_selectedcategory == "Paid Basis") |
            (_selectedcategory == "Obligatory Service")) {
          _selectedgst = body["GSTP"];
          _sparechargecontroller.text = body["SPARE_CHARGE"];
          _servicechargecontroller.text = body["SERVICE_CHARGE"];
          _otherchargecontroller.text = body["OTHER_CHARGE"];
          _gstamountcontroller.text = body["GST"];
        }
        if (_selectedcategory == "Under AMC") {
          _amcdatecontroller.text = body["INSTALLATION_DATE"] ?? "";
        }
        if (_selectedcategory == "Free Service as per Installation Agreement") {
          _installdatecontroller.text = body["INSTALLATION_DATE"] ?? "";
        }
        _leadstat = 2;
        _resendotp = true;
      });
    }
    if (mounted) {
      ss(() {
        _isLoading = false;
      });
    }
  }

  Future<int> submitdata(String sendmsg, bool resendotp) async {
    var locaurl = await getLocation();
    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0; // Reset progress bar state to 0%
      _checkoutloca = locaurl;
    });

    var sp = await SharedPreferences.getInstance();
    String encodedcheckin = sp.getString("checkindata_$_pjc") as String;
    Map<String, dynamic> decodecheckin = json.decode(encodedcheckin);

    final List<String> leadforp =
        _selectedfollowupproduct.map((item) => item.product).toList();
    final List<Map<String, dynamic>> wpm = _selectedfollowupproduct
        .map((item) => {item.product: item.wpm ?? ""})
        .toList();

    if (kDebugMode) {
      print(leadforp);
    }

    // 1. Initialize custom ProgressMultipartRequest instead of standard http.MultipartRequest
    final uri = Uri.parse('$baseuri/api/lead_update/');
    final request = ProgressMultipartRequest(
      'POST',
      uri,
      onProgress: (bytesTransferred, totalBytes) {
        if (totalBytes <= 0) return;
        setState(() {
          // Calculates progress coefficient from 0.0 up to 1.0 for the UI
          _uploadProgress = bytesTransferred / totalBytes;
        });
      },
    );

    // 2. Add authorization headers
    request.headers.addAll({
      "Authorization": "Bearer ${sp.getString('TOKEN') ?? ''}",
    });

    // 3. Map scalar variables and serialized objects to string fields
    request.fields.addAll({
      "CURR_NAME": sp.getString("NAME") ?? "",
      "CURR_MOB": sp.getString("Mobile") ?? "",
      'PJC': decodecheckin["pjc"]?.toString() ?? "",
      'LEADFORP': jsonEncode(leadforp),
      'WPM': jsonEncode(wpm),
      "institems": jsonEncode(
          _selectedinstallationitems.map((item) => item.code).toList()),
      "institemsid": jsonEncode(
          _selectedinstallationitems.map((item) => item.id).toList()),
      'CHECKIN': (decodecheckin["checkin_time"]?.toString().isEmpty ?? true)
          ? DateTime.now().toString()
          : decodecheckin["checkin_time"].toString(),
      'CHECKIN_LOCA': decodecheckin["checkin_loca"]?.toString() ?? "",
      'LEAD_TYPE': _selectedleadtype ?? "",
      'IBYOUR': _selectedinsbyour ?? "",
      'CONTP': _instcontpnamecontroller.text,
      'COMMENTS': _commentcontroller.text,
      'NEXT_FUBY': _selectedfollowupby ?? "",
      'CHECKOUT': DateTime.now().toString(),
      'OPEN': _leadstat == 1 ? "Y" : "N",
      'CHECKOUT_LOCA': _checkoutloca ?? "",
      'NEXT_FUDATETIME': _nextfudatecontroller.text,
      "STATUS": _selectedstatus ?? "",
      "CATEGORY": _selectedcategory ?? "",
      "SPARE PART COST": _sparepartcostcontroller.text,
      "SPARE PART NAME": _sparepartnamecontroller.text,
      "AMC DATE": _amcdatecontroller.text,
      "INSTALLATION_DATE": _installdatecontroller.text,
      "SERVICE_CHARGE": _servicechargecontroller.text,
      "SPARE_CHARGE": _sparechargecontroller.text,
      "OTHER_CHARGE": _otherchargecontroller.text,
      "GSTP": _selectedgst ?? "",
      "GST": _gstamountcontroller.text,
      "SEND_MSG": sendmsg,
      "MOBFOROTP": _mobforotpcontroller.text,
      'leadid': _selectedfollowupproduct.map((item) => item.leadid).join(","),
      "RESEND_OTP":
          sendmsg == "false" ? "false" : (resendotp ? "true" : "false")
    });

    // 4. COMPRESS AND ATTACH THE MEDIA FILES
    for (String path in _selectedImage) {
      if (path.isNotEmpty) {
        // Runs native image optimization or video hardware crunching automatically

        request.files.add(
          await http.MultipartFile.fromPath(
            'media_files', // Match this with key expected by Django (request.FILES.getlist)
            path,
          ),
        );
      }
    }

    // 5. Send stream requests out safely
    try {
      final streamedResponse = await request.send();
      final resp = await http.Response.fromStream(streamedResponse);

      // Clean up compression engine file caches right after completing upload stream
      // (Ensure you have 'package:video_compress/video_compress.dart' if compression library is in use)
      // await VideoCompress.deleteAllCache();

      // 6. Parse response metadata
      if (resp.body.isNotEmpty) {
        var responseBody = jsonDecode(resp.body);
        setState(() {
          ino = responseBody['ino'];
        });
      }

      sp.remove("checkindata_$_pjc");

      setState(() {
        _isLoading = false;
      });

      return resp.statusCode;
    } catch (e) {
      // Graceful error cleanup to reset screen overlays if connection crashes
      setState(() {
        _isLoading = false;
      });
      if (kDebugMode) {
        print("Upload execution error: $e");
      }
      return 500;
    }
  }

  Future<void> getmeetingdetail() async {
    String pjc = _pjc;
    final connectivityProvider =
        Provider.of<NetworkProvider>(context, listen: false);

    try {
      var sharedpref = await SharedPreferences.getInstance();
      var ut = sharedpref.getString('UT');
      final response =
          await http.get(Uri.parse('$baseuri/api/messagelist/$pjc/'));

      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);

        if (kDebugMode) {
          print(body);
        }

        // 1. Create a local temporary list to hold our mapped data safely
        List<Meeting> parsedMeetings = [];

        if (body.isNotEmpty) {
          for (var meet in body) {
            var visitdate = "";
            var createddate = "";
            var checkoutdate = "";

            if (meet['CHECKIN'] != null) {
              visitdate = DateFormat('dd/MM/yyyy h:mm a')
                  .format(DateTime.parse(meet['CHECKIN']));
            }

            if (meet['CHECKOUT'] != null &&
                meet['CHECKOUT'].toString().isNotEmpty) {
              String isoCheckout =
                  meet['CHECKOUT'].toString().replaceFirst(' ', 'T');
              DateTime checkoutTime = DateTime.parse(isoCheckout);
              checkoutdate =
                  DateFormat('dd/MM/yyyy h:mm a').format(checkoutTime);
            }

            if (meet['LEAD_DATE'] != null) {
              createddate = DateFormat("dd/MM/yyyy h:mm a")
                  .format(DateTime.parse(meet['LEAD_DATE']));
            }

            // Push into our temporary local list
            parsedMeetings.add(Meeting(
              leadid: meet["LEAD_ID"],
              product: meet['LEADFORP'],
              leadbyn: meet['LEADBYN'],
              leadton: meet['LEADTON'] != "" ? meet['LEADTON'] : "Unassigned",
              message: meet['MESSAGE'],
              comments: meet['COMMENTS'],
              checkinloca: meet['CHECKIN_LOCA'] ?? "",
              checkoutloca: meet['CHECKOUT_LOCA'] ?? "",
              scheduleMeeting: meet['MEETING_DATETIME'],
              checkout: checkoutdate,
              nextMeeting: meet['NEXT_FUDATETIME'],
              visitdate: visitdate,
              createddate: createddate,
              leadtype: meet['LEAD_TYPE'],
              open: meet['OPEN'],
              reportlink:
                  meet['report_link'], // Maps to your JSON snake_case properly
              imagelink: meet['image_link'],
            ));
          }
        }

        // 2. Trigger UI render ONCE with clean, un-duplicated data
        setState(() {
          meeting =
              parsedMeetings; // Replaces list completely, preventing duplication
          _isAdmin = ut == 'ADMIN';
          _isdataLoaded = true;
        });
      } else {
        setState(() {
          meeting = [];
          _isdataLoaded = true;
        });
      }
    } on SocketException catch (_) {
      connectivityProvider.setConnected(false);
    } on http.ClientException catch (_) {
      connectivityProvider.setConnected(false);
    } catch (e, stackTrace) {
      // THIS WILL CATCH JSON MAPPING OR UNEXPECTED SERVER ERRORS
      debugPrint("Unexpected error in getmeetingdetail: $e");
      debugPrint("Stacktrace: $stackTrace");
      setState(() {
        _isdataLoaded = true;
      });
    }
  }

  Future<void> getcategory() async {
    final response = await http.get(
        Uri.parse('$baseuri/api/leadstatcategory/?status=$_selectedstatus'));
    final body = json.decode(response.body);
    // List<String> names = [];
    if (response.statusCode == 200) {
      for (var c in body) {
        _category.add(c["DDL12"]);
      }
    }
  }

  Future<List<String>> getgst() async {
    try {
      final response = await http.get(Uri.parse('$baseuri/api/gst/'));
      final body = json.decode(response.body);
      if (kDebugMode) {
        print(body);
      }
      List<String> gst = [];
      if (response.statusCode == 200) {
        // user.clear();
        for (var ut in body) {
          gst.add(ut["DDL14"]);
        }
      }
      return gst;
    } catch (e) {
      return [];
    }
  }

  assigndata() async {
    var sp = await SharedPreferences.getInstance();

    setState(() {
      if (widget.pjc != null) {
        _pjc = widget.pjc as String;
      } else {
        _pjc = widget.currentlead!.pjc;
      }
      if (widget.pname != null) {
        _pname = widget.pname as String;
      } else {
        _pname = widget.currentlead!.pname;
      }
      if (sp.getString("checkindata_$_pjc") != null) {
        ischeckedin = true;
      }
    });
    // sp.remove("checkindata_$_pjc");
    var openproducts = await getproducts();
    if (kDebugMode) {
      print(openproducts);
      print(meeting.length);
    }
    if (openproducts.isEmpty) {
      setState(() {
        // ischeckedin = true;
        _allProductsDone = true;
      });
    } else {
      setState(() {
        _leadtypes = Future.value(
            openproducts.map((item) => item.leadtype).toSet().toList());
        products = openproducts;
      });
    }
    await getprojdetail(widget.pjc ?? widget.currentlead!.pjc);
    await getmeetingdetail();
    if (kDebugMode) {
      print(meeting);
    }
    _isRightPerson = await isRightPerson();
  }

  Future<void> getprojdetail(pjc) async {
    try {
      final response =
          await http.get(Uri.parse('$baseuri/api/projectdetail/$pjc/'));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (mounted) {
          setState(() {
            _name = body["CONTP"];
            _ownermobile = body["OMOBILE"];
            _add1 = body["ADD1"];
            _add2 = body["ADD2"];
            // Removed _pin assignment
            _state = body["STATE"];
            _city = body["CITY"];
            _district = body["DIST"];
            _mobile1 = body["MOBILE1"];
            _mobile2 = body["MOBILE2"];
            _pin = body["PIN"];
            _gstno = body["GSTN"] ?? "";
            // _formkey.currentState?.validate();
          });
        }
        // print("Pincode doesnt exists");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching project details: $e");
      }
    }
  }

  Future<bool> isRightPerson() async {
    var sharedpref = await SharedPreferences.getInstance();
    var username = sharedpref.getString('NAME')!;
    var ut = sharedpref.getString("UT")!;
    // print(ut);
    var uniqueLeadIds = meeting.map((m) => m.leadid).toSet();
    // print(uniqueLeadIds);
    // 2. Iterate only over the unique leadid values
    for (var id in uniqueLeadIds) {
      // 3. Find the index of the last item matching this leadid
      var lastidx = meeting.lastIndexWhere((m) => m.leadid == id);

      // 4. Perform the logic check using correct logical operators (&& and ||)
      if (lastidx != -1) {
        // Safety check in case the uniqueLeadIds list somehow gets an ID not in meeting
        var lastMeeting = meeting[lastidx];

        // Check: (open == "Y" AND leadton == username) OR (ut == "ADMIN")
        if (((lastMeeting.open == "Y") && (lastMeeting.leadton == username)) ||
            ((lastMeeting.open == "Y") && (ut == "ADMIN"))) {
          // Condition met for at least one leadid's final entry
          return true;
        }
      }
    }
    // if ((username == meeting.last.leadton) || (ut == "ADMIN")) {
    //   return true;
    // }
    return false;
  }

  // Removed unused _selectinstalldate and _selectamcdate methods

  @override
  void initState() {
    super.initState();
    // notificationService.firebaseInit(context);
    // notificationService.setupInteractMessage(context);
    // assigndata();
    // if (kDebugMode) {
    //   print(meeting);
    //   print(_allProductsDone);
    // }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get the current connectivity status using listen: true
    // This tells Flutter to call didChangeDependencies when the provider changes
    final isConnected = Provider.of<NetworkProvider>(context).isOnline;

    // Condition to restart API call:
    // 1. Internet is currently connected
    // 2. The previous state was NOT connected
    // 3. We are not in the middle of a fetch
    if (isConnected && !_isdataLoaded) {
      _reloadTimer?.cancel();

      // Start a new timer to delay the API call
      _reloadTimer = Timer(const Duration(seconds: 2), () {
        assigndata(); // Call _fetchData() after a 3-second delay
      });
    }

    // Update the previous state for the next check
    // _lastConnectivityStatus = isConnected;

    // If we lose connection, reset _dataLoaded so it will fetch again
    if (!isConnected) {
      _reloadTimer?.cancel();
      setState(() {
        _isdataLoaded = false;
      });
    }
  }

  @override
  void dispose() {
    // It's crucial to cancel the timer when the widget is disposed
    _reloadTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Background(
        appbaractions: const [],
        appbar: true,
        appbartitle: GestureDetector(
          onTap: () {
            showDialog(
                context: context,
                builder: (context) => AlertDialog(
                      title: Text(_pname),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SelectableText(
                            "PJC - $_pjc",
                            textAlign: TextAlign.start,
                          ),
                          SelectableText(
                            "Owner Name - $_name",
                            textAlign: TextAlign.start,
                          ),
                          SelectableText(
                            "Owner Mobile- $_ownermobile",
                            textAlign: TextAlign.start,
                          ),
                          SelectableText(
                            "Manager Mobile- $_mobile1",
                            textAlign: TextAlign.start,
                          ),
                          SelectableText(
                            "Staff Mobile- $_mobile2",
                            textAlign: TextAlign.start,
                          ),
                          SelectableText(
                            "Add1- $_add1",
                            textAlign: TextAlign.start,
                          ),
                          SelectableText(
                            "Add2- $_add2",
                            textAlign: TextAlign.start,
                          ),
                          SelectableText(
                            "City- $_city",
                            textAlign: TextAlign.start,
                          ),
                          SelectableText(
                            "District- $_district",
                            textAlign: TextAlign.start,
                          ),
                          SelectableText(
                            "State- $_state",
                            textAlign: TextAlign.start,
                          ),
                          SelectableText(
                            "PIN- $_pin",
                            textAlign: TextAlign.start,
                          ),
                          SelectableText(
                            "GST No- $_gstno",
                            textAlign: TextAlign.start,
                          ),
                        ],
                      ),
                    ));
          },
          child: Text(_pname),
        ),
        floatbutton: true,
        floatbtn: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(252, 101, 8, 1),
                    foregroundColor: Colors.white),
                onPressed: !_isRightPerson || ischeckedin || _allProductsDone
                    ? null
                    : () async {
                        await checkin();
                        // setState(() {
                        //   ischeckedin = true;
                        // });
                      },
                child: const Text("Check In")),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(252, 101, 8, 1),
                    foregroundColor: Colors.white),
                onPressed: ischeckedin && !_allProductsDone
                    ? () async {
                        var result = await showModalBottomSheet(
                            backgroundColor: const Color(0xffffe6bd),
                            isScrollControlled: true,
                            context: context,
                            builder: (BuildContext context) {
                              return SafeArea(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      top:
                                          MediaQuery.of(context).viewInsets.top,
                                      bottom: MediaQuery.of(context)
                                          .viewInsets
                                          .bottom),
                                  child: StatefulBuilder(
                                      builder: (context, setstate) {
                                    return Center(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 40.0),
                                        child: Form(
                                            child: Center(
                                          child: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(5.0),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        _pname,
                                                        style: const TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      const Spacer(),
                                                      IconButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          icon: const Icon(
                                                              Icons.close))
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child:
                                                        FutureBuilder<
                                                                List<String>>(
                                                            future: _leadtypes,
                                                            builder: (context,
                                                                snapshot) {
                                                              if (snapshot
                                                                      .hasData &&
                                                                  snapshot.data !=
                                                                      null) {
                                                                return DropdownSearch<
                                                                    String>(
                                                                  popupProps: const PopupProps
                                                                      .dialog(
                                                                      showSelectedItems:
                                                                          true,
                                                                      showSearchBox:
                                                                          true),
                                                                  // mode: Mode.dialog,
                                                                  // showSelectedItems: true,
                                                                  items: snapshot
                                                                      .data!,
                                                                  dropdownDecoratorProps:
                                                                      const DropDownDecoratorProps(
                                                                    dropdownSearchDecoration:
                                                                        InputDecoration(
                                                                      labelText:
                                                                          "Lead Type",
                                                                      hintText:
                                                                          "Select a Lead Type",
                                                                    ),
                                                                  ),

                                                                  onChanged:
                                                                      (value) {
                                                                    setstate(
                                                                        () {
                                                                      _selectedleadtype =
                                                                          value;
                                                                      filterproducts = products
                                                                          .where((item) => item
                                                                              .leadtype
                                                                              .contains(value!))
                                                                          .toList();
                                                                    });
                                                                    if (value ==
                                                                        "SERVICE") {
                                                                      // Navigator.of(
                                                                      //         context)
                                                                      //     .pop();
                                                                      Navigator.push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                              builder: (context) => Servicecheckout(pname: _pname, pjc: widget.pjc ?? widget.currentlead!.pjc, products: filterproducts))).then(
                                                                          (val) {
                                                                        Navigator.pop(
                                                                            context);
                                                                        Navigator.pop(
                                                                            context);
                                                                        // assigndata();
                                                                      });
                                                                    }
                                                                  },
                                                                  selectedItem:
                                                                      _selectedleadtype,
                                                                );
                                                              } else {
                                                                return const Center(
                                                                    child:
                                                                        CircularProgressIndicator());
                                                              }
                                                            })),
                                                Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: DropdownSearch<
                                                        Product>.multiSelection(
                                                      itemAsString:
                                                          (Product item) {
                                                        return item.product;
                                                      },
                                                      popupProps:
                                                          const PopupPropsMultiSelection
                                                              .dialog(
                                                              // showSelectedItems:
                                                              //     true,
                                                              showSearchBox:
                                                                  true),
                                                      // mode: Mode.dialog,
                                                      // showSelectedItems: true,
                                                      items: filterproducts,
                                                      dropdownDecoratorProps:
                                                          const DropDownDecoratorProps(
                                                        dropdownSearchDecoration:
                                                            InputDecoration(
                                                          labelText:
                                                              "Follow-up For Product",
                                                          hintText:
                                                              "Select a Product",
                                                        ),
                                                      ),
                                                      onChanged: (value) async {
                                                        setstate(() {
                                                          _selectedfollowupproduct =
                                                              value;
                                                          if (_selectedleadtype ==
                                                              "INSTALLATION") {
                                                            // getproductinfo(
                                                            //     widget
                                                            //         .currentlead!
                                                            //         .pjc,
                                                            //     value
                                                            //         .map((e) =>
                                                            //             e.product)
                                                            //         .toList());
                                                          }
                                                        });
                                                        await fetchcheckoutdetail(
                                                            _selectedfollowupproduct,
                                                            setstate);
                                                      },
                                                      selectedItems:
                                                          _selectedfollowupproduct,
                                                    )),

                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(5.0),
                                                  child: DropdownSearch<String>(
                                                      enabled: !_resendotp,
                                                      popupProps:
                                                          const PopupProps
                                                              .dialog(
                                                              showSelectedItems:
                                                                  true,
                                                              showSearchBox:
                                                                  false),
                                                      // mode: Mode.dialog,
                                                      // showSelectedItems: true,
                                                      items:
                                                          _selectedleadtype ==
                                                                  "INSTALLATION"
                                                              ? [
                                                                  "Installation Completed",
                                                                  "Job Not Completed"
                                                                ]
                                                              : [
                                                                  "Job Completed ",
                                                                  "Job Not Completed"
                                                                ],
                                                      dropdownDecoratorProps:
                                                          const DropDownDecoratorProps(
                                                        dropdownSearchDecoration:
                                                            InputDecoration(
                                                          labelText:
                                                              "Lead Status",
                                                          hintText:
                                                              "Select status",
                                                        ),
                                                      ),
                                                      onChanged: (value) {
                                                        setstate(() {
                                                          _category.clear();
                                                          _selectedstatus =
                                                              value!;
                                                          if (_selectedstatus ==
                                                              "Job Not Completed") {
                                                            _leadstat = 1;
                                                          } else {
                                                            _leadstat = 2;
                                                          }
                                                          getcategory();
                                                        });
                                                      },
                                                      selectedItem:
                                                          _selectedstatus),
                                                  // child: Row(
                                                  //   mainAxisAlignment:
                                                  //       MainAxisAlignment
                                                  //           .spaceAround,
                                                  //   crossAxisAlignment:
                                                  //       CrossAxisAlignment.center,
                                                  //   children: [
                                                  //     Row(
                                                  //       children: [
                                                  //         Radio<int>(
                                                  //             value: 1,
                                                  //             groupValue: _leadstat,
                                                  //             // selected: false,
                                                  //             onChanged:
                                                  //                 (int? value) {
                                                  //               setstate(() {
                                                  //                 _leadstat =
                                                  //                     value!;
                                                  //               });
                                                  //             }),
                                                  //         const SizedBox(
                                                  //             width: 10.0),
                                                  //         const Text("Open")
                                                  //       ],
                                                  //     ),
                                                  //     Row(
                                                  //       children: [
                                                  //         Radio<int>(
                                                  //             value: 2,
                                                  //             groupValue: _leadstat,
                                                  //             // selected: false,
                                                  //             onChanged:
                                                  //                 (int? value) {
                                                  //               setstate(() {
                                                  //                 _leadstat =
                                                  //                     value!;
                                                  //               });
                                                  //             }),
                                                  //         const SizedBox(
                                                  //             width: 10.0),
                                                  //         const Text("Close")
                                                  //       ],
                                                  //     )
                                                  //   ],
                                                  // ),
                                                ),
                                                if (_selectedstatus ==
                                                        "Installation Completed" ||
                                                    ((_selectedstatus ==
                                                            "Job Completed ") &&
                                                        (_selectedleadtype ==
                                                            "SERVICE")))
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: FutureBuilder<
                                                            List<InvItem>>(
                                                        future: getinstitems(
                                                            widget.currentlead!
                                                                .pjc,
                                                            _selectedfollowupproduct
                                                                .map((e) =>
                                                                    e.product)
                                                                .toList(),
                                                            _selectedleadtype!),
                                                        builder: (context,
                                                            snapshot) {
                                                          if (snapshot
                                                              .hasData) {
                                                            return DropdownSearch<
                                                                InvItem>.multiSelection(
                                                              // enabled: !_resendotp,
                                                              popupProps: const PopupPropsMultiSelection
                                                                  .dialog(
                                                                  showSelectedItems:
                                                                      true,
                                                                  showSearchBox:
                                                                      true),
                                                              // mode: Mode.dialog,
                                                              // showSelectedItems: true,
                                                              items: snapshot
                                                                  .data!,
                                                              itemAsString:
                                                                  (item) =>
                                                                      item.name,
                                                              compareFn: (item1,
                                                                      item2) =>
                                                                  item1.id ==
                                                                  item2.id,
                                                              dropdownDecoratorProps:
                                                                  const DropDownDecoratorProps(
                                                                dropdownSearchDecoration:
                                                                    InputDecoration(
                                                                  labelText:
                                                                      "Select Products",
                                                                  hintText:
                                                                      "Select a Product",
                                                                ),
                                                              ),

                                                              onChanged:
                                                                  (value) {
                                                                setstate(() {
                                                                  _selectedinstallationitems =
                                                                      value;
                                                                });
                                                              },
                                                              selectedItems:
                                                                  _selectedinstallationitems,
                                                            );
                                                          } else {
                                                            // print(snapshot.error);
                                                            return const Center(
                                                                child:
                                                                    CircularProgressIndicator());
                                                          }
                                                        }),
                                                  ),
                                                // if ((_selectedstatus ==
                                                //     "Job Completed "))
                                                Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child:
                                                        DropdownSearch<String>(
                                                      enabled: !_resendotp,
                                                      popupProps:
                                                          const PopupProps
                                                              .dialog(
                                                              showSelectedItems:
                                                                  true,
                                                              showSearchBox:
                                                                  true),
                                                      // mode: Mode.dialog,
                                                      // showSelectedItems: true,
                                                      items: _category,
                                                      dropdownDecoratorProps:
                                                          const DropDownDecoratorProps(
                                                        dropdownSearchDecoration:
                                                            InputDecoration(
                                                          labelText:
                                                              "Reason/Category",
                                                          hintText:
                                                              "Select an option",
                                                        ),
                                                      ),

                                                      onChanged: (value) {
                                                        setstate(() {
                                                          // _company.clear();
                                                          _selectedcategory =
                                                              value!;
                                                          // getcomp();
                                                        });
                                                      },
                                                      selectedItem:
                                                          _selectedcategory,
                                                    )),
                                                if (_selectedcategory ==
                                                    "Spare Part Required")
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: InputField(
                                                      readOnly: _resendotp,
                                                      label: "Part Name",
                                                      controller:
                                                          _sparepartnamecontroller,
                                                    ),
                                                  ),
                                                if (_selectedcategory ==
                                                    "Spare Part Required")
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: InputField(
                                                      readOnly: _resendotp,
                                                      label: "Part Cost",
                                                      controller:
                                                          _sparepartcostcontroller,
                                                      keyboardtype:
                                                          TextInputType.number,
                                                    ),
                                                  ),
                                                if ((_selectedcategory ==
                                                        "Paid Basis") |
                                                    (_selectedcategory ==
                                                        "Obligatory Service"))
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: InputField(
                                                      readOnly: _resendotp,
                                                      label: "Service Charge",
                                                      controller:
                                                          _servicechargecontroller,
                                                      keyboardtype:
                                                          TextInputType.number,
                                                      onChanged: (value) {
                                                        _charge1 =
                                                            double.tryParse(
                                                                    value) ??
                                                                0.0;
                                                        // _calculateGstAmount();
                                                      },
                                                    ),
                                                  ),
                                                if (_selectedcategory ==
                                                    "Paid Basis")
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: InputField(
                                                      readOnly: _resendotp,
                                                      label: "Spare Charge",
                                                      controller:
                                                          _sparechargecontroller,
                                                      keyboardtype:
                                                          TextInputType.number,
                                                      onChanged: (value) {
                                                        _charge2 =
                                                            double.tryParse(
                                                                    value) ??
                                                                0.0;
                                                        // _calculateGstAmount();
                                                      },
                                                    ),
                                                  ),
                                                if (_selectedcategory ==
                                                    "Paid Basis")
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: InputField(
                                                      readOnly: _resendotp,
                                                      label: "Other Charge",
                                                      controller:
                                                          _otherchargecontroller,
                                                      keyboardtype:
                                                          TextInputType.number,
                                                      onChanged: (value) {
                                                        _charge3 =
                                                            double.tryParse(
                                                                    value) ??
                                                                0.0;
                                                        // _calculateGstAmount();
                                                      },
                                                    ),
                                                  ),
                                                // gst %
                                                if ((_selectedcategory ==
                                                        "Paid Basis") |
                                                    (_selectedcategory ==
                                                        "Obligatory Service"))
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: FutureBuilder<
                                                            List<String>>(
                                                        future: getgst(),
                                                        builder: ((context,
                                                            snapshot) {
                                                          if (snapshot
                                                                  .hasData &&
                                                              snapshot.data !=
                                                                  null) {
                                                            return DropdownSearch<
                                                                String>(
                                                              enabled:
                                                                  !_resendotp,
                                                              popupProps: const PopupProps
                                                                  .dialog(
                                                                  showSelectedItems:
                                                                      true,
                                                                  showSearchBox:
                                                                      true),
                                                              // mode: Mode.dialog,
                                                              // showSelectedItems: true,
                                                              items: snapshot
                                                                  .data!,
                                                              dropdownDecoratorProps:
                                                                  const DropDownDecoratorProps(
                                                                dropdownSearchDecoration:
                                                                    InputDecoration(
                                                                  labelText:
                                                                      "GST %",
                                                                  hintText:
                                                                      "Select a GST %",
                                                                ),
                                                              ),
                                                              autoValidateMode:
                                                                  AutovalidateMode
                                                                      .onUserInteraction,
                                                              validator:
                                                                  (value) {
                                                                if (value!
                                                                    .isEmpty) {
                                                                  return "Select a GST %";
                                                                }
                                                                return null;
                                                              },
                                                              // dropdownSearchDecoration: const InputDecoration(
                                                              // labelText: "Menu mode",
                                                              // hintText: "country in menu mode",
                                                              // ),
                                                              // popupItemDisabled: isItemDisabled,
                                                              onChanged:
                                                                  (value) {
                                                                setstate(() {
                                                                  _selectedgst =
                                                                      value!;
                                                                });
                                                                _gstPercent =
                                                                    double.tryParse(
                                                                            value!) ??
                                                                        18.0;
                                                                _calculateGstAmount();
                                                              },
                                                              selectedItem:
                                                                  _selectedgst,
                                                              // showSearchBox: true,
                                                              // searchFieldProps: TextFieldProps(
                                                              //   cursorColor: Colors.blue,
                                                              // ),
                                                            );
                                                          } else {
                                                            return const Center(
                                                                child:
                                                                    CircularProgressIndicator());
                                                          }
                                                        })),
                                                  ),
                                                if ((_selectedcategory ==
                                                        "Paid Basis") |
                                                    (_selectedcategory ==
                                                        "Obligatory Service"))
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: InputField(
                                                      readOnly: true,
                                                      label: "GST Amount",
                                                      controller:
                                                          _gstamountcontroller,
                                                      keyboardtype:
                                                          TextInputType.number,
                                                    ),
                                                  ),
                                                if (_selectedcategory ==
                                                    "Free Service as per Installation Agreement")
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: InputField(
                                                      label:
                                                          "Installation Date",
                                                      controller:
                                                          _installdatecontroller,
                                                      readOnly: true,
                                                      onTap: _resendotp
                                                          ? null
                                                          : () async {
                                                              DateTime? picked = await showDatePicker(
                                                                  context:
                                                                      context,
                                                                  initialDate:
                                                                      DateTime
                                                                          .now(),
                                                                  firstDate:
                                                                      DateTime(
                                                                          1900),
                                                                  lastDate:
                                                                      DateTime(
                                                                          2100));
                                                              if (picked !=
                                                                  null) {
                                                                setstate(() {
                                                                  _installdatecontroller
                                                                          .text =
                                                                      picked
                                                                          .toString()
                                                                          .split(
                                                                              " ")[0];
                                                                });
                                                              }
                                                              // setstate(() {
                                                              //   _dobdate = picked;
                                                              // });
                                                            },
                                                    ),
                                                  ),
                                                if (_selectedcategory ==
                                                    "Under AMC")
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: InputField(
                                                      label: "AMC Date",
                                                      controller:
                                                          _amcdatecontroller,
                                                      readOnly: true,
                                                      onTap: _resendotp
                                                          ? null
                                                          : () async {
                                                              DateTime? picked = await showDatePicker(
                                                                  context:
                                                                      context,
                                                                  initialDate:
                                                                      DateTime
                                                                          .now(),
                                                                  firstDate:
                                                                      DateTime(
                                                                          1900),
                                                                  lastDate:
                                                                      DateTime(
                                                                          2100));
                                                              if (picked !=
                                                                  null) {
                                                                setstate(() {
                                                                  _amcdatecontroller
                                                                          .text =
                                                                      picked
                                                                          .toString()
                                                                          .split(
                                                                              " ")[0];
                                                                });
                                                              }
                                                            },
                                                    ),
                                                  ),
                                                if (_selectedstatus ==
                                                    "Installation Completed")
                                                  Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5.0),
                                                      child: FutureBuilder<
                                                              List<String>>(
                                                          future: getnames(),
                                                          builder: (context,
                                                              snapshot) {
                                                            if (snapshot
                                                                    .hasData &&
                                                                snapshot.data !=
                                                                    null) {
                                                              return DropdownSearch<
                                                                  String>(
                                                                popupProps: const PopupProps
                                                                    .dialog(
                                                                    showSelectedItems:
                                                                        true,
                                                                    showSearchBox:
                                                                        true),
                                                                // mode: Mode.dialog,
                                                                // showSelectedItems: true,
                                                                items: snapshot
                                                                    .data!,
                                                                dropdownDecoratorProps:
                                                                    const DropDownDecoratorProps(
                                                                  dropdownSearchDecoration:
                                                                      InputDecoration(
                                                                    labelText:
                                                                        "Installation by Our",
                                                                    hintText:
                                                                        "Select a Name",
                                                                  ),
                                                                ),

                                                                onChanged:
                                                                    (value) {
                                                                  setstate(() {
                                                                    _selectedinsbyour =
                                                                        value;
                                                                  });
                                                                },
                                                                selectedItem:
                                                                    _selectedinsbyour,
                                                              );
                                                            } else {
                                                              return const Center(
                                                                  child:
                                                                      CircularProgressIndicator());
                                                            }
                                                          })),
                                                if (_selectedstatus ==
                                                        "Installation Completed" &&
                                                    _selectedcategory !=
                                                        "Installation Created by Mistake")
                                                  for (var product
                                                      in _selectedfollowupproduct)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5.0),
                                                      child: DropdownSearch<
                                                              String>(
                                                          popupProps:
                                                              const PopupProps
                                                                  .dialog(
                                                                  showSelectedItems:
                                                                      true,
                                                                  showSearchBox:
                                                                      false),
                                                          // mode: Mode.dialog,
                                                          // showSelectedItems: true,
                                                          items: const [
                                                            "6 Months",
                                                            "12 Months",
                                                            "24 Months",
                                                            "36 Months"
                                                          ],
                                                          dropdownDecoratorProps:
                                                              DropDownDecoratorProps(
                                                            dropdownSearchDecoration:
                                                                InputDecoration(
                                                              labelText:
                                                                  "Waranty Period for ${product.product}",
                                                              hintText:
                                                                  "Select waranty period",
                                                            ),
                                                          ),
                                                          onChanged: (value) {
                                                            product.wpm = value;
                                                          },
                                                          selectedItem:
                                                              product.wpm),
                                                    ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(5.0),
                                                  child: InputField(
                                                    readOnly: _resendotp,
                                                    label: "Comments",
                                                    controller:
                                                        _commentcontroller,
                                                    minlines: 1,
                                                    maxlines: 10,
                                                  ),
                                                ),
                                                if (_selectedstatus ==
                                                    "Installation Completed")
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: InputField(
                                                      label:
                                                          "Site Represtative Name",
                                                      controller:
                                                          _instcontpnamecontroller,
                                                    ),
                                                  ),

                                                if (_leadstat == 1)
                                                  Column(
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(5.0),
                                                        child: InputField(
                                                          label:
                                                              "Next Follow Up Date",
                                                          controller:
                                                              _nextfudatecontroller,
                                                          readOnly: true,
                                                          onTap: () async {
                                                            DateTime? meet =
                                                                await showOmniDateTimePicker(
                                                                    context:
                                                                        context,
                                                                    minutesInterval:
                                                                        15);
                                                            if (meet != null) {
                                                              _nextfudatecontroller
                                                                      .text =
                                                                  DateFormat(
                                                                          "dd/MM/yyyy")
                                                                      .add_jm()
                                                                      .format(
                                                                          meet);
                                                            }
                                                          },
                                                        ),
                                                      ),
                                                      Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(5.0),
                                                          child: FutureBuilder<
                                                                  List<String>>(
                                                              future:
                                                                  getnames(),
                                                              builder: (context,
                                                                  snapshot) {
                                                                if (snapshot
                                                                        .hasData &&
                                                                    snapshot.data !=
                                                                        null) {
                                                                  return DropdownSearch<
                                                                      String>(
                                                                    popupProps: const PopupProps
                                                                        .dialog(
                                                                        showSelectedItems:
                                                                            true,
                                                                        showSearchBox:
                                                                            true),
                                                                    // mode: Mode.dialog,
                                                                    // showSelectedItems: true,
                                                                    items: snapshot
                                                                        .data!,
                                                                    dropdownDecoratorProps:
                                                                        const DropDownDecoratorProps(
                                                                      dropdownSearchDecoration:
                                                                          InputDecoration(
                                                                        labelText:
                                                                            "Next Follow-up By",
                                                                        hintText:
                                                                            "Select a Name",
                                                                      ),
                                                                    ),

                                                                    onChanged:
                                                                        (value) {
                                                                      setstate(
                                                                          () {
                                                                        _selectedfollowupby =
                                                                            value;
                                                                      });
                                                                    },
                                                                    selectedItem:
                                                                        _selectedfollowupby,
                                                                  );
                                                                } else {
                                                                  return const Center(
                                                                      child:
                                                                          CircularProgressIndicator());
                                                                }
                                                              })),
                                                    ],
                                                  ),

                                                if (_leadstat != 1)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: InputField(
                                                        label: _selectedstatus ==
                                                                "Installation Completed"
                                                            ? "Site Representative Mobile Number"
                                                            : "Mobile Number for OTP",
                                                        controller:
                                                            _mobforotpcontroller,
                                                        keyboardtype:
                                                            TextInputType.phone,
                                                        sufficon: IconButton(
                                                            onPressed:
                                                                () async {
                                                              Contact? contact =
                                                                  await _contactPicker
                                                                      .selectPhoneNumber();
                                                              setstate(() {
                                                                _selectedPhoneNumber =
                                                                    contact
                                                                        ?.selectedPhoneNumber;
                                                                if (_selectedPhoneNumber !=
                                                                    null) {
                                                                  var phno = _selectedPhoneNumber!
                                                                      .replaceAll(
                                                                          " ",
                                                                          "");
                                                                  _mobforotpcontroller
                                                                          .text =
                                                                      phno.substring(
                                                                          phno.length -
                                                                              10);
                                                                  _selectedPhoneNumber =
                                                                      null;
                                                                }
                                                              });
                                                            },
                                                            icon: const Icon(
                                                                Icons
                                                                    .contacts))),
                                                  ),
                                                if (_leadstat != 1)
                                                  // image/vedio upload
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                            "Upload Image/Video",
                                                            style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color:
                                                                    Colors.grey[
                                                                        700])),
                                                        const Spacer(),
                                                        // camera iconbutton
                                                        SpeedDial(
                                                          icon:
                                                              Icons.camera_alt,
                                                          activeIcon: Icons
                                                              .close_rounded,
                                                          children: [
                                                            SpeedDialChild(
                                                              child: const Icon(
                                                                  Icons
                                                                      .camera_alt),
                                                              label:
                                                                  "Capture Image",
                                                              onTap: () async {
                                                                final XFile?
                                                                    image =
                                                                    await _picker.pickImage(
                                                                        source: ImageSource
                                                                            .camera,
                                                                        imageQuality:
                                                                            75);
                                                                if (image !=
                                                                    null) {
                                                                  setstate(() {
                                                                    _selectedImage
                                                                        .add(image
                                                                            .path);
                                                                  });
                                                                }
                                                              },
                                                            ),
                                                            SpeedDialChild(
                                                              child: const Icon(
                                                                  Icons
                                                                      .videocam),
                                                              label:
                                                                  "Capture Video",
                                                              onTap: () async {
                                                                final XFile? video = await _picker.pickVideo(
                                                                    source: ImageSource
                                                                        .camera,
                                                                    maxDuration:
                                                                        const Duration(
                                                                            seconds:
                                                                                30));
                                                                if (video !=
                                                                    null) {
                                                                  final mediaInfo =
                                                                      await VideoCompress
                                                                          .compressVideo(
                                                                    video.path,
                                                                    quality:
                                                                        VideoQuality
                                                                            .MediumQuality,
                                                                    includeAudio:
                                                                        true,
                                                                    deleteOrigin:
                                                                        false, // Set to true to delete the original video after compression
                                                                  );
                                                                  setstate(() {
                                                                    _selectedImage.add(
                                                                        mediaInfo!
                                                                            .file!
                                                                            .path);
                                                                  });
                                                                }
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                              Icons.photo),
                                                          onPressed: () async {
                                                            final List<XFile>
                                                                images =
                                                                await _picker
                                                                    .pickMultipleMedia(
                                                                        imageQuality:
                                                                            75);
                                                            if (images
                                                                .isNotEmpty) {
                                                              for (var element
                                                                  in images) {
                                                                if (element.path
                                                                        .endsWith(
                                                                            '.mp4') ||
                                                                    element.path
                                                                        .endsWith(
                                                                            '.mov')) {
                                                                  VideoCompress
                                                                      .compressVideo(
                                                                    element
                                                                        .path,
                                                                    quality:
                                                                        VideoQuality
                                                                            .MediumQuality,
                                                                    includeAudio:
                                                                        true,
                                                                    deleteOrigin:
                                                                        false, // Set to true to delete the original video after compression
                                                                  ).then(
                                                                      (mediaInfo) {
                                                                    setstate(
                                                                        () {
                                                                      _selectedImage.add(mediaInfo!
                                                                          .file!
                                                                          .path);
                                                                    });
                                                                  });
                                                                } else {
                                                                  setstate(() {
                                                                    _selectedImage
                                                                        .add(element
                                                                            .path);
                                                                  });
                                                                }
                                                              }
                                                            }
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                if (_leadstat != 1)
                                                  // preview of selected files
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: SizedBox(
                                                      height: 90,
                                                      child: ListView.builder(
                                                        scrollDirection:
                                                            Axis.horizontal,
                                                        itemCount:
                                                            _selectedImage
                                                                .length,
                                                        itemBuilder:
                                                            (context, index) {
                                                          final file =
                                                              _selectedImage[
                                                                  index];
                                                          final isVideo = file
                                                                  .endsWith(
                                                                      '.mp4') ||
                                                              file.endsWith(
                                                                  '.mov'); // Quick extension check

                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        8.0),
                                                            child: Stack(
                                                              alignment:
                                                                  Alignment
                                                                      .topRight,
                                                              children: [
                                                                // 1. The Media Container
                                                                ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8.0),
                                                                  child:
                                                                      Container(
                                                                    width: 80,
                                                                    height: 80,
                                                                    color: Colors
                                                                            .grey[
                                                                        200],
                                                                    child:
                                                                        Stack(
                                                                      fit: StackFit
                                                                          .expand,
                                                                      children: [
                                                                        // Render based on file type
                                                                        if (isVideo)
                                                                          VideoPreviewWidget(
                                                                              file: File(file))
                                                                        else
                                                                          Image
                                                                              .file(
                                                                            File(file),
                                                                            fit:
                                                                                BoxFit.cover,
                                                                          ),

                                                                        // Overlay a play icon if it's a video so the user knows it's not a photo
                                                                        // if (isVideo)
                                                                        //   const Center(
                                                                        //     child:
                                                                        //         Icon(
                                                                        //       Icons.play_circle_fill,
                                                                        //       size: 30,
                                                                        //       color: Colors.white70,
                                                                        //     ),
                                                                        //   ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),

                                                                // 2. The Red Cross Button Overlaid on Top
                                                                Positioned(
                                                                  top: 0,
                                                                  right: 0,
                                                                  child:
                                                                      GestureDetector(
                                                                    onTap: () {
                                                                      setstate(
                                                                          () {
                                                                        _selectedImage
                                                                            .removeAt(index);
                                                                      });
                                                                    },
                                                                    child:
                                                                        Container(
                                                                      decoration:
                                                                          const BoxDecoration(
                                                                        color: Colors
                                                                            .red,
                                                                        shape: BoxShape
                                                                            .circle,
                                                                      ),
                                                                      padding: const EdgeInsets
                                                                          .all(
                                                                          4.0),
                                                                      child: const Icon(
                                                                          Icons
                                                                              .close,
                                                                          size:
                                                                              14,
                                                                          color:
                                                                              Colors.white),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                if (_isLoading)
                                                  Center(
                                                      child: Column(
                                                    children: [
                                                      if (_leadstat != 1)
                                                        Container(
                                                          margin:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      24.0,
                                                                  vertical:
                                                                      16.0),
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(20.0),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .black
                                                                    .withValues(
                                                                        alpha:
                                                                            0.05),
                                                                blurRadius: 10,
                                                                offset:
                                                                    const Offset(
                                                                        0, 4),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min, // Wrap tightly around progress items
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  const Icon(
                                                                      Icons
                                                                          .cloud_upload_outlined,
                                                                      color: Colors
                                                                          .brown),
                                                                  const SizedBox(
                                                                      width:
                                                                          12),
                                                                  Expanded(
                                                                    child: Text(
                                                                      _uploadProgress >=
                                                                              1.0
                                                                          ? "Processing on server..."
                                                                          : "Uploading file data...",
                                                                      style:
                                                                          const TextStyle(
                                                                        fontSize:
                                                                            15,
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        color: Colors
                                                                            .black87,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  // Shows raw text layout percentage (e.g., 45%)
                                                                  Text(
                                                                    "${(_uploadProgress * 100).toStringAsFixed(0)}%",
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          15,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                          .brown,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              const SizedBox(
                                                                  height: 14),

                                                              // The actual linear bar displaying state data
                                                              ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            4), // Rounds the edges of the bar
                                                                child:
                                                                    LinearProgressIndicator(
                                                                  value:
                                                                      _uploadProgress,
                                                                  color: Colors
                                                                      .brown,
                                                                  backgroundColor:
                                                                      Colors
                                                                          .transparent,
                                                                  minHeight:
                                                                      8, // Makes the bar visually easy to track
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      const CircularProgressIndicator(
                                                          color: Colors.brown),
                                                    ],
                                                  )),
                                                Padding(
                                                    padding:
                                                        const EdgeInsets.all(5),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceAround,
                                                      children: [
                                                        ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  const Color
                                                                      .fromRGBO(
                                                                      252,
                                                                      101,
                                                                      8,
                                                                      1),
                                                              foregroundColor:
                                                                  Colors.white),
                                                          onPressed: _isLoading
                                                              ? null
                                                              : (() async {
                                                                  FocusScope.of(
                                                                          context)
                                                                      .unfocus();
                                                                  setstate(() {
                                                                    _isLoading =
                                                                        true;
                                                                  });
                                                                  var respcode =
                                                                      await submitdata(
                                                                          "true",
                                                                          _resendotp);
                                                                  if (respcode ==
                                                                          200 ||
                                                                      respcode ==
                                                                          201) {
                                                                    setstate(
                                                                        () {
                                                                      if (_leadstat ==
                                                                          1) {
                                                                        _isLoading =
                                                                            false;
                                                                      }
                                                                      ischeckedin =
                                                                          false;
                                                                    });
                                                                    if (_leadstat !=
                                                                        1) {
                                                                      var jcc = await openDialog(
                                                                          "Job Complete OTP",
                                                                          "Enter OTP");
                                                                      // setstate(
                                                                      //     () {

                                                                      //     });
                                                                      // List<String>
                                                                      //     leadids =
                                                                      //     [];
                                                                      // print("ino check: $ino");

                                                                      final resp = await http.post(
                                                                          Uri.parse(
                                                                              '$baseuri/api/verify-jcc/'),
                                                                          body: jsonEncode({
                                                                            "JCC":
                                                                                jcc ?? "",
                                                                            "LEAD_ID":
                                                                                _selectedfollowupproduct.map((item) => item.leadid).toList(),
                                                                            "PJC":
                                                                                _pjc,
                                                                            "ino":
                                                                                ino
                                                                          }),
                                                                          headers: {
                                                                            "Content-Type":
                                                                                "application/json"
                                                                          });
                                                                      if (resp.statusCode ==
                                                                          200) {
                                                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                                                            content:
                                                                                Text("OTP Verified Successfully"),
                                                                            backgroundColor: Colors.green));
                                                                      } else {
                                                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                                                            content:
                                                                                Text("OTP couldnot be verified. Please try again."),
                                                                            backgroundColor: Colors.red));
                                                                      }
                                                                    }

                                                                    Navigator.of(
                                                                            context)
                                                                        .pop(
                                                                            "Data saved");

                                                                    setstate(
                                                                        () {
                                                                      _isLoading =
                                                                          false;
                                                                    });

                                                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                                        content:
                                                                            const Text(
                                                                                "Data saved successfully"),
                                                                        backgroundColor:
                                                                            Colors.green[400]));
                                                                    // if (kDebugMode) {
                                                                    //   SendNotificationService.sendNotificationUsingApi(
                                                                    //       token:
                                                                    //           "test",
                                                                    //       title: "Lead Follow UP",
                                                                    //       body: "Party: $_pname\nProduct: ${_selectedfollowupproduct.map((item) => item.product).join(", ")}",
                                                                    //       data: {
                                                                    //         "screen":
                                                                    //             "detail",
                                                                    //         "pjc":
                                                                    //             _pjc,
                                                                    //         "pname":
                                                                    //             _pname
                                                                    //       });
                                                                    // } else {
                                                                    //   SendNotificationService.sendNotificationUsingApi(
                                                                    //       token:
                                                                    //           "all",
                                                                    //       title: "Lead Follow UP",
                                                                    //       body: "Party: $_pname\nProduct: ${_selectedfollowupproduct.map((item) => item.product).join(", ")}",
                                                                    //       data: {
                                                                    //         "screen":
                                                                    //             "detail",
                                                                    //         "pjc":
                                                                    //             _pjc,
                                                                    //         "pname":
                                                                    //             _pname
                                                                    //       });
                                                                    // }
                                                                  } else {
                                                                    setstate(
                                                                        () {
                                                                      _isLoading =
                                                                          false;
                                                                      ischeckedin =
                                                                          false;
                                                                    });
                                                                    // Navigator.of(
                                                                    //         context)
                                                                    //     .pop(
                                                                    //         "Data saved");
                                                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                                                        content:
                                                                            Text(
                                                                                "Something went wrong. Please try again."),
                                                                        backgroundColor:
                                                                            Colors.red));
                                                                  }
                                                                }),
                                                          child: _selectedstatus ==
                                                                  "Installation Completed"
                                                              ? const Text(
                                                                  "Save and Send OTP")
                                                              : const Text(
                                                                  "Save and Send"),
                                                        ),
                                                        // _selectedstatus ==
                                                        //         "Installation Completed"
                                                        //     ? ElevatedButton(
                                                        //         style: ElevatedButton.styleFrom(
                                                        //             backgroundColor: const Color
                                                        //                 .fromRGBO(
                                                        //                 252,
                                                        //                 101,
                                                        //                 8,
                                                        //                 1),
                                                        //             foregroundColor:
                                                        //                 Colors
                                                        //                     .white),
                                                        //         onPressed:
                                                        //             _isLoading
                                                        //                 ? null
                                                        //                 : (() async {
                                                        //                     setstate(() {
                                                        //                       _isLoading = true;
                                                        //                     });
                                                        //                     String queryparam = _selectedfollowupproduct.map((item) => "leadid=${item.leadid}").join("&");
                                                        //                     var respcode = await http.get(Uri.parse('$baseuri/api/ins_report/?$queryparam'));
                                                        //                     if (respcode.statusCode == 200 || respcode.statusCode == 201) {
                                                        //                       setstate(() {
                                                        //                         _isLoading = false;
                                                        //                         ischeckedin = false;
                                                        //                       });
                                                        //                       Navigator.of(context).pop("Data saved and Report Sent");
                                                        //                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Data saved and Report Sent successfully"), backgroundColor: Colors.green[400]));
                                                        //                     }
                                                        //                   }),
                                                        //         child:
                                                        //             const Text(
                                                        //           "Send Report",
                                                        //         ))
                                                        ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  const Color
                                                                      .fromRGBO(
                                                                      252,
                                                                      101,
                                                                      8,
                                                                      1),
                                                              foregroundColor:
                                                                  Colors.white),
                                                          onPressed: _isLoading
                                                              ? null
                                                              : (() async {
                                                                  setstate(() {
                                                                    _isLoading =
                                                                        true;
                                                                  });
                                                                  var respcode =
                                                                      await submitdata(
                                                                          "false",
                                                                          _resendotp);
                                                                  if (respcode ==
                                                                          200 ||
                                                                      respcode ==
                                                                          201) {
                                                                    setstate(
                                                                        () {
                                                                      _isLoading =
                                                                          false;
                                                                      ischeckedin =
                                                                          false;
                                                                    });
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop(
                                                                            "Data saved");
                                                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                                        content:
                                                                            const Text(
                                                                                "Data saved successfully"),
                                                                        backgroundColor:
                                                                            Colors.green[400]));
                                                                    // if (kDebugMode) {
                                                                    //   SendNotificationService.sendNotificationUsingApi(
                                                                    //       token:
                                                                    //           "test",
                                                                    //       title: "Lead Follow UP",
                                                                    //       body: "Party: $_pname\nProduct: ${_selectedfollowupproduct.map((item) => item.product).join(", ")}",
                                                                    //       data: {
                                                                    //         "screen":
                                                                    //             "detail",
                                                                    //         "pjc":
                                                                    //             _pjc,
                                                                    //         "pname":
                                                                    //             _pname
                                                                    //       });
                                                                    // } else {
                                                                    //   SendNotificationService.sendNotificationUsingApi(
                                                                    //       token:
                                                                    //           "all",
                                                                    //       title: "Lead Follow UP",
                                                                    //       body: "Party: $_pname\nProduct: ${_selectedfollowupproduct.map((item) => item.product).join(", ")}",
                                                                    //       data: {
                                                                    //         "screen":
                                                                    //             "detail",
                                                                    //         "pjc":
                                                                    //             _pjc,
                                                                    //         "pname":
                                                                    //             _pname
                                                                    //       });
                                                                    // }
                                                                  } else {
                                                                    setstate(
                                                                        () {
                                                                      _isLoading =
                                                                          false;
                                                                    });
                                                                    // Navigator.of(
                                                                    //         context)
                                                                    //     .pop(
                                                                    //         "Data saved");
                                                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                                                        content:
                                                                            Text(
                                                                                "Something went wrong. Please try again."),
                                                                        backgroundColor:
                                                                            Colors.red));
                                                                  }
                                                                }),
                                                          child: const Text(
                                                              "Save Details"),
                                                        ),
                                                      ],
                                                    ))
                                              ],
                                            ),
                                          ),
                                        )),
                                      ),
                                    );
                                  }),
                                ),
                              );
                            });
                        if (result != null) {
                          // assigndata();
                          Navigator.of(context).pop();
                          // setState(() {});
                        }
                      }
                    : null,
                child: const Text("Check Out"))
          ],
        ),
        childs: !_isdataLoaded
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView.builder(
                itemCount: meeting.length,
                itemBuilder: (context, index) {
                  var firstidx = meeting.indexWhere(
                      (meet) => meet.leadid == meeting[index].leadid);
                  var lastidx = meeting.lastIndexWhere(
                      (meet) => meet.leadid == meeting[index].leadid);
                  if (kDebugMode) {
                    print(
                      "firstidx: $firstidx, lastidx: $lastidx, index: $index, open: ${meeting[index].open}, reportlink: ${meeting[index].reportlink}, imagelink: ${meeting[index].imagelink}",
                    );
                  }
                  if ((index == firstidx)) {
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(5.0),
                            child: Container(
                              // Outer container for the border and background color
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 212, 234, 223),
                                // A color similar to the image's background
                                border: Border.all(
                                  color: Colors.grey, // Border color
                                  width: 1.0, // Border width
                                ),
                                borderRadius: BorderRadius.circular(
                                    5.0), // Optional: slight rounded corners
                              ),
                              padding: const EdgeInsets.all(
                                  6.0), // Padding inside the container
                              child: Column(
                                mainAxisSize: MainAxisSize
                                    .min, // To make the column only take necessary space
                                crossAxisAlignment: CrossAxisAlignment
                                    .start, // Align text to the start
                                children: [
                                  _buildInfoRow(
                                      'Created',
                                      meeting[index].createddate,
                                      'By',
                                      meeting[index].leadbyn,
                                      "Lead Type",
                                      "${meeting[index].leadtype} (${meeting[index].leadid})",
                                      _isAdmin,
                                      ""),
                                  const SizedBox(
                                      height: 8.0), // Space between rows
                                  _buildInfoRow(
                                      '',
                                      "",
                                      'To',
                                      meeting[index].leadton,
                                      "",
                                      "",
                                      _isAdmin,
                                      ""),
                                  const SizedBox(height: 8.0),
                                  _buildInfoRow(
                                      'Scheduled',
                                      meeting[index].scheduleMeeting,
                                      'For',
                                      meeting[index].product,
                                      "Status",
                                      "Open",
                                      _isAdmin,
                                      ""),
                                  const SizedBox(
                                      height:
                                          16.0), // Space before the "Comments" section
                                  Container(
                                    width: double.infinity, // Take full width
                                    color: const Color.fromARGB(255, 241, 211,
                                        132), // Yellowish background color
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12.0),
                                    alignment: Alignment.center,
                                    child: Text(
                                      meeting[index]
                                          .message
                                          .replaceAll("(New Lead Created)", ""),
                                      style: const TextStyle(
                                        color: Colors
                                            .black, // Black text for comments
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if ((meeting[index].visitdate.isNotEmpty))
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(5.0),
                              child: Container(
                                // Outer container for the border and background color
                                decoration: BoxDecoration(
                                  color: (index == lastidx) &
                                          (meeting[index].open == "N")
                                      ? const Color.fromARGB(255, 243, 180, 180)
                                      : const Color(
                                          0xFFF0E5D5), // A color similar to the image's background
                                  border: Border.all(
                                    color: Colors.grey, // Border color
                                    width: 1.0, // Border width
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      5.0), // Optional: slight rounded corners
                                ),
                                padding: const EdgeInsets.all(
                                    6.0), // Padding inside the container
                                child: Column(
                                  mainAxisSize: MainAxisSize
                                      .min, // To make the column only take necessary space
                                  crossAxisAlignment: CrossAxisAlignment
                                      .start, // Align text to the start
                                  children: [
                                    _buildInfoRow(
                                        'Checkin',
                                        meeting[index].visitdate,
                                        'By',
                                        meeting[index].leadbyn,
                                        "Lead Type",
                                        "${meeting[index].leadtype} (${meeting[index].leadid})",
                                        _isAdmin,
                                        meeting[index].checkinloca),
                                    const SizedBox(
                                        height: 8.0), // Space between rows
                                    _buildInfoRow(
                                        'Checkout',
                                        meeting[index].checkout,
                                        'To',
                                        meeting[index].leadton,
                                        "Created",
                                        meeting[firstidx].createddate,
                                        _isAdmin,
                                        meeting[index].checkoutloca),
                                    const SizedBox(height: 8.0),
                                    _buildInfoRow(
                                        'Next Visit',
                                        meeting[index].nextMeeting,
                                        'For',
                                        meeting[index].product,
                                        "Status",
                                        (index == lastidx) &
                                                (meeting[index].open == "N")
                                            ? "Closed"
                                            : "Open",
                                        _isAdmin,
                                        ""),
                                    const SizedBox(
                                        height:
                                            16.0), // Space before the "Comments" section
                                    Container(
                                      width: double.infinity, // Take full width
                                      color: const Color.fromARGB(255, 241, 211,
                                          132), // Yellowish background color
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10.0),
                                      alignment: Alignment.center,
                                      child: ((meeting[index].reportlink !=
                                                  null) ||
                                              (meeting[index].imagelink !=
                                                  null))
                                          ? Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Text("link found"),
                                                Text(
                                                  meeting[index]
                                                      .comments
                                                      .replaceAll(
                                                          RegExp(
                                                              r'\(Lead Open\)|\(Lead Closed\)'),
                                                          ""),
                                                  style: const TextStyle(
                                                    color: Colors
                                                        .black, // Black text for comments
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceAround,
                                                  children: [
                                                    if (meeting[index]
                                                            .reportlink !=
                                                        null)
                                                      TextButton(
                                                        onPressed: () {
                                                          // Handle report link action
                                                          openReportOnDemand(
                                                              meeting[index]);
                                                        },
                                                        child: const Text(
                                                            "View Report"),
                                                      ),
                                                    if (meeting[index]
                                                            .imagelink ==
                                                        true)
                                                      TextButton(
                                                        onPressed: () {
                                                          // Handle image link action
                                                          fetchImagesOnDemand(
                                                              meeting[index]);
                                                        },
                                                        child: const Text(
                                                            "View Images"),
                                                      ),
                                                  ],
                                                ),
                                                if (index == meeting.length - 1)
                                                  const SizedBox(height: 40.0),
                                              ],
                                            )
                                          : Text(
                                              meeting[index].comments.replaceAll(
                                                  RegExp(
                                                      r'\(Lead Open\)|\(Lead Closed\)'),
                                                  ""),
                                              style: const TextStyle(
                                                color: Colors
                                                    .black, // Black text for comments
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                      ],
                    );
                  } else {
                    if ((meeting[index].visitdate.isNotEmpty) &&
                        (index != firstidx)) {
                      // ((meeting[index].visitdate.isNotEmpty))) {
                      return Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(5.0),
                          child: Container(
                            // Outer container for the border and background color
                            decoration: BoxDecoration(
                              color: (index == firstidx) &
                                      (meeting[index].open == "Y")
                                  ? const Color.fromARGB(255, 212, 234, 223)
                                  : (index == lastidx) &
                                          (meeting[index].open == "N")
                                      ? const Color.fromARGB(255, 243, 180, 180)
                                      : const Color(
                                          0xFFF0E5D5), // A color similar to the image's background
                              border: Border.all(
                                color: Colors.grey, // Border color
                                width: 1.0, // Border width
                              ),
                              borderRadius: BorderRadius.circular(
                                  5.0), // Optional: slight rounded corners
                            ),
                            padding: const EdgeInsets.all(
                                6.0), // Padding inside the container
                            child: Column(
                              mainAxisSize: MainAxisSize
                                  .min, // To make the column only take necessary space
                              crossAxisAlignment: CrossAxisAlignment
                                  .start, // Align text to the start
                              children: [
                                _buildInfoRow(
                                    'Checkin',
                                    meeting[index].visitdate,
                                    'By',
                                    meeting[index].leadbyn,
                                    "Lead Type",
                                    "${meeting[index].leadtype} (${meeting[index].leadid})",
                                    _isAdmin,
                                    meeting[index].checkinloca),
                                const SizedBox(
                                    height: 8.0), // Space between rows
                                _buildInfoRow(
                                    'Checkout',
                                    meeting[index].checkout,
                                    'To',
                                    meeting[index].leadton,
                                    "Created",
                                    meeting[firstidx].createddate,
                                    _isAdmin,
                                    meeting[index].checkoutloca),
                                const SizedBox(height: 8.0),
                                _buildInfoRow(
                                    'Next Visit',
                                    meeting[index].nextMeeting,
                                    'For',
                                    meeting[index].product,
                                    "Status",
                                    (index == lastidx) &
                                            (meeting[index].open == "N")
                                        ? "Closed"
                                        : "Open",
                                    _isAdmin,
                                    ""),
                                const SizedBox(
                                    height:
                                        16.0), // Space before the "Comments" section
                                Container(
                                  width: double.infinity, // Take full width
                                  color: const Color.fromARGB(255, 241, 211,
                                      132), // Yellowish background color
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0),
                                  alignment: Alignment.center,
                                  child: ((meeting[index].reportlink != null) ||
                                          (meeting[index].imagelink != null))
                                      ? Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Text("link found"),
                                            Text(
                                              meeting[index].comments.replaceAll(
                                                  RegExp(
                                                      r'\(Lead Open\)|\(Lead Closed\)'),
                                                  ""),
                                              style: const TextStyle(
                                                color: Colors
                                                    .black, // Black text for comments
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),

                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: [
                                                if (meeting[index].reportlink !=
                                                    null)
                                                  TextButton(
                                                    onPressed: () {
                                                      // Handle report link action
                                                      openReportOnDemand(
                                                          meeting[index]);
                                                    },
                                                    child: const Text(
                                                        "View Report"),
                                                  ),
                                                if (meeting[index].imagelink ==
                                                    true)
                                                  TextButton(
                                                    onPressed: () {
                                                      // Handle image link action
                                                      fetchImagesOnDemand(
                                                          meeting[index]);
                                                    },
                                                    child: const Text(
                                                        "View Images"),
                                                  ),
                                              ],
                                            ),
                                            if (index == meeting.length - 1)
                                            const SizedBox(height: 40.0),
                                          ],
                                        )
                                      : Text(
                                          meeting[index].comments.replaceAll(
                                              RegExp(
                                                  r'\(Lead Open\)|\(Lead Closed\)'),
                                              ""),
                                          style: const TextStyle(
                                            color: Colors
                                                .black, // Black text for comments
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                },
              ));
  }

  Future<String?> openDialog(title, lablel) => showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: InputField(label: lablel, controller: _jcccontroller),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(_jcccontroller.text);
                },
                child: const Text("SUBMIT"))
          ],
        ),
      );

  void getproductinfo(String pjc, List<String> value) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Installation Product Details"),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<ProductAggregation>>(
            future: fetchInstProductDetails(pjc, value),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No data found'));
              } else {
                final products = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      title: Text("${product.product} - ${product.company}"),
                      subtitle: Column(
                        // CRITICAL: Aligns the content to the start (left)
                        crossAxisAlignment: CrossAxisAlignment.start,
                        // CRITICAL: Ensures the Column takes minimum vertical space,
                        // preventing layout issues inside the ListTile.
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. Display Charge and Company

                          // 3. Iterate and display each item from the list
                          // The .map().toList() creates a list of Text widgets from the List<String>
                          ...product.items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                  left:
                                      8.0), // Optional: Indent the items slightly
                              // You can prepend a bullet point (•) or a dash (-) for better formatting
                              child: Text(
                                  "• ${item.name} (Qty: ${item.quantity})"),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<List<ProductAggregation>>? fetchInstProductDetails(
      String pjc, List<String> value) async {
    final response = await http.get(Uri.parse(
        '$baseuri/api/instproductdetail/?pjc=$pjc&leadforp=${value.join(",")}'));
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      List<ProductAggregation> products = [];
      for (var item in body) {
        products.add(ProductAggregation.fromJson(item));
      }
      return products;
    } else {
      throw Exception('Failed to load installation product details');
    }
  }

  Future<List<InvItem>>? getinstitems(
      String pjc, List<String> list, String leadtype) async {
    final response = await http.post(Uri.parse('$baseuri/api/institems/'),
        body:
            jsonEncode({"pjc": pjc, "leadtype": leadtype, "productlist": list}),
        headers: {"Content-Type": "application/json"});
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      List<InvItem> items = [];
      // print(body);
      for (var item in body) {
        items.add(InvItem(
            code: item['CODE'],
            mc: "${item['MC']}",
            name: "${item['ITEM']} (Qty: ${item['QTY']})",
            id: "${item['id']}"));
      }
      if (kDebugMode) {
        print(
            "Fetched Installation Items: ${items.map((e) => e.toJson()).toList()}");
      }
      return items;
    } else {
      throw Exception('Failed to load installation items');
    }
  }
}
