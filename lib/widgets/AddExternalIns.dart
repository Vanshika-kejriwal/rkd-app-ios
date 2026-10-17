import 'dart:convert';

import 'package:business_app/constants.dart';
import 'package:business_app/models/utils.dart';
import 'package:business_app/screens/project_registration.dart';
import 'package:business_app/widgets/background.dart';
import 'package:business_app/widgets/input_field.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddExternalIns extends StatefulWidget {
  const AddExternalIns({super.key});

  @override
  State<AddExternalIns> createState() => _AddExternalInsState();
}

class _AddExternalInsState extends State<AddExternalIns> {
  final GlobalKey<DropdownSearchState<Project>> _projectkey =
      GlobalKey<DropdownSearchState<Project>>();
  final _searchcontroller = TextEditingController();
  final _dealernamecontroller = TextEditingController();
  final _billQuantityController = TextEditingController();
  final _billDateController = TextEditingController();
  final _billNumberController = TextEditingController();
  String _loginut = '';
  List<Project> _projects = [];
  bool _isprojLoading = false;
  bool _isLoading = false;
  Project? selectedItem;
  LeadProduct? selectedcomp;
  LeadProduct? selectedproduct;
  List<LeadProduct> comp = [];
  List<InvItem> items = [];
  InvItem? selecteditemdetail;
  late Future<List<LeadProduct>>? product;
  @override
  void initState() {
    super.initState();
    getcustomerprojects();
    // _projects = [Project(pjc: "Add New", pname: "Add New", custtype: "")];
    product = getcomp();
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

  getitems(String mc) async {
    List<InvItem> data = [];
    // List<LeadProduct> uniqueData = [];
    var response =
        await http.get(Uri.parse("$baseuri/api/getitemsinst/?mc=$mc"));
    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body);
      // data.add(
      //     LeadProduct(company: "Add New", product: "Add New", mc: "Add New"));
      data.addAll((jsonData as List)
          .map((e) => InvItem(code: e['CODE'], name: e['F2'], mc: e["MC"]))
          .toList());
      // uniqueData = {for (var item in data) item.product: item}.values.toList();
      setState(() {
        items = data;
      });
    }
    // return data;
  }

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
      'PJC': selectedItem!.pjc,
      'SOLD_BY': _dealernamecontroller.text,
      // 'PNAME': _selectedproject!.pname,
      'LEADFORP': selectedproduct?.product,
      'CNAME': selectedcomp!.company,
      // 'LEAD_DATE': DateTime.now().toString().split(" ")[0],
      'MC':selectedcomp!.mc,
      'CODE': selecteditemdetail?.code,
      'ITEM': selecteditemdetail?.name,
      'CDATE': _billDateController.text,
      'VNO': _billNumberController.text,
      'QTY': _billQuantityController.text,
      
      // 'Payment_mode': paymentMethod,
    };
    final resp = await http.post(Uri.parse('$baseuri/api/createextins/'),
        body: jsonEncode(data), headers: {"Content-Type": "application/json"});
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      setState(() {
        _isLoading = false;
      });
      final result = json.decode(resp.body);
      final String message = result['message'];
      final String amcNumber = result['amc_number'];

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
        selectedItem = null;
        selectedproduct = null;
        selectedcomp = null;
        selecteditemdetail = null;
        // _selectedleadton = null;

        _billDateController.clear();
        _billNumberController.clear();
        _billQuantityController.clear();
      });
      // Navigator.of(context).pop();
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

    // Map<String, String> newQueryParams = {};
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

  Future<List<LeadProduct>>? getcomp() async {
    List<LeadProduct> data = [];
    List<LeadProduct> uniqueData = [];
    var response =
        await http.get(Uri.parse("$baseuri/api/getmmastcomp/?addins=true"));
    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body);
      // data.add(
      //     LeadProduct(company: "Add New", product: "Add New", mc: "Add New"));
      data.addAll((jsonData as List)
          .map((e) =>
              LeadProduct(company: e["FNM"], product: e["PNM"], mc: e["MC"]))
          .toList());
      uniqueData = {for (var item in data) item.product: item}.values.toList();
      // setState(() {
      //   product = uniqueData;
      // });
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Background(
        childs: SafeArea(
            child: Center(
          child: SizedBox(
            child: Form(
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
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
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
                            compareFn: (item1, item2) => item1.pjc == item2.pjc,
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
                              ),
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
                            onSelected: (data) async {
                              if (data!.pname == "Add New") {
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
                                    getcustomerprojects();
                                    // _projects = [
                                    //   Project(
                                    //       pjc: "Add New",
                                    //       pname: "Add New",
                                    //       custtype: "")
                                    // ];
                                  });
                                }
                              } else {
                                setState(() {
                                  selectedItem = data;
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
                        padding: EdgeInsets.all(5),
                        child: InputField(
                            label: "Sold By (Dealer)",
                            controller: _dealernamecontroller)),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: FutureBuilder(
                          future: product,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            // Show error message if API fails
                            if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error: ${snapshot.error}'));
                            }

                            // Show message if data is empty
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Center(child: Text('No data found'));
                            }
                            if (snapshot.hasData) {
                              return DropdownSearch<LeadProduct>(
                                  // key: _projectkey,
                                  // controller
                                  compareFn: (item1, item2) =>
                                      item1.mc == item2.mc,
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
                                    ),
                                  ),
                                  // mode: Mode.dialog,
                                  // showSelectedItems: true,

                                  items: (filter, infiniteScrollProps) {
                                    final allProducts = snapshot.data ?? [];
                                    // Filter unique products by their name while keeping the LeadProduct object type
                                    final seen = <String>{};
                                    return allProducts
                                        .where((e) => seen.add(e.product))
                                        .toList();
                                  },
                                  itemAsString: (item) {
                                    return item.product;
                                  },
                                  filterFn: (item, filter) {
                                    // This function determines which items are shown in the dropdown
                                    // based on the user's input (the 'filter' string).
                                    // It's case-insensitive for better UX.
                                    // print(
                                    //     'filterFn - item: "$item", filter: "$filter"');
                                    return item.product == "Add New" ||
                                        item.product
                                            .toLowerCase()
                                            .contains(filter.toLowerCase());
                                  },
                                  decoratorProps: const DropDownDecoratorProps(
                                    decoration: InputDecoration(
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
                                  onSelected: (data) async {
                                    setState(() {
                                      selectedproduct = data;
                                    });
                                    comp.clear();
                                    var prod = await product;
                                    // product.add(LeadProduct(
                                    //     company: "Add New",
                                    //     product: "Add New",
                                    //     mc: "Add New"));
                                    comp.addAll(prod!
                                        .where((element) =>
                                            element.product == data?.product)
                                        .map((e) => LeadProduct(
                                            company: e.company,
                                            product: e.product,
                                            mc: e.mc))
                                        .toList());
                                  },
                                  selectedItem: selectedproduct
                                  // showSearchBox: true,
                                  // searchFieldProps: TextFieldProps(
                                  //   cursorColor: Colors.blue,
                                  // ),
                                  );
                            } else {
                              return Text("${snapshot.error}");
                            }
                          }),
                    ),
                    Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: DropdownSearch<LeadProduct>(
                            // key: _projectkey,
                            // controller
                            compareFn: (item1, item2) => item1.mc == item2.mc,
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
                              ),
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
                            decoratorProps: const DropDownDecoratorProps(
                              decoration: InputDecoration(
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
                              setState(() {
                                selectedcomp = data;

                                // product.clear();
                                // product.add(LeadProduct(
                                //     company: "Add New",
                                //     product: "Add New",
                                //     mc: "Add New"));
                                // product.addAll(comp
                                //     .where((element) =>
                                //         element.company ==
                                //             data.company &&
                                //         element.product !=
                                //             "Add New")
                                //     .map((e) => LeadProduct(
                                //         company: e.company,
                                //         product: e.product,
                                //         mc: e.mc))
                                //     .toList());
                              });
                              getitems(data?.mc as String);
                              // getprojdetail(data);
                            },
                            selectedItem: selectedcomp
                            // showSearchBox: true,
                            // searchFieldProps: TextFieldProps(
                            //   cursorColor: Colors.blue,
                            // ),
                            )),
                    Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: DropdownSearch<InvItem>(
                            // key: _projectkey,
                            // controller
                            compareFn: (item1, item2) =>
                                item1.code == item2.code,
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
                              ),
                            ),
                            // mode: Mode.dialog,
                            // showSelectedItems: true,

                            items: (filter, infiniteScrollProps) => items,
                            itemAsString: (item) {
                              return item.name;
                            },
                            filterFn: (item, filter) {
                              // This function determines which items are shown in the dropdown
                              // based on the user's input (the 'filter' string).
                              // It's case-insensitive for better UX.
                              // print(
                              //     'filterFn - item: "$item", filter: "$filter"');
                              return item.name
                                  .toLowerCase()
                                  .contains(filter.toLowerCase());
                            },
                            decoratorProps: const DropDownDecoratorProps(
                              decoration: InputDecoration(
                                labelText: "Item*",
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
                              setState(() {
                                selecteditemdetail = data;

                                // product.clear();
                                // product.add(LeadProduct(
                                //     company: "Add New",
                                //     product: "Add New",
                                //     mc: "Add New"));
                                // product.addAll(comp
                                //     .where((element) =>
                                //         element.company ==
                                //             data.company &&
                                //         element.product !=
                                //             "Add New")
                                //     .map((e) => LeadProduct(
                                //         company: e.company,
                                //         product: e.product,
                                //         mc: e.mc))
                                //     .toList());
                              });
                              // getitems(data?.mc as String);
                              // getprojdetail(data);
                            },
                            selectedItem: selecteditemdetail
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
                        // onChanged: (val) {
                        //   getrate(custom: true);
                        // },
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
                                    submitdata("online");
                                  }),
                            style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromRGBO(252, 101, 8, 1),
                                foregroundColor: Colors.white),
                            child: const Text("Save Details"),
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
        )),
        appbar: true,
        appbartitle: Text("Add External Installation"),
        appbaractions: []);
  }
}
