import "dart:convert";
import "package:business_app/models/utils.dart";
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
import "package:quickalert/models/quickalert_type.dart";
import "package:quickalert/widgets/quickalert_dialog.dart";
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
  final List<LeadCategory> _category = [];
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
  String _selectedDate = "";
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
  LeadCategory? _selectedcategory;
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
    List<LeadProduct> comp = [];
    print(widget.leadinfo);
    if (widget.leadinfo != null && widget.leadinfo!['leadtype'] == "SERVICE") {
      final response = await http.post(Uri.parse('$baseuri/api/servforc/'),
          body: jsonEncode(
              {"ut1": _selectedproduct, "pjc": _selectedproject!.pjc}),
          headers: {"Content-Type": "application/json"});
      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        for (var c in body) {
          comp.add(LeadProduct(
              company: c['CNAME'], product: c['LEADFORP'], mc: c["MC"]));
        }
      }
    }
    setState(() {
      _company.clear();
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
      'COMPLAIN_CATEGORY': _selectedcategory!.ddl12,
      'LEADTON': _selectedleadton ?? "",
      'MEETING_DATETIME': _meetingdatetimecontroller.text,
      'OPEN': 'Y',
      "LEAD_TYPE": widget.leadinfo!['leadtype'],
      'COMPLAIN_MOB': _mobilecontroller.text,
      "MESSAGE": "${_msgcontroller.text} (New Lead Created)",
      "SEND_MSG": sendmsg
    };
    var assignexisting = "";
    if (widget.assignExisting & (widget.leadinfo != null)) {
      assignexisting = "true";
    } else {
      assignexisting = "false";
    }
    final resp = await http.post(
        Uri.parse('$baseuri/api/leads/?assign_existing=false'),
        body: jsonEncode(data),
        headers: {"Content-Type": "application/json"});
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
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => LeadGeneration(
        //       fromForm: true,
        //     ),
        //   ),
        // );
        Navigator.of(context).pop(true);
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

  Future<void> _openDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.confirm,
        title: "Change Service Date",
        text:
            "Are you sure you want to change the service of ${_selectedproduct.join(", ")} for Site ${_selectedproject!.pname} to ${DateFormat("dd/MM/yyyy").format(picked)}?",
        onConfirmBtnTap: () async {
          setState(() {
            _selectedDate = DateFormat("dd/MM/yyyy").format(picked);
          });
          print("Change Service Date");
          await _sendToBackend("CHANGE_DATE");
        },
      );
    }
  }

  Future<void> _sendToBackend(String actionType) async {
    // Show Loading Overlay
    QuickAlert.show(
        context: context,
        type: QuickAlertType.loading,
        title: "Processing $actionType");

    try {
      http.Response resp;
      // api call
      if (actionType == "CHANGE_DATE") {
        resp = await http.post(Uri.parse("$baseuri/api/servforp/"),
            headers: {
              "Content-Type": "application/json",
              // "Accept": "application/json",
            },
            body: jsonEncode({
              "products": _selectedproduct,
              "PJC": _selectedproject!.pjc,
              "MEETING_DATETIME": _selectedDate
            }));
      } else {
        resp = await http.post(Uri.parse("$baseuri/api/editservice/"),
            headers: {
              "Content-Type": "application/json",
              // "Accept": "application/json",
            },
            body: jsonEncode({
              "products": _selectedproduct,
              "PJC": _selectedproject!.pjc,
            }));
      }
      if ((mounted) && (resp.statusCode == 200)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$actionType executed successfully!")),
        );
      }
    } catch (e) {
      debugPrint("API Error: $e");
    } finally {
      if (mounted) Navigator.pop(context);
      if (mounted) Navigator.pop(context); // Dismiss loading overlay
    }
  }

  Future<void> getcategory() async {
    final response = await http.get(Uri.parse(
        '$baseuri/api/leadstatcategory/?status=servicebooking&type=SERVICE&pjc=${_selectedproject!.pjc}&product=${_selectedproduct[0]}'));
    final body = json.decode(response.body);
    // List<String> names = [];
    if (response.statusCode == 200) {
      _category.clear();
      for (var c in body) {
        _category.add(LeadCategory(
            ddl12: c['DDL12'],
            enabled: c['is_enabled'],
            extrainfo: c['extra_info']));
      }
    }
  }

  Future<List<PaidRowData>> fetchTableData() async {
    final url = Uri.parse(
        '$baseuri/api/paidbasischarge/?product=${_selectedproduct[0]}&pjc=${_selectedproject!.pjc}'); // Replace with your endpoint

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => PaidRowData.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load data: Status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

// 3. Display the Table in the AlertDialog
  void showResponsiveApiDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;

        return AlertDialog(
          title: const Text('Paid Basis Charges'),
          content: SizedBox(
            width: screenSize.width * 0.85,
            height: screenSize.height * 0.6,
            // FutureBuilder listens to the API function
            child: FutureBuilder<List<PaidRowData>>(
              future: fetchTableData(),
              builder: (context, snapshot) {
                // Show loading spinner while fetching
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Show error message if API fails
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                // Show message if data is empty
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No data found'));
                }

                final data = snapshot.data!;

                // Build the dual-scroll table when data arrives
                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Product')),
                        DataColumn(label: Text('Company')),
                        DataColumn(label: Text('Model')),
                        DataColumn(label: Text('Condition 1')),
                        DataColumn(label: Text('Condition 2')),
                        DataColumn(label: Text('Charges')),
                      ],
                      rows: data.map((item) {
                        return DataRow(cells: [
                          DataCell(Text(item.col1)),
                          DataCell(Text(item.col2)),
                          DataCell(Text(item.col3)),
                          DataCell(Text(item.col4)),
                          DataCell(Text(item.col5)),
                          DataCell(Text(item.col6))
                        ]);
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void getproductinfo(String pjc, List<String> value) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${widget.leadinfo!["leadtype"]} Product Details"),
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
        Uri.parse('$baseuri/api/servproductdetail/'),
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

  @override
  Widget build(BuildContext context) {
    double swidth = MediaQuery.of(context).size.width;
    final bool hasSelection = _selectedproduct.isNotEmpty;
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
                        SelectableText("Owner Mobile Number - $_ownermobile"),
                        SelectableText("Mobile 1 - $_mobile1"),
                        SelectableText("Mobile 2 - $_mobile2"),
                        SelectableText(
                            "Address - $_add1 $_add2 $_city $_district $_state")
                      ],
                    ),
                  ));
        },
        child: Text("Assign ${widget.leadinfo!['leadtype']}"),
      ),
      appbaractions: [
        // Action 1: Change Date Button
        IconButton(
          icon: const Icon(Icons.calendar_month),
          tooltip: 'Change Date',
          onPressed: hasSelection ? _openDatePicker : null,
        ),
        // Action 2: Delete Button
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete Selected',
          color: hasSelection ? Colors.red : null,
          onPressed: hasSelection
              ? () => QuickAlert.show(
                    context: context,
                    type: QuickAlertType.confirm,
                    title: "Delete Service",
                    text:
                        "Are you sure you want to delete the service of ${_selectedproduct.join(", ")} for Site ${_selectedproject!.pname}?",
                    onConfirmBtnTap: () async {
                      print("Delete Service");
                      await _sendToBackend("DELETE");
                    },
                  )
              : null,
        ),
      ],
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
                                        dialogProps: DialogProps(
                                            barrierDismissible: true,
                                            barrierLabel: "Dismiss"),
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
                                    items: (filter, infiniteScrollProps) =>
                                        snapshot.data!,
                                    compareFn: (item1, item2) {
                                      return item1.pjc == item2.pjc;
                                    },
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
                          child: DropdownSearch<String>(
                            // enabled: _isenabled,
                            popupProps: PopupProps.dialog(
                                dialogProps: DialogProps(
                                    barrierDismissible: true,
                                    barrierLabel: "Dismiss"),
                                showSelectedItems: true,
                                showSearchBox: true),
                            // mode: Mode.dialog,
                            // showSelectedItems: true,
                            items: (filter, infiniteScrollProps) => _products,
                            decoratorProps: const DropDownDecoratorProps(
                              decoration: InputDecoration(
                                labelText: "Product",
                                hintText: "Select a Product",
                              ),
                            ),

                            onSelected: (value) {
                              setState(() {
                                _company.clear();
                                _selectedproduct.clear();
                                _selectedproduct.add(value!);
                                _selectedcomp.clear();
                                _category.clear();
                                _selectedcategory = null;

                                getcomp();
                              });
                              getproductinfo(_selectedproject!.pjc, [value!]);
                              getcategory();
                            },
                            selectedItem: _selectedproduct.isNotEmpty
                                ? _selectedproduct[0]
                                : null,
                          )),
                      Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: DropdownSearch<LeadProduct>(
                            // enabled: _isenabled,
                            popupProps: const PopupProps.dialog(
                                dialogProps: DialogProps(
                                    barrierDismissible: true,
                                    barrierLabel: "Dismiss"),
                                // showSelectedItems: true,
                                showSearchBox: true),
                            // mode: Mode.dialog,
                            // showSelectedItems: true,
                            items: (filter, infiniteScrollProps) => _company,
                            compareFn: (item1, item2) {
                              return item1.company == item2.company;
                            },
                            itemAsString: (item) {
                              return "${item.company} (${item.product})";
                            },
                            decoratorProps: const DropDownDecoratorProps(
                              decoration: InputDecoration(
                                labelText: "Company",
                                hintText: "Select a Company",
                              ),
                            ),

                            onSelected: (value) {
                              setState(() {
                                _selectedcomp.add(value!);
                              });
                            },
                            selectedItem: _selectedcomp.isNotEmpty
                                ? _selectedcomp[0]
                                : null,
                          )),
                      Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: DropdownSearch<LeadCategory>(
                            compareFn: (item1, item2) {
                              return item1.ddl12 == item2.ddl12;
                            },
                            itemAsString: (item) => item.ddl12,
                            // enabled: !_resendotp,
                            popupProps: PopupProps.dialog(
                                itemBuilder:
                                    (context, item, isDisabled, isSelected) =>
                                        ListTile(
                                          enabled: item.enabled,
                                          title: Text(item.ddl12),
                                          trailing: item.extrainfo != null
                                              ? Text(item.extrainfo!)
                                              : null,
                                        ),
                                disabledItemFn: (item) {
                                  return !item.enabled;
                                },
                                dialogProps: const DialogProps(
                                  barrierDismissible: true,
                                  barrierLabel: "Dismiss",
                                ),
                                showSelectedItems: true,
                                showSearchBox: true),
                            // mode: Mode.dialog,
                            // showSelectedItems: true,
                            items: (filter, infiniteScrollProps) => _category,
                            decoratorProps: const DropDownDecoratorProps(
                              decoration: InputDecoration(
                                labelText: "Service Type",
                                hintText: "Select an option",
                              ),
                            ),

                            onSelected: (value) {
                              setState(() {
                                // _company.clear();
                                _selectedcategory = value!;
                                // getcomp();
                              });
                              if (value?.ddl12 == "Paid Basis") {
                                showResponsiveApiDialog(context);
                              }
                            },
                            selectedItem: _selectedcategory,
                          )),
                      Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: FutureBuilder<List<String>>(
                              future: getnames(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
                                  return DropdownSearch<String>(
                                    popupProps: const PopupProps.dialog(
                                        dialogProps: DialogProps(
                                            barrierDismissible: true,
                                            barrierLabel: "Dismiss"),
                                        showSelectedItems: true,
                                        showSearchBox: true),
                                    // mode: Mode.dialog,
                                    // showSelectedItems: true,
                                    items: (filter, infiniteScrollProps) =>
                                        snapshot.data!,
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
