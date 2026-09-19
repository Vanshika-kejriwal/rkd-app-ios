import 'dart:convert';

import 'package:business_app/constants.dart';
import 'package:business_app/models/utils.dart';
import 'package:business_app/widgets/background.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PickupForm extends StatefulWidget {
  final List<Invoice> selectedInvoices;
  const PickupForm({super.key, required this.selectedInvoices});

  @override
  State<PickupForm> createState() => _PickupFormState();
}

class _PickupFormState extends State<PickupForm> {
  String? _selecteddeltype;
  Future<List<String>>? _vhn;
  Future<List<String>>? _enames;
  Future<List<String>>? _deltype;
  List<String> _emobile = [];
  String? selectedvhn;
  String? _selectedename;
  String? _selectedemobile;
  final TextEditingController _emobileAddController = TextEditingController();
  final TextEditingController _vhnAddController = TextEditingController();
  final TextEditingController _enameAddController = TextEditingController();
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

  Future<List<String>> getvhno() async {
    final response = await http.get(Uri.parse('$baseuri/api/pickupvhno/'));
    final body = json.decode(response.body);
    // print('Response body: $body'); // Debugging line to check the response
    List<String> comp = [];
    if (response.statusCode == 200) {
      for (var c in body) {
        comp.add(c["VHN"]);
      }
    }
    return comp;
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
    final response = await http.get(Uri.parse('$baseuri/api/getpickupemobile/?ename=$_selectedename'));
    final body = json.decode(response.body);
    List<String> comp = [];
    if (response.statusCode == 200) {
      for (var c in body) {
        comp.add(c["EMOBILE"]);
      }
    }
    setState(() {
      _emobile = comp;
      _selectedemobile = _emobile.isNotEmpty ? _emobile.first : null; // Set the first mobile number as selected if available
    });
    // return comp;
  }

  @override
  initState() {
    super.initState();
    _vhn = getvhno();
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
              future: _vhn,
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
                                    final newItem =
                                        _vhnAddController.text.trim();
                                    if (newItem.isNotEmpty &&
                                        !asyncSnapshot.data!.contains(newItem)) {
                                      setState(() {
                                        asyncSnapshot.data!.add(newItem);
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
                );
              }),
        ),
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
                      labelText: 'Select or Add Vehicle Number',
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
                                        !asyncSnapshot.data!.contains(newItem)) {
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
                    });
                  },
                );
              }),
        ),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: 
                DropdownSearch<String>(
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
                )
              ),
        
        if (_isloading) Center(child: const CircularProgressIndicator()),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromRGBO(252, 101, 8, 1),
                                  foregroundColor: Colors.white),
              onPressed: _isloading? null: () async {
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
                }else{
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
