import 'dart:convert';

import 'package:business_app/constants.dart';
import 'package:business_app/models/utils.dart';
import 'package:business_app/widgets/background.dart';
import 'package:business_app/widgets/input_field.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SiteInfo extends StatefulWidget {
  const SiteInfo({super.key});

  @override
  State<SiteInfo> createState() => _SiteInfoState();
}

class _SiteInfoState extends State<SiteInfo> {
  final _namecontroller = TextEditingController();
  final _pnamecontroller = TextEditingController();
  String? _selectedut;
  String? _selectedState;
  String? _selectedDistrict;
  final List<String> _districts = [];
  String? _existpjc;
  final _add1controller = TextEditingController();
  final _add2controller = TextEditingController();
  final _pincontroller = TextEditingController();
  final _statecontroller = TextEditingController();
  final _citycontroller = TextEditingController();
  final _districtcontroller = TextEditingController();
  final _ownermobilecontroller = TextEditingController();
  final _mobilecontroller = TextEditingController();
  final _mobile2controller = TextEditingController();
  final _emailcontroller = TextEditingController();
  final _gstcontroller = TextEditingController();
  final _reracontroller = TextEditingController();
  final _projectsearchcontroller = TextEditingController();
  final _searchcontroller = TextEditingController();
  final _otcontroller = TextEditingController();
  final _bedscontroller = TextEditingController();
  final _floorscontroller = TextEditingController();
  final _rwtsizecontroller = TextEditingController();
  final _swtsizecontroller = TextEditingController();
  final _firetsizecontroller = TextEditingController();
  final _flushingsizecontroller = TextEditingController();
  final _stpsizecontroller = TextEditingController();
  final _etpsizecontroller = TextEditingController();
  final _noboringcontroller = TextEditingController();
  final _amobilecontroller = TextEditingController();
  final _pmobilecontroller = TextEditingController();
  final _emobilecontroller = TextEditingController();
  String? _selectedwtplacement;
  int _selectednowt = 0;
  bool _isLoading = false;
  bool _isprojLoading = false;
  bool _editmode = false;
  Project? selectedItem;
  bool showTextField = false;
  String _loginut = '';
  final textController = TextEditingController();
  // late Future<List<Project>>? _projects;
  List<Project> _projects = [];
  final _formkey = GlobalKey<FormState>();
  final bool _verifyEmail = false;
  final bool _isVerifiedEmail = false;
  String? _existemail;
  final bool _newEmail = false;
  final bool _verifyomob = false;
  final bool _isVerifiedomob = false;
  String? _existomob;
  final _emailotpcontroller = TextEditingController();
  // static const platform = MethodChannel('com.example.myapp/otp');
  final String _otpCode = '';
  Future<List<Project>>? _searchedProj;
  Future<List<Project>>? _mobsearchedProj;
  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();
  List<Contact>? _contacts;
  String? _selectedPhoneNumber;
  final GlobalKey<DropdownSearchState<Project>> _projectkey =
      GlobalKey<DropdownSearchState<Project>>();

  Future<List<CustType>> getut() async {
    final response = await http.get(Uri.parse('$baseuri/api/custtype/'));
    final body = json.decode(response.body);
    List<CustType> user = [];
    if (response.statusCode == 200) {
      for (var ut in body) {
        user.add(CustType.fromJson(ut));
      }
    }
    return user;
  }

  Future<List<String>> getcomp() async {
    final response = await http.get(Uri.parse('$baseuri/api/custtype/'));
    final body = json.decode(response.body);
    List<String> comp = [];
    if (response.statusCode == 200) {
      for (var c in body) {
        comp.add(c["UT1"]);
      }
    }
    return comp;
  }

  Future<List<String>> getStates() async {
    final response = await http.get(Uri.parse('$baseuri/api/states/'));
    final body = json.decode(response.body);
    List<String> states = [];
    if (response.statusCode == 200) {
      for (var c in body) {
        states.add(c["STATE"]);
      }
    }
    return states;
  }

  Future<void> getDistricts() async {
    final response = await http
        .get(Uri.parse('$baseuri/api/districts/?state=$_selectedState'));
    final body = json.decode(response.body);
    // List<String> states = [];
    if (response.statusCode == 200) {
      for (var c in body) {
        _districts.add(c["DIST"]);
      }
    }
  }

  Future<List<Project>> getprojects({String? searchterm}) async {
    setState(() {
      _projects.clear();
    });
    Uri uri;
    if (kDebugMode) {
      uri = Uri.http(
        searchdevbaseuri,
        '/api/pnamelist/',
      );
    } else {
      uri = Uri.https(
        searchprodbaseuri,
        '/api/pnamelist/',
      );
    }

    Map<String, String> newQueryParams = {};
    List<Project> proj = [];
    proj.add(Project(pjc: "Add New", pname: "Add New", custtype: ""));
    if (searchterm != null && searchterm.isNotEmpty) {
      var searchlist =
          searchterm.split(" ").where((term) => term.isNotEmpty).toList();
      // print(searchlist);
      // searchterm.split(" ").forEach((item) {
      //   if (item.isNotEmpty) {
      //     newQueryParams["searchterm"] =
      //         item;
      //   }
      // });
      if (kDebugMode) {
        uri = Uri.http(searchdevbaseuri, '/api/pnamelist/', {
          'searchterm': searchlist, // The correct way to pass a list
        });
      } else {
        uri = Uri.http(searchprodbaseuri, '/api/pnamelist/', {
          'searchterm': searchlist, // The correct way to pass a list
        });
      }
      // var params =
      //     searchlist.map((term) => MapEntry('searchterm', term)).toList();
      // newQueryParams = Map.fromEntries(params);
      // print(newQueryParams);
    } else {
      proj.add(Project(pjc: "Add New", pname: "Add New", custtype: ""));
    }
    // if (newQueryParams.isNotEmpty) {
    //   uri = uri.replace(queryParameters: newQueryParams);
    // }
    final response = await http.get(uri);
    final body = json.decode(response.body);

    if (response.statusCode == 200 && body is List && body.isNotEmpty) {
      for (var c in body) {
        String name = c['PNAME'];
        String pjc = c["PJC"];
        proj.add(Project(pjc: pjc, pname: name, custtype: c["CUSTTYPE"]));
      }
    }
    return proj;
  }

  bool _checkEmailFn(String value) {
    final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
    return emailRegex.hasMatch(value);
  }

  Future<void> getprojdetail(Project project) async {
    final response =
        await http.get(Uri.parse('$baseuri/api/projectdetail/${project.pjc}/'));
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      setState(() {
        _existpjc = body["PJC"];
        _selectedut = body["CUSTTYPE"];
        _namecontroller.text = body["ARCHITECT_NAME"];
        _amobilecontroller.text = body['AMOBILE'];
        _ownermobilecontroller.text = body["PLUMBER_NAME"];
        _pmobilecontroller.text = body["PMOBILE"];
        _emobilecontroller.text = body['EMOBILE'];
        // _existomob = body["OMOBILE"];
        _add1controller.text = body["NOB"];
        _add2controller.text = body["NOK"];
        _pincontroller.text = body["NOBH"];
        // _selectedState = body["STATE"];
        _citycontroller.text = body["NO_RESTRAUNTS"];
        // _selectedDistrict = body["DIST"];
        _mobilecontroller.text = body["ELECTRICIAN_NAME"];
        _mobile2controller.text = body["NOR"];
        // _emailcontroller.text = body["EMAIL"];
        // _existemail = body["EMAIL"];
        _gstcontroller.text = body["NOC"];
        _otcontroller.text = body["NO_OT"];
        _bedscontroller.text = body["BEDS"];
        _floorscontroller.text = body["NOF"];
        _selectednowt = int.tryParse(body["NOWT"]) ?? 0;
        _rwtsizecontroller.text = body["RWT_SIZE"];
        _swtsizecontroller.text = body["SWT_SIZE"];
        _firetsizecontroller.text = body["FT_SIZE"];
        _flushingsizecontroller.text = body["FLUSHING_TANK_SIZE"];
        _stpsizecontroller.text = body["STP_TANK_SIZE"];
        _etpsizecontroller.text = body["ETP_TANK_SIZE"];
        _selectedwtplacement = body["WT_PLACEMENT"];
        _noboringcontroller.text = body["NO_BORING"];
        // _reracontroller.text = body["RERA"];
        // _formkey.currentState?.validate();
      });
      // print("Pincode doesnt exists");
    }
  }

  @override
  void initState() {
    super.initState();
    getcustomerprojects();
    // _projects = [Project(pjc: "Add New", pname: "Add New", custtype: "")];
  }

  getcustomerprojects() async {
    var sharedpref = await SharedPreferences.getInstance();
    var ut = sharedpref.getString("UT");
    setState(() {
      _loginut = ut!;
    });
    if (ut!.toLowerCase() == "consumer" ||
        ut.toLowerCase() == "contractor" ||
        ut.toLowerCase() == "supplier) ") {
      List<Project> projects = await getcustprojects();
      setState(() {
        _projects = projects;
      });
    }
  }

  Future<List<Project>> getcustprojects() async {
    http.Response response;
    var sharedpref = await SharedPreferences.getInstance();
    var ut = sharedpref.getString("UT");
    var mob = sharedpref.getString("Mobile");
    if (ut!.toLowerCase() == "consumer" ||
        ut.toLowerCase() == "contractor" ||
        ut.toLowerCase() == "supplier") {
      response =
          await http.get(Uri.parse('$baseuri/api/custprojlist/?mob=$mob'));
    } else {
      response = await http.get(Uri.parse('$baseuri/api/pnamelist/'));
    }

    final body = json.decode(response.body);
    List<Project> projects = [];
    // projects.add(Project(pjc: "", pname: "Add New", custtype: ""));
    if (response.statusCode == 200) {
      for (var c in body) {
        // String name = c['PNAME'];
        // String ctype = c['CUSTTYPE'];
        projects.add(
            Project(pjc: c["PJC"], pname: c["PNAME"], custtype: c["CUSTTYPE"]));
      }
    }
    return projects;
    // setState(() {
    //   _projects = projects;
    // });
  }

  Future<void> _fetchprojectsAndOpenDropdown() async {
    // Fetch your data
    setState(() {
      _isprojLoading = true;
    });
    final fetchedProjects =
        await getprojects(searchterm: _searchcontroller.text);

    if (!mounted) return; // Always check if the widget is still in the tree

    setState(() {
      _projects = fetchedProjects;
      _selectedut = null;
      _existpjc = null;
      selectedItem = null;
      _namecontroller.clear();
      _ownermobilecontroller.clear();
      _add1controller.clear();
      _add2controller.clear();
      _pincontroller.clear();
      _selectedState = null;
      _citycontroller.clear();
      _selectedDistrict = null;
      _mobilecontroller.clear();
      _mobile2controller.clear();
      _emailcontroller.clear();
      _gstcontroller.clear();
      _reracontroller.clear();
      showTextField = false;
      _editmode = false;
      _isprojLoading = false;
      // Update the list
      // Hide loading indicator
    });

    // Check if the key and the current state are available, then open
    if (_projectkey.currentState != null) {
      // Use a post-frame callback to ensure the widget has been rebuilt
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _projectkey.currentState!.openDropDownSearch();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double swidth = MediaQuery.of(context).size.width;
    double sheight = MediaQuery.of(context).size.height;
    return Background(
        appbaractions: [
          TextButton(
              onPressed: () {
                setState(() {
                  _editmode = !_editmode;
                  if ((_editmode) & (selectedItem != null)) {
                    _pnamecontroller.text = selectedItem!.pname;
                    _formkey.currentState?.validate();
                  }
                });
              },
              child: const Text("Edit")),

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
        appbartitle: const Text("Site Information"),
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
                          if (!["consumer", "contractor", "supplier"]
                              .contains(_loginut.toLowerCase()))
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: InputField(
                                controller: _searchcontroller,
                                label: "Search Here",
                                suff: _isprojLoading
                                    ? const SizedBox(
                                        width:
                                            24, // Give it a fixed size to avoid layout shifts
                                        height: 24,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : IconButton(
                                        onPressed: () {
                                          _fetchprojectsAndOpenDropdown();
                                        },
                                        icon: const Icon(Icons.search)),
                              ),
                            ),
                          Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: DropdownSearch<Project>(
                                  key: _projectkey,
                                  // controller
                                  compareFn: (item1, item2) =>
                                      item1.pjc == item2.pjc,
                                  popupProps: PopupProps.dialog(
                                    dialogProps: DialogProps(
                                      barrierDismissible: true,
                                      barrierLabel: "Dismiss",
                                    ),
                                    // showSelectedItems: true,
                                    showSearchBox: true,
                                    searchFieldProps: TextFieldProps(
                                        decoration: const InputDecoration(
                                          labelText: "Search for an item*",
                                        ),
                                        controller: _projectsearchcontroller),
                                  ),
                                  // mode: Mode.dialog,
                                  // showSelectedItems: true,

                                  items: (filter, infiniteScrollProps) =>
                                      _projects,
                                  itemAsString: (item) {
                                    return "${item.pname} (${item.custtype})";
                                  },
                                  filterFn: (item, filter) {
                                    // This function determines which items are shown in the dropdown
                                    // based on the user's input (the 'filter' string).
                                    // It's case-insensitive for better UX.
                                    // print(
                                    //     'filterFn - item: "$item", filter: "$filter"');
                                    return item.pname == "Add New" ||
                                        item.custtype
                                            .toLowerCase()
                                            .contains(filter.toLowerCase()) ||
                                        item.pname
                                            .toLowerCase()
                                            .contains(filter.toLowerCase());
                                  },
                                  decoratorProps: const DropDownDecoratorProps(
                                    decoration: InputDecoration(
                                      labelText: "Project*",
                                      hintText: "Select a Project",
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select a project from the List or enter a new name"';
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
                                    if (data!.pname == "Add New") {
                                      setState(() {
                                        _pnamecontroller.text =
                                            _projectsearchcontroller.text;
                                        _selectedut = null;
                                        _existpjc = null;
                                        _namecontroller.clear();
                                        _ownermobilecontroller.clear();
                                        _add1controller.clear();
                                        _add2controller.clear();
                                        _pincontroller.clear();
                                        _selectedState = null;
                                        _citycontroller.clear();
                                        _selectedDistrict = null;
                                        _mobilecontroller.clear();
                                        _mobile2controller.clear();
                                        _emailcontroller.clear();
                                        _gstcontroller.clear();
                                        _reracontroller.clear();
                                        // showTextField = true;
                                        _editmode = true;
                                      });
                                    } else {
                                      setState(() {
                                        selectedItem = data;
                                        _selectedut = data.custtype;
                                      });
                                      getprojdetail(data);
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
                              child: FutureBuilder<List<String>>(
                                  future: getcomp(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData &&
                                        snapshot.data != null) {
                                      return DropdownSearch<String>(
                                        enabled: false,
                                        items: (filter, infiniteScrollProps) =>
                                            snapshot.data!,
                                        // itemAsString: (item) {
                                        //   return item.pname;
                                        // },
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
                                            return "Please select a Customer Type";
                                          }
                                          return null;
                                        },
                                        popupProps: PopupProps.dialog(
                                          dialogProps: DialogProps(
                                            barrierDismissible: true,
                                            barrierLabel: "Dismiss",
                                          ),
                                          itemBuilder: (context, item,
                                              isSelected, onTap) {
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
                                            _selectedut = data;
                                          });
                                          // getprojdetail(data);
                                        },
                                        selectedItem: _selectedut,
                                        decoratorProps:
                                            const DropDownDecoratorProps(
                                          decoration: InputDecoration(
                                            labelText: "Select an item",
                                          ),
                                        ),
                                      );
                                    } else {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }
                                  })),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: InputField(
                              readOnly: !_editmode,
                              label: "Architect Name",
                              controller: _namecontroller,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: InputField(
                              readOnly: !_editmode,
                              label: " Architect Mobile",
                              controller: _amobilecontroller,
                              keyboardtype: TextInputType.phone,
                              onChanged: (value) async {},
                              sufficon: !_editmode
                                  ? null
                                  : IconButton(
                                      onPressed: () async {
                                        Contact? contact = await _contactPicker
                                            .selectPhoneNumber();
                                        setState(() {
                                          _selectedPhoneNumber =
                                              contact?.selectedPhoneNumber;
                                          if (_selectedPhoneNumber != null) {
                                            var phno = _selectedPhoneNumber!
                                                .replaceAll(" ", "");
                                            _amobilecontroller.text = phno
                                                .substring(phno.length - 10);

                                            _selectedPhoneNumber = null;
                                          }
                                        });
                                      },
                                      icon: const Icon(Icons.contacts)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: InputField(
                              readOnly: !_editmode,

                              onChanged: (value) async {
                                // if ((value.length == 10) &&
                                //     (value != _existomob)) {
                                //   setState(() {
                                //     _verifyomob = true;
                                //   });
                              },

                              label: "Plumber Name",
                              controller: _ownermobilecontroller,
                              // keyboardtype: TextInputType.phone,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: InputField(
                              readOnly: !_editmode,
                              label: "Plumber Mobile",
                              controller: _pmobilecontroller,
                              keyboardtype: TextInputType.phone,
                              onChanged: (value) async {},
                              sufficon: !_editmode
                                  ? null
                                  : IconButton(
                                      onPressed: () async {
                                        Contact? contact = await _contactPicker
                                            .selectPhoneNumber();
                                        setState(() {
                                          _selectedPhoneNumber =
                                              contact?.selectedPhoneNumber;
                                          if (_selectedPhoneNumber != null) {
                                            var phno = _selectedPhoneNumber!
                                                .replaceAll(" ", "");
                                            _pmobilecontroller.text = phno
                                                .substring(phno.length - 10);

                                            _selectedPhoneNumber = null;
                                          }
                                        });
                                      },
                                      icon: const Icon(Icons.contacts)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: InputField(
                              readOnly: !_editmode,
                              label: "Electrician Name",
                              controller: _mobilecontroller,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: InputField(
                              readOnly: !_editmode,
                              label: "Electrician Mobile",
                              controller: _emobilecontroller,
                              keyboardtype: TextInputType.phone,
                              onChanged: (value) async {},
                              sufficon: !_editmode
                                  ? null
                                  : IconButton(
                                      onPressed: () async {
                                        Contact? contact = await _contactPicker
                                            .selectPhoneNumber();
                                        setState(() {
                                          _selectedPhoneNumber =
                                              contact?.selectedPhoneNumber;
                                          if (_selectedPhoneNumber != null) {
                                            var phno = _selectedPhoneNumber!
                                                .replaceAll(" ", "");
                                            _emobilecontroller.text = phno
                                                .substring(phno.length - 10);

                                            _selectedPhoneNumber = null;
                                          }
                                        });
                                      },
                                      icon: const Icon(Icons.contacts)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: InputField(
                              readOnly: !_editmode,
                              label: "Number of Rooms",
                              controller: _mobile2controller,
                              keyboardtype: TextInputType.number,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: InputField(
                              readOnly: !_editmode,
                              label: "Number of Bathrooms",
                              controller: _add1controller,
                              keyboardtype: TextInputType.number,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: InputField(
                              readOnly: !_editmode,
                              label: "Number of Kitchen",
                              keyboardtype: TextInputType.number,
                              controller: _add2controller,
                            ),
                          ),
                          if (selectedItem?.custtype == "Hotel")
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: InputField(
                                label: "Number of Restraunts",
                                controller: _citycontroller,
                                keyboardtype: TextInputType.number,
                                readOnly: !_editmode,
                              ),
                            ),
                          if (selectedItem?.custtype == "Hotel")
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: InputField(
                                readOnly: !_editmode,
                                label: "No of Banquet Hall",
                                controller: _pincontroller,
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
                          if (selectedItem?.custtype == "Hospital")
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: InputField(
                                readOnly: !_editmode,
                                label: "No of Cafeteria",
                                keyboardtype: TextInputType.number,
                                controller: _gstcontroller,
                              ),
                            ),
                          if (selectedItem?.custtype == "Hospital")
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: InputField(
                                readOnly: !_editmode,
                                label: "No of Operation Theatres",
                                keyboardtype: TextInputType.number,
                                controller: _otcontroller,
                              ),
                            ),
                          if (selectedItem?.custtype == "Hospital")
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: InputField(
                                readOnly: !_editmode,
                                label: "No of Beds (Total)",
                                keyboardtype: TextInputType.number,
                                controller: _bedscontroller,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: InputField(
                              readOnly: !_editmode,
                              label: "No of Floors (Including Basement)",
                              keyboardtype: TextInputType.number,
                              controller: _floorscontroller,
                            ),
                          ),
                          Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: DropdownSearch<int>(
                                enabled: _editmode,
                                items: (filter, infiniteScrollProps) =>
                                    [1, 2, 3, 4, 5, 6],
                                // itemAsString: (item) {
                                //   return item.pname;
                                // },
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

                                popupProps: PopupProps.dialog(
                                  dialogProps: DialogProps(
                                    barrierDismissible: true,
                                    barrierLabel: "Dismiss",
                                  ),
                                  itemBuilder:
                                      (context, item, isSelected, onTap) {
                                    return ListTile(
                                      title: Text('$item'),
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
                                    _selectednowt = data!;
                                  });
                                  // getprojdetail(data);
                                },
                                selectedItem: _selectednowt,
                                decoratorProps: const DropDownDecoratorProps(
                                  decoration: InputDecoration(
                                    labelText: "Number of water tanks",
                                  ),
                                ),
                              )),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: InputField(
                              readOnly: !_editmode,
                              label: "Raw water tank size (Litres)",
                              keyboardtype: TextInputType.number,
                              controller: _rwtsizecontroller,
                            ),
                          ),
                          if (_selectednowt > 1)
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: InputField(
                                readOnly: !_editmode,
                                label: "Soft water tank size (Litres)",
                                keyboardtype: TextInputType.number,
                                controller: _swtsizecontroller,
                              ),
                            ),
                          if (_selectednowt > 1)
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: InputField(
                                readOnly: !_editmode,
                                label: "Fire tank size (Litres)",
                                keyboardtype: TextInputType.number,
                                controller: _firetsizecontroller,
                              ),
                            ),
                          if (_selectednowt > 1)
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: InputField(
                                readOnly: !_editmode,
                                label:
                                    "Flushing (Treated Water) tank size (Litres)",
                                keyboardtype: TextInputType.number,
                                controller: _flushingsizecontroller,
                              ),
                            ),
                          if (_selectednowt > 1)
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: InputField(
                                readOnly: !_editmode,
                                label: "STP Collection tank size (Litres)",
                                keyboardtype: TextInputType.number,
                                controller: _stpsizecontroller,
                              ),
                            ),
                          if (_selectednowt > 1)
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: InputField(
                                readOnly: !_editmode,
                                label: "ETP Collection tank size (Litres)",
                                keyboardtype: TextInputType.number,
                                controller: _etpsizecontroller,
                              ),
                            ),
                          Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: DropdownSearch<String>(
                                enabled: _editmode,
                                items: (filter, infiniteScrollProps) => [
                                  "Under Groud",
                                  "Over Ground",
                                  "Over Head",
                                  "UGT + OHT Both"
                                ],
                                // itemAsString: (item) {
                                //   return item.pname;
                                // },
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

                                popupProps: PopupProps.dialog(
                                  dialogProps: DialogProps(
                                    barrierDismissible: true,
                                    barrierLabel: "Dismiss",
                                  ),
                                  itemBuilder:
                                      (context, item, isSelected, onTap) {
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
                                    _selectedwtplacement = data;
                                  });
                                  // getprojdetail(data);
                                },
                                selectedItem: _selectedwtplacement,
                                decoratorProps: const DropDownDecoratorProps(
                                  decoration: InputDecoration(
                                    labelText: "Water Tank Placement",
                                  ),
                                ),
                              )),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: InputField(
                              readOnly: !_editmode,
                              label: "No of Boring",
                              keyboardtype: TextInputType.number,
                              controller: _noboringcontroller,
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
                                        setState(() {
                                          _isLoading = true;
                                        });
                                        final Map<String, dynamic> data = {
                                          'PJC': _existpjc,
                                          // 'PNAME': _pnamecontroller.text,
                                          // 'CUSTTYPE': _selectedut,
                                          'ARCHITECT_NAME':
                                              _namecontroller.text,
                                          'AMOBILE': _amobilecontroller.text,
                                          'PLUMBER_NAME':
                                              _ownermobilecontroller.text,
                                          'PMOBILE': _pmobilecontroller.text,
                                          'NOB': _add1controller.text,
                                          'NOK': _add2controller.text,
                                          'NOBH': _pincontroller.text,
                                          // 'STATE': _selectedState,
                                          // 'DIST': _selectedDistrict,
                                          'NO_RESTRAUNTS': _citycontroller.text,
                                          'ELECTRICIAN_NAME':
                                              _mobilecontroller.text,
                                          'EMOBILE': _emobilecontroller.text,
                                          'NOR': _mobile2controller.text,
                                          // 'EMAIL': _emailcontroller.text,
                                          'NOC': _gstcontroller.text,
                                          'NO_OT': _otcontroller.text,
                                          'BEDS': _bedscontroller.text,
                                          'NOF': _floorscontroller.text,
                                          'NOWT': _selectednowt.toString(),
                                          'RWT_SIZE': _rwtsizecontroller.text,
                                          'SWT_SIZE': _swtsizecontroller.text,
                                          'FT_SIZE': _firetsizecontroller.text,
                                          'FLUSHING_TANK_SIZE':
                                              _flushingsizecontroller.text,
                                          'STP_TANK_SIZE':
                                              _stpsizecontroller.text,
                                          "ETP_TANK_SIZE":
                                              _etpsizecontroller.text,
                                          'WT_PLACEMENT': _selectedwtplacement,
                                          'NO_BORING': _noboringcontroller.text,
                                          // 'RERA': _reracontroller.text,
                                        };
                                        final resp = await http.patch(
                                            Uri.parse(
                                                '$baseuri/api/projectdetail/$_existpjc/'),
                                            body: data);
                                        if (resp.statusCode == 200 ||
                                            resp.statusCode == 201) {
                                          setState(() {
                                            _isLoading = false;
                                          });
                                          // if (widget.fromUserReg == true) {
                                          //   Navigator.pop(context);
                                          //   // context.pop();
                                          // }
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
                                                  backgroundColor: Colors.red));
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

  Future<String?> openDialog(title, lablel) => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: InputField(label: lablel, controller: _emailotpcontroller),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(_emailotpcontroller.text);
                },
                child: const Text("SUBMIT"))
          ],
        ),
      );

  Future<Project?> checkmobDialog(mob, sheight) async {
    final Project? selectedProject = await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(builder: (context, searchstate) {
              return AlertDialog(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Search Projects"),
                    IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close))
                  ],
                ),
                // actions: [
                //   IconButton(
                //       onPressed: () {
                //         Navigator.of(context).pop();
                //       },
                //       icon: const Icon(Icons.close))
                // ],
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                        "This Mobile Number $mob is already associated with the following projects"),
                    const SizedBox(
                      height: 10,
                    ),
                    FutureBuilder<List<Project>>(
                      future: _mobsearchedProj,
                      builder: (context, snapshot) {
                        // 1. Check Connection State
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          // 2. Check for Errors
                          return Text('Error: ${snapshot.error}');
                        } else if (snapshot.hasData) {
                          // 3. Data is Available - Now check for null/emptiness of the List
                          final List<Project>? dataList = snapshot.data;
                          if (kDebugMode) {
                            print(dataList);
                          }
                          if (dataList == null || dataList.isEmpty) {
                            return const Text(
                                'List is null or empty. Displaying no data message.');
                          } else {
                            // List has data, display it
                            return SizedBox(
                              width: 400,
                              height: sheight * 0.2,
                              child: ListView.builder(
                                itemCount: dataList.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    title: Text(
                                        "${dataList[index].pname} (${dataList[index].custtype})"),
                                    onTap: () {
                                      // setState(() {
                                      //   selectedItem = dataList[index];
                                      // });
                                      // getprojdetail(dataList[index]);
                                      Navigator.of(context)
                                          .pop(dataList[index]);
                                    },
                                  );
                                },
                              ),
                            );
                          }
                        } else {
                          // This case is typically reached if snapshot.hasData is false,
                          // but there's no error and not waiting. Could be no data yet.
                          return const Text('No data available.');
                        }
                      },
                    ),
                  ],
                ),
              );
            }));
    return selectedProject;
  }

  void fetchuseradd(String mob) async {
    final response =
        await http.get(Uri.parse('$baseuri/api/useraddressdetail/?mob=$mob'));
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      // print(body[0]);
      if (body.length > 0 && mounted) {
        setState(() {
          _add1controller.text = body[0]["ADD1"];
          _add2controller.text = body[0]["ADD2"];
          _pincontroller.text = body[0]["PIN"];
          _selectedState = body[0]["STATE"];
          _citycontroller.text = body[0]["CITY"];
          _selectedDistrict = body[0]["DIST"];
          // _formkey.currentState?.validate();
        });
        // print("Pincode doesnt exists");
      }
    }
  }
}
