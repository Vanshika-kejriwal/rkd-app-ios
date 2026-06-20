import 'dart:convert';

import 'package:business_app/constants.dart';
import 'package:business_app/models/utils.dart';
import 'package:business_app/widgets/background.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';

class InstMast extends StatefulWidget {
  bool service;
  InstMast({super.key, this.service = false});

  @override
  State<InstMast> createState() => _InstMastState();
}

class _InstMastState extends State<InstMast> {
  String? _selectedProduct;
  final _formkey = GlobalKey<FormState>();
  final TextEditingController _projectsearchcontroller =
      TextEditingController();
  final List<String> _projects = [];
  List<String> _newproducts = [];
  List<Amast> _company = [];
  List<Amast> _newcompany = [];
  bool _isLoading = false;
  Amast? _selectedcompany;
  List<Institem> _selecteditem = [];
  List<Institem> _serviceitems = [];
  List<Institem> _selectedxserviceitem = [];
  List<Institem> _items = [];
  final _dwmcontroller = TextEditingController();
  final _nfdcontroller = TextEditingController();
  final _amcdcontroller = TextEditingController();

  Future<List<String>> getproducttype() async {
    List<String> products = [];
    try {
      final response =
          await http.get(Uri.parse('$baseuri/api/get_instproduct_type/?type=${widget.service ? "service" : "installation"}'));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        print(data);
        for (var item in data) {
          products.add(item['PNM'] as String);
        }
      } else {
        throw Exception('Failed to load product types');
      }
    } catch (error) {
      print('Error fetching product types: $error');
    }
    return products;
  }

  @override
  void initState() {
    // getproducttype();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double swidth = MediaQuery.of(context).size.width;
    return Background(
        childs: SafeArea(
          child: Center(
            child: SizedBox(
              width: swidth * 0.8,
              child: Form(
                  key: _formkey,
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: FutureBuilder<List<String>>(
                                  future: getproducttype(),
                                  builder: (context, asyncSnapshot) {
                                    return DropdownSearch<String>(
                                        // key: _projectkey,
                                        // controller
                                        popupProps: PopupProps.dialog(
                                          // showSelectedItems: true,
                                          showSearchBox: true,
                                          searchFieldProps: TextFieldProps(
                                              decoration: const InputDecoration(
                                                labelText:
                                                    "Search for an item*",
                                              ),
                                              controller:
                                                  _projectsearchcontroller),
                                        ),
                                        // mode: Mode.dialog,
                                        // showSelectedItems: true,

                                        items: (filter, infiniteScrollProps) => asyncSnapshot.data ?? [],
                                        // itemAsString: (item) {
                                        //   return "${item.pname} (${item.custtype})";
                                        // },
                                        filterFn: (item, filter) {
                                          // This function determines which items are shown in the dropdown
                                          // based on the user's input (the 'filter' string).
                                          // It's case-insensitive for better UX.
                                          // print(
                                          //     'filterFn - item: "$item", filter: "$filter"');
                                          return item == "Add New" ||
                                              item.toLowerCase().contains(
                                                  filter.toLowerCase());
                                        },
                                        decoratorProps:
                                            const DropDownDecoratorProps(
                                          decoration:
                                              InputDecoration(
                                            labelText: "Product",
                                            hintText: "Select a Product",
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null) {
                                            return 'Please select a product from the List or enter a new name"';
                                          }
                                          return null;
                                        },
                                        autoValidateMode:
                                            AutovalidateMode.onUserInteraction,
                                        // dropdownSearchDecoration: const InputDecoration(
                                        // labelText: "Menu mode",
                                        // hintText: "country in menu mode",
                                        // ),
                                        // popupItemDisabled: isItemDisabled,
                                        onSelected: (data) {
                                          if (data == "Add New") {
                                            // Handle the "Add New" option here
                                            // For example, you can show a dialog to enter a new product name
                                            // getnewproduct();
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                String newProductController =
                                                    "";
                                                return StatefulBuilder(builder:
                                                    (context, productstate) {
                                                  return AlertDialog(
                                                    title: const Text(
                                                        "Add New Product"),
                                                    content: FutureBuilder<
                                                            List<String>>(
                                                        future: getnewproduct(),
                                                        builder: (context,
                                                            asyncSnapshot) {
                                                          return DropdownSearch<
                                                              String>(
                                                            items: (filter, infiniteScrollProps) => asyncSnapshot
                                                                    .data ??
                                                                [],
                                                            onSelected: (value) {
                                                              if (value !=
                                                                  null) {
                                                                newProductController =
                                                                    value;
                                                              }
                                                            },
                                                          );
                                                        }),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        child: const Text(
                                                            "Cancel"),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          // String newProduct =
                                                          //     _newProductController
                                                          //         .text
                                                          //         .trim();
                                                          if (newProductController
                                                              .isNotEmpty) {
                                                            productstate(() {
                                                              _selectedProduct =
                                                                  newProductController;
                                                              // _projects.add(
                                                              //     newProductController);
                                                            });
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                            getnewcompany(
                                                                _selectedProduct);
                                                          }
                                                        },
                                                        child:
                                                            const Text("Add"),
                                                      ),
                                                    ],
                                                  );
                                                });
                                              },
                                            );
                                          } else {
                                            setState(() {
                                              _selectedProduct = data;
                                              _selectedcompany = null;
                                              _dwmcontroller.clear();
                                              _nfdcontroller.clear();
                                              _amcdcontroller.clear();
                                              _items = [];
                                              _selecteditem = [];
                                              _serviceitems = [];
                                              _selectedxserviceitem = [];
                                            });
                                            getcompany(data);
                                          }
                                        },
                                        selectedItem: _selectedProduct
                                        // showSearchBox: true,
                                        // searchFieldProps: TextFieldProps(
                                        //   cursorColor: Colors.blue,
                                        // ),
                                        );
                                  })),
                          Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: DropdownSearch<Amast>(
                                // enabled: _editmode,
                                items: (filter, infiniteScrollProps) => _company,
                                itemAsString: (item) {
                                  return item.name;
                                },
                                autoValidateMode:
                                    AutovalidateMode.onUserInteraction,
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
                                    return "Please select a company";
                                  }
                                  return null;
                                },
                                popupProps: PopupProps.dialog(
                                  itemBuilder: (context, item, isSelected, selectedItems) {
                                    return ListTile(
                                      title: Text(item.name),
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
                                  if (data!.name == "Add New") {
                                    // Handle the "Add New" option here
                                    // For example, you can show a dialog to enter a new company name
                                    // getnewcompany(_selectedProduct);
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        Amast? newCompany;

                                        return StatefulBuilder(
                                            builder: (context, compstate) {
                                          return AlertDialog(
                                            title:
                                                const Text("Add New Company"),
                                            content: FutureBuilder<List<Amast>>(
                                              future: getnewcompany(_selectedProduct),
                                              builder: (context, asyncSnapshot) {
                                                return DropdownSearch<Amast>(
                                                  itemAsString: (item) => item.name,
                                                  items: (filter, infiniteScrollProps) => asyncSnapshot.data ?? [],
                                                  onSelected: (value) {
                                                    if (value != null) {
                                                      newCompany = value;
                                                    }
                                                  },
                                                );
                                              }
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text("Cancel"),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  // String newProduct =
                                                  //     _newProductController
                                                  //         .text
                                                  //         .trim();
                                                  if (newCompany != null &&
                                                      newCompany!
                                                          .name.isNotEmpty) {
                                                    compstate(() {
                                                      _selectedcompany =
                                                          newCompany;
                                                      // _company.add(
                                                      //     newCompany!);
                                                    });
                                                    Navigator.of(context).pop();
                                                    getitems(newCompany!.ac);
                                                    // getnewcompany(
                                                    //     newCompany);
                                                  }
                                                },
                                                child: const Text("Add"),
                                              ),
                                            ],
                                          );
                                        });
                                      },
                                    );
                                  } else {
                                    setState(() {
                                      _selectedcompany = data;
                                      _dwmcontroller.clear();
                                      _nfdcontroller.clear();
                                      _amcdcontroller.clear();
                                    });
                                    getdetail(data);
                                  }
                                },
                                selectedItem: _selectedcompany,
                                decoratorProps:
                                    const DropDownDecoratorProps(
                                  decoration: InputDecoration(
                                    labelText: "Select a Company",
                                  ),
                                ),
                              )),
                          // Padding(
                          //   padding: const EdgeInsets.all(5.0),
                          //   child: InputField(
                          //     readOnly: !widget.service,
                          //     validator: (value) {
                          //       if (value!.isEmpty) {
                          //         return "DWM is requirted";
                          //       }
                          //       // if (value.length != 10) {
                          //       //   return "Please enter 10-digit mobile number";
                          //       // }

                          //       return null;
                          //     },
                          //     label: "Default waranty month*",
                          //     controller: _dwmcontroller,
                          //   ),
                          // ),
                          // Padding(
                          //   padding: const EdgeInsets.all(5.0),
                          //   child: InputField(
                          //     readOnly: !widget.service,
                          //     validator: (value) {
                          //       if (value!.isEmpty) {
                          //         return "NFD is required";
                          //       }

                          //       // if (value.length == 10 &&
                          //       //     !_isVerifiedomob &&
                          //       //     value != _existomob) {
                          //       //   return "Please verify mobile number";
                          //       // }
                          //       return null;
                          //     },
                          //     controller: _nfdcontroller,
                          //     label: "NFD",
                          //   ),
                          // ),
                          // Padding(
                          //   padding: const EdgeInsets.all(5.0),
                          //   child: InputField(
                          //     readOnly: !widget.service,
                          //     label: "AMCD",
                          //     controller: _amcdcontroller,
                          //     keyboardtype: TextInputType.number,
                          //   ),
                          // ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: DropdownSearch<Institem>.multiSelection(
                              enabled: !widget.service,
                              items: (filter, infiniteScrollProps) => _items,
                              itemAsString: (item) {
                                return item.item;
                              },
                              filterFn: (item, filter) => item.item
                                  .toLowerCase()
                                  .contains(filter.toLowerCase()) ||
                                  item.code.toLowerCase().contains(filter.toLowerCase()),
                              autoValidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: (value) {
                                return null;
                              },
                              popupProps:MultiSelectionPopupProps.dialog(
                                itemBuilder: (context, item, isSelected, selectedItems) {
                                  return ListTile(
                                    title: Text(item.item),
                                  );
                                },
                                showSearchBox: true,
                              ),
                              onSelected: (data) {
                                setState(() {
                                  _selecteditem = data;
                                  _serviceitems = _items.where((item) => !_selecteditem.contains(item)).toList();
                                });
                              },
                              selectedItems: _selecteditem,
                              decoratorProps:
                                  const DropDownDecoratorProps(
                                decoration: InputDecoration(
                                    labelText:
                                        "Select an Item to remove from installation",
                                    labelStyle: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: DropdownSearch<Institem>.multiSelection(
                              enabled: widget.service,
                              items: (filter, infiniteScrollProps) => _serviceitems,
                              itemAsString: (item) {
                                return item.item;
                              },
                              filterFn: (item, filter) => item.item
                                  .toLowerCase()
                                  .contains(filter.toLowerCase()) ||
                                  item.code.toLowerCase().contains(filter.toLowerCase()),
                              autoValidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: (value) {
                                return null;
                              },
                              popupProps:MultiSelectionPopupProps.dialog(
                                itemBuilder: (context, item, isSelected, selectedItems) {
                                  return ListTile(
                                    title: Text(item.item),
                                  );
                                },
                                showSearchBox: true,
                              ),
                              onSelected: (data) {
                                setState(() {
                                  _selectedxserviceitem = data;
                                });
                              },
                              selectedItems: _selectedxserviceitem,
                              decoratorProps:
                                  const DropDownDecoratorProps(
                                decoration: InputDecoration(
                                    labelText:
                                        "Select an Item to remove from Service",
                                    labelStyle: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ),
                          if (_isLoading)
                            const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.brown)),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : (() async {
                                        if (_formkey.currentState!.validate()) {
                                          setState(() {
                                            _isLoading = true;
                                          });
                                          final Map<String, dynamic> data = {
                                            "company":
                                                _selectedcompany?.ac ?? "",
                                            "dwm": _dwmcontroller.text,
                                            "nfd": _nfdcontroller.text,
                                            "amcd": _amcdcontroller.text,
                                            "product": _selectedProduct ?? "",
                                            "items": _selecteditem
                                                .map((e) => e.code)
                                                .toList(),
                                              "xservice": _selectedxserviceitem
                                                .map((e) => e.code)
                                                .toList(),
                                            "company_name":
                                                _selectedcompany?.name ?? ""
                                          };
                                          final resp = await http.post(
                                              Uri.parse(
                                                  '$baseuri/api/instmasterupdate/'),
                                              headers: {
                                                "Content-Type":
                                                    "application/json", // Critical addition
                                              },
                                              body: jsonEncode(data));
                                          if (resp.statusCode == 200 ||
                                              resp.statusCode == 201) {
                                            setState(() {
                                              _isLoading = false;
                                            });

                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: const Text(
                                                        "Data saved successfully"),
                                                    backgroundColor:
                                                        Colors.green[400]));
                                            Navigator.of(context).pop(true);
                                            // context.pop(true);
                                          }
                                        }
                                      }),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromRGBO(252, 101, 8, 1),
                                    foregroundColor: Colors.white),
                                child: const Text("Save Details")),
                          )
                        ],
                      ),
                    ),
                  )),
            ),
          ),
        ),
        appbartitle: widget.service ? const Text("Service Master") : const Text("Installation Master"),
        appbar: true,
        appbaractions: [
          if (!widget.service)
          IconButton(
              onPressed: () {
                // Example action for delete button
                if (kDebugMode) {
                  print("Delete button pressed");
                }
                QuickAlert.show(
                  context: context,
                  type: QuickAlertType.confirm,
                  title: 'Confirm Deletion',
                  text: 'Are you sure you want to delete this item?',
                  confirmBtnText: 'Yes, Delete',
                  cancelBtnText: 'No, Cancel',
                  onConfirmBtnTap: () async {
                    // Handle the deletion logic here
                    setState(() {
                      _isLoading = true;
                    });
                    final Map<String, dynamic> data = {
                      "company": _selectedcompany?.ac ?? "",
                      "dwm": _dwmcontroller.text,
                      "nfd": _nfdcontroller.text,
                      "amcd": _amcdcontroller.text,
                      "product": _selectedProduct ?? "",
                      "items": _selecteditem.map((e) => e.code).toList(),
                        "xservice": _selectedxserviceitem
                                                  .map((e) => e.code)
                                                  .toList(),
                      "company_name": _selectedcompany?.name ?? ""
                    };
                    final resp = await http.delete(
                        Uri.parse('$baseuri/api/instmasterupdate/'),
                        headers: {
                          "Content-Type":
                              "application/json", // Critical addition
                        },
                        body: jsonEncode(data));
                    if (resp.statusCode == 200 || resp.statusCode == 201) {
                      setState(() {
                        _isLoading = false;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text("Data saved successfully"),
                          backgroundColor: Colors.green[400]));
                      Navigator.of(context).pop(true);
                      // context.pop(true);
                    }
                    Navigator.of(context).pop(); // Close the dialog
                  },
                );
              },
              icon: const Icon(Icons.delete))
        ]);
  }

  Future<List<Institem>> getitems(String? data) async {
    List<Institem> itemsList = [];
    try {
      final response = await http
          .get(Uri.parse('$baseuri/api/get_institems/?product=$data'));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        print(data);
        for (var item in data) {
          if (item['ITEM'] != null) {
            itemsList.add(Institem(
              code: item['CODE'] as String,
              item: item['ITEM'] as String,
              instremoved: item['REMOVED'] as bool,
              serviceremoved: item['SERVICE_REMOVED'] as bool,
            ));
          }
        }
        // print(itemsList);
        setState(() {
          // Update the state with the fetched items list
          _items = itemsList;
          _selecteditem = itemsList.where((item) => item.instremoved).toList();
          _serviceitems = _items.where((item) => !_selecteditem.contains(item)).toList();
          _selectedxserviceitem = _serviceitems.where((item) => item.serviceremoved).toList();
        });
      } else {
        throw Exception('Failed to load items');
      }
    } catch (error) {
      print('Error fetching items: $error');
    }
    return itemsList;
  }

  Future<List<Amast>> getcompany(String? data) async {
    List<Amast> company = [];
    try {
      http.post(Uri.parse('$baseuri/api/get_companylist/'),
          body: {"product": data, "type": widget.service ? "service" : "installation"}).then((response) {
        if (response.statusCode == 200) {
          List<dynamic> data = jsonDecode(response.body);
          for (var item in data) {
            company.add(Amast(ac: item['MC'], name: item['FNM']));
          }
          setState(() {
            // Update the state with the fetched company list
            _company = company;
          });
        } else {
          throw Exception('Failed to load company list');
        }
      });
    } catch (error) {
      print('Error fetching company list: $error');
    }
    return company;
  }

  Future<List<Amast>> getnewcompany(String? data) async {
    List<Amast> company = [];
    try {
      print(data);
      http.post(Uri.parse('$baseuri/api/get_newcompanylist/'),
          body: {"product": data}).then((response) {
        if (response.statusCode == 200) {
          List<dynamic> data = jsonDecode(response.body);
          for (var item in data) {
            company.add(Amast(ac: item['MC'], name: item['FNM']));
          }
          setState(() {
            // Update the state with the fetched company list
            // _company = company;
            _company = company;
            _newcompany = company;
          });
        } else {
          throw Exception('Failed to load company list');
        }
      });
    } catch (error) {
      print('Error fetching company list: $error');
    }
    return company;
  }

  void getdetail(Amast? data1) async {
    if (data1 == null) return;

    try {
      final response = await http.post(
        Uri.parse('$baseuri/api/get_instdetail/'),
        body: {"mc": data1.ac},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        if (!mounted) return;

        // FIX: Check if the list has at least one element
        if (data.isNotEmpty) {
          setState(() {
            var firstItem = data.first;
            _dwmcontroller.text = firstItem['DWM']?.toString() ?? '';
            _nfdcontroller.text = firstItem['NFD']?.toString() ?? '';
            _amcdcontroller.text = firstItem['AMCD']?.toString() ?? '';
          });
        } else {
          // Optional: Clear the controllers if no data is found
          setState(() {
            _dwmcontroller.clear();
            _nfdcontroller.clear();
            _amcdcontroller.clear();
          });
          print("No details found for this ID.");
        }

        getitems(data1.ac);
      }
    } catch (error) {
      print('Error fetching project details: $error');
    }
  }

  Future<List<String>> getnewproduct() async {
    List<String> products = [];
    try {
      final response =
          await http.get(Uri.parse('$baseuri/api/get_newinstproduct_type/'));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        print(data);
        for (var item in data) {
          products.add(item['PNM'] as String);
        }
        setState(() {
          _newproducts = products;
        });
      } else {
        throw Exception('Failed to load product types');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error fetching product types: $error');
      }
    }
    return products;
  }
}
