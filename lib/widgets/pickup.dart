import 'dart:convert';
import 'dart:io';

import 'package:business_app/constants.dart';
import 'package:business_app/models/utils.dart';
import 'package:business_app/screens/pdfview.dart';
import 'package:business_app/widgets/background.dart';
import 'package:business_app/widgets/input_field.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';

class PickupForm extends StatefulWidget {
  final List<Invoice> selectedInvoices;
  const PickupForm({super.key, required this.selectedInvoices});

  @override
  State<PickupForm> createState() => _PickupFormState();
}

class _PickupFormState extends State<PickupForm> {
  String? _selecteddeltype;
  List<String> _vhn = [];
  Future<List<String>>? _enames;
  Future<List<String>>? _deltype;
  List<String> _emobile = [];
  String? selectedvhn;
  String? _selectedename;
  String? _selectedemobile;
  final TextEditingController _emobileAddController = TextEditingController();
  final TextEditingController _vhnAddController = TextEditingController();
  final TextEditingController _enameAddController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  String? _selectedPhoneNumber;
  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();
  bool _isloading = false;

  Future<List<String>> getdeltype() async {
    final response = await http.get(Uri.parse('$baseuri/api/deltype/'));
    final body = json.decode(response.body);
    List<String> comp = [];
    if (response.statusCode == 200) {
      for (var c in body) {
        comp.add(c["Deliverytype"]);
      }
    }
    return comp;
  }

  Future<void> getvhno() async {
    final response = await http
        .get(Uri.parse('$baseuri/api/pickupvhno/?ename=$_selectedename'));
    final body = json.decode(response.body);
    // print('Response body: $body'); // Debugging line to check the response
    List<String> comp = [];
    if (response.statusCode == 200) {
      for (var c in body) {
        comp.add(c["VHN"]);
      }
    }
    setState(() {
      _vhn = comp;
      selectedvhn = _vhn.isNotEmpty
          ? _vhn.first
          : null; // Set the first mobile number as selected if available
    });
    // return comp;
  }

  Future<List<String>> getenames() async {
    final response = await http.get(Uri.parse('$baseuri/api/pickupenames/'));
    final body = json.decode(response.body);
    List<String> comp = [];
    if (response.statusCode == 200) {
      for (var c in body) {
        comp.add(c["ENAME"]);
      }
    }
    return comp;
  }

  Future<void> getemobile() async {
    final response = await http
        .get(Uri.parse('$baseuri/api/getpickupemobile/?ename=$_selectedename'));
    final body = json.decode(response.body);
    List<String> comp = [];
    if (response.statusCode == 200) {
      for (var c in body) {
        comp.add(c["EMOBILE"]);
      }
    }
    setState(() {
      _emobile = comp;
      _selectedemobile = _emobile.isNotEmpty
          ? _emobile.first
          : null; // Set the first mobile number as selected if available
    });
    // return comp;
  }

  @override
  initState() {
    super.initState();
    // _vhn = getvhno();
    _enames = getenames();
    _deltype = getdeltype();
    // _emobile = getemobile();
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      childs: SafeArea(
          child: Center(
              child: SizedBox(
                  child: Form(
                      child: Center(
                          child: SingleChildScrollView(
                              child: Column(children: [
        if (widget.selectedInvoices.isNotEmpty)
          Container(
            // height: 400,
            margin: const EdgeInsets.all(8.0),
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Selected Invoices (${widget.selectedInvoices.length}):",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.deepOrange,
                      ),
                    ),
                    TextButton(
                        onPressed: (() {
                          QuickAlert.show(
                            context: context,
                            type: QuickAlertType.loading,
                            title: 'Generating Invoice...',
                            barrierDismissible: false,
                          );
                          var gstvno = widget.selectedInvoices
                              .map(((e) => e.gstvno))
                              .toList()
                              .join(",");
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
                              final String filename = jsonResponse['filename'];

                              if (kDebugMode) {
                                print(
                                    '✅ Received Mobile Numbers: $mobileNumbers');
                                print('✅ Filename: $filename');
                              }

                              // --- Decoding and Saving the PDF File ---

                              final String base64Pdf = jsonResponse['pdf_data'];
                              var billfilename = gstvno.split(',').length > 1
                                  ? 'Invoices'
                                  : gstvno;
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
                                    file: file,
                                    type: widget.selectedInvoices.length > 1
                                        ? "All invoices"
                                        : "invoice",
                                    // ac: ac,
                                  ),
                                ),
                              );

                              // final body = json.decode(response.body);
                              // String pdfurl = body['pdf_url'];
                              // Utils.openUrl(pdfurl);
                            }
                          });
                        }),
                        child: Text("View Bills"))
                  ],
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 200, // Maximum height before it starts scrolling
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.selectedInvoices.length,
                    itemBuilder: (context, index) {
                      final inv = widget.selectedInvoices[index];

                      // Format date safely if available
                      String formattedDate = inv.date;
                      try {
                        formattedDate = DateFormat("dd/MM/yyyy").format(
                          DateFormat("yyyy-MM-dd").parse(inv.date),
                        );
                      } catch (_) {}

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        elevation: 0,
                        color: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Row 1: Name (Bold)
                              Text(
                                inv.name ?? "Unknown Customer",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Row 2: GSTVNO, Date, and Amount
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Bill: ${inv.gstvno}",
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black),
                                  ),
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black),
                                  ),
                                  Text(
                                    "₹${inv.amount}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        Padding(
            padding: const EdgeInsets.all(5.0),
            child: FutureBuilder<List<String>>(
                future: _deltype,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return DropdownSearch<String>(
                      // enabled: _editmode,
                      items: (filter, infiniteScrollProps) => snapshot.data!,
                      // itemAsString: (item) {
                      //   return item.pname;
                      // },
                      autoValidateMode: AutovalidateMode.onUserInteraction,
                      // filterFn: (item, filter) {
                      //   // This function determines which items are shown in the dropdown
                      //   // based on the user's input (the 'filter' string).
                      //   // It's case-insensitive for better UX.
                      //   // print(
                      //   //     'filterFn - item: "$item", filter: "$filter"');
                      //   return item.pname == "Add New" ||
                      //       item.pname
                      //           .toLowerCase()
                      //           .contains(filter.toLowerCase());
                      // },
                      validator: (value) {
                        if (value == null) {
                          return "Please select a Customer Type";
                        }
                        return null;
                      },
                      popupProps: PopupProps.dialog(
                        dialogProps: DialogProps(
                          barrierDismissible: true,
                          barrierLabel: "Dismiss",
                        ),
                        itemBuilder: (context, item, isSelected, onTap) {
                          return ListTile(
                            title: Text(item),
                          );
                        },
                        showSearchBox: true,

                        // isFilterOnline: true,

                        // emptyBuilder: (context, searchEntry) {
                        //   // WidgetsBinding.instance
                        //   // .addPostFrameCallback((_) {
                        //   if (searchEntry.isNotEmpty) {
                        //     // setState(() {
                        //     //   showTextField = true;
                        //     //   _pnamecontroller.text =
                        //     //       searchEntry;
                        //     //   // _namecontroller.clear();
                        //     //   // _ownermobilecontroller.clear();
                        //     //   // _add1controller.clear();
                        //     //   // _add2controller.clear();
                        //     //   // _pincontroller.clear();
                        //     //   // _statecontroller.clear();
                        //     //   // _citycontroller.clear();
                        //     //   // _districtcontroller.clear();
                        //     //   // _mobilecontroller.clear();
                        //     //   // _mobile2controller.clear();
                        //     //   // _emailcontroller.clear();
                        //     //   // _gstcontroller.clear();
                        //     //   // _reracontroller.clear();
                        //     // });
                        //   } else {
                        //     return const SizedBox
                        //         .shrink(); // Hide the empty message
                        //   }
                        // },
                      ),
                      onSelected: (data) {
                        setState(() {
                          _selecteddeltype = data;
                        });
                        // getprojdetail(data);
                      },
                      selectedItem: _selecteddeltype,
                      decoratorProps: const DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: "Select a Delivery Type",
                        ),
                      ),
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                })),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: FutureBuilder<List<String>>(
              future: _enames,
              builder: (context, asyncSnapshot) {
                if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (asyncSnapshot.hasError) {
                  return Text('Error: ${asyncSnapshot.error}');
                } else if (!asyncSnapshot.hasData ||
                    asyncSnapshot.data!.isEmpty) {
                  return const Text('No vehicle numbers available');
                }
                return DropdownSearch<String>(
                  items: (filter, loadProps) => asyncSnapshot.data!,
                  selectedItem: _selectedename,
                  decoratorProps: const DropDownDecoratorProps(
                    decoration: InputDecoration(
                      labelText: 'Select or Add Employee Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  popupProps: PopupProps.dialog(
                    showSearchBox: true,
                    dialogProps: const DialogProps(
                      barrierDismissible: true,
                      barrierLabel:
                          "Dismiss", // Allows tapping outside to dismiss
                    ),
                    // Add a custom widget at the bottom of the popup for adding new items
                    containerBuilder: (ctx, popupWidget) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _enameAddController,
                                    decoration: const InputDecoration(
                                      hintText: 'Add new item...',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    final newItem =
                                        _enameAddController.text.trim();
                                    if (newItem.isNotEmpty &&
                                        !asyncSnapshot.data!
                                            .contains(newItem)) {
                                      setState(() {
                                        asyncSnapshot.data!.add(newItem);
                                        _selectedename = newItem;
                                        getemobile(); // Fetch employee mobile numbers when a new employee name is added
                                      });
                                      _enameAddController.clear();
                                      // Close the popup/menu
                                      Navigator.pop(ctx);
                                    }
                                  },
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Flexible(child: popupWidget),
                        ],
                      );
                    },
                  ),
                  onSelected: (value) {
                    setState(() {
                      _selectedename = value;
                      getemobile(); // Fetch employee mobile numbers when an employee name is selected
                      getvhno();
                    });
                  },
                );
              }),
        ),
        Padding(
            padding: const EdgeInsets.all(5.0),
            child: DropdownSearch<String>(
              items: (filter, loadProps) => _vhn,
              selectedItem: selectedvhn,
              decoratorProps: const DropDownDecoratorProps(
                decoration: InputDecoration(
                  labelText: 'Select or Add Vehicle Number',
                  border: OutlineInputBorder(),
                ),
              ),
              popupProps: PopupProps.dialog(
                showSearchBox: true,
                dialogProps: const DialogProps(
                  barrierDismissible: true,
                  barrierLabel: "Dismiss", // Allows tapping outside to dismiss
                ),
                // Add a custom widget at the bottom of the popup for adding new items
                containerBuilder: (ctx, popupWidget) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _vhnAddController,
                                decoration: const InputDecoration(
                                  hintText: 'Add new item...',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                final newItem = _vhnAddController.text.trim();
                                if (newItem.isNotEmpty &&
                                    _vhn.contains(newItem)) {
                                  setState(() {
                                    _vhn.add(newItem);
                                    selectedvhn = newItem;
                                  });
                                  _vhnAddController.clear();
                                  // Close the popup/menu
                                  Navigator.pop(ctx);
                                }
                              },
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Flexible(child: popupWidget),
                    ],
                  );
                },
              ),
              onSelected: (value) {
                setState(() {
                  selectedvhn = value;
                });
              },
            )),
        Padding(
            padding: const EdgeInsets.all(5.0),
            child: DropdownSearch<String>(
              items: (filter, loadProps) => _emobile,
              selectedItem: _selectedemobile,
              decoratorProps: const DropDownDecoratorProps(
                decoration: InputDecoration(
                  labelText: 'Select or Add Employee Mobile Number',
                  border: OutlineInputBorder(),
                ),
              ),
              popupProps: PopupProps.dialog(
                showSearchBox: true,
                dialogProps: const DialogProps(
                  barrierDismissible: true,
                  barrierLabel: "Dismiss", // Allows tapping outside to dismiss
                ),
                // Add a custom widget at the bottom of the popup for adding new items
                containerBuilder: (ctx, popupWidget) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _emobileAddController,
                                decoration: const InputDecoration(
                                  hintText: 'Add new item...',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                final newItem =
                                    _emobileAddController.text.trim();
                                if (newItem.isNotEmpty &&
                                    _emobile.contains(newItem)) {
                                  setState(() {
                                    _emobile.add(newItem);
                                    _selectedemobile = newItem;
                                  });
                                  _emobileAddController.clear();
                                  // Close the popup/menu
                                  Navigator.pop(ctx);
                                }
                              },
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Flexible(child: popupWidget),
                    ],
                  );
                },
              ),
              onSelected: (value) {
                setState(() {
                  _selectedemobile = value;
                });
              },
            )),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: InputField(
            label: "Mobile Number",
            keyboardtype: TextInputType.phone,
            controller: _mobileController,
            sufficon: IconButton(
                onPressed: () async {
                  Contact? contact = await _contactPicker.selectPhoneNumber();
                  setState(() {
                    _selectedPhoneNumber = contact?.selectedPhoneNumber;
                    if (_selectedPhoneNumber != null) {
                      var phno = _selectedPhoneNumber!.replaceAll(" ", "");
                      _mobileController.text = phno.substring(phno.length - 10);
                      _selectedPhoneNumber = null;
                    }
                  });
                },
                icon: const Icon(Icons.contacts)),
          ),
        ),
        if (_isloading) Center(child: const CircularProgressIndicator()),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(252, 101, 8, 1),
                  foregroundColor: Colors.white),
              onPressed: _isloading
                  ? null
                  : () async {
                      setState(() {
                        _isloading = true;
                      });
                      var resp = await http
                          .post(Uri.parse('$baseuri/api/createpickup/'), body: {
                        "vno": widget.selectedInvoices
                            .map(
                              (e) => e.gstvno,
                            )
                            .toList()
                            .join(","),
                        "deltype": _selecteddeltype,
                        'vhn': selectedvhn,
                        'ename': _selectedename,
                        'emobile': _selectedemobile,
                        'extra_contact': _mobileController.text
                      });
                      if (resp.statusCode == 200 || resp.statusCode == 201) {
                        if (mounted) {
                          setState(() {
                            _isloading = false;
                          });
                        }
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text("Data saved successfully"),
                            backgroundColor: Colors.green[400]));
                        Navigator.pop(context);
                      } else {
                        if (mounted) {
                          setState(() {
                            _isloading = false;
                          });
                        }
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text("Something Went Wrong"),
                            backgroundColor: Colors.red));
                      }
                    },
              child: Text("Save Detail")),
        )
      ]))))))),
      appbar: true,
      appbartitle: Text("Goods Pickup Form"),
      appbaractions: [],
    );
  }
}
