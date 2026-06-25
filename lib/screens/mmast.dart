import 'dart:convert';

import 'package:business_app/constants.dart';
import 'package:business_app/models/utils.dart';
import 'package:business_app/widgets/background.dart';
import 'package:business_app/widgets/input_field.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Mmast extends StatefulWidget {
  const Mmast({super.key});

  @override
  State<Mmast> createState() => _MmastState();
}

class _MmastState extends State<Mmast> {

  bool showTextField = false;
  bool showCompTextField = false;
  bool _editmode = false;
  bool _isLoading = false;
  final _formkey = GlobalKey<FormState>();
  final TextEditingController _productnamecontroller = TextEditingController();
  final TextEditingController _compnamecontroller = TextEditingController();
  final TextEditingController _productsearchcontroller = TextEditingController();
  final TextEditingController _compsearchcontroller = TextEditingController();
  final TextEditingController _namecontroller = TextEditingController();
  final TextEditingController _dwmcontroller = TextEditingController();
  final TextEditingController _nfdcontroller = TextEditingController();
  final TextEditingController _amcsdcontroller = TextEditingController();
  final TextEditingController _mccontroller = TextEditingController();
  bool _online = false;
  bool _gstless = false;
  bool _instc = false;
  bool _servc = false;
  final List _projects = [];
  LeadProduct? selectedItem;
  LeadProduct? selectedproduct;
  String? appmc;
  List<LeadProduct> comp = [LeadProduct(company: "Add New", product: "Add New", mc: "Add New")];
  List<LeadProduct> product = [LeadProduct(company: "Add New", product: "Add New", mc: "Add New")];

  Future<void> getprojdetail(LeadProduct project) async {
    final response =
        await http.get(Uri.parse('$baseuri/api/mmast/${project.mc}/'));
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      setState(() {
        appmc = body["APPMC"];
        _namecontroller.text = body["NAME"]??"";
        _dwmcontroller.text = body["DWM"]??"";
        _nfdcontroller.text = body["NFD"]??"";
        _amcsdcontroller.text = body["AMCSD"]??"";
        _mccontroller.text = body["MC"]??"";
        _online = body["ONLINE"] == "Y"?true:false;
        _gstless = body["GSTLESS"] == "Y"?true:false;
        _instc = body["INSC"] == "Y"?true:false;
        _servc = body["SERC"] == "Y"?true:false;
      });
        // _formkey.currentState?.validate();
      // print("Pincode doesnt exists");
    }
  }

  @override
  void initState() {
    getcomp();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double swidth = MediaQuery.of(context).size.width;
    double sheight = MediaQuery.of(context).size.height;
    return Background(
        appbaractions: [
          IconButton(
              onPressed: () {
                setState(() {
                  _editmode = !_editmode;
                  if ((_editmode) & (selectedItem != null)) {
                    _compnamecontroller.text = selectedItem!.company;
                    _productnamecontroller.text = selectedItem!.product;
                    _formkey.currentState?.validate();
                  }
                });
              },
              icon: const Icon(Icons.edit)),
          IconButton(
              onPressed: !_editmode
                  ? null
                  : () {
                      QuickAlert.show(
                        context: context,
                        type: QuickAlertType.confirm,
                        text:
                            "Delete ${selectedItem!.company} (${selectedItem!.product})",
                        onCancelBtnTap: () {
                          Navigator.of(context).pop();
                        },
                        onConfirmBtnTap: () async {
                          Navigator.of(context).pop();
                          final response = await http.delete(Uri.parse(
                              '$baseuri/api/mmast/$appmc/'));
                          if (response.statusCode.toString().startsWith("2")) {
                            QuickAlert.show(
                                context: context,
                                type: QuickAlertType.success,
                                text:
                                    "Successfully Deleted Project ${selectedItem!.company} (${selectedItem!.product})");
                            setState(() {
                              
                              // _selectedut = null;
                              appmc = null;
                              selectedItem = null;
                              _compnamecontroller.clear();
                              _productnamecontroller.clear();
                              _namecontroller.clear();
                              _dwmcontroller.clear();
                              _nfdcontroller.clear();
                              _amcsdcontroller.clear();
                              _mccontroller.clear();
                              showTextField = false;
                              _editmode = false;
                            });
                          } else {
                            if (kDebugMode) {
                              print(response.headers["location"]);
                            }
                            QuickAlert.show(
                                context: context,
                                type: QuickAlertType.error,
                                text:
                                    "Couldnot Delete Company ${selectedItem!.company} (${selectedItem!.product})");
                          }
                        },
                      );
                    },
              icon: const Icon(Icons.delete)),
          // IconButton(
          //     onPressed: () async {
          //       setState(() {
          //         _searchedProj = null;
          //         _searchcontroller.clear();
          //       });
          //       var result = await showDialog(
          //           context: context,
          //           builder: (context) =>
          //               StatefulBuilder(builder: (context, searchstate) {
          //                 return AlertDialog(
          //                   title: Row(
          //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //                     children: [
          //                       const Text("Search Projects"),
          //                       IconButton(
          //                           onPressed: () {
          //                             Navigator.of(context).pop();
          //                           },
          //                           icon: const Icon(Icons.close))
          //                     ],
          //                   ),
          //                   // actions: [
          //                   //   IconButton(
          //                   //       onPressed: () {
          //                   //         Navigator.of(context).pop();
          //                   //       },
          //                   //       icon: const Icon(Icons.close))
          //                   // ],
          //                   content: Column(
          //                     mainAxisSize: MainAxisSize.min,
          //                     children: [
          //                       InputField(
          //                         controller: _searchcontroller,
          //                         label: "Search Here",
          //                         suff: IconButton(
          //                             onPressed: () {
          //                               searchstate(() {
          //                                 _searchedProj = getprojects(
          //                                     searchterm:
          //                                         _searchcontroller.text);
          //                                 // print(searchedProj);
          //                               });
          //                             },
          //                             icon: const Icon(Icons.search)),
          //                       ),
          //                       const SizedBox(
          //                         height: 10,
          //                       ),
          //                       FutureBuilder<List<Project>>(
          //                         future: _searchedProj,
          //                         builder: (context, snapshot) {
          //                           // 1. Check Connection State
          //                           if (snapshot.connectionState ==
          //                               ConnectionState.waiting) {
          //                             return const CircularProgressIndicator();
          //                           } else if (snapshot.hasError) {
          //                             // 2. Check for Errors
          //                             return Text('Error: ${snapshot.error}');
          //                           } else if (snapshot.hasData) {
          //                             // 3. Data is Available - Now check for null/emptiness of the List
          //                             final List<Project>? dataList =
          //                                 snapshot.data;
          //                             if (kDebugMode) {
          //                               print(dataList);
          //                             }
          //                             if (dataList == null ||
          //                                 dataList.isEmpty) {
          //                               return const Text(
          //                                   'List is null or empty. Displaying no data message.');
          //                             } else {
          //                               // List has data, display it
          //                               return SizedBox(
          //                                 width: 400,
          //                                 height: sheight * 0.2,
          //                                 child: ListView.builder(
          //                                   itemCount: dataList.length,
          //                                   itemBuilder: (context, index) {
          //                                     return ListTile(
          //                                       title: Text(
          //                                           "${dataList[index].pname} (${dataList[index].custtype})"),
          //                                       onTap: () {
          //                                         // setState(() {
          //                                         //   selectedItem = dataList[index];
          //                                         // });
          //                                         // getprojdetail(dataList[index]);
          //                                         Navigator.of(context)
          //                                             .pop(dataList[index]);
          //                                       },
          //                                     );
          //                                   },
          //                                 ),
          //                               );
          //                             }
          //                           } else {
          //                             // This case is typically reached if snapshot.hasData is false,
          //                             // but there's no error and not waiting. Could be no data yet.
          //                             return const Text('No data available.');
          //                           }
          //                         },
          //                       ),
          //                     ],
          //                   ),
          //                 );
          //               }));
          //       if (result != null) {
          //         setState(() {
          //           selectedItem = result;
          //         });
          //         getprojdetail(result);
          //       }
          //     },
          //     icon: const Icon(Icons.search))
        ],
        appbar: true,
        appbartitle: const Text("Manufacturing Master"),
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
                              child: showCompTextField || _editmode
                                  ? InputField(
                                      // autofocus: true,
                                      controller: _compnamecontroller,
                                      label: "Company",
                                      onChanged: (value) {
                                        setState(() {
                                          if (value.isEmpty) {
                                            showCompTextField = false;
                                          }
                                        });
                                      },
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return "Please give a Company Name";
                                        }
                                        return null;
                                      },
                                    )
                                  : DropdownSearch<LeadProduct>(
                                      // key: _projectkey,
                                      // controller
                                      compareFn: (item1, item2) => item1.mc == item2.mc,
                                      popupProps: PopupProps.dialog(
                                        dialogProps: DialogProps(barrierDismissible: true,barrierLabel: "Dismiss",),
                                        // showSelectedItems: true,
                                        showSearchBox: true,
                                        searchFieldProps: TextFieldProps(
                                            decoration: const InputDecoration(
                                              labelText: "Search for an item*",
                                            ),
                                            controller:
                                                _compsearchcontroller),
                                      ),
                                      // mode: Mode.dialog,
                                      // showSelectedItems: true,
                                  
                                      items: (filter, infiniteScrollProps) => comp,
                                      itemAsString: (item) {
                                        return item.company;
                                      },
                                      filterFn: (item, filter) {
                                        // This function determines which items are shown in the dropdown
                                        // based on the user's input (the 'filter' string).
                                        // It's case-insensitive for better UX.
                                        // print(
                                        //     'filterFn - item: "$item", filter: "$filter"');
                                        return item.company == "Add New" ||
                                            item.company
                                                .toLowerCase()
                                                .contains(filter.toLowerCase());
                                      },
                                      decoratorProps:
                                          const DropDownDecoratorProps(
                                        decoration:
                                            InputDecoration(
                                          labelText: "Company*",
                                          hintText: "Select a Company",
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null) {
                                          return 'Please select a company from the List or enter a new name"';
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
                                        if (data!.company == "Add New") {
                                          setState(() {
                                            _compnamecontroller.text =
                                                _compsearchcontroller.text;
                                           
                                            appmc = null;
                                            product.clear();
                                            product.add(LeadProduct(company: "Add New", product: "Add New", mc: "Add New"));
                                            product.addAll( comp.where((element) => element.product != "Add New").map((e) => LeadProduct(company:e.company, product: e.product, mc: e.mc)).toList());
                                            product = {for (var item in product) item.product: item}.values.toList();
                                            showCompTextField = true;
                                            // _editmode = true;
                                          });
                                        } else {
                                          setState(() {
                                            selectedItem = data;
                                            appmc = data.mc;
                                            product.clear();
                                            product.add(LeadProduct(company: "Add New", product: "Add New", mc: "Add New"));
                                            product.addAll( comp.where((element) => element.company == data.company && element.product != "Add New").map((e) => LeadProduct(company:e.company, product: e.product, mc: e.mc)).toList());
                                          });
                                          // getprojdetail(data);
                                        }
                                      },
                                      selectedItem: selectedItem
                                      // showSearchBox: true,
                                      // searchFieldProps: TextFieldProps(
                                      //   cursorColor: Colors.blue,
                                      // ),
                                      )),
                          Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: showTextField || _editmode
                                  ? InputField(
                                      // autofocus: true,
                                      controller: _productnamecontroller,
                                      label: "Product",
                                      onChanged: (value) {
                                        setState(() {
                                          if (value.isEmpty) {
                                            showTextField = false;
                                          }
                                        });
                                      },
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return "Please give a Product Name";
                                        }
                                        return null;
                                      },
                                    )
                                  : DropdownSearch<LeadProduct>(
                                      // key: _projectkey,
                                      // controller
                                      compareFn: (item1, item2) => item1.mc == item2.mc,
                                      popupProps: PopupProps.dialog(
                                        dialogProps: DialogProps(barrierDismissible: true,barrierLabel: "Dismiss",),
                                        // showSelectedItems: true,
                                        showSearchBox: true,
                                        searchFieldProps: TextFieldProps(
                                            decoration: const InputDecoration(
                                              labelText: "Search for an item*",
                                            ),
                                            controller:
                                                _productsearchcontroller),
                                      ),
                                      // mode: Mode.dialog,
                                      // showSelectedItems: true,
                                  
                                      items: (filter, infiniteScrollProps) => product,
                                      itemAsString: (item) {
                                        return item.product;
                                      },
                                      filterFn: (item, filter) {
                                        // This function determines which items are shown in the dropdown
                                        // based on the user's input (the 'filter' string).
                                        // It's case-insensitive for better UX.
                                        // print(
                                        //     'filterFn - item: "$item", filter: "$filter"');
                                        return item.product == "Add New"  ||
                                            item.product
                                                .toLowerCase()
                                                .contains(filter.toLowerCase());
                                      },
                                      decoratorProps:
                                          const DropDownDecoratorProps(
                                        decoration:
                                            InputDecoration(
                                          labelText: "Product*",
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
                                        if (data!.product == "Add New") {
                                          setState(() {
                                            _productnamecontroller.text =
                                                _productsearchcontroller.text;
                                           
                                            appmc = null;
                                            
                                            showTextField = true;
                                            // _editmode = true;
                                          });
                                        } else {
                                          setState(() {
                                            selectedproduct = data;
                                            
                                          });
                                          if (selectedItem?.company != "Add New"){
                                            appmc = data.mc;
                                            getprojdetail(data);
                                          }
                                        }
                                      },
                                      selectedItem: selectedproduct
                                      // showSearchBox: true,
                                      // searchFieldProps: TextFieldProps(
                                      //   cursorColor: Colors.blue,
                                      // ),
                                      )),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: InputField(
                              readOnly: !_editmode,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return "Company Name is required";
                                }
                                // if (value.length != 10) {
                                //   return "Please enter 10-digit mobile number";
                                // }

                                return null;
                              },
                              label: "Full Name of Company",
                              controller: _namecontroller,
                            ),
                          ),
                          Padding(padding: const EdgeInsets.all(5.0),
                          child: CheckboxListTile(title: const Text('Show in App'),
                          enabled: _editmode,
                            value: _online, onChanged: (val){
                              setState(() {
                                _online = val!;
                              });
                          })
                          ,),
                          Padding(padding: const EdgeInsets.all(5.0),
                          child: CheckboxListTile(title: const Text('GST included in Rates'),
                          enabled: _editmode,
                            value: _gstless, onChanged: (val){
                              setState(() {
                                _gstless = val!;
                              });
                          })
                          ,),
                          Padding(padding: const EdgeInsets.all(5.0),
                          child: CheckboxListTile(title: const Text('Include for Installation Creation'),
                          enabled: _editmode,
                            value: _instc, onChanged: (val){
                              setState(() {
                                _instc = val!;
                              });
                          })
                          ,),
                          Padding(padding: const EdgeInsets.all(5.0),
                          child: CheckboxListTile(title: const Text('Include for Service Creation'),
                            enabled: _editmode,
                            value: _servc, onChanged: (val){
                              setState(() {
                                _servc = val!;
                              });
                          })
                          ,),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: InputField(
                              readOnly: !_editmode,
                             
                              label: "Default Waranty month",
                              controller: _dwmcontroller,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: InputField(
                              readOnly: !_editmode,
                              label: "NFD",
                              controller: _nfdcontroller,
                            ),
                          ),
                          
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: InputField(
                              label: "AMCSD",
                              controller: _amcsdcontroller,
                              readOnly: !_editmode,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: InputField(
                              readOnly: !_editmode,
                              label: "Billing Software Code",
                              controller: _mccontroller,
                              keyboardtype: TextInputType.number,
                              onChanged: (value) async {
                                // if (value.length == 6) {
                                //   final response = await http.get(
                                //       Uri.parse('$baseuri/api/loca/$value/'));
                                //   if (response.statusCode == 200) {
                                //     final body = json.decode(response.body);
                                //     _statecontroller.text = body["STATE"];
                                //     _citycontroller.text = body["CITY"];
                                //     _districtcontroller.text = body["CITY"];
                                //     // print("Pincode doesnt exists");
                                //   } else {
                                //     QuickAlert.show(
                                //         context: context,
                                //         type: QuickAlertType.error,
                                //         title: "Error",
                                //         text:
                                //             "Pincode doesnot exist. Please enter a valid Pincode");
                                //   }
                                // }
                              },
                            ),
                          ),
                          
                          if (_isLoading)
                            const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.brown)),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: ElevatedButton(
                              onPressed: _isLoading | !_editmode
                                  ? null
                                  : (() async {
                                      if (_formkey.currentState!.validate()) {
                                        if (appmc != null) {
                                          setState(() {
                                            _isLoading = true;
                                          });
                                          final Map<String, dynamic> data = {
                                            'APPMC': appmc,
                                            'NAME': _namecontroller.text,
                                            'DWM': _dwmcontroller.text,
                                            'NFD': _nfdcontroller.text,
                                            'AMCSD': _amcsdcontroller.text,
                                            'MC': _mccontroller.text,
                                            'PNM': selectedproduct!.product,
                                            'FNM': selectedItem!.company,
                                            "ONLINE": _online?"Y":"N",
                                            "GSTLESS": _gstless?"Y":"N",
                                            "INSC": _instc?"Y":"N",
                                            "SERC": _servc?"Y":"N",
                                          };
                                          final resp = await http.patch(
                                              Uri.parse(
                                                  '$baseuri/api/mmast/$appmc/'),
                                              body: data);
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
                                          } else {
                                            setState(() {
                                              _isLoading = false;
                                            });
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        "Something went wrong. Please try again."),
                                                    backgroundColor:
                                                        Colors.red));
                                          }
                                        } else {
                                          var sharedpref =
                                              await SharedPreferences
                                                  .getInstance();
                                          var loggedinmob =
                                              sharedpref.getString("Mobile");
                                          setState(() {
                                            _isLoading = true;
                                          });
                                          final Map<String, dynamic> data = {
                                            'NAME': _namecontroller.text,
                                            'DWM': _dwmcontroller.text,
                                            'NFD': _nfdcontroller.text,
                                            'AMCSD': _amcsdcontroller.text,
                                            'MC': _mccontroller.text,
                                            'PNM': selectedproduct!.product,
                                            'FNM': selectedItem!.company,
                                            "ONLINE": _online?"Y":"N",
                                            "GSTLESS": _gstless?"Y":"N",
                                            "INSC": _instc?"Y":"N",
                                            "SERC": _servc?"Y":"N",
                                          };
                                          final resp = await http.post(
                                              Uri.parse(
                                                  '$baseuri/api/mmastcreate/'),
                                              body: data);
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
                                          } else {
                                            setState(() {
                                              _isLoading = false;
                                            });
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        "Something went wrong. Please try again."),
                                                    backgroundColor:
                                                        Colors.red));
                                          }
                                        }
                                      }
                                    }),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromRGBO(252, 101, 8, 1),
                                  foregroundColor: Colors.white),
                              child: const Text("Save Details"),
                            ),
                          )
                        ],
                      ),
                    ),
                  )),
            ),
          ),
        ));
  }
  
  Future<List<LeadProduct>>? getcomp() async {
    List<LeadProduct> data = [];
    var response = await http.get(Uri.parse("$baseuri/api/getmmastcomp/"));
    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body);
      data.add(LeadProduct(company: "Add New", product: "Add New", mc: "Add New"));
      data.addAll((jsonData as List).map((e) => LeadProduct(company: e["FNM"], product: e["PNM"], mc: e["APPMC"])).toList());
      var uniqueData = {for (var item in data) item.company: item}.values.toList();
      setState(() {
        comp = uniqueData;
      });
    }
    return data;
  }
  
  void getcompdetail(LeadProduct data) {}
}