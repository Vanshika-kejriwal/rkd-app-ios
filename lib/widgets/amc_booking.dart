import 'dart:convert';

import 'package:business_app/constants.dart';
import 'package:business_app/models/utils.dart';
import 'package:business_app/screens/project_registration.dart';
import 'package:business_app/widgets/background.dart';
import 'package:business_app/widgets/input_field.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AMC extends StatefulWidget {
  const AMC({super.key});

  @override
  State<AMC> createState() => _AMCState();
}

class _AMCState extends State<AMC> {
  late Future<List<Project>> _projects;
  Project? _selectedproject;
  List<String> _products = [];
  String? _selectedproduct;
  List<LeadProduct> _company = [];
  LeadProduct? _selectedcomp;
  List<String> _models = [];
  List<AMCModel> _amcitemdetail = [];
  String? _selectedmodel;
  List<AMCModel> _selectedamcitemdetail = [];
  List<String> _amctypes = [];
  String? _selectedamctype;
  bool _isLoading = false;
  final _formkey = GlobalKey<FormState>();
  String? _selectedduration;
  final TextEditingController _billDateController = TextEditingController();
  final TextEditingController _billNumberController = TextEditingController();
  final TextEditingController _billQuantityController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _amcstartDateController = TextEditingController();
  final TextEditingController _cashRecieverNameController =
      TextEditingController();
  final TextEditingController _cashRecieverContactController =
      TextEditingController();
  final TextEditingController _cashGiverNameController =
      TextEditingController();
  final TextEditingController _cashGiverContactController =
      TextEditingController();
  final TextEditingController _jcccontroller = TextEditingController();
  String? _selectedpaymentmethod;
  final TextEditingController _documentNumberController =
      TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _amtController = TextEditingController();
  final TextEditingController _gstamtController = TextEditingController();
  String _gstper = "18";
  String _ratetype = "";

  Future<List<Project>> getprojects() async {
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

  Future<void> getrate({custom = false}) async {
    if ((_selectedamctype != null) && (_selectedduration != null)) {
      if (!custom) {
        final response = await http.post(Uri.parse('$baseuri/api/amcrate/'),
            body: jsonEncode({
              "product": "$_selectedproduct",
              "company": _selectedcomp!.company,
              "model": _selectedmodel,
              "amctype": _selectedamctype,
              "duration": _selectedduration,
            }),
            headers: {"Content-Type": "application/json"});
        final body = json.decode(response.body);
        if (response.statusCode == 200) {
          var targetkey = "_${_selectedduration!.split(" ")[0]}_MONTHS";
          var gst = body[0]["GST"].substring(0, body[0]["GST"].length - 1);
          var qty = _billQuantityController.text.isNotEmpty
              ? double.parse(_billQuantityController.text)
              : 1;
          var amount = double.parse(body[0][targetkey].toString()) *
              qty *
              (1 + double.parse(gst) / 100);
          var amtwogst = double.parse(body[0][targetkey].toString()) * qty;
          var gstamt = amtwogst * (double.parse(gst) / 100);
          setState(() {
            _gstper = gst;
            _rateController.text = body[0][targetkey].toString();
            _ratetype = body[0]['F2'].toString();
            _amtController.text = amtwogst.toStringAsFixed(2);
            _gstamtController.text = gstamt.toStringAsFixed(2);
            _amountController.text = amount.toStringAsFixed(2);
          });
        }
      } else {
        var gst = _gstper;
        var qty = _billQuantityController.text.isNotEmpty
            ? double.parse(_billQuantityController.text)
            : 1;
        var amount = double.parse(_rateController.text) *
            qty *
            (1 + double.parse(gst) / 100);
        var amtwogst = double.parse(_rateController.text) * qty;
        var gstamt = amtwogst * (double.parse(gst) / 100);
        setState(() {
          _amtController.text = amtwogst.toStringAsFixed(2);
          _gstamtController.text = gstamt.toStringAsFixed(2);
          _amountController.text = amount.toStringAsFixed(2);
        });
      }
    }
  }

  Future<String?> openDialog(title, lablel) => showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: InputField(label: lablel, controller: _jcccontroller),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(_jcccontroller.text);
                },
                child: const Text("SUBMIT"))
          ],
        ),
      );

  Future submitdata(String paymentMethod) async {
    setState(() {
      _isLoading = true;
    });
    var sharedpref = await SharedPreferences.getInstance();
    var username = sharedpref.getString('NAME');
    var usermobile = sharedpref.getString('Mobile');
    // final List<Map<String, dynamic>> comp =
    //     _selectedcomp.map((item) => item.toJson()).toList();
    final Map<String, dynamic> data = {
      // "CUSTTYPE": _selectedproject!.custtype,
      'PJC': _selectedproject!.pjc,
      // 'PNAME': _selectedproject!.pname,
      'Product_Type': _selectedproduct,
      'Company': _selectedcomp!.company,
      // 'LEAD_DATE': DateTime.now().toString().split(" ")[0],
      'Model': _selectedamcitemdetail.isNotEmpty
          ? _selectedamcitemdetail.first.item
          : _selectedmodel,
      'AMC_Type': _selectedamctype,
      'AMC_Period': _selectedduration,
      'Bill_date': _billDateController.text,
      'Bill_Number': _billNumberController.text,
      'Qty': _billQuantityController.text,
      'AMC_Date': DateTime.now().toString().split(" ")[0],
      'AMC_Start_Date': _amcstartDateController.text,
      'Rate': _rateController.text,
      'Amount': _amountController.text,
      // 'Payment_mode': paymentMethod,
    };
    final resp = await http.post(Uri.parse('$baseuri/api/amcbooking/'),
        body: jsonEncode(data), headers: {"Content-Type": "application/json"});
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      setState(() {
        _isLoading = false;
      });
      final result = json.decode(resp.body);
      final String message = result['message'];
      final String amcNumber = result['amc_number'];
      var res = await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Payment Handover Confirmation"),
          content: StatefulBuilder(
            // 1. Wrap with StatefulBuilder
            builder: (BuildContext context, StateSetter setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: DropdownSearch<String>(
                        popupProps: const PopupProps.dialog(
                          dialogProps: DialogProps(
                            barrierDismissible: true,
                            barrierLabel: "Dismiss",
                          ),
                          showSelectedItems: true,
                          showSearchBox: true,
                        ),
                        items: (filter, infiniteScrollProps) =>
                            ["Cash", "Cheque", "NEFT/RTGS"],
                        decoratorProps: const DropDownDecoratorProps(
                          decoration: InputDecoration(
                            labelText: "Payment Method",
                            hintText: "Select Payment Method",
                          ),
                        ),
                        onSelected: (value) {
                          // 2. Use setDialogState to rebuild the dialog internally
                          setDialogState(() {
                            _selectedpaymentmethod = value!;
                          });

                          // Also update the parent view state if needed outside the dialog
                          setState(() {
                            _selectedpaymentmethod = value!;
                          });
                        },
                        selectedItem: _selectedpaymentmethod,
                      ),
                    ),

                    // 3. This condition will now actively re-evaluate inside the dialog!
                    if (_selectedpaymentmethod == "Cheque" ||
                        _selectedpaymentmethod == "NEFT/RTGS") ...[
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: InputField(
                          label: "Document Number",
                          controller: _documentNumberController,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: InputField(
                          label: "Bank Name",
                          controller: _bankNameController,
                        ),
                      ),
                    ],

                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: InputField(
                        label: "Payment Giver Name",
                        controller: _cashGiverNameController,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: InputField(
                        label: "Payment Giver Contact",
                        controller: _cashGiverContactController,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, {
                "receiver_name": username,
                "receiver_contact": usermobile,
                "giver_name": _cashGiverNameController.text,
                "giver_contact": _cashGiverContactController.text,
                "payment_method": _selectedpaymentmethod,
                'document_number': _documentNumberController.text,
                'bank_name': _bankNameController.text,
              }),
              child: const Text("OK"),
            )
          ],
        ),
      );
      if (res != null) {
        // You can now use the res map to access the entered details
        print("Cash Handover Details: $res");
        // Here you can send this data to your backend or perform any other action
        QuickAlert.show(
          context: context,
          type: QuickAlertType.loading,
          text: 'Sending OTP to ${res["giver_contact"]}',
        );
        var resp = await http.post(Uri.parse('$baseuri/api/amcpayment/'),
            body: jsonEncode({
              "amc_number": amcNumber,
              "payment_mode": _selectedpaymentmethod,
              "receiver_name": res["receiver_name"],
              "receiver_contact": res["receiver_contact"],
              "giver_name": res["giver_name"],
              "giver_contact": res["giver_contact"],
              'document_number': res['document_number'],
              'bank_name': res['bank_name'],
            }),
            headers: {"Content-Type": "application/json"});
        if (resp.statusCode == 200) {
          // enter otp dialog
          Navigator.of(context).pop(); // Close the loading dialog
          var jcc = await openDialog(" Cash Recieve OTP", "Enter OTP");
          var otpverifyresp =
              await http.post(Uri.parse('$baseuri/api/amcpaymentverify/'),
                  body: jsonEncode({
                    "amc_number": amcNumber,
                    "otp": jcc,
                    'item_codes': _selectedamcitemdetail
                        .map((item) => item.code)
                        .toList(),
                  }),
                  headers: {"Content-Type": "application/json"});
        }
      }
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
        // _selectedut = null;
        _selectedproject = null;
        _selectedproduct = null;
        _selectedcomp = null;
        // _selectedleadton = null;
        _selectedmodel = null;
        _selectedamctype = null;
        _selectedduration = null;
        _billDateController.clear();
        _billNumberController.clear();
        _billQuantityController.clear();
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

  Future<void> getproduct() async {
    final response = await http.get(Uri.parse('$baseuri/api/amcproduct/'));
    final body = json.decode(response.body);
    Set<String> product = {};
    if (response.statusCode == 200) {
      for (var c in body) {
        product.add(c["Product_Type"]);
      }
    }
    setState(() {
      _products = product.toList();
    });
  }

  Future<void> checkrunningamc() async {
    final response = await http.post(Uri.parse('$baseuri/api/amcrunningcheck/'),
        body: jsonEncode(
            {"product": "$_selectedproduct", "pjc": _selectedproject!.pjc}),
        headers: {"Content-Type": "application/json"});
    final body = json.decode(response.body);
    if (response.statusCode == 200) {
      if (body['running_amc_exists'] == true) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.warning,
          text:
              'There is already a running AMC for the selected product with following details:Booking Date: ${body['booking_date']}\nCompany: ${body['company']}\nModel: ${body['model']}\nAMC Type: ${body['amc_type']}\nAMC Duration: ${body['amc_duration']}',
        );
      }
    }
  }

  Future<void> getcomp() async {
    // String queryparam = _selectedproduct.map((item) => "ut1=$item").join("&");
    List<String> queryparams = [];
    queryparams.add("$_selectedproduct");
    final response = await http.post(Uri.parse('$baseuri/api/amccomp/'),
        body: jsonEncode({"ut1": "$_selectedproduct"}),
        headers: {"Content-Type": "application/json"});
    final body = json.decode(response.body);
    List<LeadProduct> comp = [];
    if (response.statusCode == 200) {
      for (var c in body) {
        comp.add(
            LeadProduct(company: c['Company'], product: c['Product_Type']));
      }
    }
    setState(() {
      _company = comp;
    });
  }

  Future<void> getmodel() async {
    // String queryparam = _selectedproduct.map((item) => "ut1=$item").join("&");
    List<String> queryparams = [];
    queryparams.add("$_selectedproduct");
    final response = await http.post(Uri.parse('$baseuri/api/amcproductmodel/'),
        body: jsonEncode({
          "product": "$_selectedproduct",
          "company": _selectedcomp!.company
        }),
        headers: {"Content-Type": "application/json"});
    final body = json.decode(response.body);
    List<String> comp = [];
    if (response.statusCode == 200) {
      for (var c in body) {
        comp.add(c['Model']);
      }
    }
    setState(() {
      _models = comp;
    });
  }

  Future<void> getitemdetail() async {
    // String queryparam = _selectedproduct.map((item) => "ut1=$item").join("&");
    List<String> queryparams = [];
    queryparams.add("$_selectedproduct");
    final response = await http.post(Uri.parse('$baseuri/api/amcitemdetail/'),
        body: jsonEncode({
          'pjc': _selectedproject!.pjc,
          "product": "$_selectedproduct",
          "company": _selectedcomp!.company
        }),
        headers: {"Content-Type": "application/json"});
    final body = json.decode(response.body);
    List<AMCModel> comp = [];
    if (response.statusCode == 200) {
      for (var c in body) {
        comp.add(
            AMCModel(code: c['CODE'], item: c['ITEM'], idatec: c['IDATEC']));
      }
    }
    setState(() {
      _amcitemdetail = comp;
    });
  }

  Future<void> getbilldetail() async {
    if (_selectedamcitemdetail.isNotEmpty) {
      List<String> itemCodes =
          _selectedamcitemdetail.map((item) => item.code).toList();
      final response = await http.post(Uri.parse('$baseuri/api/amcbilldetail/'),
          body: jsonEncode({
            'pjc': _selectedproject!.pjc,
            "product": "$_selectedproduct",
            "company": _selectedcomp!.company,
            "item_codes": itemCodes
          }),
          headers: {"Content-Type": "application/json"});
      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _billDateController.text = body['bill_date'] ?? '';
          _billNumberController.text = body['bill_no'] ?? '';
          _billQuantityController.text = body['qty']?.toString() ?? '';
        });
      }
    }
  }

  Future<void> getamctype() async {
    final response = await http.post(Uri.parse('$baseuri/api/amctype/'),
        body: jsonEncode({
          "product": "$_selectedproduct",
          "company": _selectedcomp!.company,
          "model": _selectedmodel
        }),
        headers: {"Content-Type": "application/json"});
    List<String> comp = [];
    final body = json.decode(response.body);
    if (response.statusCode == 200) {
      for (var c in body) {
        comp.add(c['AMC_type']);
      }
      setState(() {
        _amctypes = comp;
        _selectedamctype = comp.first;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _projects = getprojects();
    // getloginut();
  }

  @override
  Widget build(BuildContext context) {
    double swidth = MediaQuery.of(context).size.width;
    return Background(
      appbar: true,
      appbartitle: const Text("AMC Purchase"),
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
                                    // enabled: _isenabled,
                                    compareFn: (item1, item2) =>
                                        item1.pjc == item2.pjc,
                                    popupProps: const PopupProps.dialog(
                                        dialogProps: DialogProps(
                                          barrierDismissible: true,
                                          barrierLabel: "Dismiss",
                                        ),
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
                                        _amcitemdetail.clear();
                                        _selectedproduct = null;
                                        _selectedcomp = null;
                                        _selectedamcitemdetail = [];
                                        _selectedmodel = null;
                                        _selectedamctype = null;
                                        _selectedduration = null;
                                        _billDateController.clear();
                                        _billNumberController.clear();
                                        _billQuantityController.clear();
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
                            // enabled: _isenabled,
                            popupProps: const PopupProps.dialog(
                                dialogProps: DialogProps(
                                  barrierDismissible: true,
                                  barrierLabel: "Dismiss",
                                ),
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
                                _models.clear();
                                _amctypes.clear();
                                _selectedproduct = value;
                                checkrunningamc();
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
                            // enabled: _isenabled,
                            popupProps: const PopupProps.dialog(
                                dialogProps: DialogProps(
                                  barrierDismissible: true,
                                  barrierLabel: "Dismiss",
                                ),
                                // showSelectedItems: true,
                                showSearchBox: true),
                            // mode: Mode.dialog,
                            // showSelectedItems: true,
                            items: (filter, infiniteScrollProps) => _company,
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
                                _selectedcomp = value;
                                _models.clear();
                                _amcitemdetail.clear();
                                _amctypes.clear();
                                getmodel();
                                getitemdetail();
                              });
                            },
                            selectedItem: _selectedcomp,
                          )),

                      // if (_allowAssign)
                      Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: DropdownSearch<String>(
                            popupProps: const PopupProps.dialog(
                                dialogProps: DialogProps(
                                  barrierDismissible: true,
                                  barrierLabel: "Dismiss",
                                ),
                                showSelectedItems: true,
                                showSearchBox: true),
                            // mode: Mode.dialog,
                            // showSelectedItems: true,
                            items: (filter, infiniteScrollProps) => _models,
                            decoratorProps: const DropDownDecoratorProps(
                              decoration: InputDecoration(
                                labelText: "Model",
                                hintText: "Select Model",
                              ),
                            ),
                            // dropdownSearchDecoration: const InputDecoration(
                            // labelText: "Menu mode",
                            // hintText: "country in menu mode",
                            // ),
                            // popupItemDisabled: isItemDisabled,
                            onSelected: (value) {
                              setState(() {
                                _selectedmodel = value!;
                                getamctype();
                              });
                            },
                            selectedItem: _selectedmodel,
                            // showSearchBox: true,
                            // searchFieldProps: TextFieldProps(
                            //   cursorColor: Colors.blue,
                            // ),
                          )),
                      // if (_allowAssign)
                      Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: DropdownSearch<AMCModel>.multiSelection(
                            compareFn: (item1, item2) =>
                                item1.code == item2.code &&
                                item1.item == item2.item,
                            popupProps: const MultiSelectionPopupProps.dialog(
                                dialogProps: DialogProps(
                                  barrierDismissible: true,
                                  barrierLabel: "Dismiss",
                                ),
                                // showSelectedItems: true,
                                showSearchBox: true),
                            // mode: Mode.dialog,
                            // showSelectedItems: true,
                            items: (filter, infiniteScrollProps) =>
                                _amcitemdetail,
                            itemAsString: (item) {
                              return "${item.item} (${item.idatec})";
                            },
                            decoratorProps: const DropDownDecoratorProps(
                              decoration: InputDecoration(
                                labelText: "Item",
                                hintText: "Select Item",
                              ),
                            ),

                            onSelected: (value) {
                              setState(() {
                                _selectedamcitemdetail = value;
                                getbilldetail();
                              });
                            },
                            selectedItems: _selectedamcitemdetail,
                          )),
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: InputField(
                          onTap: () => showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          ).then((selectedDate) {
                            if (selectedDate != null) {
                              setState(() {
                                _billDateController.text =
                                    "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";
                              });
                            }
                          }),
                          label: "Bill Date",
                          controller: _billDateController,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: InputField(
                          label: "Bill Number",
                          controller: _billNumberController,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: InputField(
                          label: "Bill Quantity",
                          controller: _billQuantityController,
                          onChanged: (val) {
                            getrate(custom: true);
                          },
                        ),
                      ),
                      Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: DropdownSearch<String>(
                            popupProps: const PopupProps.dialog(
                                dialogProps: DialogProps(
                                  barrierDismissible: true,
                                  barrierLabel: "Dismiss",
                                ),
                                showSelectedItems: true,
                                showSearchBox: true),
                            // mode: Mode.dialog,
                            // showSelectedItems: true,
                            items: (filter, infiniteScrollProps) => _amctypes,
                            decoratorProps: const DropDownDecoratorProps(
                              decoration: InputDecoration(
                                labelText: "AMC Type",
                                hintText: "Select AMC Type",
                              ),
                            ),
                            // dropdownSearchDecoration: const InputDecoration(
                            // labelText: "Menu mode",
                            // hintText: "country in menu mode",
                            // ),
                            // popupItemDisabled: isItemDisabled,
                            onSelected: (value) {
                              setState(() {
                                _selectedamctype = value!;
                                _selectedduration = null;
                                _rateController.clear();
                                _amountController.clear();
                              });
                            },
                            selectedItem: _selectedamctype,
                            // showSearchBox: true,
                            // searchFieldProps: TextFieldProps(
                            //   cursorColor: Colors.blue,
                            // ),
                          )),
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: InputField(
                          onTap: () => showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          ).then((selectedDate) {
                            if (selectedDate != null) {
                              setState(() {
                                _amcstartDateController.text =
                                    DateFormat('dd/MM/yyyy')
                                        .format(selectedDate);
                              });
                            }
                          }),
                          label: "AMC Start Date",
                          controller: _amcstartDateController,
                        ),
                      ),
                      Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: DropdownSearch<String>(
                            // enabled: _isenabled,
                            popupProps: const PopupProps.dialog(
                                dialogProps: DialogProps(
                                  barrierDismissible: true,
                                  barrierLabel: "Dismiss",
                                ),
                                showSelectedItems: true,
                                showSearchBox: true),
                            // mode: Mode.dialog,
                            // showSelectedItems: true,
                            items: (filter, infiniteScrollProps) => [
                              "12 Months",
                              "24 Months",
                              "36 Months",
                            ],
                            decoratorProps: const DropDownDecoratorProps(
                              decoration: InputDecoration(
                                labelText: "AMC Duration",
                                hintText: "Select AMC Duration",
                              ),
                            ),

                            onSelected: (value) {
                              setState(() {
                                // _company.clear();
                                _selectedduration = value;
                                getrate();
                              });
                            },
                            selectedItem: _selectedduration,
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
                          label: "Rate $_ratetype",
                          controller: _rateController,
                          // readOnly: true,
                          onChanged: (p0) {
                            getrate(custom: true);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: InputField(
                          label: "Amount",
                          controller: _amtController,
                          readOnly: true,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: InputField(
                          label: "GST Amount",
                          controller: _gstamtController,
                          readOnly: true,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: InputField(
                          label: "Total Amount",
                          controller: _amountController,
                          readOnly: true,
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
                                        submitdata("online");
                                      }
                                    }),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromRGBO(252, 101, 8, 1),
                                  foregroundColor: Colors.white),
                              child: const Text("Pay Now"),
                            ),
                            // ElevatedButton(
                            //   onPressed: _isLoading
                            //       ? null
                            //       : (() {
                            //           if (_formkey.currentState!.validate()) {
                            //             submitdata("cash");
                            //           }
                            //         }),
                            //   style: ElevatedButton.styleFrom(
                            //       backgroundColor:
                            //           const Color.fromRGBO(252, 101, 8, 1),
                            //       foregroundColor: Colors.white),
                            //   child: const Text("Pay Cash"),
                            // ),
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
