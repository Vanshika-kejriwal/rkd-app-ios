import "dart:convert";
import "package:business_app/models/utils.dart";
import "package:business_app/screens/lead_gen.dart";
import "package:business_app/screens/project_registration.dart";
import "package:business_app/services/notification_service.dart";
// import "package:business_app/services/send_notification_service.dart";
import "package:business_app/widgets/background.dart";
import "package:flutter/foundation.dart";
import "package:flutter_native_contact_picker/flutter_native_contact_picker.dart";
import "package:flutter_native_contact_picker/model/contact.dart";
import 'package:http/http.dart' as http;
import "package:business_app/constants.dart";
import "package:business_app/widgets/input_field.dart";
import "package:dropdown_search/dropdown_search.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import "package:shared_preferences/shared_preferences.dart";
// Removed go_router import

class Installationasiggn extends StatefulWidget {
  bool assignExisting;
  Map<String, dynamic>? leadinfo;
  Installationasiggn({super.key, this.assignExisting = false, this.leadinfo});

  @override
  State<Installationasiggn> createState() => _InstallationasiggnState();
}

class _InstallationasiggnState extends State<Installationasiggn> {
  // final _leadtoncontroller = TextEditingController();
  // final _pnamecontroller = TextEditingController();
  final _meetingdatetimecontroller = TextEditingController();
  final _msgcontroller = TextEditingController();
  List<String> _selectedproduct = [];
  List<LeadProduct> _selectedcomp = [];
  // Removed unused _selectedut field
  Project? _selectedproject;
  String? _selectedleadton;
  bool _isLoading = false;
  bool _isenabled = true;
  List<LeadProduct> _company = [];
  late Future<List<Project>> _projects;
  List<String> _products = [];
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
  final _formkey = GlobalKey<FormState>();
  String? _selectedPhoneNumber;
  final _mobilecontroller = TextEditingController();
  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();
  NotificationService notificationService = NotificationService();
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
    final response = await http.get(Uri.parse(
        '$baseuri/api/leadforp/?project=${_selectedproject!.pname}&custtype=${_selectedproject!.custtype}'));
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
    String queryparam = _selectedproduct.map((item) => "ut1=$item").join("&");
    final response =
        await http.get(Uri.parse('$baseuri/api/instforc/?$queryparam'));
    final body = json.decode(response.body);
    List<LeadProduct> comp = [];
    if (response.statusCode == 200) {
      for (var c in body) {
        comp.add(LeadProduct(company: c['CNAME'], product: c['LEADFORP']));
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

  Future<List<Project>> getprojects() async {
    final response = await http.get(Uri.parse('$baseuri/api/pnamelist/'));
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

  Future submitdata(String sendmsg) async {
    setState(() {
      _isLoading = true;
    });
    var sharedpref = await SharedPreferences.getInstance();
    var username = sharedpref.getString('NAME');
    final List<Map<String, dynamic>> comp =
        _selectedcomp.map((item) => item.toJson()).toList();
    final Map<String, dynamic> data = {
      'PJC': _selectedproject!.pjc,
      'LEADBYN': username,
      "CUSTTYPE": _selectedproject!.custtype,
      'PNAME': _selectedproject!.pname,
      'lead_products': _selectedproduct,
      'lead_companies': comp,
      'LEAD_DATE': DateTime.now().toString().split(" ")[0],
      'LEADTON': _selectedleadton ?? "",
      'MEETING_DATETIME': _meetingdatetimecontroller.text,
      'OPEN': 'Y',
      "LEAD_TYPE": "INSTALLATION",
      'COMPLAIN_MOB': _mobilecontroller.text,
      "MESSAGE": "${_msgcontroller.text} (New Lead Created)",
      "SEND_MSG": sendmsg
    };
    // var assignexisting = "";
    // if (widget.assignExisting & (widget.leadinfo != null)) {
    //   assignexisting = "true";
    // } else {
    //   assignexisting = "false";
    // }
    final resp = await http.post(Uri.parse('$baseuri/api/leads/'),
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
      setState(() {
        _selectedproject = null;
        _selectedproduct = [];
        _selectedcomp = [];
        _selectedleadton = null;
        _meetingdatetimecontroller.clear();
        _msgcontroller.clear();
      });
      if (kIsWeb) {
        Navigator.pushReplacementNamed(context, '/lead_generation/open');
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LeadGeneration(fromForm: true,),
          ),
        );
      }
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
      _products = List<String>.from(widget.leadinfo!["product"]);
      // _selectedcomp = [LeadProduct(
      //     company: widget.leadinfo!["company"],
      //     product: widget.leadinfo!["product"])];
      _isenabled = false;
      getprojdetail(widget.leadinfo!["pjc"]);
    }
    _projects = getprojects();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double swidth = MediaQuery.of(context).size.width;
    return Background(
      appbar: true,
      appbartitle: GestureDetector(
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: Text(_selectedproject!.pname),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SelectableText("Owner Name - $_name"),
                            SelectableText(
                                "Owner Mobile Number - $_ownermobile"),
                            SelectableText("Mobile 1 - $_mobile1"),
                            SelectableText("Mobile 2 - $_mobile2"),
                            SelectableText(
                                "Address - $_add1 $_add2 $_city $_district $_state")
                          ],
                        ),
                      ));
            },
            child: const Text("Assign Installation"),
          ),
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
                                    popupProps: const PopupProps.dialog(
                                      dialogProps: DialogProps(barrierDismissible: true,barrierLabel: "Dismiss"),
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
                                        // Removed _selectedut assignment
                                        getproduct();
                                      });
                                      if (value!.pname == "Add New") {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ProjectRegistration(),
                                          ),
                                        );
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
                          child: DropdownSearch<String>.multiSelection(
                            // enabled: _isenabled,
                            popupProps: const MultiSelectionPopupProps.dialog(
                              dialogProps: DialogProps(barrierDismissible: true,barrierLabel: "Dismiss"),
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
                            selectedItems: _selectedproduct,
                          )),
                      Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: DropdownSearch<LeadProduct>.multiSelection(
                            // enabled: _isenabled,
                            popupProps: const MultiSelectionPopupProps.dialog(
                                dialogProps: DialogProps(barrierDismissible: true, barrierLabel: "Dismiss"),
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
                          )),
                      Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: FutureBuilder<List<String>>(
                              future: getnames(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
                                  return DropdownSearch<String>(
                                    popupProps: const PopupProps.dialog(
                                      dialogProps: DialogProps(barrierDismissible: true, barrierLabel: "Dismiss"),
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
                                      submitdata("true");
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
                                      submitdata("false");
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
}
