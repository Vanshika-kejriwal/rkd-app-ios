import 'dart:convert';
import 'dart:io';

import 'package:business_app/constants.dart';
import 'package:business_app/models/installation.dart';
import 'package:business_app/models/utils.dart';
import 'package:business_app/services/location.dart';
import 'package:business_app/widgets/background.dart';
import 'package:business_app/widgets/input_field.dart';
import 'package:business_app/widgets/progressive_multipartrequest.dart';
import 'package:business_app/widgets/videopreview.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_compress/video_compress.dart';

class Installationcheckout extends StatefulWidget {
  String pname;
  String pjc;
  List<Product> products;
  Installationcheckout(
      {super.key,
      required this.pname,
      required this.pjc,
      required this.products});

  @override
  State<Installationcheckout> createState() => _InstallationcheckoutState();
}

class _InstallationcheckoutState extends State<Installationcheckout> {
  List<Product> products = [];
  List<Product> filterproducts = [];
  List<InstallItem> _selectedinstallationitems = [];
  List<LeadCategory> _category = [];
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
  final _formkey = GlobalKey<FormState>();
  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();
  double _charge1 = 0.0;
  double _charge2 = 0.0;
  double _charge3 = 0.0;
  double _gstPercent = 18.0; // Default GST
  double _uploadProgress = 0.0;
  // Calculated field
  double _gstAmount = 0.0;
  String _selectedstatus = '';
  String _selectedgst = '';
  LeadCategory? _selectedcategory;
  final String _pname = '';
  String _checkoutloca = '';
  bool _isLoading = false;
  bool _showquestions = true;
  // bool _isAdmin = false;
  bool _resendotp = false;
  bool _dataupload = false;
  final _commentcontroller = TextEditingController();
  String? _ut;
  final _nextfudatecontroller = TextEditingController();
  String? _selectedfollowupby;
  String? _selectedinsbyour;
  String? _selectedleadtype;
  List<Product> _selectedfollowupproduct = [];
  int _leadstat = 1;
  bool _questionsanswered = false;
  final Map<String, Map<String, dynamic>> answersMap = {};
  final ImagePicker _picker = ImagePicker();
  final List<String> _selectedImage = [];

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
        _selectedcategory = LeadCategory(
          ddl12: body["CATEGORY"],
          enabled: true,
        );
        // _selectedcategory?.ddl12 = body["CATEGORY"];
        // _selectedcategory?.enabled = true;
        _commentcontroller.text = body["COMMENTS"] ?? "";
        _selectedinsbyour = body["IBYOUR"] ?? "";
        if ((_selectedcategory?.ddl12 == "Paid Basis") ||
            (_selectedcategory?.ddl12 == "Obligatory Service")) {
          _selectedgst = body["GSTP"];
          _sparechargecontroller.text = body["SPARE_CHARGE"] ?? "";
          _servicechargecontroller.text = body["SERVICE_CHARGE"] ?? "";
          _otherchargecontroller.text = body["OTHER_CHARGE"] ?? "";
          _gstamountcontroller.text = body["GST"] ?? "";
        }
        if (_selectedcategory?.ddl12 == "Under AMC") {
          _amcdatecontroller.text = body["INSTALLATION_DATE"] ?? "";
        }
        if (_selectedcategory?.ddl12 ==
            "Free Service as per Installation Agreement") {
          _installdatecontroller.text = body["INSTALLATION_DATE"] ?? "";
        }

        // Clear previous states before populating
        _selectedinstallationitems.clear();
        answersMap.clear();
        body['waranty']?.forEach((warranty) {
          String leadid = warranty['leadid'];
          // Store warranty info in a map for easy access later
          _selectedfollowupproduct.firstWhere(
              (product) => product.leadid == leadid,
              orElse: () => Product(
                  leadid: leadid,
                  product: '',
                  wpm: '',
                  fsp: '',
                  leadtype: 'INSTALLATION'))
            ..wpm = warranty['wpm']
            ..fsp = warranty['fsp'];
        });
        // Process items and their answers
        body["items"]?.forEach((item) {
          final installItem = InstallItem(
            code: item['CODE'],
            mc: "${item['MC']}",
            leadid: "${item['LEAD_ID']}",
            name: "${item['ITEM']} (Qty: ${item['QTY']})",
            id: "${item['id']}",
            subCategoryName: "${item['subcategory'] ?? ''}",
          );

          _selectedinstallationitems.add(installItem);

          // Populate answersMap and controllers for this specific item using uniqueKey
          if (item['answers'] != null) {
            Map<String, dynamic> rawAnswers = item['answers'];
            answersMap[installItem.uniqueKey] = {};

            rawAnswers.forEach((qText, answer) {
              String ansStr = answer.toString();
              answersMap[installItem.uniqueKey]![qText] = ansStr;

              // Handle Split types (e.g. "25 / 45")
              if (ansStr.contains(' / ')) {
                List<String> parts = ansStr.split(' / ');
                if (parts.length == 2) {
                  answersMap[installItem.uniqueKey]!["${qText}_pt1"] = parts[0];
                  answersMap[installItem.uniqueKey]!["${qText}_pt2"] = parts[1];

                  _controllers["${installItem.uniqueKey}_${qText}_pt1"]?.text =
                      parts[0];
                  _controllers["${installItem.uniqueKey}_${qText}_pt2"]?.text =
                      parts[1];
                }
              } else {
                // Standard single text/dropdown/date controller
                _controllers["${installItem.uniqueKey}_$qText"]?.text = ansStr;
              }
            });
          }
        });

        _leadstat = 2;
        _resendotp = true;
        _questionsanswered = true;
      });
    }
    getcategory();
    ss(() {
      _isLoading = false;
    });
  }

  Future<void> sendserviceotp(ss) async {
    ss(() {
      _isLoading = true;
    });
    final response = await http.post(Uri.parse('$baseuri/api/instotp/'),
        body: {'pjc': widget.pjc, "mob": _mobforotpcontroller.text});

    if (response.statusCode == 200) {
      ss(() {
        _openotpfield = true;
      });
    }
    ss(() {
      _isLoading = false;
    });
  }

  Future<void> getcategory() async {
    final response = await http.get(Uri.parse(
        '$baseuri/api/leadstatcategory/?status=$_selectedstatus&type=SERVICE&pjc=${widget.pjc}&product=${_selectedfollowupproduct.first.product}&items=${_selectedinstallationitems.map((item) => item.code).toList().join(",")}'));
    final body = json.decode(response.body);
    List<LeadCategory> names = [];
    var insDate = "";
    var amcDate = "";
    if (response.statusCode == 200) {
      for (var c in body) {
        // print(c['DDL12']);
        // print(c['inst_date']);
        names.add(LeadCategory(
            ddl12: c['DDL12'],
            enabled: c['is_enabled'],
            extrainfo: c['extra_info']));
        if (c["inst_date"] != null) {
          insDate = c["inst_date"];
        }
        if (c["amc_date"] != null) {
          amcDate = c["amc_date"];
        }
      }
      setState(() {
        _category = names;
        _installdatecontroller.text = insDate;
        _amcdatecontroller.text = amcDate;
      });
    }
  }

  Future<List<PaidRowData>> fetchTableData() async {
    final url = Uri.parse(
        '$baseuri/api/paidbasischarge/?leadid=${_selectedfollowupproduct.map((item) => item.leadid).toList().join(",")}'); // Replace with your endpoint

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => PaidRowData.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load data: Status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

// 3. Display the Table in the AlertDialog
  void showResponsiveApiDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;

        return AlertDialog(
          title: const Text('Paid Basis Charges'),
          content: SizedBox(
            width: screenSize.width * 0.85,
            height: screenSize.height * 0.6,
            // FutureBuilder listens to the API function
            child: FutureBuilder<List<PaidRowData>>(
              future: fetchTableData(),
              builder: (context, snapshot) {
                // Show loading spinner while fetching
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Show error message if API fails
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                // Show message if data is empty
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No data found'));
                }

                final data = snapshot.data!;

                // Build the dual-scroll table when data arrives
                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Product')),
                        DataColumn(label: Text('Company')),
                        DataColumn(label: Text('Model')),
                        DataColumn(label: Text('Condition 1')),
                        DataColumn(label: Text('Condition 2')),
                        DataColumn(label: Text('Charges')),
                      ],
                      rows: data.map((item) {
                        return DataRow(cells: [
                          DataCell(Text(item.col1)),
                          DataCell(Text(item.col2)),
                          DataCell(Text(item.col3)),
                          DataCell(Text(item.col4)),
                          DataCell(Text(item.col5)),
                          DataCell(Text(item.col6))
                        ]);
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
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

  Future<int> submitdata(String sendmsg, bool resendotp) async {
    var locaurl = await getLocation();
    setState(() {
      _isLoading = true;
      _dataupload = true;
      _uploadProgress = 0.0; // Initialize progress tracking state
      _checkoutloca = locaurl;
    });

    var sp = await SharedPreferences.getInstance();
    String encodedcheckin = sp.getString("checkindata_${widget.pjc}") as String;
    Map<String, dynamic> decodecheckin = json.decode(encodedcheckin);
    // final String leadforp = _selectedfollowupproduct!.product;

    if (kDebugMode) {
      // print(leadforp);
    }

    // 1. Initialize our custom Progress tracking request
    final url = Uri.parse('$baseuri/api/installationcheckout/');
    final request = ProgressMultipartRequest(
      'POST',
      url,
      onProgress: (bytesTransferred, totalBytes) {
        if (totalBytes <= 0) return;
        setState(() {
          _uploadProgress = (bytesTransferred / totalBytes);
        });
      },
    );

    // 3. Map your standard textual/scalar payloads into request.fields
    // Note: Multipart request fields MUST map explicitly as String to String.
    request.fields.addAll({
      "CURR_NAME": sp.getString("NAME") ?? "",
      "CURR_MOB": sp.getString("Mobile") ?? "",
      'PJC': decodecheckin["pjc"]?.toString() ?? "",
      // 'LEADFORP': leadforp,
      'CHECKIN': decodecheckin["checkin_time"]?.toString() ?? "",
      'CHECKIN_LOCA': decodecheckin["checkin_loca"]?.toString() ?? "",
      'LEAD_TYPE': "INSTALLATION",
      // "LEAD_ID": _selectedfollowupproduct!.leadid.toString(),
      'CONTP': _instcontpnamecontroller.text,
      'COMMENTS': _commentcontroller.text,
      'NEXT_FUBY': _selectedfollowupby ?? "",
      'CHECKOUT': DateTime.now().toString(),
      'OPEN': _leadstat == 1 ? "Y" : "N",
      'CHECKOUT_LOCA': _checkoutloca ?? "",
      'NEXT_FUDATETIME': _nextfudatecontroller.text,
      "STATUS": _selectedstatus ?? "",
      "CATEGORY": _selectedcategory!.ddl12 ?? "",
      "SPARE PART COST": _sparepartcostcontroller.text,
      "SPARE PART NAME": _sparepartnamecontroller.text,
      "AMC DATE": _amcdatecontroller.text,
      "INSTALLATION_DATE": _installdatecontroller.text,
      "SERVICE_CHARGE":
          double.tryParse(_servicechargecontroller.text)?.toStringAsFixed(2) ??
              "0.00",
      "SPARE_CHARGE":
          double.tryParse(_sparechargecontroller.text)?.toStringAsFixed(2) ??
              "0.00",
      "OTHER_CHARGE":
          double.tryParse(_otherchargecontroller.text)?.toStringAsFixed(2) ??
              "0.00",
      "GSTP": _selectedgst ?? "",
      "GST": double.tryParse(_gstamountcontroller.text)?.toStringAsFixed(2) ??
          "0.00",
      "SEND_MSG": sendmsg,
      'IBYOUR': _selectedinsbyour ?? "",
      'waranty_period': _selectedfollowupproduct.isNotEmpty
          ? jsonEncode(_selectedfollowupproduct
              .map((p) => {
                    'leadid': p.leadid,
                    'wpm': p.wpm,
                    'fsp': p.fsp,
                  })
              .toList())
          : "",
      "institems": jsonEncode(_selectedinstallationitems.map((item) {
        // Build sequential Q1, A1, Q2, A2 map for this specific item
        Map<String, dynamic> numberedAnswers = {};
        int index = 1;

        for (var question in item.questions) {
          String qText = question['q'];
          dynamic answerValue = answersMap[item.uniqueKey]?[qText] ?? "";

          numberedAnswers["Q$index"] = qText;
          numberedAnswers["A$index"] = answerValue;
          index++;
        }

        return {
          'leadid': item.leadid,
          'id': item.id,
          'mc': item.mc,
          'code': item.code,
          'answers': numberedAnswers,
        };
      }).toList()),
      "MOBFOROTP": _mobforotpcontroller.text,
      "RESEND_OTP":
          sendmsg == "false" ? "false" : (resendotp ? "true" : "false"),

      // Complex lists must be explicitly serialized to JSON strings for Multipart collections
    });

    // 4. Inject Dynamic Question/Answer pairs into fields

    // 5. ATTACH THE PRE-OPTIMIZED MEDIA FILES
    // Assumes files were compressed right at selection, otherwise invoke optimizeMediaNative(path) here
    for (String path in _selectedImage) {
      if (path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'media_files', // Matches Django's request.FILES.getlist('media_files')
              file.path,
            ),
          );
        }
      }
    }

    // 6. Execute Request Stream
    try {
      final streamedResponse = await request.send();
      final resp = await http.Response.fromStream(streamedResponse);

      if (resp.body.isNotEmpty) {
        var responseBody = jsonDecode(resp.body);
        // Optional: process 'ino' if returned by your Django view code
      }

      sp.remove("checkindata_${widget.pjc}");

      setState(() {
        _isLoading = false;
        _dataupload = false;
      });

      return resp.statusCode;
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (kDebugMode) {
        print("Upload execution error: $e");
      }
      return 500;
    }
  }

  Future<int> submitotp(String otp) async {
    setState(() {
      _isLoading = true;
    });
    final response =
        await http.patch(Uri.parse('$baseuri/api/instotp/'), body: {
      'pjc': widget.pjc,
      "otp": otp,
      "leadid": _selectedfollowupproduct
          .map((item) => item.leadid)
          .toList()
          .join(","),
      "mob": _mobforotpcontroller.text,
      "name": _instcontpnamecontroller.text
    });

    if (response.statusCode == 200) {
      setState(() {
        _isLoading = false;
      });
      return 200;
    } else {
      setState(() {
        _isLoading = false;
      });
      return response.statusCode;
    }
  }

  Future<List<InstallItem>>? getinstitems(
      String pjc, list, String leadtype) async {
    final response =
        await http.post(Uri.parse('$baseuri/api/installationitems/'),
            body: jsonEncode({
              "pjc": pjc,
              "leadtype": leadtype,
              "productlist": list
                  .map((item) => {
                        'leadid':
                            item.leadid, // or whatever key holds your lead id
                        'product': item
                            .product, // using the item CODE or relevant product key
                      })
                  .toList(),
            }),
            headers: {"Content-Type": "application/json"});
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      List<InstallItem> items = [];
      // print(body);
      for (var item in body) {
        items.add(InstallItem(
            leadid: "${item['LEAD_ID']}",
            code: item['CODE'],
            mc: "${item['MC']}",
            name: "${item['ITEM']} (Qty: ${item['QTY']})",
            id: "${item['id']}",
            subCategoryName: "${item['subcategory']}"));
      }
      if (kDebugMode) {
        // print(
        //     "Fetched Installation Items: ${items.map((e) => e.toJson()).toList()}");
      }
      return items;
    } else {
      throw Exception('Failed to load installation items');
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

  // 1. Map to store answers dynamically: {"Question Text" : "Answer Value"}
  final Map<String, String> _answers = {};
  final Map<String, TextEditingController> _controllers = {};

  TextEditingController _getOrCreateController(String key, String initialText) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: initialText);
    }
    return _controllers[key]!;
  }

  @override
  void dispose() {
    // 2. IMPORTANT: Clean up controllers to prevent memory leaks
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  bool _openotpfield = false;

  // The Switch Case logic to return the specific field set
  Widget _buildConditionalFields() {
    if (_selectedinstallationitems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
            "Please select items from the dropdown above to view questions."),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _selectedinstallationitems.length,
      itemBuilder: (context, index) {
        final item = _selectedinstallationitems[index];

        // Ensure inner map exists for this specific item
        answersMap[item.uniqueKey] ??= {};

        return Card(
          key: ValueKey(item.uniqueKey),
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Header Info
                Text(
                  "Item: ${item.name}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontSize: 15),
                ),
                Text(
                  "Subcategory: ${item.subCategoryName}",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const Divider(height: 20),

                // Render questions for this item using your product list mapping
                ...item.questions.where((question) {
                  String qText = question['q'];

                  // Conditional rule for "Insulation Date"
                  if (qText == "Insulation Date") {
                    // Check what the user selected for "Pre Insulated?"
                    String? preInsulatedAnswer =
                        answersMap[item.uniqueKey]?["Pre Insulated?"];
                    return preInsulatedAnswer ==
                        "No"; // Only show if answer is "No"
                  }
                  if (item.subCategoryName.toLowerCase() == "smart panel") {
                    if (qText == "On Time Set" || qText == "Off Time Set") {
                      // Check if any selected item is "other pumps" and has "Installed For?" == "Return Line"
                      bool isReturnLineOtherPump =
                          _selectedinstallationitems.any((otherItem) {
                        if (otherItem.subCategoryName.toLowerCase() ==
                            "other pumps") {
                          String? installedFor = answersMap[otherItem.uniqueKey]
                              ?["Installed For?"];
                          return installedFor == "Return Line";
                        }
                        return false;
                      });
                      return isReturnLineOtherPump; // Only show if an other pump is set to "Return Line"
                    }
                  }
                  return true; // Show all other questions normally
                }).map((question) => _renderField(item, question)),
              ],
            ),
          ),
        );
      },
    );
  }

  // Factory widget to build Dropdown, Split Row, or Text Field
  Widget _renderField(InstallItem item, Map<String, dynamic> question) {
    final String qText = question['q'];
    final String type = question['type'];
    final List<String>? labels = question['labels'];
    final String uniqueKey = item.uniqueKey;

    answersMap[uniqueKey] ??= {};

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(qText,
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          const SizedBox(height: 6),
          if (type == 'dropdown')
            DropdownSearch<String>(
              items: (filter, infiniteScrollProps) =>
                  const ["Yes", "No", "Not Applicable"],
              selectedItem: (() {
                // Determine the value (saved answer or default "Yes")
                String currentVal = (answersMap[uniqueKey]?[qText] != null &&
                        answersMap[uniqueKey]?[qText] != "")
                    ? answersMap[uniqueKey]![qText]
                    : "Yes";

                // Automatically record the default into the map if it's currently empty
                if (answersMap[uniqueKey]?[qText] == null ||
                    answersMap[uniqueKey]?[qText] == "") {
                  answersMap[uniqueKey]?[qText] = currentVal;
                }

                return currentVal;
              })(),
              popupProps: const PopupProps.dialog(
                dialogProps: DialogProps(
                    barrierDismissible: true, barrierLabel: "Dismiss"),
                showSearchBox: true,
              ),
              decoratorProps: const DropDownDecoratorProps(
                decoration: InputDecoration(
                  labelText: "",
                  hintText: "Select an option",
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              onSelected: (val) {
                setState(() {
                  answersMap[uniqueKey]?[qText] = val ?? '';
                });
              },
            )
          else if (type == 'pump type')
            DropdownSearch<String>(
              items: (filter, infiniteScrollProps) => const [
                "Primary Circulation",
                "Return Line",
                "De-Watering",
                "Water Transfer",
                "Filter Feed",
                "Booster"
              ],
              selectedItem: answersMap[uniqueKey]?[qText] != null &&
                      answersMap[uniqueKey]?[qText] != ""
                  ? answersMap[uniqueKey]![qText]
                  : null,
              popupProps: const PopupProps.dialog(
                dialogProps: DialogProps(
                    barrierDismissible: true, barrierLabel: "Dismiss"),
                showSearchBox: true,
              ),
              decoratorProps: const DropDownDecoratorProps(
                decoration: InputDecoration(
                  labelText: "",
                  hintText: "Select an option",
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              onSelected: (val) {
                setState(() {
                  answersMap[uniqueKey]?[qText] = val ?? '';
                });
              },
            )
          else if (type == 'split' && labels != null)
            Row(
              children: [
                Expanded(
                  child: InputField(
                    label: labels[0],
                    controller: _getOrCreateController(
                      "${uniqueKey}_${qText}_pt1",
                      answersMap[uniqueKey]?["${qText}_pt1"] ?? "",
                    ),
                    onChanged: (val) {
                      answersMap[uniqueKey]?["${qText}_pt1"] = val;
                      String pt2 = answersMap[uniqueKey]?["${qText}_pt2"] ?? "";
                      answersMap[uniqueKey]?[qText] = "$val / $pt2";
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InputField(
                    label: labels[1],
                    controller: _getOrCreateController(
                      "${uniqueKey}_${qText}_pt2",
                      answersMap[uniqueKey]?["${qText}_pt2"] ?? "",
                    ),
                    onChanged: (val) {
                      answersMap[uniqueKey]?["${qText}_pt2"] = val;
                      String pt1 = answersMap[uniqueKey]?["${qText}_pt1"] ?? "";
                      answersMap[uniqueKey]?[qText] = "$pt1 / $val";
                    },
                  ),
                ),
              ],
            )
          else if (type == 'date')
            InputField(
              label: qText,
              controller: _getOrCreateController(
                "${uniqueKey}_$qText",
                answersMap[uniqueKey]?[qText] ?? "",
              ),
              readOnly: true,
              onTap: () async {
                DateTime? pickedDate = await showOmniDateTimePicker(
                  type: OmniDateTimePickerType.date,
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  is24HourMode: false,
                );
                if (pickedDate != null) {
                  String formattedDate =
                      DateFormat('dd/MM/yyyy').format(pickedDate);
                  setState(() {
                    answersMap[uniqueKey]?[qText] = formattedDate;
                    _controllers["${uniqueKey}_$qText"]?.text = formattedDate;
                  });
                }
              },
            )
          else // Single Text Field
            InputField(
              label: "Enter Value",
              controller: _getOrCreateController(
                "${uniqueKey}_$qText",
                answersMap[uniqueKey]?[qText] ?? "",
              ),
              onChanged: (val) {
                answersMap[uniqueKey]?[qText] = val;
              },
            ),
        ],
      ),
    );
  }

  @override
  void initState() {
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _ut = prefs.getString("UT") ?? "";
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double swidth = MediaQuery.of(context).size.width;

    return Background(
        appbar: true,
        childs: Center(
          child: SafeArea(
            child: SizedBox(
              width: swidth * 0.8,
              child: Form(
                  key: _formkey,
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Text(
                              widget.pname,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),

                          Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: DropdownSearch<Product>.multiSelection(
                                itemAsString: (Product item) {
                                  return item.product;
                                },
                                compareFn: (Product item1, Product item2) {
                                  return item1.leadid ==
                                      item2
                                          .leadid; // Or whatever unique property your Product model uses
                                },
                                popupProps:
                                    const MultiSelectionPopupProps.dialog(
                                        dialogProps: DialogProps(
                                            barrierDismissible: true,
                                            barrierLabel: "Dismiss"),
                                        // showSelectedItems:
                                        //     true,
                                        showSearchBox: true),
                                // mode: Mode.dialog,
                                // showSelectedItems: true,
                                items: (filter, infiniteScrollProps) =>
                                    widget.products,
                                decoratorProps: const DropDownDecoratorProps(
                                  decoration: InputDecoration(
                                    labelText: "Follow-up For Product",
                                    hintText: "Select a Product",
                                  ),
                                ),
                                onSelected: (value) async {
                                  setState(() {
                                    _resendotp = false;
                                    _selectedfollowupproduct = value;
                                    _answers.clear();
                                    _selectedstatus = "";
                                    _selectedcategory = null;
                                    _selectedinstallationitems = [];
                                    _controllers.forEach((key, controller) =>
                                        controller.clear()); // Reset visuals
                                    _sparepartnamecontroller.clear();
                                    _sparepartcostcontroller.clear();
                                    _servicechargecontroller.clear();
                                    _sparechargecontroller.clear();
                                    _otherchargecontroller.clear();
                                    _gstamountcontroller.clear();
                                    _installdatecontroller.clear();
                                    _amcdatecontroller.clear();
                                    _mobforotpcontroller.clear();
                                    _jcccontroller.clear();
                                    _instcontpnamecontroller.clear();
                                    _selectedgst = "";
                                    _commentcontroller.clear();
                                  });
                                  await fetchcheckoutdetail(
                                      _selectedfollowupproduct, setState);
                                },
                                selectedItems: _selectedfollowupproduct,
                              )),

                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: DropdownSearch<String>(
                                enabled: !_resendotp,
                                popupProps: const PopupProps.dialog(
                                    dialogProps: DialogProps(
                                        barrierDismissible: true,
                                        barrierLabel: "Dismiss"),
                                    showSelectedItems: true,
                                    showSearchBox: false),
                                // mode: Mode.dialog,
                                // showSelectedItems: true,
                                items: (filter, infiniteScrollProps) => const [
                                      "Installation Completed",
                                      "Job Not Completed"
                                    ],
                                decoratorProps: const DropDownDecoratorProps(
                                  decoration: InputDecoration(
                                    labelText: "Lead Status",
                                    hintText: "Select status",
                                  ),
                                ),
                                onSelected: (value) {
                                  setState(() {
                                    _category.clear();
                                    _selectedstatus = value!;
                                    if (_selectedstatus ==
                                        "Job Not Completed") {
                                      _leadstat = 1;
                                    } else {
                                      _leadstat = 2;
                                    }
                                    getcategory();
                                  });
                                },
                                selectedItem: _selectedstatus),
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
                            //               setState(() {
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
                            //               setState(() {
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
                          if (_selectedstatus == "Installation Completed")
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: FutureBuilder<List<InstallItem>>(
                                  future: getinstitems(widget.pjc,
                                      _selectedfollowupproduct, "INSTALLATION"),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return DropdownSearch<
                                          InstallItem>.multiSelection(
                                        // enabled: !_resendotp,
                                        popupProps:
                                            const MultiSelectionPopupProps
                                                .dialog(
                                                dialogProps: DialogProps(
                                                    barrierDismissible: true,
                                                    barrierLabel: "Dismiss"),
                                                showSelectedItems: true,
                                                showSearchBox: true),
                                        // mode: Mode.dialog,
                                        // showSelectedItems: true,
                                        items: (filter, infiniteScrollProps) =>
                                            snapshot.data!,
                                        itemAsString: (item) => item.name,
                                        compareFn: (item1, item2) =>
                                            item1.id == item2.id,
                                        decoratorProps:
                                            const DropDownDecoratorProps(
                                          decoration: InputDecoration(
                                            labelText: "Select Products",
                                            hintText: "Select a Product",
                                          ),
                                        ),

                                        onSelected: (value) {
                                          setState(() {
                                            _selectedinstallationitems = value;
                                            getcategory();
                                          });
                                        },
                                        selectedItems:
                                            _selectedinstallationitems,
                                      );
                                    } else {
                                      // print(snapshot.error);
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }
                                  }),
                            ),
                          // waranty period
                          if ((_showquestions) && (_leadstat != 1))
                            ..._selectedfollowupproduct.map((product) {
                              // Set default values safely only if they are null
                              product.fsp ??= "12 Months";
                              // product.wpm ??= "12 Months";

                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: DropdownSearch<String>(
                                      popupProps: const PopupProps.dialog(
                                        dialogProps: DialogProps(
                                          barrierDismissible: true,
                                          barrierLabel: "Dismiss",
                                        ),
                                        showSelectedItems: true,
                                        showSearchBox: false,
                                      ),
                                      items: (filter, infiniteScrollProps) =>
                                          const [
                                        "6 Months",
                                        "12 Months",
                                        "24 Months",
                                        "36 Months"
                                      ],
                                      decoratorProps: DropDownDecoratorProps(
                                        decoration: InputDecoration(
                                          labelText:
                                              "Warranty Period for ${product.product}",
                                          hintText: "Select warranty period",
                                        ),
                                      ),
                                      onSelected: (value) {
                                        setState(() {
                                          product.wpm = value;
                                        });
                                      },
                                      selectedItem: product.wpm,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: DropdownSearch<String>(
                                      enabled: _ut!.toLowerCase() == "admin",
                                      popupProps: const PopupProps.dialog(
                                        dialogProps: DialogProps(
                                          barrierDismissible: true,
                                          barrierLabel: "Dismiss",
                                        ),
                                        showSelectedItems: true,
                                        showSearchBox: false,
                                      ),
                                      items: (filter, infiniteScrollProps) =>
                                          const [
                                        "12 Months",
                                        "24 Months",
                                        "36 Months"
                                      ],
                                      decoratorProps: DropDownDecoratorProps(
                                        decoration: InputDecoration(
                                          labelText:
                                              "Free Service Period for ${product.product}",
                                          hintText:
                                              "Select free service period",
                                        ),
                                      ),
                                      onSelected: (value) {
                                        setState(() {
                                          product.fsp =
                                              value; // Assigns fsp value per product
                                        });
                                      },
                                      selectedItem: product.fsp,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: DropdownSearch<LeadCategory>(
                                compareFn: ((item1, item2) {
                                  return item1.ddl12 == item2.ddl12;
                                }),
                                // enabled: !_resendotp,
                                popupProps: PopupProps.dialog(
                                    disabledItemFn: (item) {
                                      return !item.enabled;
                                    },
                                    itemBuilder: (context, item, isDisabled,
                                            isSelected) =>
                                        ListTile(
                                          enabled: item.enabled,
                                          title: Text(item.ddl12),
                                          trailing: item.extrainfo != null
                                              ? Text(item.extrainfo!)
                                              : null,
                                        ),
                                    dialogProps: const DialogProps(
                                        barrierDismissible: true,
                                        barrierLabel: "Dismiss"),
                                    showSelectedItems: true,
                                    showSearchBox: true),
                                // mode: Mode.dialog,
                                // showSelectedItems: true,
                                items: (filter, infiniteScrollProps) =>
                                    _category,
                                itemAsString: (item) {
                                  return item.ddl12;
                                },
                                decoratorProps: const DropDownDecoratorProps(
                                  decoration: InputDecoration(
                                    labelText: "Service Type",
                                    hintText: "Select an option",
                                  ),
                                ),

                                onSelected: (value) {
                                  setState(() {
                                    // _company.clear();
                                    _selectedcategory = value!;
                                    // getcomp();
                                    if (value.ddl12 ==
                                        "Installation Created by Mistake") {
                                      _showquestions = false;
                                    } else {
                                      _showquestions = true;
                                    }
                                  });

                                  // if (value?.ddl12 == "Paid Basis") {
                                  //   showResponsiveApiDialog(context);
                                  // }
                                },
                                selectedItem: _selectedcategory,
                              )),
                          if ((_selectedstatus == "Installation Completed") &&
                              (_showquestions))
                            _buildConditionalFields(),
                          // if ((_selectedstatus == "Job Completed "))

                          if (_selectedcategory?.ddl12 == "Spare Part Required")
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: InputField(
                                // readOnly: _resendotp,
                                label: "Part Name",
                                controller: _sparepartnamecontroller,
                              ),
                            ),
                          if (_selectedcategory?.ddl12 == "Spare Part Required")
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: InputField(
                                // readOnly: _resendotp,
                                label: "Part Cost",
                                controller: _sparepartcostcontroller,
                                keyboardtype: TextInputType.number,
                              ),
                            ),
                          if ((_selectedcategory?.ddl12 == "Paid Basis") |
                              (_selectedcategory?.ddl12 ==
                                  "Obligatory Service") |
                              (_selectedcategory?.ddl12 ==
                                  "Free Service as per Installation Agreement"))
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: InputField(
                                // readOnly: _resendotp,
                                label: "Service Charge",
                                controller: _servicechargecontroller,
                                keyboardtype: TextInputType.number,
                                onChanged: (value) {
                                  _charge1 = double.tryParse(value) ?? 0.0;
                                  // _calculateGstAmount();
                                },
                              ),
                            ),
                          if ((_selectedcategory?.ddl12 == "Paid Basis") |
                              (_selectedcategory?.ddl12 ==
                                  "Obligatory Service") |
                              (_selectedcategory?.ddl12 ==
                                  "Free Service as per Installation Agreement"))
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: InputField(
                                // readOnly: _resendotp,
                                label: "Spare Charge",
                                controller: _sparechargecontroller,
                                keyboardtype: TextInputType.number,
                                onChanged: (value) {
                                  _charge2 = double.tryParse(value) ?? 0.0;
                                  // _calculateGstAmount();
                                },
                              ),
                            ),
                          if ((_selectedcategory?.ddl12 == "Paid Basis") |
                              (_selectedcategory?.ddl12 ==
                                  "Obligatory Service") |
                              (_selectedcategory?.ddl12 ==
                                  "Free Service as per Installation Agreement"))
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: InputField(
                                // readOnly: _resendotp,
                                label: "Other Charge",
                                controller: _otherchargecontroller,
                                keyboardtype: TextInputType.number,
                                onChanged: (value) {
                                  _charge3 = double.tryParse(value) ?? 0.0;
                                  // _calculateGstAmount();
                                },
                              ),
                            ),
                          // gst %
                          if ((_selectedcategory?.ddl12 == "Paid Basis") |
                              (_selectedcategory?.ddl12 ==
                                  "Obligatory Service") |
                              (_selectedcategory?.ddl12 ==
                                  "Free Service as per Installation Agreement"))
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: FutureBuilder<List<String>>(
                                  future: getgst(),
                                  builder: ((context, snapshot) {
                                    if (snapshot.hasData &&
                                        snapshot.data != null) {
                                      return DropdownSearch<String>(
                                        // enabled: !_resendotp,
                                        popupProps: const PopupProps.dialog(
                                            dialogProps: DialogProps(
                                                barrierDismissible: true,
                                                barrierLabel: "Dismiss"),
                                            showSelectedItems: true,
                                            showSearchBox: true),
                                        // mode: Mode.dialog,
                                        // showSelectedItems: true,
                                        items: (filter, infiniteScrollProps) =>
                                            snapshot.data!,
                                        decoratorProps:
                                            const DropDownDecoratorProps(
                                          decoration: InputDecoration(
                                            labelText: "GST %",
                                            hintText: "Select a GST %",
                                          ),
                                        ),
                                        autoValidateMode:
                                            AutovalidateMode.onUserInteraction,
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return "Select a GST %";
                                          }
                                          return null;
                                        },
                                        // dropdownSearchDecoration: const InputDecoration(
                                        // labelText: "Menu mode",
                                        // hintText: "country in menu mode",
                                        // ),
                                        // popupItemDisabled: isItemDisabled,
                                        onSelected: (value) {
                                          setState(() {
                                            _selectedgst = value!;
                                          });
                                          _gstPercent =
                                              double.tryParse(value!) ?? 18.0;
                                          _calculateGstAmount();
                                        },
                                        selectedItem: _selectedgst,
                                        // showSearchBox: true,
                                        // searchFieldProps: TextFieldProps(
                                        //   cursorColor: Colors.blue,
                                        // ),
                                      );
                                    } else {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }
                                  })),
                            ),
                          if ((_selectedcategory?.ddl12 == "Paid Basis") |
                              (_selectedcategory?.ddl12 ==
                                  "Obligatory Service") |
                              (_selectedcategory?.ddl12 ==
                                  "Free Service as per Installation Agreement"))
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: InputField(
                                readOnly: true,
                                label: "GST Amount",
                                controller: _gstamountcontroller,
                                keyboardtype: TextInputType.number,
                              ),
                            ),
                          if (_selectedcategory?.ddl12 ==
                              "Free Service as per Installation Agreement")
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: InputField(
                                label: "Installation Date",
                                controller: _installdatecontroller,
                                readOnly: true,
                                // onTap: _resendotp
                                //     ? null
                                //     : () async {
                                //         DateTime? picked = await showDatePicker(
                                //             context: context,
                                //             initialDate: DateTime.now(),
                                //             firstDate: DateTime(1900),
                                //             lastDate: DateTime(2100));
                                //         if (picked != null) {
                                //           setState(() {
                                //             _installdatecontroller.text =
                                //                 picked.toString().split(" ")[0];
                                //           });
                                //         }
                                //         // setState(() {
                                //         //   _dobdate = picked;
                                //         // });
                                //       },
                              ),
                            ),
                          if (_selectedcategory?.ddl12 == "Under AMC")
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: InputField(
                                label: "AMC Date",
                                controller: _amcdatecontroller,
                                readOnly: true,
                                // onTap: _resendotp
                                //     ? null
                                //     : () async {
                                //         DateTime? picked = await showDatePicker(
                                //             context: context,
                                //             initialDate: DateTime.now(),
                                //             firstDate: DateTime(1900),
                                //             lastDate: DateTime(2100));
                                //         if (picked != null) {
                                //           setState(() {
                                //             _amcdatecontroller.text =
                                //                 picked.toString().split(" ")[0];
                                //           });
                                //         }
                                //       },
                              ),
                            ),
                          if ((_showquestions) && (_leadstat != 1))
                            Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: FutureBuilder<List<String>>(
                                    future: getnames(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData &&
                                          snapshot.data != null) {
                                        return DropdownSearch<String>(
                                          popupProps: const PopupProps.dialog(
                                              dialogProps: DialogProps(
                                                barrierDismissible: true,
                                                barrierLabel: "Dismiss",
                                              ),
                                              showSelectedItems: true,
                                              showSearchBox: true),
                                          // mode: Mode.dialog,
                                          // showSelectedItems: true,
                                          items:
                                              (filter, infiniteScrollProps) =>
                                                  snapshot.data!,
                                          decoratorProps:
                                              const DropDownDecoratorProps(
                                            decoration: InputDecoration(
                                              labelText: "Installation by Our",
                                              hintText: "Select a Name",
                                            ),
                                          ),

                                          onSelected: (value) {
                                            setState(() {
                                              _selectedinsbyour = value;
                                            });
                                          },
                                          selectedItem: _selectedinsbyour,
                                        );
                                      } else {
                                        return const Center(
                                            child: CircularProgressIndicator());
                                      }
                                    })),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: InputField(
                              // readOnly: _resendotp,
                              label: "Comments",
                              controller: _commentcontroller,
                              minlines: 1,
                              maxlines: 10,
                            ),
                          ),

                          if ((_leadstat != 1) && (_showquestions))
                            // image/vedio upload
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Row(
                                children: [
                                  Text("Upload Image/Video",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[700])),
                                  const Spacer(),
                                  // camera iconbutton
                                  SpeedDial(
                                    icon: Icons.camera_alt,
                                    activeIcon: Icons.close_rounded,
                                    children: [
                                      SpeedDialChild(
                                        child: const Icon(Icons.camera_alt),
                                        label: "Capture Image",
                                        onTap: () async {
                                          final XFile? image =
                                              await _picker.pickImage(
                                                  source: ImageSource.camera,
                                                  imageQuality: 75);
                                          if (image != null) {
                                            setState(() {
                                              _selectedImage.add(image.path);
                                            });
                                          }
                                        },
                                      ),
                                      SpeedDialChild(
                                        child: const Icon(Icons.videocam),
                                        label: "Capture Video",
                                        onTap: () async {
                                          final XFile? video =
                                              await _picker.pickVideo(
                                                  source: ImageSource.camera,
                                                  maxDuration: const Duration(
                                                      seconds: 30));
                                          if (video != null) {
                                            final mediaInfo =
                                                await VideoCompress
                                                    .compressVideo(
                                              video.path,
                                              quality:
                                                  VideoQuality.MediumQuality,
                                              includeAudio: true,
                                              deleteOrigin:
                                                  false, // Set to true to delete the original video after compression
                                            );
                                            setState(() {
                                              _selectedImage
                                                  .add(mediaInfo!.file!.path);
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.photo),
                                    onPressed: () async {
                                      final List<XFile> images = await _picker
                                          .pickMultipleMedia(imageQuality: 75);
                                      if (images.isNotEmpty) {
                                        for (var element in images) {
                                          if (element.path.endsWith('.mp4') ||
                                              element.path.endsWith('.mov')) {
                                            VideoCompress.compressVideo(
                                              element.path,
                                              quality:
                                                  VideoQuality.MediumQuality,
                                              includeAudio: true,
                                              deleteOrigin:
                                                  false, // Set to true to delete the original video after compression
                                            ).then((mediaInfo) {
                                              setState(() {
                                                _selectedImage
                                                    .add(mediaInfo!.file!.path);
                                              });
                                            });
                                          } else {
                                            setState(() {
                                              _selectedImage.add(element.path);
                                            });
                                          }
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          if ((_leadstat != 1) && (_showquestions))
                            // preview of selected files
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: SizedBox(
                                height: 90,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _selectedImage.length,
                                  itemBuilder: (context, index) {
                                    final file = _selectedImage[index];
                                    final isVideo = file.endsWith('.mp4') ||
                                        file.endsWith(
                                            '.mov'); // Quick extension check

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Stack(
                                        alignment: Alignment.topRight,
                                        children: [
                                          // 1. The Media Container
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            child: Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey[200],
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  // Render based on file type
                                                  if (isVideo)
                                                    VideoPreviewWidget(
                                                        file: File(file))
                                                  else
                                                    Image.file(
                                                      File(file),
                                                      fit: BoxFit.cover,
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
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedImage
                                                      .removeAt(index);
                                                });
                                              },
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                padding:
                                                    const EdgeInsets.all(4.0),
                                                child: const Icon(Icons.close,
                                                    size: 14,
                                                    color: Colors.white),
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
                          if (_dataupload && _leadstat != 1)
                            Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 24.0, vertical: 16.0),
                                padding: const EdgeInsets.all(20.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize
                                      .min, // Wrap tightly around progress items
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.cloud_upload_outlined,
                                            color: Colors.brown),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _uploadProgress >= 1.0
                                                ? "Processing on server..."
                                                : "Uploading file data...",
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        // Shows raw text layout percentage (e.g., 45%)
                                        Text(
                                          "${(_uploadProgress * 100).toStringAsFixed(0)}%",
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.brown,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),

                                    // The actual linear bar displaying state data
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                          4), // Rounds the edges of the bar
                                      child: LinearProgressIndicator(
                                        value: _uploadProgress,
                                        color: Colors.brown,
                                        backgroundColor: Colors.transparent,
                                        minHeight:
                                            8, // Makes the bar visually easy to track
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_leadstat != 1)
                            Padding(
                                padding: const EdgeInsets.all(5),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromRGBO(
                                                    252, 101, 8, 1),
                                            foregroundColor: Colors.white),
                                        onPressed: _isLoading
                                            ? null
                                            : (() async {
                                                FocusScope.of(context)
                                                    .unfocus();
                                                setState(() {
                                                  _isLoading = true;
                                                });
                                                var respcode = await submitdata(
                                                    _showquestions
                                                        ? "true"
                                                        : "false",
                                                    _resendotp);
                                                if (respcode == 200 ||
                                                    respcode == 201) {
                                                  setState(() {
                                                    _isLoading = false;
                                                    _dataupload = false;
                                                    _questionsanswered = true;
                                                  });

                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(SnackBar(
                                                          content: const Text(
                                                              "Data saved successfully"),
                                                          backgroundColor:
                                                              Colors
                                                                  .green[400]));
                                                  // if (kDebugMode) {
                                                  //   SendNotificationService
                                                  //       .sendNotificationUsingApi(
                                                  //           token: "test",
                                                  //           title: "Lead Follow UP",
                                                  //           body:
                                                  //               "Party: ${widget.pname}\nProduct: ${_selectedfollowupproduct!.product}",
                                                  //           data: {
                                                  //         "screen": "detail",
                                                  //         "pjc": widget.pjc,
                                                  //         "pname": widget.pname
                                                  //       });
                                                  // } else {
                                                  //   SendNotificationService
                                                  //       .sendNotificationUsingApi(
                                                  //           token: "all",
                                                  //           title: "Lead Follow UP",
                                                  //           body:
                                                  //               "Party: ${widget.pname}\nProduct: ${_selectedfollowupproduct!.product}",
                                                  //           data: {
                                                  //         "screen": "detail",
                                                  //         "pjc": widget.pjc,
                                                  //         "pname": widget.pname
                                                  //       });
                                                  // }
                                                } else {
                                                  setState(() {
                                                    _isLoading = false;
                                                    _dataupload = false;
                                                  });
                                                  // Navigator.of(
                                                  //         context)
                                                  //     .pop(
                                                  //         "Data saved");
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(const SnackBar(
                                                          content: Text(
                                                              "Something went wrong. Please try again."),
                                                          backgroundColor:
                                                              Colors.red));
                                                }
                                              }),
                                        child: const Text('Save')),
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
                                    //                     setState(() {
                                    //                       _isLoading = true;
                                    //                     });
                                    //                     String queryparam = _selectedfollowupproduct.map((item) => "leadid=${item.leadid}").join("&");
                                    //                     var respcode = await http.get(Uri.parse('$baseuri/api/ins_report/?$queryparam'));
                                    //                     if (respcode.statusCode == 200 || respcode.statusCode == 201) {
                                    //                       setState(() {
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
                                  ],
                                )),
                          if ((_leadstat != 1) && (_showquestions))
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: InputField(
                                label: "Site Represtative Name",
                                controller: _instcontpnamecontroller,
                              ),
                            ),

                          if (_leadstat == 1)
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: InputField(
                                    label: "Next Follow Up Date",
                                    controller: _nextfudatecontroller,
                                    readOnly: true,
                                    onTap: () async {
                                      DateTime? meet =
                                          await showOmniDateTimePicker(
                                              context: context,
                                              minutesInterval: 15);
                                      if (meet != null) {
                                        _nextfudatecontroller.text =
                                            DateFormat("dd/MM/yyyy")
                                                .add_jm()
                                                .format(meet);
                                      }
                                    },
                                  ),
                                ),
                                Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: FutureBuilder<List<String>>(
                                        future: getnames(),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData &&
                                              snapshot.data != null) {
                                            return DropdownSearch<String>(
                                              popupProps:
                                                  const PopupProps.dialog(
                                                      dialogProps: DialogProps(
                                                          barrierDismissible:
                                                              true,
                                                          barrierLabel:
                                                              "Dismiss"),
                                                      showSelectedItems: true,
                                                      showSearchBox: true),
                                              // mode: Mode.dialog,
                                              // showSelectedItems: true,
                                              items: (filter,
                                                      infiniteScrollProps) =>
                                                  snapshot.data!,
                                              decoratorProps:
                                                  const DropDownDecoratorProps(
                                                decoration: InputDecoration(
                                                  labelText:
                                                      "Next Follow-up By",
                                                  hintText: "Select a Name",
                                                ),
                                              ),

                                              onSelected: (value) {
                                                setState(() {
                                                  _selectedfollowupby = value;
                                                });
                                              },
                                              selectedItem: _selectedfollowupby,
                                            );
                                          } else {
                                            return const Center(
                                                child:
                                                    CircularProgressIndicator());
                                          }
                                        })),
                              ],
                            ),

                          if ((_leadstat != 1) && (_showquestions))
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: InputField(
                                  label: "Site Representative Mobile Number",
                                  controller: _mobforotpcontroller,
                                  validator: (val) {
                                    if (val?.length != 10) {
                                      return "Enter a valid 10-digit whatsapp number";
                                    }
                                    return null;
                                  },
                                  keyboardtype: TextInputType.phone,
                                  sufficon: IconButton(
                                      onPressed: () async {
                                        Contact? contact = await _contactPicker
                                            .selectPhoneNumber();
                                        setState(() {
                                          _selectedPhoneNumber =
                                              contact?.selectedPhoneNumber;
                                          if (_selectedPhoneNumber != null) {
                                            var phno = _selectedPhoneNumber!
                                                .replaceAll(" ", "");
                                            _mobforotpcontroller.text = phno
                                                .substring(phno.length - 10);
                                            _selectedPhoneNumber = null;
                                          }
                                        });
                                      },
                                      icon: const Icon(Icons.contacts))),
                            ),
                          if ((_selectedstatus == "Installation Completed") &&
                              (_showquestions))
                            TextButton(
                                onPressed: () {
                                  if (!_questionsanswered) {
                                    QuickAlert.show(
                                        context: context,
                                        type: QuickAlertType.warning,
                                        text:
                                            "Please answer the questions and save the data before sending OTP.");
                                  } else {
                                    sendserviceotp(setState);
                                  }
                                },
                                child: const Text('Send OTP')),
                          if (_openotpfield)
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: InputField(
                                label: "Enter OTP",
                                controller: _jcccontroller,
                              ),
                            ),

                          if (_isLoading)
                            const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.brown)),
                          if (_showquestions)
                            Padding(
                                padding: const EdgeInsets.all(5),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromRGBO(
                                                    252, 101, 8, 1),
                                            foregroundColor: Colors.white),
                                        onPressed: _isLoading
                                            ? null
                                            : (() async {
                                                FocusScope.of(context)
                                                    .unfocus();
                                                setState(() {
                                                  _isLoading = true;
                                                });
                                                if (_leadstat == 1) {
                                                  var respcode =
                                                      await submitdata(
                                                          "true", _resendotp);
                                                  if (respcode == 200 ||
                                                      respcode == 201) {
                                                    setState(() {
                                                      _isLoading = false;
                                                      _dataupload = true;
                                                    });

                                                    ScaffoldMessenger
                                                            .of(context)
                                                        .showSnackBar(SnackBar(
                                                            content: const Text(
                                                                "Data saved successfully"),
                                                            backgroundColor:
                                                                Colors.green[
                                                                    400]));
                                                    // if (kDebugMode) {
                                                    //   SendNotificationService
                                                    //       .sendNotificationUsingApi(
                                                    //           token: "test",
                                                    //           title: "Lead Follow UP",
                                                    //           body:
                                                    //               "Party: ${widget.pname}\nProduct: ${_selectedfollowupproduct!.product}",
                                                    //           data: {
                                                    //         "screen": "detail",
                                                    //         "pjc": widget.pjc,
                                                    //         "pname": widget.pname
                                                    //       });
                                                    // } else {
                                                    //   SendNotificationService
                                                    //       .sendNotificationUsingApi(
                                                    //           token: "all",
                                                    //           title: "Lead Follow UP",
                                                    //           body:
                                                    //               "Party: ${widget.pname}\nProduct: ${_selectedfollowupproduct!.product}",
                                                    //           data: {
                                                    //         "screen": "detail",
                                                    //         "pjc": widget.pjc,
                                                    //         "pname": widget.pname
                                                    //       });
                                                    // }
                                                    Navigator.of(context)
                                                        .pop("Data saved");
                                                  } else {
                                                    setState(() {
                                                      _isLoading = false;
                                                    });
                                                    // Navigator.of(
                                                    //         context)
                                                    //     .pop(
                                                    //         "Data saved");
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                            const SnackBar(
                                                                content: Text(
                                                                    "Something went wrong. Please try again."),
                                                                backgroundColor:
                                                                    Colors
                                                                        .red));
                                                  }
                                                } else {
                                                  var respcode =
                                                      await submitotp(
                                                          _jcccontroller.text);
                                                  // var respcode = await submitdata(
                                                  //   "true", _resendotp);
                                                  if (respcode == 200 ||
                                                      respcode == 201) {
                                                    setState(() {
                                                      _isLoading = false;
                                                      _dataupload = false;
                                                    });

                                                    ScaffoldMessenger
                                                            .of(context)
                                                        .showSnackBar(SnackBar(
                                                            content: const Text(
                                                                "OTP Verified Successfully"),
                                                            backgroundColor:
                                                                Colors.green[
                                                                    400]));
                                                    // Navigator.of(context)
                                                    //     .pop("Data saved");
                                                    // if (kDebugMode) {
                                                    //   SendNotificationService
                                                    //       .sendNotificationUsingApi(
                                                    //           token: "test",
                                                    //           title: "Lead Follow UP",
                                                    //           body:
                                                    //               "Party: ${widget.pname}\nProduct: ${_selectedfollowupproduct!.product}",
                                                    //           data: {
                                                    //         "screen": "detail",
                                                    //         "pjc": widget.pjc,
                                                    //         "pname": widget.pname
                                                    //       });
                                                    // } else {
                                                    //   SendNotificationService
                                                    //       .sendNotificationUsingApi(
                                                    //           token: "all",
                                                    //           title: "Lead Follow UP",
                                                    //           body:
                                                    //               "Party: ${widget.pname}\nProduct: ${_selectedfollowupproduct!.product}",
                                                    //           data: {
                                                    //         "screen": "detail",
                                                    //         "pjc": widget.pjc,
                                                    //         "pname": widget.pname
                                                    //       });
                                                    // }
                                                    Navigator.of(context)
                                                        .pop("Data saved");
                                                  } else {
                                                    setState(() {
                                                      _isLoading = false;
                                                    });
                                                    // Navigator.of(
                                                    //         context)
                                                    //     .pop(
                                                    //         "Data saved");
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                            const SnackBar(
                                                                content: Text(
                                                                    "Something went wrong. Please try again."),
                                                                backgroundColor:
                                                                    Colors
                                                                        .red));
                                                  }
                                                }
                                              }),
                                        child: _leadstat == 1
                                            ? const Text('Save')
                                            : const Text("Verify OTP")),
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
                                    //                     setState(() {
                                    //                       _isLoading = true;
                                    //                     });
                                    //                     String queryparam = _selectedfollowupproduct.map((item) => "leadid=${item.leadid}").join("&");
                                    //                     var respcode = await http.get(Uri.parse('$baseuri/api/ins_report/?$queryparam'));
                                    //                     if (respcode.statusCode == 200 || respcode.statusCode == 201) {
                                    //                       setState(() {
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
                                  ],
                                ))
                        ],
                      ),
                    ),
                  )),
            ),
          ),
        ),
        appbartitle: const Text("Installation Checkout"),
        appbaractions: const []);
  }

  Future<void> getsaltbilling() async {
    var response = await http.get(Uri.parse(
        '$baseuri/api/serviceqa/?product=water treatment&pjc=${widget.pjc}'));
    var resp = jsonDecode(response.body);

    setState(() {
      _answers["Last Salt Billing Date & Quantity_pt1"] = resp["date"];
      _answers["Last Salt Billing Date & Quantity_pt2"] = resp["qty"];
      _answers["Last Salt Billing Date & Quantity"] =
          "${resp["date"].toString()} / ${resp["qty"].toString()}";
      _controllers["Last Salt Billing Date & Quantity_pt1"]?.text =
          resp["date"].toString();
      _controllers["Last Salt Billing Date & Quantity_pt2"]?.text =
          resp["qty"].toString();
    });
  }
}
