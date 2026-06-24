// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/foundation.dart';
import "package:flutter/material.dart";
// import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:business_app/models/utils.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:business_app/widgets/background.dart';
import 'package:business_app/widgets/input_field.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
// import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import "package:business_app/constants.dart";
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class ProjectRegistration extends StatefulWidget {
  final bool? fromUserReg;
  const ProjectRegistration({super.key, this.fromUserReg = false});

  @override
  State<ProjectRegistration> createState() => _ProjectRegistrationState();
}

class _ProjectRegistrationState extends State<ProjectRegistration> {
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
  bool _verifyEmail = false;
  bool _isVerifiedEmail = false;
  String? _existemail;
  bool _newEmail = false;
  bool _verifyomob = false;
  bool _isVerifiedomob = false;
  String? _existomob;
  final _emailotpcontroller = TextEditingController();
  static const platform = MethodChannel('com.example.myapp/otp');
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
    final response = await http.get(Uri.parse('$baseuri/api/districts/?state=$_selectedState'));
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
        _namecontroller.text = body["CONTP"];
        _ownermobilecontroller.text = body["OMOBILE"];
        _existomob = body["OMOBILE"];
        _add1controller.text = body["ADD1"];
        _add2controller.text = body["ADD2"];
        _pincontroller.text = body["PIN"];
        _selectedState = body["STATE"];
        _citycontroller.text = body["CITY"];
        _selectedDistrict = body["DIST"];
        _mobilecontroller.text = body["MOBILE1"];
        _mobile2controller.text = body["MOBILE2"];
        _emailcontroller.text = body["EMAIL"];
        _existemail = body["EMAIL"];
        _gstcontroller.text = body["GSTN"];
        _reracontroller.text = body["RERA"];
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
    if (ut!.toLowerCase() == "consumer" || ut.toLowerCase() == "contractor" || ut.toLowerCase() == "supplier) ") {
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
    if (ut!.toLowerCase() == "consumer" || ut.toLowerCase() == "contractor" || ut.toLowerCase() == "supplier") {
      response =
          await http.get(Uri.parse('$baseuri/api/custprojlist/?mob=$mob'));
    } else {
      response = await http.get(Uri.parse('$baseuri/api/pnamelist/'));
    }

    final body = json.decode(response.body);
    List<Project> projects = [];
    projects.add(Project(pjc: "", pname: "Add New", custtype: ""));
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
          IconButton(
              onPressed: () {
                setState(() {
                  _editmode = !_editmode;
                  if ((_editmode) & (selectedItem != null)) {
                    _pnamecontroller.text = selectedItem!.pname;
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
                            "Delete ${selectedItem!.pname} (${selectedItem!.custtype})",
                        onCancelBtnTap: () {
                          Navigator.of(context).pop();
                        },
                        onConfirmBtnTap: () async {
                          Navigator.of(context).pop();
                          final response = await http.delete(Uri.parse(
                              '$baseuri/api/projectdetail/${selectedItem!.pjc}/'));
                          if (response.statusCode.toString().startsWith("2")) {
                            QuickAlert.show(
                                context: context,
                                type: QuickAlertType.success,
                                text:
                                    "Successfully Deleted Project ${selectedItem!.pname} (${selectedItem!.custtype})");
                            setState(() {
                              _projects = [
                                Project(
                                    pjc: "Add New",
                                    pname: "Add New",
                                    custtype: "")
                              ];
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
                            });
                          } else {
                            if (kDebugMode) {
                              print(response.headers["location"]);
                            }
                            QuickAlert.show(
                                context: context,
                                type: QuickAlertType.error,
                                text:
                                    "Couldnot Delete Project ${selectedItem!.pname} (${selectedItem!.custtype})");
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
        appbartitle: const Text("Project Registration"),
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
                              child: showTextField || _editmode
                                  ? InputField(
                                      // autofocus: true,
                                      controller: _pnamecontroller,
                                      label: "Project Name*",
                                      onChanged: (value) {
                                        setState(() {
                                          if (value.isEmpty) {
                                            showTextField = false;
                                          }
                                        });
                                      },
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return "Please give a Project Name";
                                        }
                                        return null;
                                      },
                                    )
                                  : DropdownSearch<Project>(
                                      key: _projectkey,
                                      // controller
                                      compareFn: (item1, item2) => item1.pjc == item2.pjc,
                                      popupProps: PopupProps.dialog(
                                        dialogProps: DialogProps(barrierDismissible: true,),
                                        // showSelectedItems: true,
                                        showSearchBox: true,
                                        searchFieldProps: TextFieldProps(
                                            decoration: const InputDecoration(
                                              labelText: "Search for an item*",
                                            ),
                                            controller:
                                                _projectsearchcontroller),
                                      ),
                                      // mode: Mode.dialog,
                                      // showSelectedItems: true,

                                      items: (filter, infiniteScrollProps) => _projects,
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
                                                .contains(
                                                    filter.toLowerCase()) ||
                                            item.pname
                                                .toLowerCase()
                                                .contains(filter.toLowerCase());
                                      },
                                      decoratorProps:
                                          const DropDownDecoratorProps(
                                        decoration:
                                            InputDecoration(
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
                                            showTextField = true;
                                            _editmode = true;
                                          });
                                        } else {
                                          setState(() {
                                            selectedItem = data;
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
                                        enabled: _editmode,
                                        items: (filter, infiniteScrollProps) => snapshot.data!,
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
                                          dialogProps: DialogProps(barrierDismissible: true,),
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
                                            _selectedut = data;
                                          });
                                          // getprojdetail(data);
                                        },
                                        selectedItem: _selectedut,
                                        decoratorProps:
                                            const DropDownDecoratorProps(
                                          decoration:
                                              InputDecoration(
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
                              child: _existpjc == null
                                  ? const Text("")
                                  : Text("Code- $_existpjc")),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: InputField(
                              readOnly: !_editmode,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return "Owner Name is required";
                                }
                                // if (value.length != 10) {
                                //   return "Please enter 10-digit mobile number";
                                // }

                                return null;
                              },
                              label: "Owner Name*",
                              controller: _namecontroller,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: InputField(
                              readOnly: !_editmode,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return "Owner Whatsapp number is required";
                                }
                                if (value.isNotEmpty && value.length != 10) {
                                  return "Please enter a 10-digit mobile number";
                                }
                                // if (value.length == 10 &&
                                //     !_isVerifiedomob &&
                                //     value != _existomob) {
                                //   return "Please verify mobile number";
                                // }
                                return null;
                              },
                              onChanged: (value) async {
                                // if ((value.length == 10) &&
                                //     (value != _existomob)) {
                                //   setState(() {
                                //     _verifyomob = true;
                                //   });
                                // }
                                if (value.length == 10) {
                                  setState(() {
                                    _mobsearchedProj =
                                        getprojects(searchterm: value);
                                  });
                                  List<Project> prj = await _mobsearchedProj!;
                                  prj.removeWhere((p) =>
                                      p.pname == "Add New" ||
                                      p.pjc == _existpjc);
                                  // print("prj list $prj");
                                  if (prj.isNotEmpty) {
                                    var result =
                                        await checkmobDialog(value, sheight);
                                    if (result != null) {
                                      setState(() {
                                        selectedItem = result;
                                        _pnamecontroller.text = result.pname;
                                      });
                                      getprojdetail(result);
                                    }
                                  } else {
                                    // print(_existpjc);
                                    if (_existpjc == null) {
                                      fetchuseradd(value);
                                    }
                                  }
                                }
                                if (value == _existomob) {
                                  setState(() {
                                    _verifyomob = false;
                                    _isVerifiedomob = true;
                                  });
                                }
                              },
                              suff: _verifyomob
                                  ? TextButton(
                                      onPressed: () async {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text(
                                                    "OTP sent on Whatsapp"),
                                                backgroundColor: Colors.green));
                                        final res = await http.post(
                                            Uri.parse(
                                                '$baseuri/api/send_otp_verify/'),
                                            body: {
                                              "send_to":
                                                  _ownermobilecontroller.text
                                            });
                                        if (res.statusCode == 200) {
                                          _emailotpcontroller.clear();
                                          final otp = await openDialog(
                                              "Verify Mobile",
                                              "Emter OTP from Whatsapp");
                                          final resver = await http.post(
                                              Uri.parse(
                                                  '$baseuri/api/validate_otp_email_omob/'),
                                              body: {
                                                "phone_num":
                                                    _ownermobilecontroller.text,
                                                "otp": otp ?? ''
                                              });
                                          if (resver.statusCode == 200) {
                                            setState(() {
                                              _isVerifiedomob = true;
                                              _verifyomob = false;
                                            });
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        "Mobile Number Verified Successfully"),
                                                    backgroundColor:
                                                        Colors.green));
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        "Mobile Number couldnot be verified. Please try again."),
                                                    backgroundColor:
                                                        Colors.red));
                                          }
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      "OTP couldnot be sent. Please try again."),
                                                  backgroundColor: Colors.red));
                                        }
                                      },
                                      child: const Text("Verify"))
                                  : null,
                              label: "Owner Mobile Number (Whatsapp)*",
                              controller: _ownermobilecontroller,
                              keyboardtype: TextInputType.phone,
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
                                            _ownermobilecontroller.text = phno
                                                .substring(phno.length - 10);
                                            _selectedPhoneNumber = null;
                                          }
                                        });
                                        if (_ownermobilecontroller
                                                .text.length ==
                                            10) {
                                          setState(() {
                                            _mobsearchedProj = getprojects(
                                                searchterm:
                                                    _ownermobilecontroller.text);
                                          });
                                          List<Project>? prj =
                                              await _mobsearchedProj;
                                          prj!.removeWhere((p) =>
                                              p.pname == "Add New" ||
                                              p.pjc == _existpjc);
                                          if (prj.isNotEmpty) {
                                            var result = await checkmobDialog(
                                                _ownermobilecontroller.text,
                                                sheight);
                                            if (result != null) {
                                              setState(() {
                                                selectedItem = result;
                                                _pnamecontroller.text =
                                                    result.pname;
                                              });
                                              getprojdetail(result);
                                            }
                                          } else {
                                            if (_existpjc == null) {
                                              fetchuseradd(
                                                  _ownermobilecontroller.text);
                                            }
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.contacts)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: InputField(
                              readOnly: !_editmode,
                              label: " Manager Mobile",
                              controller: _mobilecontroller,
                              keyboardtype: TextInputType.phone,
                              onChanged: (value) async {
                                if (value.length == 10) {
                                  setState(() {
                                    _mobsearchedProj =
                                        getprojects(searchterm: value);
                                  });
                                  List<Project> prj = await _mobsearchedProj!;
                                  prj.removeWhere((p) =>
                                      p.pname == "Add New" ||
                                      p.pjc == _existpjc);
                                  if (prj.isNotEmpty) {
                                    var result =
                                        await checkmobDialog(value, sheight);
                                    if (result != null) {
                                      setState(() {
                                        selectedItem = result;
                                        _pnamecontroller.text = result.pname;
                                      });
                                      getprojdetail(result);
                                    }
                                  }
                                }
                              },
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
                                            _mobilecontroller.text = phno
                                                .substring(phno.length - 10);

                                            _selectedPhoneNumber = null;
                                          }
                                        });
                                        if (_mobilecontroller.text.length ==
                                            10) {
                                          setState(() {
                                            _mobsearchedProj = getprojects(
                                                searchterm:
                                                    _mobilecontroller.text);
                                          });
                                          List<Project>? prj =
                                              await _mobsearchedProj;
                                          prj!.removeWhere((p) =>
                                              p.pname == "Add New" ||
                                              p.pjc == _existpjc);
                                          if (prj.isNotEmpty) {
                                            var result = await checkmobDialog(
                                                _mobilecontroller.text,
                                                sheight);
                                            if (result != null) {
                                              setState(() {
                                                selectedItem = result;
                                                _pnamecontroller.text =
                                                    result.pname;
                                              });
                                              getprojdetail(result);
                                            }
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.contacts)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: InputField(
                              readOnly: !_editmode,
                              label: " Staff Mobile",
                              controller: _mobile2controller,
                              keyboardtype: TextInputType.phone,
                              onChanged: (value) async {
                                if (value.length == 10) {
                                  setState(() {
                                    _mobsearchedProj =
                                        getprojects(searchterm: value);
                                  });
                                  List<Project> prj = await _mobsearchedProj!;
                                  prj.removeWhere((p) =>
                                      p.pname == "Add New" ||
                                      p.pjc == _existpjc);
                                  if (prj.isNotEmpty) {
                                    var result =
                                        await checkmobDialog(value, sheight);
                                    if (result != null) {
                                      setState(() {
                                        selectedItem = result;
                                        _pnamecontroller.text = result.pname;
                                      });
                                      getprojdetail(result);
                                    }
                                  }
                                }
                              },
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
                                            _mobile2controller.text = phno
                                                .substring(phno.length - 10);
                                            _selectedPhoneNumber = null;
                                          }
                                        });
                                        if (_mobilecontroller.text.length ==
                                            10) {
                                          setState(() {
                                            _mobsearchedProj = getprojects(
                                                searchterm:
                                                    _mobilecontroller.text);
                                          });
                                          List<Project>? prj =
                                              await _mobsearchedProj;
                                          prj!.removeWhere((p) =>
                                              p.pname == "Add New" ||
                                              p.pjc == _existpjc);
                                          if (prj.isNotEmpty) {
                                            var result = await checkmobDialog(
                                                _mobilecontroller.text,
                                                sheight);
                                            if (result != null) {
                                              setState(() {
                                                selectedItem = result;
                                                _pnamecontroller.text =
                                                    result.pname;
                                              });
                                              getprojdetail(result);
                                            }
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.contacts)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: InputField(
                              readOnly: !_editmode,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return "Address 1 is required";
                                }
                                return null;
                              },
                              label: "Address Line 1*",
                              controller: _add1controller,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: InputField(
                              readOnly: !_editmode,
                              label: "Adress Line 2",
                              controller: _add2controller,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: FutureBuilder<List<String>>(
                                future: getStates(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData &&
                                      snapshot.data != null) {
                                    return DropdownSearch<String>(
                                      enabled: _editmode,
                                      items: (filter, infiniteScrollProps) => snapshot.data!,
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
                                          return "Please select a State";
                                        }
                                        return null;
                                      },
                                      popupProps: PopupProps.dialog(
                                        dialogProps: DialogProps(barrierDismissible: true,),
                                        itemBuilder:
                                            (context, item, isSelected, onTap) {
                                          return ListTile(
                                            title: Text(item),
                                          );
                                        },
                                        showSearchBox: true,
                                      ),
                                      onSelected: (data) {
                                        setState(() {
                                          _districts.clear();
                                          _selectedState = data;
                                          getDistricts();
                                        });
                                        // getprojdetail(data);
                                      },
                                      selectedItem: _selectedState,
                                      decoratorProps:
                                          const DropDownDecoratorProps(
                                        decoration:
                                            InputDecoration(
                                          labelText: "Select a State",
                                        ),
                                      ),
                                    );
                                  } else {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }
                                }),
                          ),
                          Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: DropdownSearch<String>(
                                validator: (value) {
                                  if (value == null) {
                                    return "Please select a District";
                                  }
                                  return null;
                                },
                                enabled: _editmode,
                                popupProps: const PopupProps.dialog(
                                    dialogProps: DialogProps(barrierDismissible: true,),
                                    showSelectedItems: true,
                                    showSearchBox: true),
                                // mode: Mode.dialog,
                                // showSelectedItems: true,
                                items: (filter, infiniteScrollProps) => _districts,
                                decoratorProps:
                                    const DropDownDecoratorProps(
                                  decoration: InputDecoration(
                                    labelText: "District*",
                                    hintText: "Select a District",
                                  ),
                                ),

                                onSelected: (value) {
                                  setState(() {
                                    // _company.clear();
                                    _selectedDistrict = value;
                                    _citycontroller.text = _selectedDistrict!;
                                    // getcomp();
                                  });
                                },
                                selectedItem: _selectedDistrict,
                              )),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: InputField(
                              label: "City",
                              controller: _citycontroller,
                              readOnly: !_editmode,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: InputField(
                              readOnly: !_editmode,
                              label: "Pin Code",
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
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: InputField(
                              readOnly: !_editmode,
                              label: "Email",
                              controller: _emailcontroller,
                              keyboardtype: TextInputType.emailAddress,
                              suff: (_verifyEmail && _newEmail)
                                  ? TextButton(
                                      onPressed: () async {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content:
                                                    Text("OTP sent on Mail"),
                                                backgroundColor: Colors.green));
                                        final res = await http.post(
                                            Uri.parse(
                                                '$baseuri/api/send_otp_verify/'),
                                            body: {
                                              "send_to": _emailcontroller.text
                                            });
                                        if (res.statusCode == 200) {
                                          _emailotpcontroller.clear();
                                          final otp = await openDialog(
                                              "Verify Email",
                                              "Enter OTP from Mail");
                                          final resver = await http.post(
                                              Uri.parse(
                                                  '$baseuri/api/validate_otp_email_omob/'),
                                              body: {
                                                "phone_num":
                                                    _emailcontroller.text,
                                                "otp": otp ?? ''
                                              });
                                          if (resver.statusCode == 200) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        "Email Verified Successfully"),
                                                    backgroundColor:
                                                        Colors.green));
                                            setState(() {
                                              _isVerifiedEmail = true;
                                              _verifyEmail = false;
                                              _newEmail = false;
                                            });
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        "Email couldnot be verified. Please try again."),
                                                    backgroundColor:
                                                        Colors.red));
                                          }
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      "OTP couldnot be sent. Please try again."),
                                                  backgroundColor: Colors.red));
                                        }
                                      },
                                      child: const Text("Verify Email"))
                                  : null,
                              validator: (value) {
                                if (!_checkEmailFn(value!) &&
                                    value.isNotEmpty) {
                                  return 'Please enter a valid Email or Blank';
                                }
                                if (_verifyEmail &&
                                    !_isVerifiedEmail &&
                                    !_newEmail) {
                                  return 'Please Verify Email';
                                }
                                if (value.isEmpty) {
                                  return null;
                                }
                                return null;
                              },
                              onChanged: (value) {
                                setState(() {
                                  _verifyEmail = _checkEmailFn(value);
                                  _isVerifiedEmail = false;
                                  if (_verifyEmail) {
                                    _isVerifiedEmail = false;
                                  }
                                  if (value.isEmpty) {
                                    _verifyEmail = false;
                                  }
                                  if (value != _existemail) {
                                    _newEmail = true;
                                  } else {
                                    _verifyEmail = false;
                                  }
                                });
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: InputField(
                              readOnly: !_editmode,
                              label: "GST Number",
                              controller: _gstcontroller,
                            ),
                          ),
                          if (_selectedut == "Builder")
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: InputField(
                                readOnly: !_editmode,
                                label: "RERA Number",
                                controller: _reracontroller,
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
                                        if (_existpjc != null) {
                                          setState(() {
                                            _isLoading = true;
                                          });
                                          final Map<String, dynamic> data = {
                                            'PJC': _existpjc,
                                            'PNAME': _pnamecontroller.text,
                                            'CUSTTYPE': _selectedut,
                                            'CONTP': _namecontroller.text,
                                            'OMOBILE':
                                                _ownermobilecontroller.text,
                                            'ADD1': _add1controller.text,
                                            'ADD2': _add2controller.text,
                                            'PIN': _pincontroller.text,
                                            'STATE': _selectedState,
                                            'DIST': _selectedDistrict,
                                            'CITY': _citycontroller.text,
                                            'MOBILE1': _mobilecontroller.text,
                                            'MOBILE2': _mobile2controller.text,
                                            'EMAIL': _emailcontroller.text,
                                            'GSTN': _gstcontroller.text,
                                            'RERA': _reracontroller.text,
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
                                            if (widget.fromUserReg == true) {
                                              Navigator.pop(context);
                                              // context.pop();
                                            }
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
                                            'PNAME': _pnamecontroller.text,
                                            'CUSTTYPE': _selectedut,
                                            'CONTP': _namecontroller.text,
                                            'OMOBILE':
                                                _ownermobilecontroller.text,
                                            'ADD1': _add1controller.text,
                                            'ADD2': _add2controller.text,
                                            'PIN': _pincontroller.text,
                                            'STATE': _selectedState,
                                            'DIST': _selectedDistrict,
                                            'CITY': _citycontroller.text,
                                            'MOBILE1': _mobilecontroller.text,
                                            'MOBILE2': _mobile2controller.text,
                                            'EMAIL': _emailcontroller.text,
                                            'GSTN': _gstcontroller.text,
                                            'RERA': _reracontroller.text,
                                            'CREATEDBY_MOB': loggedinmob
                                          };
                                          final resp = await http.post(
                                              Uri.parse(
                                                  '$baseuri/api/project/'),
                                              body: data);
                                          if (resp.statusCode == 200 ||
                                              resp.statusCode == 201) {
                                            setState(() {
                                              _isLoading = false;
                                            });
                                            final body = json.decode(resp.body);
                                            await QuickAlert.show(
                                                context: context,
                                                type: QuickAlertType.info,
                                                text: "Code-${body["Code"]}");
                                            if (widget.fromUserReg == true) {
                                              Navigator.pop(context);
                                              // context.pop();
                                            }
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
