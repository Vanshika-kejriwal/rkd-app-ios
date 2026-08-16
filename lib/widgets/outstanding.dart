import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:business_app/constants.dart';
import 'package:business_app/models/outstanding.dart';
import 'package:business_app/services/network_provider.dart';
import 'package:business_app/widgets/input_field.dart';
import 'package:business_app/widgets/osmainlistitem.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class OsList extends StatefulWidget {
  String? ut;
  OsList({super.key, this.ut});

  @override
  State<OsList> createState() => _OsListState();
}

class _OsListState extends State<OsList> {
  final GlobalKey<SfDataGridState> dataGridKey = GlobalKey<SfDataGridState>();
  List<Outstanding> leads = [];
  List<Outstanding> _foundleads = [];
  List<Outstanding> _filterleads = [];
  List<String> _filteredProducts = [];
  final TextEditingController _amtcontroller = TextEditingController();
  final TextEditingController _odcontroller = TextEditingController();
  bool _isDataLoaded = false;
  bool summary = false;
  Timer? _reloadTimer;

  Future<void> fetchOutstandingData() async {
    final connectivityProvider =
        Provider.of<NetworkProvider>(context, listen: false);

    http.Response response;
    var sharedpref = await SharedPreferences.getInstance();
    var ut = sharedpref.getString("UT");
    var mob = sharedpref.getString("Mobile");

    try {
      setState(() {
        _isDataLoaded = false;
        leads = [];
      });
      if (ut!.toLowerCase() == "consumer" ||
          ut.toLowerCase() == "contractor" ||
          ut.toLowerCase() == "supplier") {
        response =
            await http.get(Uri.parse('$baseuri/api/outstanding/?mob=$mob'));
      } else {
        response = await http.get(Uri.parse('$baseuri/api/outstanding/'));
      }
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<Outstanding> outstanding = body.map<Outstanding>((e) {
          return Outstanding.fromJson(e as Map<String, dynamic>);
        }).toList();

        if (mounted) {
          setState(() {
            leads = outstanding;
            _foundleads = outstanding;
            _isDataLoaded = true;
          });
        }
      } else {
        // Handle error
        if (mounted) {
          setState(() {
            _isDataLoaded = true;
          });
        }
      }
    } on SocketException catch (_) {
      connectivityProvider.setConnected(false);
    } on http.ClientException catch (_) {
      connectivityProvider.setConnected(false);
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
    if (isConnected && !_isDataLoaded) {
      _reloadTimer?.cancel();

      // Start a new timer to delay the API call
      _reloadTimer = Timer(const Duration(seconds: 2), () {
        fetchOutstandingData(); // Call _fetchData() after a 3-second delay
      });
    }

    // Update the previous state for the next check
    // _lastConnectivityStatus = isConnected;

    // If we lose connection, reset _dataLoaded so it will fetch again
    if (!isConnected) {
      _reloadTimer?.cancel();
      setState(() {
        _isDataLoaded = false;
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
    return !_isDataLoaded
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : Column(
            children: [
              // IconButton(onPressed: () {
              //  final document = dataGridKey.currentState?.exportToPdfDocument();
              //    List<int> bytes = document!.saveSync();
              //    File('OutstandingReport.pdf').writeAsBytes(bytes, flush: true);
              //    document.dispose();
              // }, icon: Icon(Icons.download)),
              Padding(
                padding: const EdgeInsets.all(5),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: InputField(
                        label: "Search",
                        onChanged: (value) {
                          List<Outstanding> results = [];
                          if (value.isEmpty) {
                            results =
                                _filterleads.isEmpty ? leads : _filterleads;
                          } else {
                            results = _filterleads.isEmpty
                                ? leads.where((lead) {
                                    return value
                                            .toLowerCase()
                                            .split(" ")
                                            .where((word) => word.isNotEmpty)
                                            .toList()
                                            .every((word) => lead.nAME!
                                                .toLowerCase()
                                                .contains(word)) ||
                                        value
                                            .toLowerCase()
                                            .split(" ")
                                            .where((word) => word.isNotEmpty)
                                            .toList()
                                            .every((word) => lead.aC!
                                                .toLowerCase()
                                                .contains(word));
                                  }).toList()
                                : _filterleads.where((lead) {
                                    return value
                                            .toLowerCase()
                                            .split(" ")
                                            .where((word) => word.isNotEmpty)
                                            .toList()
                                            .every((word) => lead.nAME!
                                                .toLowerCase()
                                                .contains(word)) ||
                                        value
                                            .toLowerCase()
                                            .split(" ")
                                            .where((word) => word.isNotEmpty)
                                            .toList()
                                            .every((word) => lead.aC!
                                                .toLowerCase()
                                                .contains(word));
                                  }).toList();
                          }
                          setState(() {
                            _foundleads = results;
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: 2,
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Expanded(
                            child: Text(
                              "Summary",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                              overflow: TextOverflow
                                  .ellipsis, // Prevents text overflow
                            ),
                          ),
                          Transform.scale(
                            scale:
                                0.8, // Slightly reduces switch size to fit compact rows
                            child: Switch(
                              value: summary,
                              onChanged: (val) {
                                setState(() {
                                  summary = val;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.ut!.toLowerCase() == "admin" ||
                        widget.ut!.toLowerCase() == "employee")
                      Expanded(
                          flex: 1,
                          child: IconButton(
                              onPressed: () async {
                                TextEditingController amountcontroller =
                                    TextEditingController();
                                TextEditingController odcontroller =
                                    TextEditingController();
                                amountcontroller.text = _amtcontroller.text;
                                odcontroller.text = _odcontroller.text;
                                List<String> filteredProducts =
                                    _filteredProducts;
                                final result = await showModalBottomSheet(
                                  isScrollControlled: true,
                                  context: context,
                                  builder: (context) {
                                    return Scaffold(
                                      body: SafeArea(
                                        child: StatefulBuilder(
                                            builder: (context, setstate) {
                                          return Container(
                                            padding: const EdgeInsets.all(10),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(5.0),
                                                  child: DropdownSearch<
                                                      String>.multiSelection(
                                                    selectedItems:
                                                        filteredProducts,
                                                    items: (filter,
                                                            infiniteScrollProps) =>
                                                        leads
                                                            .map((e) =>
                                                                e.sm ??
                                                                "Unknown")
                                                            .toSet()
                                                            .toList(),
                                                    onSelected: (value) {
                                                      setstate(() {
                                                        filteredProducts =
                                                            value;
                                                      });
                                                    },
                                                    popupProps:
                                                        const MultiSelectionPopupProps
                                                            .dialog(
                                                            dialogProps: DialogProps(
                                                                barrierDismissible:
                                                                    true,
                                                                barrierLabel:
                                                                    "Dismiss"),
                                                            showSelectedItems:
                                                                true,
                                                            showSearchBox:
                                                                true),
                                                    decoratorProps:
                                                        const DropDownDecoratorProps(
                                                      decoration:
                                                          InputDecoration(
                                                        labelText: "Salesman",
                                                        hintText:
                                                            "Select Salesman",
                                                      ),
                                                    ),
                                                    validator: (value) {
                                                      if (value == null) {
                                                        return 'Please select an emplyee name';
                                                      }
                                                      return null;
                                                    },
                                                    autoValidateMode:
                                                        AutovalidateMode
                                                            .onUserInteraction,
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(5.0),
                                                  child: InputField(
                                                    label:
                                                        "Amount greater than",
                                                    // initialValue: _amtcontroller.text,
                                                    controller:
                                                        amountcontroller,
                                                    keyboardtype:
                                                        TextInputType.number,
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(5.0),
                                                  child: InputField(
                                                    label:
                                                        "OD days greater than",
                                                    // initialValue: _odcontroller.text,
                                                    controller: odcontroller,
                                                    keyboardtype:
                                                        TextInputType.number,
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceAround,
                                                  children: [
                                                    Expanded(
                                                        child: ElevatedButton(
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            },
                                                            child: const Text(
                                                                "Cancel"))),
                                                    Expanded(
                                                        child: ElevatedButton(
                                                            onPressed: () {
                                                              Map<String,
                                                                      dynamic>
                                                                  filterval = {
                                                                "SM":
                                                                    filteredProducts,
                                                                "AMT":
                                                                    amountcontroller
                                                                        .text,
                                                                "OD":
                                                                    odcontroller
                                                                        .text
                                                              };
                                                              // filterlist(filterval);
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(
                                                                      filterval);
                                                            },
                                                            child: const Text(
                                                                "Apply"))),
                                                    Expanded(
                                                        child: ElevatedButton(
                                                            onPressed: () {
                                                              setstate(() {
                                                                filteredProducts =
                                                                    [];
                                                                // filteredProjects = [];
                                                                amountcontroller
                                                                    .text = "";
                                                                odcontroller
                                                                    .text = "";
                                                              });
                                                            },
                                                            child: const Text(
                                                                "Clear All"))),
                                                  ],
                                                )
                                              ],
                                            ),
                                          );
                                        }),
                                      ),
                                    );
                                  },
                                );
                                if (result != null && mounted) {
                                  // print
                                  setState(() {
                                    _filteredProducts = result["SM"] ?? [];
                                    _amtcontroller.text = result["AMT"] ?? "";
                                    _odcontroller.text = result["OD"] ?? "";
                                    _filterleads = leads.where((lead) {
                                      bool matchesProduct =
                                          result["SM"] == null ||
                                              result["SM"]!.isEmpty ||
                                              result["SM"]!.contains(lead.sm);
                                      bool matchesAmount = result["AMT"] ==
                                              null ||
                                          result["AMT"]!.isEmpty ||
                                          (double.tryParse(lead.bAM ?? "0") !=
                                                  null &&
                                              double.tryParse(result["AMT"]!) !=
                                                  null &&
                                              double.parse(lead.bAM!) >
                                                  double.parse(result["AMT"]!));
                                      bool matchesOD = result["OD"] == null ||
                                          result["OD"]!.isEmpty ||
                                          (double.tryParse(lead.od ?? "0") !=
                                                  null &&
                                              double.tryParse(result["OD"]!) !=
                                                  null &&
                                              double.parse(lead.od!) >
                                                  double.parse(result["OD"]!));
                                      return matchesProduct &&
                                          matchesAmount &&
                                          matchesOD;
                                    }).toList();
                                    _foundleads = _filterleads;
                                  });
                                  // print("${leads.length} total leads, ${_filterleads.length} after filtering.");
                                  // print("Filter applied: ${_filterleads.length} leads match the criteria.");
                                }
                              },
                              icon: const Icon(Icons.filter_list))),
                    if (summary)
                      Expanded(
                        child: IconButton(
                          icon: const Icon(Icons.share),
                          tooltip: "Share Summary",
                          onPressed: () {
                            _shareOutstandingSummary(
                                _foundleads,
                                _filteredProducts,
                                _amtcontroller.text,
                                _odcontroller.text);
                          },
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                    // key: dataGridKey,
                    itemCount: _foundleads.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: Column(
                          children: [
                            CustomDataGridItem(
                              key: ValueKey(_foundleads[index].aC),
                              summary: summary,
                              outstandingData: _foundleads[index],
                            ),
                            if (!summary) const SizedBox(height: 15),
                            if (!summary)
                              const Divider(
                                thickness: 3,
                                color: Colors.black87,
                              )
                          ],
                        ),
                      );
                    }),
              ),
            ],
          );
  }

  Future<void> _shareOutstandingSummary(
      List<Outstanding> foundleads, salesman, amt, oddays) async {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      title: 'Generating Outstanding List...',
      barrierDismissible: false,
    );
    var query = {
      "ac": foundleads.map((item) => item.aC).toList(),
      "salesman": salesman,
      "amtgt": amt,
      "oddaysgt": oddays
    };
    http.post(
      Uri.parse('$baseuri/api/oslistprint/'),
      body: json.encode(query),
      headers: {"Content-Type": "application/json"},
    ).then((response) async {
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        // --- Extracting Mobile Numbers and Filename ---

        final String filename = jsonResponse['filename'];

        // print(
        //     '✅ Received Mobile Numbers: $mobileNumbers');
        print('✅ Filename: $filename');

        // --- Decoding and Saving the PDF File ---

        final String base64Pdf = jsonResponse['pdf_data'];

        // 3. Base64 Decode the PDF string into raw bytes (Uint8List)
        final pdfBytes = base64Decode(base64Pdf);
        final dir = await getTemporaryDirectory();
        final filepath =
            '${dir.path}/OutstandingSummary-${DateTime.now().millisecondsSinceEpoch}.pdf';
        File file = File(filepath);
        await file.writeAsBytes(pdfBytes);
        Navigator.of(context).pop(); // Close the loading dialog
        // Navigator.of(context).push(
        //   MaterialPageRoute(
        //     builder: (context) => Pdfview(
        //       file: file,
        //       type: "Ledger",
        //       ac: _pjc,
        //       mobileNumbers: mobileNumbers,
        //     ),
        //   ),
        // );
        try {
          // 1. Find the render box for iPad positioning support
          final box = context.findRenderObject() as RenderBox?;
          final Rect? sharePositionOrigin = box != null 
              ? box.localToGlobal(Offset.zero) & box.size 
              : null;

          // 2. Share the file with explicit MIME type & placement tracking
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path, mimeType: 'application/pdf')],
              sharePositionOrigin: sharePositionOrigin,
            ),
          );

          // ❌ REMOVE THE IMMEDIATE FILE CLEANUP CODE FROM HERE.
          // Let iOS clear the cache naturally, or perform cleanup when 
          // navigating away / disposing of the stateful widget.

        } on FileSystemException catch (e) {
          if (e.osError?.errorCode != 39) {
            rethrow; 
          }
        } catch (e) {
          if (kDebugMode) {
            print('An unexpected error occurred during sharing: $e');
          }
        }
        // final body = json.decode(response.body);
        // String pdfurl = body['pdf_url'];
        // Utils.openUrl(pdfurl);
      }
    });
  }
}
