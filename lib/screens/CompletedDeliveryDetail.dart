import 'dart:convert';
import 'dart:io';

import 'package:business_app/constants.dart';
import 'package:business_app/models/utils.dart';
import 'package:business_app/screens/pdfview.dart';
import 'package:business_app/widgets/background.dart';
import 'package:business_app/widgets/gallery.dart';
import 'package:business_app/widgets/input_field.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';

class CompletedDeliveryDetail extends StatefulWidget {
  Amast currentlead;
  CompletedDeliveryDetail({super.key, required this.currentlead});

  @override
  State<CompletedDeliveryDetail> createState() =>
      _CompletedDeliveryDetailState();
}

class _CompletedDeliveryDetailState extends State<CompletedDeliveryDetail> {
  final TextEditingController _billnosearchcontroller = TextEditingController();
  Map<String, dynamic> filters = {};
  // final List<String> _filteredCusttype = [];
  DateTimeRange? _filteredDate;
  List<LeadProduct> _filteredProducts = [];
  List<LeadProduct> comp = [];
  final _dobcontroller = TextEditingController();
  // Map<String, dynamic>? _selectedfiltervalues;
  late final PagingController<int, CompDelVno> _pagingController =
      PagingController<int, CompDelVno>(
    getNextPageKey: (state) {
      if (state.pages == null || state.pages!.isEmpty) {
        return 1;
      }

      if (state.lastPageIsEmpty) {
        return null;
      }

      return (state.keys?.last ?? 0) + 1;
    },
    fetchPage: (pageKey) {
      // print('🔥 FETCH PAGE CALLED WITH KEY = $pageKey');
      return _fetchDrfPage(pageKey);
    },
  );

  // Change return type to Future<List<Amast>>
  Future<List<CompDelVno>> _fetchDrfPage(int pageKey) async {
    // print('🚨 _fetchDrfPage ENTERED: pageKey=$pageKey');
    try {
      final Uri url = Uri.parse('$baseuri/api/completeddelvno/').replace(
        queryParameters: {
          'page': pageKey.toString(),
          "ac": widget.currentlead.ac,
          if (_billnosearchcontroller.text.isNotEmpty)
            'billno': _billnosearchcontroller.text,
          if (_filteredDate != null)
            "start_date": _filteredDate?.start.toString().split(" ")[0],
          if (_filteredDate != null)
            "end_date": _filteredDate?.end.toString().split(" ")[0],
          if (_filteredProducts.isNotEmpty)
            "mcs": _filteredProducts.map(((e) => e.mc)).toList().join(",")
        },
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        final List<dynamic> results = decodedData['results'] ?? [];

        // Return the parsed list directly
        // print(results);
        // print('PAGE $pageKey RESULTS:');

        // for (int i = 0; i < results.length; i++) {
        //   print(
        //     'PAGE $pageKey [$i] '
        //     'AC=${results[i]['AC']} '
        //     'NAME=${results[i]['Customer_Name']}',
        //   );
        // }
        return results
            .map((item) => CompDelVno(
                amount: item['AMOUNT'],
                vno: item["BNO"],
                date: item["BDATE"],
                gstvno: item["GSTVNO"] ?? ""))
            .toList();
      } else if (response.statusCode == 404) {
        // DRF returns 404 when you hit the end.
        // Return an empty list to signal that there are no more pages.
        return [];
      } else {
        throw Exception('Server error code: ${response.statusCode}');
      }
    } catch (error) {
      // Re-throw the error so the PagingController automatically catches it
      // and shifts your UI into the error/retry state.
      rethrow;
    }
  }

  Future<void> fetchcomp() async {
    List<LeadProduct> data = [];
    var response = await http.get(Uri.parse("$baseuri/api/getmmastcomp/"));
    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body);
      // data.add(LeadProduct(company: "Add New", product: "Add New", mc: "Add New"));
      data.addAll((jsonData as List)
          .map((e) =>
              LeadProduct(company: e["FNM"], product: e["PNM"], mc: e["MC"]))
          .toList());
      var uniqueData =
          {for (var item in data) item.company: item}.values.toList();
      setState(() {
        comp = uniqueData;
      });
    }
  }

  @override
  void initState() {
    fetchcomp();
    super.initState();
  }

  // Fetch detailed info for a specific bill/vno and date
  Future<Map<String, dynamic>> _fetchDeliveryDetail(
      String vno, String date) async {
    // print(item.gstvno)
    final Uri url = Uri.parse('$baseuri/api/delivery-detail/').replace(
      queryParameters: {
        'vno': vno,
        'date': date,
      },
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body).first;
    } else {
      throw Exception('Failed to load delivery details');
    }
  }

  // Show the popup dialog matching your design format
  void _showDetailPopup(BuildContext context, CompDelVno item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _fetchDeliveryDetail(item.vno, item.date),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(30.0),
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Failed to load details.",
                        style: TextStyle(color: Colors.red)),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    )
                  ],
                ),
              );
            } else if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("No details found."),
              );
            }

            final data = snapshot.data!;
            if (kDebugMode) {
              print(data);
            }
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    " Bill: ${item.vno} (${DateFormat("dd/MM/yyyy").format(DateFormat("yyyy-MM-dd").parse(item.date))})",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 20),
                  // Row 1
                  Row(
                    children: [
                      Expanded(
                          child: _buildFieldColumn(
                              "Emp Name:", data['ENAME'] ?? '-')),
                      Expanded(
                          child: _buildFieldColumn(
                              "Emp Mobile", data['EMOBILE'] ?? '-')),
                    ],
                  ),
                  const Divider(height: 20),
                  // Row 2
                  Row(
                    children: [
                      Expanded(
                          child: _buildFieldColumn(
                              "Delivery Type", data['Deliverytype'] ?? '-')),
                      Expanded(
                          child: _buildFieldColumn(
                              "Vehicle No.", data['VHN'] ?? '-')),
                    ],
                  ),
                  if (data["Deliverytype"] != "By Hand" &&
                      data["Deliverytype"] != "Self Pickup")
                    const Divider(height: 20),
                  // Row 3
                  if (data["Deliverytype"] != "By Hand" &&
                      data["Deliverytype"] != "Self Pickup")
                    Row(
                      children: [
                        Expanded(
                            child: _buildFieldColumn(
                                "Bilty No.", data['Biltyno'] ?? '-')),
                        Expanded(
                            child: _buildFieldColumn(
                                "Bilty Date", data['biltydt'] ?? '-')),
                      ],
                    ),
                  if (data["Deliverytype"] != "By Hand" &&
                      data["Deliverytype"] != "Self Pickup")
                    const Divider(height: 20),
                  // Row 4
                  if (data["Deliverytype"] != "By Hand" &&
                      data["Deliverytype"] != "Self Pickup")
                    Row(
                      children: [
                        Expanded(
                            child: _buildFieldColumn(
                                "Transprort Name", data['Name'] ?? '-')),
                        Expanded(
                            child: _buildFieldColumn(
                                "Transport Mobile", data['Mobile'] ?? "-")),
                      ],
                    ),
                  const Divider(height: 20),
                  // Row 2
                  Row(
                    children: [
                      Expanded(
                          child: _buildFieldColumn(
                              "Pickup Time", data['PICKUPDATETIME'] ?? '-')),
                      Expanded(
                          child: _buildFieldColumn(
                              "Delivery Time", data['DELDT'] ?? '-')),
                    ],
                  ),
                  const Divider(height: 20),
                  // Row 2
                  if (data["Deliverytype"] != "Self Pickup")
                    Row(
                      children: [
                        Expanded(
                            child: _buildFieldColumn(
                                "Delivery Received By", data['DELTON'] ?? '-')),
                        Expanded(
                            child: _buildFieldColumn(
                                "Delivery To Mobile", data['DELTOM'] ?? '-')),
                      ],
                    ),
                  const SizedBox(height: 20),
                  // View Receipt Button
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            side: const BorderSide(color: Colors.deepPurple),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            // Handle View Bill logic using item.vno and item.date
                            QuickAlert.show(
                              context: context,
                              type: QuickAlertType.loading,
                              title: 'Generating Invoice...',
                              barrierDismissible: false,
                            );
                            var gstvno = item.gstvno;
                            http
                                .get(
                              Uri.parse(
                                  '$baseuri/api/invoiceprint/?gstvno=$gstvno'),
                            )
                                .then((response) async {
                              if (response.statusCode == 200) {
                                final jsonResponse = jsonDecode(response.body);

                                // --- Extracting Mobile Numbers and Filename ---

                                final List<String> mobileNumbers =
                                    jsonResponse['mobile_numbers']
                                        .where((item) => item != null)
                                        .toList()
                                        .cast<String>();
                                final String filename =
                                    jsonResponse['filename'];

                                if (kDebugMode) {
                                  print(
                                      '✅ Received Mobile Numbers: $mobileNumbers');
                                  print('✅ Filename: $filename');
                                }

                                // --- Decoding and Saving the PDF File ---

                                final String base64Pdf =
                                    jsonResponse['pdf_data'];
                                var billfilename = gstvno;
                                // 3. Base64 Decode the PDF string into raw bytes (Uint8List)
                                final pdfBytes = base64Decode(base64Pdf);
                                final dir = await getTemporaryDirectory();
                                final filepath =
                                    '${dir.path}/$billfilename-${DateTime.now().millisecondsSinceEpoch}.pdf';
                                File file = File(filepath);
                                await file.writeAsBytes(pdfBytes);
                                Navigator.of(context)
                                    .pop(); // Close the loading dialog
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => Pdfview(
                                      mobileNumbers: mobileNumbers,
                                      ac: widget.currentlead.ac,
                                      file: file,
                                      type: "invoice",
                                      // ac: ac,
                                    ),
                                  ),
                                );

                                // final body = json.decode(response.body);
                                // String pdfurl = body['pdf_url'];
                                // Utils.openUrl(pdfurl);
                              }
                            });
                          },
                          icon: const Icon(Icons.description,
                              color: Colors.deepPurple, size: 18),
                          label: const Text("View Bill",
                              style: TextStyle(
                                  color: Colors.deepPurple, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            side: const BorderSide(color: Colors.deepPurple),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            // Handle View Receiving logic using item.vno and item.date
                            var links = [];
                            if (data['Blink'] != null && data['Blink'] != "") {
                              links.add(data['Blink'].replaceAll("dl=0", "raw=1"));
                            }
                            if (data['PPIC1'] != null && data['PPIC1'] != "") {
                              links.add(data['PPIC1'].replaceAll("dl=0", "raw=1"));
                            }
                            if (data['PPIC2'] != null && data['PPIC2'] != "") {
                              links.add(data['PPIC3'].replaceAll("dl=0", "raw=1"));
                            }
                            if (data['PPIC3'] != null && data['PPIC3'] != "") {
                              links.add(data['Blink'].replaceAll("dl=0", "raw=1"));
                            }
                            if (data['DELRECLINK'] != null && data['DELRECLINK'] != "") {
                              links.add(data['DELRECLINK'].replaceAll("dl=0", "raw=1"));
                            }
                            if (data['DELREC2'] != null && data['DELREC2'] != "") {
                              links.add(data['DELREC2'].replaceAll("dl=0", "raw=1"));
                            }
                            if (data['DELREC3'] != null && data['DELREC3'] != "") {
                              links.add(data['DELREC3'].replaceAll("dl=0", "raw=1"));
                            }
                            if(links.isNotEmpty){
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => CompleteGalleryScreen(
                                          mediaItems: links
                                              .map<Map<String, dynamic>>(
                                                  (url) => {
                                                        "url_or_path":
                                                            url.trim()
                                                      })
                                              .toList(),
                                        )));
                            }else{
                              QuickAlert.show(
                              context: context,
                              type: QuickAlertType.error,
                              title: 'No images to show',
                              // barrierDismissible: false,
                            );
                            }
                          },
                          icon: const Icon(Icons.assignment_turned_in,
                              color: Colors.deepPurple, size: 18),
                          label: const Text("View Receiving",
                              style: TextStyle(
                                  color: Colors.deepPurple, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFieldColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      childs: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: InputField(
              controller: _billnosearchcontroller,
              label: "Search Bill No.",
              suff: IconButton(
                  onPressed: () {
                    _pagingController.refresh();
                  },
                  icon: const Icon(Icons.search)),
            ),
          ),
          Expanded(
            child: PagingListener<int, CompDelVno>(
              controller: _pagingController,
              builder: (context, state, fetchNextPage) =>
                  PagedListView<int, CompDelVno>(
                state: state, // <-- Now Required
                fetchNextPage: fetchNextPage, // <-- Now Required
                builderDelegate: PagedChildBuilderDelegate<CompDelVno>(
                  itemBuilder: (context, item, index) => Card(
                    color: Colors.transparent,
                    child: ListTile(
                      // leading: CircleAvatar(child: Text('${item.id}')),
                      title: Text(
                        "${item.vno} (${DateFormat("dd/MM/yyyy").format(DateFormat("yyyy-MM-dd").parse(item.date))})",
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        item.amount,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      tileColor: Colors.blue[50],
                      onTap: () {
                        // Handle item interaction
                        _showDetailPopup(context, item);
                      },
                    ),
                  ),
                  noItemsFoundIndicatorBuilder: (context) => const Center(
                    child: Text('No results match your search filter.'),
                  ),
                  firstPageErrorIndicatorBuilder: (context) => Center(
                    child: ElevatedButton(
                      // In v5, you can use the fetchNextPage callback to retry
                      onPressed: () => fetchNextPage(),
                      child: const Text('Failed to load. Retry?'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      appbartitle: Text(widget.currentlead.name),
      appbaractions: [
        IconButton(
            onPressed: (() async {
              {
                // List<String> filteredProjects = _filteredCusttype;
                List<LeadProduct> filteredProducts = _filteredProducts;
                DateTimeRange? filterdate = _filteredDate;
                final result = await showModalBottomSheet(
                  isScrollControlled: true,
                  context: context,
                  builder: (context) {
                    return SafeArea(
                      child: StatefulBuilder(builder: (context, setstate) {
                        return Container(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(1.0),
                                child:
                                    DropdownSearch<LeadProduct>.multiSelection(
                                  selectedItems: filteredProducts,
                                  items: (filter, infiniteScrollProps) => comp,
                                  compareFn: (item1, item2) {
                                    return item1.mc == item2.mc;
                                  },
                                  itemAsString: (item) {
                                    return "${item.company} (${item.product})";
                                  },
                                  onSelected: (value) {
                                    setstate(() {
                                      filteredProducts = value;
                                    });
                                  },
                                  popupProps:
                                      const MultiSelectionPopupProps.dialog(
                                          dialogProps: DialogProps(
                                              barrierDismissible: true,
                                              barrierLabel: "Dismiss"),
                                          showSelectedItems: true,
                                          showSearchBox: true),
                                  decoratorProps: const DropDownDecoratorProps(
                                    decoration: InputDecoration(
                                      labelText: "Company",
                                      hintText: "Select Company",
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select an emplyee name';
                                    }
                                    return null;
                                  },
                                  autoValidateMode:
                                      AutovalidateMode.onUserInteraction,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: InputField(
                                  label: "Date Range",
                                  controller: _dobcontroller,
                                  readOnly: true,
                                  onTap: () async {
                                    var dr = await showOmniDateTimeRangePicker(
                                        context: context,
                                        barrierDismissible: true,
                                        startInitialDate: filterdate?.start,
                                        endInitialDate: filterdate?.end,
                                        type: OmniDateTimePickerType.date,
                                        isForceEndDateAfterStartDate: true);

                                    setstate(() {
                                      _dobcontroller.text = dr == null
                                          ? ""
                                          : "${DateFormat("dd/MM/yyyy").format(dr[0])}-${DateFormat("dd/MM/yyyy").format(dr[1])}";
                                      if (dr != null) {
                                        filterdate = DateTimeRange(
                                            start: dr[0], end: dr[1]);
                                      } else {
                                        filterdate = null;
                                      }
                                    });
                                  },
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Expanded(
                                      child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text("Cancel"))),
                                  Expanded(
                                      child: ElevatedButton(
                                          onPressed: () {
                                            Map<String, dynamic> filterval = {
                                              "Product": filteredProducts,
                                              // "Project": filteredProjects,
                                              "Date": filterdate
                                            };
                                            // if (kDebugMode) {
                                            //   print(filterval);
                                            // }
                                            // filterlist(filterval);
                                            Navigator.of(context)
                                                .pop(filterval);
                                          },
                                          child: const Text("Apply"))),
                                  Expanded(
                                      child: ElevatedButton(
                                          onPressed: () {
                                            setstate(() {
                                              filteredProducts = [];
                                              // filteredProjects = [];
                                              filterdate = null;
                                              _dobcontroller.clear();
                                            });
                                          },
                                          child: const Text("Clear All"))),
                                ],
                              )
                            ],
                          ),
                        );
                      }),
                    );
                  },
                );
                if (result != null) {
                  setState(() {
                    _filteredProducts = result["Product"];
                    // _filteredCusttype = result["Project"];
                    _filteredDate = result["Date"];
                  });
                  _pagingController.refresh();
                }
              }
            }),
            icon: Icon(Icons.filter_list_rounded))
      ],
      appbar: true,
    );
  }
}
