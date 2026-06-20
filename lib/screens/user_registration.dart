// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';

// import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:business_app/screens/dashboard.dart';
import 'package:business_app/services/network_provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:business_app/widgets/input_field.dart';
// Removed go_router import
import 'package:http/http.dart' as http;
import "package:business_app/constants.dart";
import 'package:provider/provider.dart';
// import 'package:quickalert/models/quickalert_type.dart';
// import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserRegistration extends StatefulWidget {
  bool fromLogin;
  UserRegistration({super.key, this.fromLogin = false});

  @override
  State<UserRegistration> createState() => _UserRegistrationState();
}

class _UserRegistrationState extends State<UserRegistration> {
  final _namecontroller = TextEditingController();
  String _selectedut = '';
  String _selectedcomp = '';
  final String _selectedproj = '';
  String _selectedsuppliercomp = '';
  List<String> _company = [];
  final List<String> _projects = [];
  List<String> _suppliercompany = [];
  // final _desigcontroller = TextEditingController();
  final _add1controller = TextEditingController();
  final _add2controller = TextEditingController();
  final _pincontroller = TextEditingController();
  // final _statecontroller = TextEditingController();
  final _citycontroller = TextEditingController();
  final _districtcontroller = TextEditingController();
  final _mobilecontroller = TextEditingController();
  final _emailcontroller = TextEditingController();
  final _dobcontroller = TextEditingController();
  final _domcontroller = TextEditingController();
  final _emailotpcontroller = TextEditingController();
  final _newproductcontroller = TextEditingController();
  final _newcompcontroller = TextEditingController();
  final _linkotp = TextEditingController();
  bool _isLoading = false;
  bool _verifyEmail = false;
  bool _edit = false;
  bool _isVerifiedEmail = false;
  final _formkey = GlobalKey<FormState>();
  DateTime? _dobdate;
  DateTime? _domdate;
  String? _selectedState;
  String? _selectedDistrict;
  final List<String> _districts = [];
  Timer? _reloadTimer;

  Future<List<String>> getut() async {
    try {
      final response = await http.get(Uri.parse('$baseuri/api/ut/'));
      final body = json.decode(response.body);
      Set<String> user = {};
      if (response.statusCode == 200) {
        user.clear();
        for (var ut in body) {
          user.add(ut["UT"] != "Employee"? ut["UT"] : "Employee (RKD)");
        }
      }
      return user.toList();
    } catch (e) {
      return [];
    }
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

  Future<void> getcomp() async {
    final response =
        await http.get(Uri.parse('$baseuri/api/category/?ut=$_selectedut'));
    final body = json.decode(response.body);
    Set<String> comp = {};
    if (response.statusCode == 200) {
      for (var c in body) {
        comp.add(c["PRODUCT_TYPE"] ?? "");
      }
      // comp.remove("ADD NEW/ OTHERS");
      if (mounted) {
        setState(() {
          _company = comp.toList();
          // print(_company);
          _company.add("Add New");
        });
      }
    }
  }

  Future<void> getsuppliercomp() async {
    final response =
        await http.get(Uri.parse('$baseuri/api/leadforc/?ut1=$_selectedcomp'));
    final body = json.decode(response.body);
    Set<String> comp = {};
    if (response.statusCode == 200) {
      for (var c in body) {
        comp.add(c["CO_NAME"]);
      }
      setState(() {
        _suppliercompany = comp.toList();
        _suppliercompany.add("Add New");
        // print(_company);
      });
    }
  }

  Future<void> getprojects() async {
    final response = await http
        .get(Uri.parse('$baseuri/api/pnamelist/?custtype=$_selectedcomp'));
    final body = json.decode(response.body);
    if (response.statusCode == 200) {
      for (var c in body) {
        String name = c['PNAME'];
        _projects.add(name);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // getuser();
  }

  void fetchmob() async {
    var sharedpref = await SharedPreferences.getInstance();
    var usermob = sharedpref.getString("Mobile");
    _mobilecontroller.text = usermob!;
  }

  Future<void> getuser() async {
    var sharedpref = await SharedPreferences.getInstance();
    var usermob = sharedpref.getString("Mobile");
    _mobilecontroller.text = usermob!;
    final connectivityProvider =
        Provider.of<NetworkProvider>(context, listen: false);
    try {
      final response = await http.get(
          Uri.parse('$baseuri/api/user/?mobile=${_mobilecontroller.text}'));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body.isNotEmpty) {
          if (mounted) {
            setState(() {
              _namecontroller.text = body[0]['NAME'] ?? '';
              _add1controller.text = body[0]['ADD1'] ?? '';
              _add2controller.text = body[0]['ADD2'] ?? '';
              _pincontroller.text = body[0]['PIN'] ?? '';
              _citycontroller.text = body[0]['CITY'] ?? '';
              _emailcontroller.text = body[0]['EMAIL'] ?? '';
              _dobcontroller.text = body[0]['DOB'] ?? '';
              _domcontroller.text = body[0]['DOM'] ?? '';
              _selectedut = body[0]['UT'] ?? '';
              _selectedcomp = body[0]['PRODUCT_TYPE'] ?? '';
              _selectedsuppliercomp = body[0]['COMPANY_NAME'] ?? '';
              _selectedState = body[0]['STATE'] ?? '';
              _selectedDistrict = body[0]['DIST'] ?? '';
              _edit = true;
              if (_selectedState != null && _selectedState!.isNotEmpty) {
                getDistricts();
              }
            });
          }
        }
        getcomp();
        // print("Pincode doesnt exists");
      }
      // } catch (e) {
      //   print(e);
      // }
    } on SocketException catch (_) {
      connectivityProvider.setConnected(false);
    } on http.ClientException catch (_) {
      connectivityProvider.setConnected(false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get the current connectivity status using listen: true
    // This tells Flutter to call didChangeDependencies when the provider changes
    final isConnected = Provider.of<NetworkProvider>(context).isOnline;

    // Condition to restart API call:
    // 1. Internet is currently connected
    // 2. The previous state was NOT connected
    // 3. We are not in the middle of a fetch
    if (isConnected) {
      _reloadTimer?.cancel();

      // Start a new timer to delay the API call
      _reloadTimer = Timer(const Duration(seconds: 2), () {
        getuser(); // Call _fetchData() after a 3-second delay
      });
    }

    // Update the previous state for the next check
    // _lastConnectivityStatus = isConnected;

    // If we lose connection, reset _dataLoaded so it will fetch again
    if (!isConnected) {
      _reloadTimer?.cancel();
      // setState(() {
      //   _isdataLoaded = false;
      // });
    }
  }

  @override
  void dispose() {
    // It's crucial to cancel the timer when the widget is disposed
    _reloadTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double swidth = MediaQuery.of(context).size.width;
    // double sheight = MediaQuery.of(context).size.height;
    return Center(
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
                          future: getut(),
                          builder: ((context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              return DropdownSearch<String>(
                                enabled: !_edit,
                                popupProps: const PopupProps.dialog(
                                    showSelectedItems: true,
                                    showSearchBox: true),
                                // mode: Mode.dialog,
                                // showSelectedItems: true,
                                items: (filter, infiniteScrollProps) => snapshot.data!,
                                decoratorProps:
                                    const DropDownDecoratorProps(
                                  decoration: InputDecoration(
                                    labelText: "User Type",
                                    hintText: "Select a User Type",
                                  ),
                                ),
                                autoValidateMode:
                                    AutovalidateMode.onUserInteraction,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return "Select a User Type";
                                  }
                                  return null;
                                },
                                // dropdownSearchDecoration: const InputDecoration(
                                // labelText: "Menu mode",
                                // hintText: "country in menu mode",
                                // ),
                                // popupItemDisabled: isItemDisabled,
                                onSelected: (value) {
                                  setState(() {
                                    _company.clear();
                                    _selectedcomp = '';
                                    _selectedut = value!.contains("Employee") ? "Employee" : value;
                                    getcomp();
                                  });
                                },
                                selectedItem: _selectedut,
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
                    ),
                    if (_selectedut == "Supplier")
                      Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: DropdownSearch<String>(
                            popupProps: const PopupProps.dialog(
                                showSelectedItems: true, showSearchBox: true),
                            // mode: Mode.dialog,
                            // showSelectedItems: true,
                            items: (filter, infiniteScrollProps) => _company,
                            decoratorProps:
                                const DropDownDecoratorProps(
                              decoration: InputDecoration(
                                labelText: "Category",
                                hintText: "Select a Category",
                              ),
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Select a sub-category";
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
                            onSelected: (value) async {
                              if (value == "Add New") {
                                var result = await openAddNewDialog();
                                setState(() {
                                  _selectedcomp = result["Product_type"];
                                  _selectedsuppliercomp = result["company"];
                                });
                              } else {
                                setState(() {
                                  _selectedcomp = value!;
                                  _suppliercompany.clear();
                                  if (_selectedut == "Supplier") {
                                    getsuppliercomp();
                                  }
                                });
                              }
                            },
                            selectedItem: _selectedcomp,
                            // showSearchBox: true,
                            // searchFieldProps: TextFieldProps(
                            //   cursorColor: Colors.blue,
                            // ),
                          )),
                    if (_selectedut == "Supplier")
                      Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: DropdownSearch<String>(
                            popupProps: const PopupProps.dialog(
                                showSelectedItems: true, showSearchBox: true),
                            // mode: Mode.dialog,
                            // showSelectedItems: true,
                            items: (filter, infiniteScrollProps) => _suppliercompany,
                            decoratorProps:
                                const DropDownDecoratorProps(
                              decoration: InputDecoration(
                                labelText: "Company",
                                hintText: "Select a Company",
                              ),
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Select a Company";
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
                            onSelected: (value) async {
                              if (value == "Add New") {
                                setState(() {
                                  _newproductcontroller.text = _selectedcomp;
                                });
                                var result = await openAddNewDialog();
                                setState(() {
                                  _selectedcomp = result["Product_type"];
                                  _selectedsuppliercomp = result["company"];
                                });
                              } else {
                                setState(() {
                                  _selectedsuppliercomp = value!;
                                });
                              }
                            },
                            selectedItem: _selectedsuppliercomp,
                            // showSearchBox: true,
                            // searchFieldProps: TextFieldProps(
                            //   cursorColor: Colors.blue,
                            // ),
                          )),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: InputField(
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Name is required";
                          }
                          return null;
                        },
                        label: "Name *",
                        controller: _namecontroller,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: InputField(
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Address 1 is required";
                          }
                          return null;
                        },
                        label: "Address Line 1 *",
                        controller: _add1controller,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: InputField(
                        label: "Adress Line 2",
                        controller: _add2controller,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: FutureBuilder<List<String>>(
                          future: getStates(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              return DropdownSearch<String>(
                                // enabled: _editmode,
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
                                  itemBuilder: (context, item, isSelected, onTap) {
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
                                  decoration: InputDecoration(
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
                          // enabled: _editmode,
                          popupProps: const PopupProps.dialog(
                              showSelectedItems: true, showSearchBox: true),
                          // mode: Mode.dialog,
                          // showSelectedItems: true,
                          items: (filter, infiniteScrollProps) => _districts,
                          decoratorProps: const DropDownDecoratorProps(
                            decoration : InputDecoration(
                              labelText: "District",
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
                        // readOnly: !_editmode,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: InputField(
                        label: "PIN Code",
                        controller: _pincontroller,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: InputField(
                        label: "Mobile Number",
                        controller: _mobilecontroller,
                        readOnly: true,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: InputField(
                        validator: (value) {
                          if (!_checkEmailFn(value!) && value.isNotEmpty) {
                            return 'Please enter a valid Email or Blank';
                          }
                          if (_verifyEmail && !_isVerifiedEmail) {
                            return 'Please Verify Email';
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
                          });
                        },
                        suff: _verifyEmail
                            ? TextButton(
                                onPressed: () async {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text("OTP sent on Mail"),
                                          backgroundColor: Colors.green));
                                  final res = await http.post(
                                      Uri.parse(
                                          '$baseuri/api/send_otp_verify/'),
                                      body: {"send_to": _emailcontroller.text});
                                  if (res.statusCode == 200) {
                                    _emailotpcontroller.clear();
                                    final otp = await openDialog();
                                    final resver = await http.post(
                                        Uri.parse(
                                            '$baseuri/api/validate_otp_email_omob/'),
                                        body: {
                                          "phone_num": _emailcontroller.text,
                                          "otp": otp
                                        });
                                    if (resver.statusCode == 200) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  "Email Verified Successfully"),
                                              backgroundColor: Colors.green));
                                      setState(() {
                                        _isVerifiedEmail = true;
                                        _verifyEmail = false;
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  "Email couldnot be verified. Please try again."),
                                              backgroundColor: Colors.red));
                                    }
                                  }
                                },
                                child: const Text("Verify Email"))
                            : null,
                        label: "Email",
                        controller: _emailcontroller,
                        keyboardtype: TextInputType.emailAddress,
                      ),
                    ),
                    // Padding(
                    //   padding: const EdgeInsets.all(5.0),
                    //   child: InputField(
                    //     label: "Date Of Birth",
                    //     controller: _dobcontroller,
                    //     readOnly: true,
                    //     onTap: () {
                    //       _selectdob();
                    //     },
                    //   ),
                    // ),
                    // Padding(
                    //   padding: const EdgeInsets.all(5.0),
                    //   child: InputField(
                    //     label: "Date Of Marriage",
                    //     controller: _domcontroller,
                    //     readOnly: true,
                    //     onTap: () {
                    //       _selectdom();
                    //     },
                    //   ),
                    // ),
                    if (_isLoading)
                      const Center(
                          child:
                              CircularProgressIndicator(color: Colors.brown)),
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
                                  var sharedpref =
                                      await SharedPreferences.getInstance();
                                  sharedpref.setString("UT", _selectedut);
                                  sharedpref.setString(
                                      "NAME", _namecontroller.text);
                                  final Map<String, dynamic> data = {
                                    'UT': _selectedut,
                                    'PRODUCT_TYPE': _selectedcomp,
                                    'COMPANY_NAME': _selectedsuppliercomp,
                                    'NAME': _namecontroller.text,
                                    'ADD1': _add1controller.text,
                                    'ADD2': _add2controller.text,
                                    'PIN': _pincontroller.text,
                                    'STATE': _selectedState,
                                    'DIST': _selectedDistrict,
                                    'CITY': _citycontroller.text,
                                    'MOBILE1': _mobilecontroller.text,
                                    'EMAIL': _emailcontroller.text,
                                    // 'GSTNO': '',
                                    'DOB': _dobcontroller.text,
                                    'DOM': _domcontroller.text
                                  };
                                  final resp = await http.post(
                                      Uri.parse('$baseuri/api/user/'),
                                      body: data);
                                  if (resp.statusCode == 200 ||
                                      resp.statusCode == 201) {
                                      final respdata = json.decode(resp.body);
                                      final userCode = respdata['user_code'];
                                      sharedpref.setString("UC", userCode);
                                    setState(() {
                                      _isLoading = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: const Text(
                                                "Data saved successfully"),
                                            backgroundColor:
                                                Colors.green[400]));
                                    if (widget.fromLogin) {
                                      var ut = await SharedPreferences.getInstance();
                                      var userType = ut.getString("UT") ?? "";
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              Dashboard(ut: userType),
                                        ),
                                      );
                                    } else {
                                      Navigator.pop(context);
                                    }
                                  } else {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
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
                    ),
                    
                  ],
                ),
              ),
            )),
      ),
    );
  }

  Future<void> _selectdob() async {
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime(2100));
    if (picked != null) {
      setState(() {
        _dobcontroller.text = picked.toString().split(" ")[0];
      });
    }else{
      setState(() {
        _dobcontroller.clear();
      });
    }
    setState(() {
      _dobdate = picked;
    });
  }

  Future<void> _selectdom() async {
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime(2100));
    if (picked != null) {
      setState(() {
        _domcontroller.text = picked.toString().split(" ")[0];
      });
    }else{
      setState(() {
        _domcontroller.clear();
      });
    }
    setState(() {
      _dobdate = picked;
    });
  }

  bool _checkEmailFn(String value) {
    final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
    return emailRegex.hasMatch(value);
  }

  Future<String?> openDialog() => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Verify Email"),
          content: InputField(
              label: "Enter OTP from Mail", controller: _emailotpcontroller),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(_emailotpcontroller.text);
                },
                child: const Text("SUBMIT"))
          ],
        ),
      );

  Future<dynamic> openAddNewDialog() => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Verify Email"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InputField(
                      label: "Add New Product Type",
                      controller: _newproductcontroller),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InputField(
                      label: "Add New Company", controller: _newcompcontroller),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop({
                    "Product_type": _newproductcontroller.text,
                    "company": _newcompcontroller.text,
                  });
                },
                child: const Text("SUBMIT"))
          ],
        ),
      );
}
