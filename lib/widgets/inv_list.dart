import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:business_app/models/utils.dart';
import 'package:business_app/screens/pdfview.dart';
import 'package:business_app/services/network_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_multi_select_items/flutter_multi_select_items.dart';
import 'package:http/http.dart' as http;
import 'package:business_app/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Removed go_router import

class InvList extends StatefulWidget {
  String? biillno;
  String leadtype;
  String pjc;
  DateTimeRange? filterdate;
  String? searchQuery;
  // final SearchQueryModel searchQueryModel;
  final ValueChanged<Map<String, dynamic>> onfilterChange;
  Map<String, List<String>>? selectedfilters;

  InvList(
      {super.key,
      required this.leadtype,
      required this.pjc,
      this.filterdate,
      this.biillno,
      this.searchQuery,
      required this.onfilterChange,
      this.selectedfilters});

  @override
  State<InvList> createState() => _InvListState();
}

class _InvListState extends State<InvList> {
  List<Invoice> leads = [];
  List<Invoice> _foundleads = [];
  List<Invoice> initleads = [];
  // String? _leadbyname = '';
  // String? _leadtoname = '';
  bool _isDataLoaded = true;
  Timer? _reloadTimer;
  final MultiSelectController<Invoice> _controller =
      MultiSelectController<Invoice>();
  bool _selectAll = false;
  // Removed unused _listener field

  Future<void> getleads() async {
    var sharedpref = await SharedPreferences.getInstance();
    var mob = sharedpref.getString("Mobile");
    var ut = sharedpref.getString("UT");
    http.Response response;

    if (kDebugMode) {
      print(widget.pjc);
    }
    // Removed unused username variable
    // if (widget.leadton != null) {
    //   _leadtoname = widget.leadton;
    //   _leadbyname = '';
    // }
    // if (widget.leadbyn == true) {
    //   _leadtoname = '';
    //   _leadbyname = username;
    // }

    final connectivityProvider =
        Provider.of<NetworkProvider>(context, listen: false);
    try {
      if (widget.pjc.isNotEmpty ||
          (widget.biillno != null && widget.biillno!.isNotEmpty)) {
        setState(() {
          _isDataLoaded = false;
          leads = [];
        });
        final Map<String, dynamic> query = {'pjc': widget.pjc};
        if (widget.biillno != null && widget.biillno!.isNotEmpty) {
          query['billno'] = widget.biillno;
        }
        if (widget.leadtype == "CNDN") {
          response = await http.get(
              Uri.parse(
                  '$baseuri/api/cndn_list/?pjc=${widget.pjc}&start=${widget.filterdate!.start.toString().split(" ")[0]}&end=${widget.filterdate!.end.toString().split(" ")[0]}'),
              headers: {"Content-Type": "application/json"});
        } else {
          response = await http.get(
              Uri.parse(
                  '$baseuri/api/inv_list/?pjc=${widget.pjc}&start=${widget.filterdate!.start.toString().split(" ")[0]}&end=${widget.filterdate!.end.toString().split(" ")[0]}&billno=${widget.biillno}'),
              headers: {"Content-Type": "application/json"});
        }
        // print(response.headers);
        // if (kDebugMode) {
        //   print(response.body);
        // }
        final body = json.decode(response.body);
        if (kDebugMode) {
          print(body);
        }
        if (response.statusCode == 200) {
          if (body.isEmpty) {
            leads = [];
          } else {
            body.forEach((lead) {
              // DateTime followup = DateFormat('yyyy-MM-ddTHH:mm:ss.SSSSSS')
              // .parse(lead['LAST_FOLLOWUP']);
              // String lastFollowup = lead["LAST_FOLLOWUP"];
              // DateFormat("dd/MM/yyyy").add_jm().format(followup);
              if (widget.leadtype == "CNDN") {
                leads.add(Invoice(
                  ac: lead['AC'],
                  gstvno: lead['CNNO'],
                  amount: lead['AM'].toString(),
                  date: lead['CDATE'],
                  tt: lead['VT'],
                ));
              } else {
                leads.add(Invoice(
                  ac: lead['AC'],
                  gstvno: lead['GSTVNO'],
                  amount: lead['AMOUNT'].toString(),
                  date: lead['DATE'],
                  tt: lead['TT'],
                ));
              }
            });
          }
          // leads.remove(value)
          leads.sort((a, b) {
            if (leads.isNotEmpty) {
              // print(b.lastfollowup);
              b.date = b.date.replaceAll('\u202f', ' ');
              // String yourDateString = a.lastfollowup;
              // for (int i = 0; i < yourDateString.length; i++) {
              //   print(
              //       "Char at $i: '${yourDateString[i]}' (Code: ${yourDateString.codeUnitAt(i)})");
              // }
              if (widget.leadtype == "CNDN") {
                var dateb = DateFormat("dd/MM/yyyy", "en_US").parse(b.date);
                a.date = a.date.replaceAll('\u202f', ' ');
                var datea = DateFormat("dd/MM/yyyy", "en_US").parse(a.date);
                return dateb.compareTo(datea);
              } else {
                var dateb = DateFormat("yyyy-MM-dd", "en_US").parse(b.date);
                a.date = a.date.replaceAll('\u202f', ' ');
                var datea = DateFormat("yyyy-MM-dd", "en_US").parse(a.date);
                return dateb.compareTo(datea);
              }
            }
            // 7/10/1996 5:08 PM
            return 0;
          });
          initleads = leads;
          _foundleads = leads;
          // filtervalues();
          setState(() {
            _isDataLoaded = true;
          });
        }
      } else {
        //     setState(() {
        //   _isDataLoaded = true;
        //   leads = [];
        // });
        return;
      }
    } on SocketException catch (_) {
      connectivityProvider.setConnected(false);
    } on http.ClientException catch (_) {
      connectivityProvider.setConnected(false);
    }
  }

  @override
  void initState() {
    // getleads();
    super.initState();
    // _listener = () {
    //   // Define the callback
    //   // _filterData();
    // };

    // widget.searchQueryModel.addListener(_listener);
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
        getleads(); // Call _fetchData() after a 3-second delay
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
  void didUpdateWidget(covariant InvList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // if (oldWidget.searchQueryModel != widget.searchQueryModel) {
    //   oldWidget.searchQueryModel.removeListener(_listener);
    //   widget.searchQueryModel.addListener(_listener);
    // }
    // print(widget.selectedfilters);
    if (oldWidget.pjc != widget.pjc ||
        oldWidget.filterdate != widget.filterdate ||
        oldWidget.biillno != widget.biillno ||
        oldWidget.leadtype != widget.leadtype) {
      getleads();
    }
    // if ((oldWidget.selectedfilters != widget.selectedfilters)) {
    //   // getleads();
    //   List<Lead> filterLeads = initleads.where((lead) {
    //     bool shouldConsiderProject =
    //         widget.selectedfilters!["Project"]!.isNotEmpty;
    //     bool shouldConsiderProduct =
    //         widget.selectedfilters!["Product"]!.isNotEmpty;
    //     bool projectmatches;
    //     if (shouldConsiderProject) {
    //       projectmatches =
    //           widget.selectedfilters!["Project"]!.contains(lead.pname);
    //     } else {
    //       projectmatches = true;
    //     }
    //     bool productmatches;
    //     if (shouldConsiderProduct) {
    //       productmatches = lead.products.any((product) =>
    //           widget.selectedfilters!["Product"]!.contains(product));
    //     } else {
    //       productmatches = true;
    //     }
    //     return productmatches & projectmatches;
    //   }).toList();
    //   leads = filterLeads;
    //   _foundleads = filterLeads;
    // }
    // if (oldWidget.searchQuery != widget.searchQuery) {
    //   print(widget.searchQuery);
    //   leads = leads
    //       .where((lead) => lead.pname
    //           .toLowerCase()
    //           .contains(widget.searchQuery!.toLowerCase()))
    //       .toList();
    // }
  }

  // void _filterData() {
  //   final searchQuery = widget.searchQueryModel.searchQuery;
  //   // ... filtering logic
  //   leads = leads
  //       .where((lead) =>
  //           lead.pname.toLowerCase().contains(searchQuery.toLowerCase()))
  //       .toList();
  //   setState(() {});
  // }

  @override
  Widget build(BuildContext context) {
    // if (kDebugMode) {
    //   print(widget.searchQuery);
    // }
    return !_isDataLoaded
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : leads.isEmpty
            ? const Center(
                child: Text("No Invoices to Show"),
              )
            : Column(
                children: [
                  // Padding(
                  //   padding: const EdgeInsets.all(5),
                  //   child: InputField(
                  //     label: "Search",
                  //     onChanged: (value) {
                  //       List<Invoice> results = [];
                  //       if (value.isEmpty) {
                  //         results = leads;
                  //       } else {
                  //         results = leads.where((lead) {
                  //           return value
                  //                   .toLowerCase()
                  //                   .split(" ")
                  //                   .where((word) => word.isNotEmpty)
                  //                   .toList()
                  //                   .every((word) => lead.gstvno
                  //                       .toLowerCase()
                  //                       .contains(word)) ||
                  //               value
                  //                   .toLowerCase()
                  //                   .split(" ")
                  //                   .where((word) => word.isNotEmpty)
                  //                   .toList()
                  //                   .every((word) => lead.date
                  //                       .toLowerCase()
                  //                       .contains(word)) ||
                  //               value
                  //                   .toLowerCase()
                  //                   .split(" ")
                  //                   .where((word) => word.isNotEmpty)
                  //                   .toList()
                  //                   .every((word) =>  lead.amount
                  //                       .toLowerCase()
                  //                       .contains(word));
                  //         }).toList();
                  //       }
                  //       setState(() {
                  //         _foundleads = results;
                  //       });
                  //     },
                  //   ),
                  // ),
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: CheckboxListTile(
                            controlAffinity: ListTileControlAffinity.leading,
                            value: _selectAll,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _controller.selectAll();
                                } else {
                                  _controller.deselectAll();
                                }
                                _selectAll = value ?? false;
                              });
                            },
                            title: const Text("Select All")),
                      ),
                      Expanded(
                        flex: 1,
                        child: IconButton(
                            onPressed: () {
                              var selectedinv = _controller.getSelectedItems();
                              print("Selected Invoices: $selectedinv");
                              if (widget.leadtype == "CNDN") {
                                getinvoicepdf(
                                    context,
                                    widget.pjc,
                                    selectedinv.map((e) => e.gstvno).join(","),
                                    "CNDN",
                                    selectedinv.first.ac);
                              } else {
                                getinvoicepdf(
                                    context,
                                    widget.pjc,
                                    selectedinv.map((e) => e.gstvno).join(","),
                                    selectedinv.length == 1
                                        ? selectedinv[0].tt
                                        : "All invoices",
                                    selectedinv.first.ac);
                              }
                            },
                            icon: const Icon(Icons.picture_as_pdf)),
                      )
                    ],
                  ),
                  Expanded(
                    child: MultiSelectCheckList<Invoice>(
                      itemsDecoration: MultiSelectDecorations(
                        // selectedColor: Colors.deepOrange.shade100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey,
                            width: 1,
                          ),
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Colors.deepOrange.shade200,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.deepOrange,
                            width: 1,
                          ),
                        ),
                        // textStyle: const TextStyle(
                        //   fontSize: 16,
                        // ),
                      ),
                      items: _foundleads
                          .map((e) => CheckListCard<Invoice>(
                                selectedColor: Colors.deepOrange[400],
                                value: e,
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    e.tt == "R8"
                                        ? const Text(
                                            "Sales Return Invoice",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          )
                                        : e.tt[0] == "C"
                                            ? const Text(
                                                "Credit Note",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              )
                                            : e.tt[0] == "D"
                                                ? const Text(
                                                    "Debit Note",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  )
                                                : const Text(
                                                    "Sale Invoice",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),

                                    // : const Text(
                                    //     "Sale Invoice",
                                    //     style: TextStyle(
                                    //         fontWeight: FontWeight.bold),
                                    //   ),
                                    if (widget.leadtype != "CNDN")
                                      Text(
                                        DateFormat("dd/MM/yyyy").format(
                                            DateFormat("yyyy-MM-dd")
                                                .parse(e.date)),
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    if (widget.leadtype == "CNDN")
                                      Text(
                                        e.date,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      )
                                  ],
                                ),
                                subtitle: Row(
                                  // mainAxisAlignment:
                                  // MainAxisAlignment.spaceAround,
                                  children: [
                                    Text(
                                      e.gstvno,
                                      textAlign: TextAlign.left,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    // const Spacer(),
                                    // Text(DateFormat("dd/MM/yyyy").format(
                                    //     DateFormat("yyyy-MM-dd")
                                    //         .parse(_foundleads[index].date)), textAlign: TextAlign.center,),
                                    const Spacer(),
                                    Text(
                                      e.amount,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                // controller: _controller,
                              ))
                          .toList(),
                      onChange: (allSelectedItems, selectedItem) {
                        // Handle selection changes here

                        if (kDebugMode) {
                          print('Selected items: ${allSelectedItems.length}');
                          print(selectedItem.gstvno);
                        }
                      },
                      controller: _controller,
                      // You can customize other properties as needed
                    ),
                    // child: ListView.builder(
                    //     itemCount: _foundleads.length,
                    //     itemBuilder: (context, index) {
                    //       return Card(
                    //           color: Colors.transparent,
                    //           child: ListTile(
                    //             title: Row(
                    //               mainAxisAlignment:
                    //                   MainAxisAlignment.spaceBetween,
                    //               children: [
                    //                 _foundleads[index].tt == "R8"
                    //                     ? const Text(
                    //                         "Sales Return Invoice",
                    //                         style: TextStyle(
                    //                             fontWeight: FontWeight.bold),
                    //                       )
                    //                     : const Text(
                    //                         "Sale Invoice",
                    //                         style: TextStyle(
                    //                             fontWeight: FontWeight.bold),
                    //                       ),

                    //                 // : const Text(
                    //                 //     "Sale Invoice",
                    //                 //     style: TextStyle(
                    //                 //         fontWeight: FontWeight.bold),
                    //                 //   ),
                    //                 Text(
                    //                   DateFormat("dd/MM/yyyy").format(
                    //                       DateFormat("yyyy-MM-dd")
                    //                           .parse(_foundleads[index].date)),
                    //                   style: const TextStyle(
                    //                       fontSize: 14,
                    //                       fontWeight: FontWeight.bold),
                    //                 )
                    //               ],
                    //             ),
                    //             subtitle: Row(
                    //               // mainAxisAlignment:
                    //               // MainAxisAlignment.spaceAround,
                    //               children: [
                    //                 Text(
                    //                   _foundleads[index].gstvno,
                    //                   textAlign: TextAlign.left,
                    //                 ),
                    //                 // const Spacer(),
                    //                 // Text(DateFormat("dd/MM/yyyy").format(
                    //                 //     DateFormat("yyyy-MM-dd")
                    //                 //         .parse(_foundleads[index].date)), textAlign: TextAlign.center,),
                    //                 const Spacer(),
                    //                 Text(
                    //                   _foundleads[index].amount,
                    //                   textAlign: TextAlign.right,
                    //                 ),
                    //               ],
                    //             ),
                    //             // isThreeLine: true,
                    //             // trailing: Text(DateFormat("dd/MM/yyyy").format(
                    //             //         DateFormat("yyyy-MM-dd")
                    //             //             .parse(_foundleads[index].date)),),
                    //             tileColor: Colors.transparent,
                    //             onTap: () {
                    //               getinvoicepdf(
                    //                   context,
                    //                   widget.pjc,
                    //                   _foundleads[index].gstvno,
                    //                   _foundleads[index].tt,
                    //                   _foundleads[index].ac);
                    //               // Use Navigator.push for navigation
                    //               // Navigator.push(
                    //               //   context,
                    //               //   MaterialPageRoute(
                    //               //     builder: (context) => LeadDetail(
                    //               //         currentlead: _foundleads[index]),
                    //               //   ),
                    //               // );
                    //             },
                    //           ));
                    //     }),
                  ),
                ],
              );
  }

  void getinvoicepdf(BuildContext context, String pjc, String gstvno, String tt,
      String ac) async {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      title: 'Generating Invoice...',
      barrierDismissible: false,
    );
    if (widget.leadtype == "CNDN") {
      tt = tt[0] == "C" ? "Credit Note" : "Debit Note";
      http
          .get(
        Uri.parse('$baseuri/api/cndnprint/?pjc=$pjc&gstvno=$gstvno'),
      )
          .then((response) async {
        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);

          // --- Extracting Mobile Numbers and Filename ---

          final List<String> mobileNumbers = jsonResponse['mobile_numbers']
              .where((item) => item != null)
              .toList()
              .cast<String>();
          final String filename = jsonResponse['filename'];

          if (kDebugMode) {
            print('✅ Received Mobile Numbers: $mobileNumbers');
            print('✅ Filename: $filename');
          }

          // --- Decoding and Saving the PDF File ---

          final String base64Pdf = jsonResponse['pdf_data'];
          var billfilename =
              gstvno.split(',').length > 1 ? 'CNDNs(${widget.pjc})' : gstvno;
          // 3. Base64 Decode the PDF string into raw bytes (Uint8List)
          final pdfBytes = base64Decode(base64Pdf);
          final dir = await getTemporaryDirectory();
          final filepath =
              '${dir.path}/$billfilename-${DateTime.now().millisecondsSinceEpoch}.pdf';
          File file = File(filepath);
          await file.writeAsBytes(pdfBytes);
          Navigator.of(context).pop(); // Close the loading dialog
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Pdfview(
                mobileNumbers: mobileNumbers,
                file: file,
                type: tt == "All invoices"
                    ? "All invoices"
                    : tt == "Credit Note"
                        ? "Credit Note"
                        : "Debit Note",
                ac: ac,
              ),
            ),
          );
        }
      });
    } else {
      http
          .get(
        Uri.parse('$baseuri/api/invoiceprint/?pjc=$pjc&gstvno=$gstvno'),
      )
          .then((response) async {
        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);

          // --- Extracting Mobile Numbers and Filename ---

          final List<String> mobileNumbers = jsonResponse['mobile_numbers']
              .where((item) => item != null)
              .toList()
              .cast<String>();
          final String filename = jsonResponse['filename'];

          if (kDebugMode) {
            print('✅ Received Mobile Numbers: $mobileNumbers');
            print('✅ Filename: $filename');
          }

          // --- Decoding and Saving the PDF File ---

          final String base64Pdf = jsonResponse['pdf_data'];
          var billfilename =
              gstvno.split(',').length > 1 ? 'Invoices(${widget.pjc})' : gstvno;
          // 3. Base64 Decode the PDF string into raw bytes (Uint8List)
          final pdfBytes = base64Decode(base64Pdf);
          final dir = await getTemporaryDirectory();
          final filepath =
              '${dir.path}/$billfilename-${DateTime.now().millisecondsSinceEpoch}.pdf';
          File file = File(filepath);
          await file.writeAsBytes(pdfBytes);
          Navigator.of(context).pop(); // Close the loading dialog
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Pdfview(
                mobileNumbers: mobileNumbers,
                file: file,
                type: tt == "All invoices"
                    ? "All invoices"
                    : tt == "S1"
                        ? "invoice"
                        : "Sales Return Invoice",
                ac: ac,
              ),
            ),
          );

          // final body = json.decode(response.body);
          // String pdfurl = body['pdf_url'];
          // Utils.openUrl(pdfurl);
        }
      });
    }
  }

  // void filtervalues() {
  //   Map<String, dynamic> filters = {};
  //   Set<String> uniqueProjects = {};
  //   Set<String> uniqueProducts = {};
  //   for (var lead in leads) {
  //     uniqueProducts.addAll(List<String>.from(lead.products));
  //     uniqueProjects.add(lead.pname);
  //   }
  //   filters["Product"] = uniqueProducts.toList();
  //   filters["Project"] = uniqueProjects.toList();
  //   widget.onfilterChange(filters);
  // }
}
