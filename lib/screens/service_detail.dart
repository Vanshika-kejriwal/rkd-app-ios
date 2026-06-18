import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:business_app/constants.dart';
import 'package:business_app/models/leads.dart';
import 'package:business_app/models/utils.dart';
import 'package:business_app/screens/pdfview.dart';
import 'package:business_app/services/network_provider.dart';
import 'package:business_app/widgets/background.dart';
import 'package:business_app/widgets/input_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServiceDetail extends StatefulWidget {
  PendingInst? currentinst;
  ServiceDetail({super.key, this.currentinst});

  @override
  State<ServiceDetail> createState() => _ServiceDetailState();
}

class _ServiceDetailState extends State<ServiceDetail> {
  bool _isdataLoaded = false;
  List<ServiceDetailModel> meeting = [];
  Timer? _reloadTimer;
  final _mobcontroller = TextEditingController();
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
  bool _isAdmin = false;
  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();
  String? _selectedPhoneNumber;

  DateTime _parseDate(String dateStr) {
    try {
      List<String> parts = dateStr.split('/');
      // Assumes [dd, mm, yyyy]
      return DateTime(
        int.parse(parts[2]), // year
        int.parse(parts[1]), // month
        int.parse(parts[0]), // day
      );
    } catch (e) {
      return DateTime(1900); // Fallback for bad data
    }
  }

  Future<void> getmeetingdetail() async {
    String pjc = widget.currentinst!.pjc;
    final connectivityProvider =
        Provider.of<NetworkProvider>(context, listen: false);
    var sharedpref = await SharedPreferences.getInstance();
    var ut = sharedpref.getString('UT');
    try {
      final response =
          await http.get(Uri.parse('$baseuri/api/service_detail/?pjc=$pjc'));
      final body = json.decode(response.body);
      if (kDebugMode) {
        print(body);
      }
      if (response.statusCode == 200) {
        if (body.isEmpty) {
          setState(() {
            meeting = [];
          });
        } else {
          setState(() {
            meeting.clear();
            body.forEach((meet) {
              meeting.add(ServiceDetailModel(
                sno: meet["SERVICE_NO"],
                servicedate: meet["SERVICE_DATE"],
                producttype: meet["LEADFORP"] ?? '',
                company: meet["CNAME"] ?? '',
              ));
            });
            meeting.sort((a, b) {
              // 1. Sort by producttype (Alphabetical)
              int productCompare = a.producttype
                  .toLowerCase()
                  .compareTo(b.producttype.toLowerCase());
              if (productCompare != 0) return productCompare;

              // 2. Sort by company (Alphabetical)
              int companyCompare =
                  a.company.toLowerCase().compareTo(b.company.toLowerCase());
              if (companyCompare != 0) return companyCompare;

              // 3. Sort by servicedate (Chronological)
              // Assumes format dd/mm/yyyy - we split and rearrange to yyyymmdd for easy comparison
              DateTime dateA = _parseDate(a.servicedate);
              DateTime dateB = _parseDate(b.servicedate);
              int dateCompare = dateA.compareTo(dateB);
              if (dateCompare != 0) return dateCompare;

              // 4. Sort by sno (Numerical)
              // Parsing string to int so '10' comes after '2'
              int snoA = int.tryParse(a.sno) ?? 0;
              int snoB = int.tryParse(b.sno) ?? 0;
              return snoA.compareTo(snoB);
            });
          });
          // print(meeting);
        }
      } else {
        meeting = [];
      }
      setState(() {
        _isAdmin = ut == 'ADMIN';
        _isdataLoaded = true;
      });
    } on SocketException catch (_) {
      connectivityProvider.setConnected(false);
    } on http.ClientException catch (_) {
      connectivityProvider.setConnected(false);
    }
  }

  Future<void> getprojdetail(pjc) async {
    final response =
        await http.get(Uri.parse('$baseuri/api/projectdetail/$pjc/'));
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
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

        // _formkey.currentState?.validate();
      });
      // print("Pincode doesnt exists");
    }
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
        getmeetingdetail();
        getprojdetail(widget.currentinst!.pjc);
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
        appbar: true,
        childs: !_isdataLoaded
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView.builder(
                itemCount: meeting.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                flex: 3,
                                child: Text(
                                    "Product: ${meeting[index].producttype} (${meeting[index].company})")),
                            Expanded(
                                flex: 2,
                                child: Text(
                                    "Date: ${meeting[index].servicedate}")),
                          ],
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromRGBO(252, 101, 8, 1),
                                foregroundColor: Colors.white),
                            onPressed: () async {
                              // var mob = await openDialog(
                              //     "Send installation Report", "Mobile Number");
                              var sno = meeting[index].sno;
                                if (context.mounted) {
                                  QuickAlert.show(
                                      context: context,
                                      type: QuickAlertType.loading,
                                      title: "Generating Report",
                                      barrierDismissible: false);
                                }
                                // String queryparam = "ino=$ino&mob=$mob";
                                var respcode = await http.get(Uri.parse(
                                    '$baseuri/api/servicereport/?serviceno=$sno')); 
                                // if (context.mounted) {
                                //   Navigator.pop(context);
                                // }
                                if (respcode.statusCode == 200 ||
                                    respcode.statusCode == 201) {
                                    final jsonResponse =
                                                    jsonDecode(respcode.body);

                                                // --- Extracting Mobile Numbers and Filename ---

                                                final List<String>
                                                    mobileNumbers =
                                                    jsonResponse[
                                                            'mobile_numbers']
                                                        .where((item) =>
                                                            item != null)
                                                        .toList()
                                                        .cast<String>();
                                                final String filename =
                                                    jsonResponse['filename'];

                                                print(
                                                    '✅ Received Mobile Numbers: $mobileNumbers');
                                                print('✅ Filename: $filename');

                                                // --- Decoding and Saving the PDF File ---

                                                final String base64Pdf =
                                                    jsonResponse['pdf_data'];

                                                // 3. Base64 Decode the PDF string into raw bytes (Uint8List)
                                                final pdfBytes =
                                                    base64Decode(base64Pdf);
                                                final dir =
                                                    await getTemporaryDirectory();
                                                final filepath =
                                                    '${dir.path}/Service Report (${widget.currentinst?.pjc})-${DateTime.now().millisecondsSinceEpoch}.pdf';
                                                File file = File(filepath);
                                                await file
                                                    .writeAsBytes(pdfBytes);
                                                Navigator.of(context)
                                                    .pop(); // Close the loading dialog
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        Pdfview(
                                                      file: file,
                                                      type: "Service Report",
                                                      ac: widget.currentinst!.pjc,
                                                      doclink: jsonResponse['link'],
                                                      mobileNumbers:
                                                          mobileNumbers,
                                                          sno: sno,
                                                    ),
                                                  ),
                                                );
                                  // if (context.mounted) {
                                  //   QuickAlert.show(
                                  //       context: context,
                                  //       type: QuickAlertType.success,
                                  //       title: "Report Generated",
                                  //       text: "Successfully generated Report");
                                  // }
                                  _mobcontroller.clear();
                                  //successfully sent message
                                } else {
                                  //something went wrong
                                  if (context.mounted) {
                                    QuickAlert.show(
                                        context: context,
                                        type: QuickAlertType.error,
                                        title: "Could not send Message",
                                        text: "Something went Wrong");
                                  }
                                }
                              
                            },
                            child: Text(
                                "View Report for Service No ${meeting[index].sno}")),
                        const Divider(
                          thickness: 2.0,
                        )
                      ],
                    ),
                  );
                }),
        appbartitle: GestureDetector(
          onTap: () {
            showDialog(
                context: context,
                builder: (context) => AlertDialog(
                      title: Text(widget.currentinst!.pname),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SelectableText("Owner Name - $_name"),
                          SelectableText("Owner Mobile Number - $_ownermobile"),
                          SelectableText("Mobile 1 - $_mobile1"),
                          SelectableText("Mobile 2 - $_mobile2"),
                          SelectableText(
                              "Address - $_add1 $_add2 $_city $_district $_state")
                        ],
                      ),
                    ));
          },
          child: Text(widget.currentinst!.pname),
        ),
        appbaractions: const []);
  }

  Future<String?> openDialog(title, lablel) => showDialog(
        // barrierDismissible: false,
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: InputField(
              label: lablel,
              controller: _mobcontroller,
              sufficon: IconButton(
                  onPressed: () async {
                    Contact? contact = await _contactPicker.selectPhoneNumber();
                    setState(() {
                      _selectedPhoneNumber = contact?.selectedPhoneNumber;
                      if (_selectedPhoneNumber != null) {
                        var phno = _selectedPhoneNumber!.replaceAll(" ", "");
                        _mobcontroller.text = phno.substring(phno.length - 10);

                        _selectedPhoneNumber = null;
                      }
                    });
                  },
                  icon: const Icon(Icons.contacts))),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(_mobcontroller.text);
                },
                child: const Text("SUBMIT"))
          ],
        ),
      );
}
