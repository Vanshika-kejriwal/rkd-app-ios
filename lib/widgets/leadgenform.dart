import "dart:convert";
import "package:business_app/models/utils.dart";
import "package:business_app/screens/lead_gen.dart";
import "package:business_app/screens/project_registration.dart";
import "package:business_app/services/notification_service.dart";
// import "package:business_app/services/send_notification_service.dart";
import "package:business_app/widgets/background.dart";
import "package:flutter/foundation.dart";
import 'package:http/http.dart' as http;
import "package:business_app/constants.dart";
import "package:business_app/widgets/input_field.dart";
import "package:dropdown_search/dropdown_search.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import "package:shared_preferences/shared_preferences.dart";
// Removed go_router import

class NewLeadForm extends StatefulWidget {
  bool assignExisting;
  Map<String, dynamic>? leadinfo;
  NewLeadForm({super.key, this.assignExisting = false, this.leadinfo});

  @override
  State<NewLeadForm> createState() => _NewLeadFormState();
}

class _NewLeadFormState extends State<NewLeadForm> {
  void _consumeRouteExtra(BuildContext context) {
    final routeExtra = ModalRoute.of(context)?.settings.arguments;
    if (routeExtra is Map<String, dynamic>) {
      if (routeExtra.containsKey('assignExisting')) {
        widget.assignExisting = routeExtra['assignExisting'] as bool;
      }
      if (routeExtra.containsKey('leadinfo')) {
        widget.leadinfo = routeExtra['leadinfo'] as Map<String, dynamic>?;
      }
    }
  }
  // Removed go_router route extra logic. Use constructor parameters for argument passing.

  // final _leadtoncontroller = TextEditingController();
  // final _pnamecontroller = TextEditingController();
  final _meetingdatetimecontroller = TextEditingController();
  final _msgcontroller = TextEditingController();
  List<String> _selectedproduct = [];
  List<LeadProduct> _selectedcomp = [];
  String? _selectedut;
  Project? _selectedproject;
  String? _selectedleadton;
  bool _isLoading = false;
  bool _isprojLoading = false;
  bool _isenabled = true;
  List<LeadProduct> _company = [];
  // late Future<List<Project>> _projects;
  List<Project> _projects = [];
  final _searchcontroller = TextEditingController();
  List<String> _products = [];
  final _formkey = GlobalKey<FormState>();
  final GlobalKey<DropdownSearchState<Project>> _projectkey =
      GlobalKey<DropdownSearchState<Project>>();
  NotificationService notificationService = NotificationService();

  String _pjc = '';
  String _name = '';
  String _ownermobile = '';
  String _add1 = '';
  String _add2 = '';
  // Removed unused _pin field
  String _state = '';
  String _city = '';
  String _district = '';
  String _mobile1 = '';
  String _mobile2 = '';
  String _pin = '';
  String _gstno = '';

  // DateTime? _meetingdatetime;
  Future<List<String>> getut() async {
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
    List<LeadProduct> comp = [];
    if (widget.leadinfo != null &&
        widget.leadinfo!['leadtype'] == "INSTALLATION") {
      // print("here");
      String queryparam = _selectedproduct.map((item) => "ut1=$item").join("&");
      final response = await http.post(Uri.parse('$baseuri/api/instforc/'),
          body: jsonEncode({"ut1": _selectedproduct}),
          headers: {"Content-Type": "application/json"});
      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        for (var c in body) {
          comp.add(LeadProduct(company: c['CNAME'], product: c['LEADFORP']));
        }
      }
    } else if (widget.leadinfo != null &&
        widget.leadinfo!['leadtype'] == "SERVICE") {
      final response = await http.post(Uri.parse('$baseuri/api/servforc/'),
          body: jsonEncode({"ut1": _selectedproduct, "pjc": _selectedproject!.pjc}),
          headers: {"Content-Type": "application/json"});
      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        for (var c in body) {
          comp.add(LeadProduct(company: c['CNAME'], product: c['LEADFORP']));
        }
      }
    } else {
      String queryparam = _selectedproduct.map((item) => "ut1=$item").join("&");
      final response = await http.post(Uri.parse('$baseuri/api/leadforc/'),
          body: jsonEncode({"ut1": _selectedproduct}),
          headers: {"Content-Type": "application/json"});
      final body = json.decode(response.body);

      if (response.statusCode == 200) {
        for (var c in body) {
          comp.add(
              LeadProduct(company: c['CO_NAME'], product: c['PRODUCT_TYPE']));
        }
      }
    }
    setState(() {
      _company = comp;
    });
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

  Future<List<Project>> getprojects({String? searchterm}) async {
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

  Future<List<String>> getcusttype() async {
    final response = await http.get(Uri.parse('$baseuri/api/custtype/'));
    final body = json.decode(response.body);
    List<String> cust = [];
    if (response.statusCode == 200) {
      for (var c in body) {
        cust.add(c["UT1"]);
      }
    }
    return cust;
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
      _selectedcomp = [];
      _selectedleadton = null;
      _meetingdatetimecontroller.clear();
      _msgcontroller.clear();
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

  Future submitdata(String sendmsg) async {
    setState(() {
      _isLoading = true;
    });
    var sharedpref = await SharedPreferences.getInstance();
    var username = sharedpref.getString('NAME');
    final List<Map<String, dynamic>> comp =
        _selectedcomp.map((item) => item.toJson()).toList();
    final Map<String, dynamic> data = {
      'LEADBYN': username,
      'PJC': _selectedproject!.pjc,
      "CUSTTYPE": _selectedproject!.custtype,
      'PNAME': _selectedproject!.pname,
      'lead_products': _selectedproduct,
      'lead_companies': comp,
      'LEAD_DATE': DateTime.now().toString().split(" ")[0],
      'LEADTON': _selectedleadton ?? "",
      'MEETING_DATETIME': _meetingdatetimecontroller.text,
      'OPEN': 'Y',
      "LEAD_TYPE":
          widget.leadinfo == null ? "NEW LEAD" : widget.leadinfo!["leadtype"],
      "MESSAGE": _msgcontroller.text,
      "SEND_MSG": sendmsg
    };
    var assignexisting = "";
    if (widget.assignExisting &&
        (widget.leadinfo != null) &&
        ((widget.leadinfo?["leadtype"] != "INSTALLATION") &&
            (widget.leadinfo?["leadtype"] != "SERVICE"))) {
      assignexisting = "true";
    } else {
      assignexisting = "false";
    }
    final resp = await http.post(
        Uri.parse('$baseuri/api/leads/?assign_existing=$assignexisting'),
        body: jsonEncode(data),
        headers: {"Content-Type": "application/json"});
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      setState(() {
        _isLoading = false;
        _selectedut = null;
        // _selectedproject = null;
        // _selectedproduct = [];
        _selectedcomp = [];
        _selectedleadton = null;
        _meetingdatetimecontroller.clear();
        _msgcontroller.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text("Data saved successfully"),
          backgroundColor: Colors.green[400]));
      // if (kDebugMode) {
      //   SendNotificationService.sendNotificationUsingApi(
      //       token: "test",
      //       title: "New Lead Generated ",
      //       body:
      //           "Party: ${_selectedproject!.pname}\nProduct: ${_selectedproduct.join(", ")}",
      //       data: {"screen": "leads"});
      // } else {
      //   SendNotificationService.sendNotificationUsingApi(
      //       token: "all",
      //       title: "New Lead Generated ",
      //       body:
      //           "Party: ${_selectedproject!.pname}\nProduct: ${_selectedproduct.join(", ")}",
      //       data: {"screen": "leads"});
      // }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LeadGeneration(
            fromForm: true,
          ),
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Something went wrong. Please try again."),
          backgroundColor: Colors.red));
    }
  }

  Future<void> getprojdetail(pjc) async {
    final response =
        await http.get(Uri.parse('$baseuri/api/projectdetail/$pjc/'));
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      setState(() {
        _pjc = pjc;
        _name = body["CONTP"];
        _ownermobile = body["OMOBILE"];
        _add1 = body["ADD1"];
        _add2 = body["ADD2"];
        // Removed _pin assignment
        _state = body["STATE"];
        _city = body["CITY"];
        _district = body["DIST"];
        _mobile1 = body["MOBILE1"];
        _mobile2 = body["MOBILE2"];
        _pin = body["PIN"];
        _gstno = body["GSTN"] ?? "";
        // _formkey.currentState?.validate();
      });
      // print("Pincode doesnt exists");
    }
  }

  @override
  void initState() {
    // notificationService.firebaseInit(context);
    // notificationService.setupInteractMessage(context);
    if (widget.assignExisting & (widget.leadinfo != null)) {
      _selectedproject = Project(
          pjc: widget.leadinfo!["pjc"],
          pname: widget.leadinfo!["pname"],
          custtype: widget.leadinfo!["custtype"]);
      _products = List<String>.from(widget.leadinfo!["products"]);
      // print(_products);
      // _selectedcomp = [
      //   LeadProduct(
      //       company: widget.leadinfo!["company"],
      //       product: widget.leadinfo!["product"])
      // ];
      _isenabled = false;
      getprojdetail(_selectedproject!.pjc);
    }
    _projects = [Project(pjc: "Add New", pname: "Add New", custtype: "")];
    // print(widget.leadinfo?['leadtype']);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Restore previous logic for consuming route extra
    if (widget.leadinfo == null) {
      _consumeRouteExtra(context);
      if (widget.assignExisting & (widget.leadinfo != null)) {
        _selectedproject = Project(
            pjc: widget.leadinfo!["pjc"],
            pname: widget.leadinfo!["pname"],
            custtype: widget.leadinfo!["custtype"]);
        _products = List<String>.from(widget.leadinfo!["product"]);
        _isenabled = false;
      }
    }
    double swidth = MediaQuery.of(context).size.width;
    return Background(
      appbar: true,
      appbartitle: widget.assignExisting
          ? GestureDetector(
              onTap: () {
                showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                          title: Text(_selectedproject!.pname),
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SelectableText(
                                "PJC - $_pjc",
                                textAlign: TextAlign.start,
                              ),
                              SelectableText(
                                "Owner Name - $_name",
                                textAlign: TextAlign.start,
                              ),
                              SelectableText(
                                "Owner Mobile- $_ownermobile",
                                textAlign: TextAlign.start,
                              ),
                              SelectableText(
                                "Manager Mobile- $_mobile1",
                                textAlign: TextAlign.start,
                              ),
                              SelectableText(
                                "Staff Mobile- $_mobile2",
                                textAlign: TextAlign.start,
                              ),
                              SelectableText(
                                "Add1- $_add1",
                                textAlign: TextAlign.start,
                              ),
                              SelectableText(
                                "Add2- $_add2",
                                textAlign: TextAlign.start,
                              ),
                              SelectableText(
                                "City- $_city",
                                textAlign: TextAlign.start,
                              ),
                              SelectableText(
                                "District- $_district",
                                textAlign: TextAlign.start,
                              ),
                              SelectableText(
                                "State- $_state",
                                textAlign: TextAlign.start,
                              ),
                              SelectableText(
                                "PIN- $_pin",
                                textAlign: TextAlign.start,
                              ),
                              SelectableText(
                                "GST No- $_gstno",
                                textAlign: TextAlign.start,
                              ),
                            ],
                          ),
                        ));
              },
              child: Text(_selectedproject!.pname),
            )
          : const Text("Leads"),
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
                      widget.assignExisting
                          ? const SizedBox.shrink()
                          : Padding(
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
                            enabled: _isenabled,
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
                            items: (filter, infiniteScrollProps) => _projects,
                            itemAsString: (item) {
                              if (item.pname == "Add New") {
                                return item.pname;
                              } else if (widget.assignExisting) {
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
                                _selectedut = _selectedproject!.custtype;
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
                                    _projects = [
                                      Project(
                                          pjc: "Add New",
                                          pname: "Add New",
                                          custtype: "")
                                    ];
                                  });
                                }
                              }
                            },
                            selectedItem: _selectedproject,
                            // showSearchBox: true,
                            // searchFieldProps: TextFieldProps(
                            //   cursorColor: Colors.blue,
                            // ),
                          )),
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
                          child: DropdownSearch<String>.multiSelection(
                            // enabled: _isenabled,
                            popupProps: const MultiSelectionPopupProps.dialog(
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
                                if (widget.leadinfo?["leadtype"] ==
                                    "INSTALLATION") {
                                  getproductinfo(_selectedproject!.pjc, value);
                                }
                              });
                            },
                            selectedItems: _selectedproduct,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please select at least one product";
                              }
                              return null;
                            },
                          )),
                      Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: DropdownSearch<LeadProduct>.multiSelection(
                            // enabled: _isenabled,
                            popupProps: const MultiSelectionPopupProps.dialog(
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
                            selectedItems: _selectedcomp,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please select at least one company";
                              }
                              return null;
                            },
                          )),
                      Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: FutureBuilder<List<String>>(
                              future: getnames(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
                                  return DropdownSearch<String>(
                                    popupProps: const PopupProps.dialog(
                                        showSelectedItems: true,
                                        showSearchBox: true),
                                    // mode: Mode.dialog,
                                    // showSelectedItems: true,
                                    items: (filter, infiniteScrollProps) => snapshot.data!,
                                    decoratorProps:
                                        const DropDownDecoratorProps(
                                      decoration: InputDecoration(
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
                                        _selectedleadton = value;
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
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: InputField(
                          validator: (p0) {
                            if ((p0 == null || p0.isEmpty) &&
                                (_selectedleadton != null)) {
                              // print(_selectedleadton);
                              return "Please select follow up date time";
                            }
                            return null;
                          },
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
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: InputField(
                          label: "Message",
                          controller: _msgcontroller,
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
                            ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : (() {
                                      if (_formkey.currentState!.validate()) {
                                        submitdata("false");
                                      }
                                    }),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromRGBO(252, 101, 8, 1),
                                  foregroundColor: Colors.white),
                              child: const Text("Save Details"),
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

  void getproductinfo(String pjc, List<String> value) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Installation Product Details"),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<ProductAggregation>>(
            future: fetchInstProductDetails(pjc, value),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No data found'));
              } else {
                final products = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      title: Text("${product.product} - ${product.company}"),
                      subtitle: Column(
                        // CRITICAL: Aligns the content to the start (left)
                        crossAxisAlignment: CrossAxisAlignment.start,
                        // CRITICAL: Ensures the Column takes minimum vertical space,
                        // preventing layout issues inside the ListTile.
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. Display Charge and Company

                          // 3. Iterate and display each item from the list
                          // The .map().toList() creates a list of Text widgets from the List<String>
                          ...product.items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                  left:
                                      8.0), // Optional: Indent the items slightly
                              // You can prepend a bullet point (•) or a dash (-) for better formatting
                              child: Text(
                                  "• ${item.name} (Qty: ${item.quantity})"),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<List<ProductAggregation>>? fetchInstProductDetails(
      String pjc, List<String> value) async {
    final response = await http.post(
        Uri.parse('$baseuri/api/instproductdetail/'),
        body: jsonEncode({"pjc": pjc, "productlist": value}),
        headers: {"Content-Type": "application/json"});
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      List<ProductAggregation> products = [];
      for (var item in body) {
        products.add(ProductAggregation.fromJson(item));
      }
      return products;
    } else {
      throw Exception('Failed to load installation product details');
    }
  }
}
