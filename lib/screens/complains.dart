import 'dart:convert';

import 'package:business_app/constants.dart';
import 'package:business_app/models/utils.dart';
import 'package:business_app/screens/project_registration.dart';
// import 'package:business_app/services/send_notification_service.dart';
import 'package:business_app/widgets/background.dart';
import 'package:business_app/widgets/input_field.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
// Removed go_router import
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Complain extends StatefulWidget {
  const Complain({super.key});

  @override
  State<Complain> createState() => _ComplainState();
}

class _ComplainState extends State<Complain> {
  final _meetingdatetimecontroller = TextEditingController();
  final _msgcontroller = TextEditingController();
  final _mobilecontroller = TextEditingController();
  String? _selectedproduct;
  LeadProduct? _selectedcomp;
  String? _selectedut;
  Project? _selectedproject;
  String? _selectedcategory;
  String? _selectedleadton;
  bool _isLoading = false;
  bool _allowAssign = false;
  final bool _isenabled = true;
  List<LeadProduct> _company = [];
  late Future<List<Project>> _projects;
  List<String> _products = [];
  String? _selectedPhoneNumber;
  final _formkey = GlobalKey<FormState>();
  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();

  Future<List<Project>> getprojects() async {
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

  Future<void> getproduct() async {
    final response = await http.get(
        Uri.parse('$baseuri/api/leadforp/?project=${_selectedproject!.pjc}'));
    final body = json.decode(response.body);
    Set<String> product = {};
    if (response.statusCode == 200) {
      for (var c in body) {
        product.add(c["PRODUCT_TYPE"]);
      }
    }
    setState(() {
      _products = product.toList();
    });
  }

  Future<void> getcomp() async {
    // String queryparam = _selectedproduct.map((item) => "ut1=$item").join("&");
    List<String> queryparams = [];
    queryparams.add("$_selectedproduct");
    final response = await http
        .post(Uri.parse('$baseuri/api/leadforc/'), body: jsonEncode({
          
          "ut1": queryparams
        }), headers: {"Content-Type": "application/json"});
    final body = json.decode(response.body);
    List<LeadProduct> comp = [];
    if (response.statusCode == 200) {
      for (var c in body) {
        comp.add(
            LeadProduct(company: c['CO_NAME'], product: c['PRODUCT_TYPE']));
      }
    }
    setState(() {
      _company = comp;
    });
  }

  Future submitdata(String sendmsg) async {
    setState(() {
      _isLoading = true;
    });
    var sharedpref = await SharedPreferences.getInstance();
    var username = sharedpref.getString('NAME');
    // final List<Map<String, dynamic>> comp =
    //     _selectedcomp.map((item) => item.toJson()).toList();
    final Map<String, dynamic> data = {
      'LEADBYN': username,
      'CURRENT_MOB': sharedpref.getString('Mobile'),
      // "CUSTTYPE": _selectedproject!.custtype,
      'PJC': _selectedproject!.pjc,
      // 'PNAME': _selectedproject!.pname,
      'LEADFORP': _selectedproduct,
      'LEADFORC': _selectedcomp!.company,
      'LEAD_DATE': DateTime.now().toString().split(" ")[0],
      'MEETING_DATETIME': _meetingdatetimecontroller.text,
      'LEADTON': _selectedleadton ?? "",
      'OPEN': 'Y',
      "LEAD_TYPE": "COMPLAIN",
      'COMPLAIN_CATEGORY': _selectedcategory,
      'COMPLAIN_MOB': _mobilecontroller.text,
      "MESSAGE": _msgcontroller.text,
      "SEND_MSG": sendmsg
    };
    final resp = await http.post(Uri.parse('$baseuri/api/complain/'),
        body: jsonEncode(data), headers: {"Content-Type": "application/json"});
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text("Data saved successfully"),
          backgroundColor: Colors.green[400]));
      // if (kDebugMode) {
      //   SendNotificationService.sendNotificationUsingApi(
      //       token: "test",
      //       title: "New Complain",
      //       body:
      //           "Party: ${_selectedproject!.pname}\nProduct: $_selectedproduct}",
      //       data: {"screen": "leads"});
      // } else {
      //   SendNotificationService.sendNotificationUsingApi(
      //       token: "all",
      //       title: "New Complain",
      //       body:
      //           "Party: ${_selectedproject!.pname}\nProduct: $_selectedproduct",
      //       data: {"screen": "leads"});
      // }
      setState(() {
        _selectedut = null;
        _selectedproject = null;
        _selectedproduct = null;
        _selectedcomp = null;
        // _selectedleadton = null;
        _meetingdatetimecontroller.clear();
        _msgcontroller.clear();
      });
      Navigator.of(context).pop();
      // context.pop();
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Something went wrong. Please try again."),
          backgroundColor: Colors.red));
    }
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

  getloginut() async {
    var sharedpref = await SharedPreferences.getInstance();
    var ut = sharedpref.getString('UT');
    if (ut == "ADMIN" || ut == "Employee") {
      setState(() {
        _allowAssign = true;
      });
    }
  }

  @override
  void initState() {
  
    super.initState();
    _projects = getprojects();
    getloginut();
  }

  @override
  Widget build(BuildContext context) {
    double swidth = MediaQuery.of(context).size.width;
    return Background(
      appbar: true,
      appbartitle: const Text("New Complain"),
      appbaractions: const [],
      childs: Center(
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
                          child: FutureBuilder<List<Project>>(
                              future: _projects,
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
                                  return DropdownSearch<Project>(
                                    enabled: _isenabled,
                                    compareFn: (item1, item2) => item1.pjc == item2.pjc,
                                    popupProps: const PopupProps.dialog(
                                        // showSelectedItems: true,
                                        showSearchBox: true),
                                    filterFn: (item, filter) {
                                      return item.pname == "Add New" ||
                                          item.pname
                                              .toLowerCase()
                                              .contains(filter.toLowerCase()) ||
                                          item.custtype
                                              .toLowerCase()
                                              .contains(filter.toLowerCase());
                                    },
                                    // filterFn: (item, filter) {
                                    //   return item == "Add New" ||
                                    //       item
                                    //           .toLowerCase()
                                    //           .contains(filter.toLowerCase());
                                    // },
                                    // mode: Mode.dialog,
                                    // showSelectedItems: true,
                                    items: (filter, infiniteScrollProps) => snapshot.data!,
                                    itemAsString: (item) {
                                      if (item.pname == "Add New") {
                                        return item.pname;
                                      } else {
                                        return "${item.pname} (${item.custtype})";
                                      }
                                    },
                                    decoratorProps:
                                        const DropDownDecoratorProps(
                                      decoration: InputDecoration(
                                        labelText: "Project*",
                                        hintText: "Select a Project",
                                      ),
                                    ),
                                    // dropdownSearchDecoration: const InputDecoration(
                                    // labelText: "Menu mode",
                                    // hintText: "country in menu mode",
                                    // ),
                                    // popupItemDisabled: isItemDisabled,
                                    onSelected: (value) async {
                                      setState(() {
                                        // _projects.clear();
                                        _selectedproject = value;
                                        _selectedut =
                                            _selectedproject!.custtype;
                                        getproduct();
                                      });
                                      if (value!.pname == "Add New") {
                                        final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const ProjectRegistration(),
                                            ));
                                        // final result = await context
                                        //     .go('/project_registration');
                                        if (result == true) {
                                          setState(() {
                                            // _projects.clear();
                                            _projects = getprojects();
                                          });
                                        }
                                      }
                                    },
                                    selectedItem: _selectedproject,
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
                      // Padding(
                      //     padding: const EdgeInsets.all(5.0),
                      //     child: DropdownSearch<String>(
                      //       enabled: _isenabled,
                      //       popupProps: const PopupProps.dialog(
                      //           showSelectedItems: true, showSearchBox: true),
                      //       filterFn: (item, filter) {
                      //         return item == "Add New" ||
                      //             item
                      //                 .toLowerCase()
                      //                 .contains(filter.toLowerCase());
                      //       },
                      //       // mode: Mode.dialog,
                      //       // showSelectedItems: true,
                      //       items: _projects,
                      //       dropdownDecoratorProps:
                      //           const DropDownDecoratorProps(
                      //         dropdownSearchDecoration: InputDecoration(
                      //           labelText: "Project",
                      //           hintText: "Select a Project",
                      //         ),
                      //       ),
                      //       // dropdownSearchDecoration: const InputDecoration(
                      //       // labelText: "Menu mode",
                      //       // hintText: "country in menu mode",
                      //       // ),
                      //       // popupItemDisabled: isItemDisabled,
                      //       onChanged: (value) async {
                      //         if (value == "Add New") {
                      //           final result = await Navigator.push(
                      //               context,
                      //               MaterialPageRoute(
                      //                 builder: (context) =>
                      //                     const ProjectRegistration(),
                      //               ));
                      //           if (result) {
                      //             setState(() {
                      //               _projects.clear();
                      //               getprojects();
                      //             });
                      //           }
                      //         }
                      //         setState(() {
                      //           _products.clear();
                      //           _selectedproject = value;
                      //           getproduct();
                      //         });
                      //       },
                      //       selectedItem: _selectedproject,
                      //       // showSearchBox: true,
                      //       // searchFieldProps: TextFieldProps(
                      //       //   cursorColor: Colors.blue,
                      //       // ),
                      //     )),
                      Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: DropdownSearch<String>(
                            enabled: _isenabled,
                            popupProps: const PopupProps.dialog(
                                showSelectedItems: true, showSearchBox: true),
                            // mode: Mode.dialog,
                            // showSelectedItems: true,
                            items: (filter, infiniteScrollProps) => _products,
                            decoratorProps:
                                const DropDownDecoratorProps(
                              decoration: InputDecoration(
                                labelText: "Product",
                                hintText: "Select a Product",
                              ),
                            ),

                            onSelected: (value) {
                              setState(() {
                                _company.clear();
                                _selectedproduct = value;
                                getcomp();
                              });
                            },
                            selectedItem: _selectedproduct,
                          )),
                      Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: DropdownSearch<LeadProduct>(
                            compareFn: (item1, item2) =>
                                item1.company == item2.company &&
                                item1.product == item2.product,
                            enabled: _isenabled,
                            popupProps: const PopupProps.dialog(
                                // showSelectedItems: true,
                                showSearchBox: true),
                            // mode: Mode.dialog,
                            // showSelectedItems: true,
                            items: (filter, infiniteScrollProps) => _company,
                            itemAsString: (item) {
                              return "${item.company} (${item.product})";
                            },
                            decoratorProps:
                                const DropDownDecoratorProps(
                              decoration: InputDecoration(
                                labelText: "Company",
                                hintText: "Select a Company",
                              ),
                            ),

                            onSelected: (value) {
                              setState(() {
                                _selectedcomp = value;
                              });
                            },
                            selectedItem: _selectedcomp,
                          )),
                      if (_allowAssign)
                        Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: FutureBuilder<List<String>>(
                                future: getnames(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData &&
                                      snapshot.data != null) {
                                    return DropdownSearch<String>(
                                      popupProps: const PopupProps.dialog(
                                          showSelectedItems: true,
                                          showSearchBox: true),
                                      // mode: Mode.dialog,
                                      // showSelectedItems: true,
                                      items: (filter, infiniteScrollProps) => snapshot.data!,
                                      decoratorProps:
                                          const DropDownDecoratorProps(
                                        decoration:
                                            InputDecoration(
                                          labelText: "Lead To Name",
                                          hintText: "Select Lead To Name",
                                        ),
                                      ),
                                      // dropdownSearchDecoration: const InputDecoration(
                                      // labelText: "Menu mode",
                                      // hintText: "country in menu mode",
                                      // ),
                                      // popupItemDisabled: isItemDisabled,
                                      onSelected: (value) {
                                        setState(() {
                                          _selectedleadton = value!;
                                        });
                                      },
                                      selectedItem: _selectedleadton,
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
                      if (_allowAssign)
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: InputField(
                            label: "Follow up Date Time",
                            controller: _meetingdatetimecontroller,
                            readOnly: true,
                            onTap: () async {
                              DateTime? meet = await showOmniDateTimePicker(
                                  context: context, minutesInterval: 15);
                              if (meet != null) {
                                _meetingdatetimecontroller.text =
                                    DateFormat("dd/MM/yyyy")
                                        .add_jm()
                                        .format(meet);
                              }
                            },
                            validator: (value) {
                              if ((value == null || value.isEmpty) &&
                                  (_selectedleadton != null)) {
                                return "Please select follow up date time";
                              }
                              return null;
                            },
                          ),
                        ),
                      Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: DropdownSearch<String>(
                            enabled: _isenabled,
                            popupProps: const PopupProps.dialog(
                                showSelectedItems: true, showSearchBox: true),
                            // mode: Mode.dialog,
                            // showSelectedItems: true,
                            items: (filter, infiniteScrollProps) => [
                              "Under AMC",
                              "Paid Basis",
                              "Free Service as per Installation Agreement"
                            ],
                            decoratorProps:
                                const DropDownDecoratorProps(
                              decoration: InputDecoration(
                                labelText: "Category",
                                hintText: "Select a category",
                              ),
                            ),

                            onSelected: (value) {
                              setState(() {
                                // _company.clear();
                                _selectedcategory = value;
                                // getcomp();
                              });
                            },
                            selectedItem: _selectedcategory,
                          )),
                      // Padding(
                      //   padding: const EdgeInsets.all(5.0),
                      //   child: InputField(
                      //     label: "Follow up Date Time",
                      //     controller: _meetingdatetimecontroller,
                      //     readOnly: true,
                      //     onTap: () async {
                      //       DateTime? meet = await showOmniDateTimePicker(
                      //           context: context, minutesInterval: 15);
                      //       if (meet != null) {
                      //         _meetingdatetimecontroller.text =
                      //             DateFormat("dd/MM/yyyy")
                      //                 .add_jm()
                      //                 .format(meet);
                      //       }
                      //     },
                      //   ),
                      // ),
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: InputField(
                          label: "Message",
                          controller: _msgcontroller,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: InputField(
                          label: "Contact Number",
                          controller: _mobilecontroller,
                          keyboardtype: TextInputType.phone,
                          sufficon: IconButton(
                              onPressed: () async {
                                Contact? contact =
                                    await _contactPicker.selectPhoneNumber();
                                setState(() {
                                  _selectedPhoneNumber =
                                      contact?.selectedPhoneNumber;
                                  if (_selectedPhoneNumber != null) {
                                    var phno = _selectedPhoneNumber!
                                        .replaceAll(" ", "");
                                    _mobilecontroller.text =
                                        phno.substring(phno.length - 10);
                                    _selectedPhoneNumber = null;
                                  }
                                });
                              },
                              icon: const Icon(Icons.contacts)),
                        ),
                      ),
                      if (_isLoading)
                        const Center(
                            child:
                                CircularProgressIndicator(color: Colors.brown)),
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : (() {
                                      if (_formkey.currentState!.validate()) {
                                        submitdata("true");
                                      }
                                      
                                    }),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromRGBO(252, 101, 8, 1),
                                  foregroundColor: Colors.white),
                              child: const Text("Save and Send"),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              )),
        ),
      ),
    );
  }
}
