import 'dart:convert';
import 'dart:io';

// import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:business_app/constants.dart';
import 'package:business_app/models/utils.dart';
import 'package:business_app/screens/pdfview.dart';
import 'package:business_app/widgets/background.dart';
import 'package:business_app/widgets/input_field.dart';
import 'package:business_app/widgets/inv_list.dart';
import 'package:business_app/widgets/outstanding.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllTrans extends StatefulWidget {
  final String leadtype;
  final Widget? child;
  const AllTrans({super.key, required this.leadtype, this.child});

  @override
  State<AllTrans> createState() => _AllTransState();
}

class _AllTransState extends State<AllTrans> with TickerProviderStateMixin {
  final String _name = '';
  String _type = "";
  String _ut = "";
  String _pjc = "";
  String? _billno;
  String searchQuery = '';
  late final SearchQueryModel _searchQueryModel;
  final List<String> _selectedItemsassignedby = ["ALL"];
  List<String> _empnames = ["ALL"];
  final List<String> _selectedItemsassignedto = [];
  Map<String, dynamic> filters = {};
  Map<String, List<String>>? _selectedfiltervalues;
  final List<String> _filteredProjects = [];
  final List<String> _filteredProducts = [];
  final _searchcontroller = TextEditingController();
  final _billnosearchcontroller = TextEditingController();
  bool _isprojLoading = false;
  // enum DetailOrSummary { Detail, Summary }
  List<Amast> _projects = [];
  List<Amast> _company = [];
  List<InvItem> _hilightitems = [];
  List<InvItem> _selectedhilightitems = [];
  Amast? _selectedproject;
  int _selectedBillDetailType = 1;
  List<Amast> _selectedcompany = [];
  final GlobalKey<DropdownSearchState<Amast>> _projectkey =
      GlobalKey<DropdownSearchState<Amast>>();
  DateTimeRange? _filteredDate;
  final TextEditingController _datecontroller = TextEditingController();
  Future<String> loggedInUser() async {
    var sharedpref = await SharedPreferences.getInstance();
    var username = sharedpref.getString('NAME')!;
    var mob = sharedpref.getString('Mobile')!;
    // if (kDebugMode) {
    //   print(username);
    // }
    return "$username - $mob";
  }

  Future<void> fetchuser() async {
    var usr = await loggedInUser();
    if (mounted) {
      setState(() {
        _selectedItemsassignedto.add(usr);
      });
    }
    // print(usr);
    // print(_selectedItemsassignedto);
  }

  Future<void> getnames() async {
    var usr = await loggedInUser();
    final response = await http.get(Uri.parse('$baseuri/api/leadnames/'));
    final body = json.decode(response.body);
    final Set<String> names = {};
    // List<String> names = [];
    if (response.statusCode == 200) {
      names.clear();
      names.add("ALL");
      for (var c in body) {
        names.add(c["NAME"]);
      }
      // print(_empnames.toSet());
      if (mounted) {
        setState(() {
          _empnames = names.toList();
          _selectedItemsassignedto.add(usr);
        });
        fetchuser();
      }
      // _selectedItemsassignedto.add(usr);
    }
  }

  void filterlist(Map<String, List<String>> filterval) {
    if (mounted) {
      setState(() {
        _selectedfiltervalues = filterval;
      });
    }
  }

  Future<List<Amast>> getcustproj() async {
    http.Response response;
    var sharedpref = await SharedPreferences.getInstance();
    var ut = sharedpref.getString("UT");
    var mob = sharedpref.getString("Mobile");
    setState(() {
      _ut = ut!;
    });
    List<Amast> projects = [];
    if (ut!.toLowerCase() == "consumer" ||
        ut.toLowerCase() == "contractor" ||
        ut.toLowerCase() == "supplier") {
      response =
          await http.get(Uri.parse('$baseuri/api/custprojamastlist/?mob=$mob'));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        for (var c in body) {
          // String name = c['PNAME'];
          // String ctype = c['CUSTTYPE'];
          projects.add(Amast(ac: c["AC"], name: c["NAME"]));
        }
      }
    }

    return projects;
    // setState(() {
    //   _projects = projects;
    // });
  }

  Future<void> getconsumerproj() async {
    var sharedpref = await SharedPreferences.getInstance();
    var ut = sharedpref.getString("UT");
    setState(() {
      _ut = ut!;
    });
    if (ut!.toLowerCase() == "consumer" ||
        ut.toLowerCase() == "contractor" ||
        ut.toLowerCase() == "supplier") {
      final fetchedProjects = await getcustproj();

      if (!mounted) return; // Always check if the widget is still in the tree

      setState(() {
        _projects = fetchedProjects;
        if (fetchedProjects.isNotEmpty) {
          _pjc = _projects[0].ac;
          _selectedproject = _projects[0];
        }
        // Update the list
        // Hide loading indicator
      });
    } else {
      return;
    }

    // if (_projectkey.currentState != null && fetchedProjects.isNotEmpty) {
    //   // Use a post-frame callback to ensure the widget has been rebuilt
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     _projectkey.currentState!.openDropDownSearch();
    //   });
    // }
  }

  Future<List<Amast>> getrkdprojects({String? searchterm}) async {
    Uri uri;
    if (kDebugMode) {
      uri = Uri.http(
        searchdevbaseuri,
        '/api/amastnamelist/',
      );
    } else {
      uri = Uri.https(
        searchprodbaseuri,
        '/api/amastnamelist/',
      );
    }

    Map<String, String> newQueryParams = {};
    List<Amast> proj = [];

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
        uri = Uri.http(searchdevbaseuri, '/api/amastnamelist/', {
          'searchterm': searchlist,
          'type': _type // The correct way to pass a list
        });
      } else {
        uri = Uri.http(searchprodbaseuri, '/api/amastnamelist/', {
          'searchterm': searchlist,
          'type': _type // The correct way to pass a list
        });
      }
      // var params =
      //     searchlist.map((term) => MapEntry('searchterm', term)).toList();
      // newQueryParams = Map.fromEntries(params);
      // print(newQueryParams);
    }
    // if (newQueryParams.isNotEmpty) {
    //   uri = uri.replace(queryParameters: newQueryParams);
    // }
    final response = await http.get(uri);
    final body = json.decode(response.body);

    if (response.statusCode == 200 && body is List && body.isNotEmpty) {
      for (var c in body) {
        // String name = c['PNAME'];
        // String pjc = c["PJC"];
        proj.add(Amast(ac: c["AC"], name: c["NAME"]));
      }
    }
    return proj;
  }

  Future<void> _fetchprojectsAndOpenDropdown() async {
    // Fetch your data
    setState(() {
      _isprojLoading = true;
    });
    final fetchedProjects =
        await getrkdprojects(searchterm: _searchcontroller.text);

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

  @override
  void initState() {
    super.initState();
    _searchQueryModel = SearchQueryModel();
    getconsumerproj();
    if (kDebugMode) {
      print(widget.leadtype);
    }
    setState(() {
      _type = widget.leadtype;
      _filteredDate = getCurrentFinancialYear();
      _datecontroller.text =
          "${DateFormat("dd/MM/yyyy").format(_filteredDate!.start)}-${DateFormat("dd/MM/yyyy").format(_filteredDate!.end)}";

      // _selectedItemsassignedto.add();
    });
    // fetchuser();
  }

  getcompany() async {
    http.Response response;
    List<Amast> company = [Amast(ac: "00", name: "ALL")];

    response = await http.get(Uri.parse(
        '$baseuri/api/invcompanylist/?ac=${_selectedproject!.ac}&start=${_filteredDate!.start.toString().split(" ")[0]}&end=${_filteredDate!.end.toString().split(" ")[0]}'));
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      for (var c in body) {
        // String name = c['PNAME'];
        // String ctype = c['CUSTTYPE'];
        company.add(Amast(ac: c["MC"], name: "${c["PNM"]} - ${c["FNM"]}"));
      }
    }
    setState(() {
      _selectedcompany = [company[0]];
      _selectedhilightitems = [];
      _company = company;
      getitemsforhilight();
    });
    // return company;
  }

  getitemsforhilight() async {
    http.Response response;
    List<InvItem> company = [];

    response = await http.get(Uri.parse(
        '$baseuri/api/invhilightitem/?pjc=${_selectedproject!.ac}&start=${_filteredDate!.start.toString().split(" ")[0]}&end=${_filteredDate!.end.toString().split(" ")[0]}&mc=${_selectedcompany.map((e) => e.ac).join(",")}'));
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      for (var c in body) {
        // String name = c['PNAME'];
        // String ctype = c['CUSTTYPE'];
        company.add(InvItem(mc: c["MC"], code: c["CODE"], name: c["F2"]));
      }
    }
    setState(() {
      _hilightitems = company;
    });
    // return company;
  }

  DateTimeRange getCurrentFinancialYear() {
    final now = DateTime.now();
    int startYear;
    int endYear;

    // Financial year starts in April (month 4)
    if (now.month >= 4) {
      // Current year is the start year
      startYear = widget.leadtype == "Ledger" ||
              widget.leadtype == "BillDetail" ||
              widget.leadtype == "Invoices"
          ? now.year - 1
          : now.year;
      endYear = now.year + 1;
    } else {
      // Previous year is the start year
      startYear = widget.leadtype == "Ledger" ||
              widget.leadtype == "BillDetail" ||
              widget.leadtype == "Invoices"
          ? now.year - 2
          : now.year - 1;
      endYear = now.year;
    }

    // Financial year starts on April 1st and ends on March 31st
    final startDate = DateTime(startYear, 4, 1);
    final endDate = DateTime(endYear, 3, 31);

    return DateTimeRange(start: startDate, end: endDate);
  }

  @override
  Widget build(BuildContext context) {
    // Use navigationShell from StatefulShellRoute for tab content
    final navigationShell = widget.child;
    Widget content = navigationShell ??
        Column(
          children: [
            if ((_ut.toLowerCase() == "admin" ||
                    _ut.toLowerCase() == "employee") &&
                _type != "Outstanding" &&
                _type != "Invoices")
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: InputField(
                  controller: _searchcontroller,
                  label: "Search Project",
                  suff: _isprojLoading
                      ? const SizedBox(
                          width:
                              24, // Give it a fixed size to avoid layout shifts
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          onPressed: () {
                            _fetchprojectsAndOpenDropdown();
                          },
                          icon: const Icon(Icons.search)),
                ),
              ),
            if (_type == "Invoices")
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: InputField(
                        controller: _searchcontroller,
                        label: "Search Project",
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
                  ),
                  Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: InputField(
                          controller: _billnosearchcontroller,
                          label: "Search Bill No.",
                          suff: IconButton(
                              onPressed: () {
                                if (mounted) {
                                  setState(() {
                                    _pjc = "";
                                    _selectedproject = null;
                                    _billno = _billnosearchcontroller.text;
                                    // print(_billno);
                                  });
                                }
                              },
                              icon: const Icon(Icons.search)),
                        ),
                      ))
                ],
              ),
            if (_type != "Outstanding")
              Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: DropdownSearch<Amast>(
                    key: _projectkey,
                    compareFn: (item1, item2) {
                      return item1.ac == item2.ac;
                    },
                    popupProps: PopupProps.dialog(
                        dialogProps: DialogProps(
                          barrierDismissible: true,
                          barrierLabel: "Dismiss",
                        ),
                        title: Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Select a Project",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  icon: const Icon(Icons.close))
                            ],
                          ),
                        ),
                        // showSelectedItems: true,
                        showSearchBox: true),
                    filterFn: (item, filter) {
                      return item.name == "Add New" ||
                          item.name
                              .toLowerCase()
                              .contains(filter.toLowerCase()) ||
                          item.ac.toLowerCase().contains(filter.toLowerCase());
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
                      if (item.name == "Add New") {
                        return item.name;
                      } else {
                        return "${item.name} (${item.ac})";
                      }
                    },
                    decoratorProps: const DropDownDecoratorProps(
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
                        _pjc = value!.ac;
                        _filteredDate = getCurrentFinancialYear();
                        _datecontroller.text =
                            "${DateFormat("dd/MM/yyyy").format(_filteredDate!.start)}-${DateFormat("dd/MM/yyyy").format(_filteredDate!.end)}";
                        if (_type == "BillDetail") {
                          getcompany();
                        }
                      });
                    },
                    selectedItem: _selectedproject,
                    // showSearchBox: true,
                    // searchFieldProps: TextFieldProps(
                    //   cursorColor: Colors.blue,
                    // ),
                  )),
            if ((_type == "Invoices") || (_type == "CNDN"))
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: InputField(
                  label: "Date Range",
                  controller: _datecontroller,
                  readOnly: true,
                  onTap: () async {
                    var dr = await showDateRangePicker(
                        initialDateRange: getCurrentFinancialYear(),
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100));
                    setState(() {
                      _datecontroller.text = dr == null
                          ? ""
                          : "${DateFormat("dd/MM/yyyy").format(dr.start)}-${DateFormat("dd/MM/yyyy").format(dr.end)}";
                      _filteredDate = dr;
                    });
                  },
                ),
              ),
            Expanded(
              child: (_type == "Invoices") || (_type == "CNDN")
                  ? InvList(
                      biillno: _billno,
                      leadtype: _type,
                      pjc: _pjc,
                      filterdate: _filteredDate,
                      selectedfilters: _selectedfiltervalues,
                      onfilterChange: (value) {
                        if (mounted) {
                          setState(() {
                            filters = value;
                          });
                        }
                      },
                    )
                  : _type == "Outstanding"
                      ? OsList(ut: _ut)
                      : _type == "Ledger"
                          ? Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: InputField(
                                    label: "Date Range",
                                    controller: _datecontroller,
                                    readOnly: true,
                                    onTap: () async {
                                      var dr = await showDateRangePicker(
                                          initialDateRange:
                                              getCurrentFinancialYear(),
                                          context: context,
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2100));
                                      setState(() {
                                        _datecontroller.text = dr == null
                                            ? ""
                                            : "${DateFormat("dd/MM/yyyy").format(dr.start)}-${DateFormat("dd/MM/yyyy").format(dr.end)}";
                                        _filteredDate = dr;
                                      });
                                    },
                                  ),
                                ),
                                ElevatedButton(
                                    onPressed: () async {
                                      QuickAlert.show(
                                        context: context,
                                        type: QuickAlertType.loading,
                                        title: 'Generating Statement...',
                                        barrierDismissible: false,
                                      );
                                      var query = {
                                        "ac": _pjc,
                                        'start': _filteredDate!.start
                                            .toString()
                                            .split(" ")[0],
                                        'end': _filteredDate!.end
                                            .toString()
                                            .split(" ")[0],
                                        'sharedby': await loggedInUser()
                                      };
                                      http.post(
                                        Uri.parse('$baseuri/api/ledgerprint/'),
                                        body: json.encode(query),
                                        headers: {
                                          "Content-Type": "application/json"
                                        },
                                      ).then((response) async {
                                        if (response.statusCode == 200) {
                                          final jsonResponse =
                                              jsonDecode(response.body);

                                          // --- Extracting Mobile Numbers and Filename ---

                                          final List<String> mobileNumbers =
                                              jsonResponse['mobile_numbers']
                                                  .where((item) => item != null)
                                                  .toList()
                                                  .cast<String>();
                                          final String filename =
                                              jsonResponse['filename'];

                                          print(
                                              '✅ Received Mobile Numbers: $mobileNumbers');
                                          print('✅ Filename: $filename');

                                          // --- Decoding and Saving the PDF File ---

                                          final String base64Pdf =
                                              jsonResponse['pdf_data'];

                                          // 3. Base64 Decode the PDF string into raw bytes (Uint8List)
                                          final pdfBytes =
                                              base64Decode(base64Pdf);
                                          final dir =
                                              await getTemporaryDirectory();
                                          final filepath =
                                              '${dir.path}/Ledger($_pjc)-${DateTime.now().millisecondsSinceEpoch}.pdf';
                                          File file = File(filepath);
                                          await file.writeAsBytes(pdfBytes);
                                          Navigator.of(context)
                                              .pop(); // Close the loading dialog
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => Pdfview(
                                                file: file,
                                                type: "Ledger",
                                                ac: _pjc,
                                                mobileNumbers: mobileNumbers,
                                              ),
                                            ),
                                          );

                                          // final body = json.decode(response.body);
                                          // String pdfurl = body['pdf_url'];
                                          // Utils.openUrl(pdfurl);
                                        }
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromRGBO(
                                            252, 101, 8, 1),
                                        foregroundColor: Colors.white),
                                    child: const Text("Search"))
                              ],
                            )
                          : _type == "BillDetail"
                              ? SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: InputField(
                                          label: "Date Range",
                                          controller: _datecontroller,
                                          readOnly: true,
                                          onTap: () async {
                                            var dr = await showDateRangePicker(
                                                initialDateRange:
                                                    getCurrentFinancialYear(),
                                                context: context,
                                                firstDate: DateTime(2000),
                                                lastDate: DateTime(2100));
                                            setState(() {
                                              _datecontroller.text = dr == null
                                                  ? ""
                                                  : "${DateFormat("dd/MM/yyyy").format(dr.start)}-${DateFormat("dd/MM/yyyy").format(dr.end)}";
                                              _filteredDate = dr;
                                              getcompany();
                                            });
                                          },
                                        ),
                                      ),
                                      Padding(
                                          padding: const EdgeInsets.all(5.0),
                                          child: DropdownSearch<
                                              Amast>.multiSelection(
                                            // key: _projectkey,
                                            compareFn: (item1, item2) => item1.ac==item2.ac,
                                            popupProps:
                                                MultiSelectionPopupProps.dialog(
                                                    dialogProps: DialogProps(
                                                      barrierDismissible: true,
                                                      barrierLabel: "Dismiss",
                                                    ),
                                                    title: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              1.0),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          const Text(
                                                            "Select a Company",
                                                            style: TextStyle(
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                          IconButton(
                                                              onPressed: () {
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                              },
                                                              icon: const Icon(
                                                                  Icons.close))
                                                        ],
                                                      ),
                                                    ),
                                                    // showSelectedItems: true,
                                                    showSearchBox: true),
                                            filterFn: (item, filter) {
                                              return item.name == "Add New" ||
                                                  item.name
                                                      .toLowerCase()
                                                      .contains(filter
                                                          .toLowerCase()) ||
                                                  item.ac
                                                      .toLowerCase()
                                                      .contains(
                                                          filter.toLowerCase());
                                            },
                                            // filterFn: (item, filter) {
                                            //   return item == "Add New" ||
                                            //       item
                                            //           .toLowerCase()
                                            //           .contains(filter.toLowerCase());
                                            // },
                                            // mode: Mode.dialog,
                                            // showSelectedItems: true,
                                            items:
                                                (filter, infiniteScrollProps) =>
                                                    _company,
                                            itemAsString: (item) {
                                              if (item.name == "Add New") {
                                                return item.name;
                                              } else {
                                                return item.name;
                                              }
                                            },
                                            decoratorProps:
                                                const DropDownDecoratorProps(
                                              decoration: InputDecoration(
                                                labelText: "Company",
                                                hintText: "Select a Company",
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
                                                _selectedcompany = value;
                                                getitemsforhilight();
                                                _selectedhilightitems = [];
                                                // _pjc = value!.ac;
                                                // _filteredDate =
                                                //     getCurrentFinancialYear();
                                                // _datecontroller.text =
                                                //     "${DateFormat("dd/MM/yyyy").format(_filteredDate!.start)}-${DateFormat("dd/MM/yyyy").format(_filteredDate!.end)}";
                                              });
                                            },
                                            selectedItems: _selectedcompany,
                                            // showSearchBox: true,
                                            // searchFieldProps: TextFieldProps(
                                            //   cursorColor: Colors.blue,
                                            // ),
                                          )),
                                      Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: DropdownSearch<
                                            InvItem>.multiSelection(
                                          // key: _projectkey,
                                          compareFn: (item1, item2) => item1.code == item2.code,
                                          popupProps:
                                              MultiSelectionPopupProps.dialog(
                                                  dialogProps: DialogProps(
                                                    barrierDismissible: true,
                                                    barrierLabel: "Dismiss",
                                                  ),
                                                  title: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            1.0),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        const Text(
                                                          "Select Items",
                                                          style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        IconButton(
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            },
                                                            icon: const Icon(
                                                                Icons.close))
                                                      ],
                                                    ),
                                                  ),
                                                  // showSelectedItems: true,
                                                  showSearchBox: true),
                                          filterFn: (item, filter) {
                                            return item.name == "Add New" ||
                                                item.name
                                                    .toLowerCase()
                                                    .contains(
                                                        filter.toLowerCase());
                                          },
                                          // filterFn: (item, filter) {
                                          //   return item == "Add New" ||
                                          //       item
                                          //           .toLowerCase()
                                          //           .contains(filter.toLowerCase());
                                          // },
                                          // mode: Mode.dialog,
                                          // showSelectedItems: true,
                                          items:
                                              (filter, infiniteScrollProps) =>
                                                  _hilightitems,
                                          itemAsString: (item) {
                                            if (item.name == "Add New") {
                                              return item.name;
                                            } else {
                                              return item.name;
                                            }
                                          },
                                          decoratorProps:
                                              const DropDownDecoratorProps(
                                            decoration: InputDecoration(
                                              labelText: "Select Items",
                                              hintText: "Select an Item",
                                            ),
                                          ),
                                          // decoration: const InputDecoration(
                                          // labelText: "Menu mode",
                                          // hintText: "country in menu mode",
                                          // ),
                                          // popupItemDisabled: isItemDisabled,
                                          onSelected: (value) async {
                                            setState(() {
                                              // _projects.clear();
                                              _selectedhilightitems = value;
                                              // _pjc = value!.ac;
                                              // _filteredDate =
                                              //     getCurrentFinancialYear();
                                              // _datecontroller.text =
                                              //     "${DateFormat("dd/MM/yyyy").format(_filteredDate!.start)}-${DateFormat("dd/MM/yyyy").format(_filteredDate!.end)}";
                                            });
                                          },
                                          selectedItems: _selectedhilightitems,
                                          // showSearchBox: true,
                                          // searchFieldProps: TextFieldProps(
                                          //   cursorColor: Colors.blue,
                                          // ),
                                        ),
                                      ),
                                      Padding(
                                          padding: const EdgeInsets.all(5.0),
                                          child: RadioGroup<int>(
                                            groupValue:
                                                _selectedBillDetailType, // Managed here once
                                            onChanged: (val) {
                                              print(val);
                                              setState(() {
                                                _selectedBillDetailType = val!;
                                              });
                                            },
                                            child: const Column(
                                              children: [
                                                RadioListTile<int>(
                                                    value: 1,
                                                    title: Text(
                                                        "Complete List with Highlight")),
                                                RadioListTile<int>(
                                                    value: 2,
                                                    title: Text(
                                                        "Only Selected Items")),
                                              ],
                                            ),
                                          )),
                                      ElevatedButton(
                                          onPressed: () async {
                                            QuickAlert.show(
                                              context: context,
                                              type: QuickAlertType.loading,
                                              title: 'Generating Statement...',
                                              barrierDismissible: false,
                                            );
                                            var query = {
                                              "ac": _pjc,
                                              'start': _filteredDate!.start
                                                  .toString()
                                                  .split(" ")[0],
                                              'end': _filteredDate!.end
                                                  .toString()
                                                  .split(" ")[0],
                                              'bill_detail_type':
                                                  _selectedBillDetailType,
                                              'hilight_items':
                                                  _selectedhilightitems
                                                      .map((e) =>
                                                          "${e.mc}|||${e.code}")
                                                      .toList(),
                                              'selected_company':
                                                  _selectedcompany
                                                      .map((e) => e.ac)
                                                      .toList(),
                                            };
                                            http.post(
                                              Uri.parse(
                                                  '$baseuri/api/billdetail/'),
                                              body: json.encode(query),
                                              headers: {
                                                "Content-Type":
                                                    "application/json"
                                              },
                                            ).then((response) async {
                                              if (response.statusCode == 200) {
                                                final jsonResponse =
                                                    jsonDecode(response.body);

                                                // --- Extracting Mobile Numbers and Filename ---

                                                final List<String>
                                                    mobileNumbers =
                                                    jsonResponse[
                                                            'mobile_numbers']
                                                        .where((item) =>
                                                            item != null)
                                                        .toList()
                                                        .cast<String>();
                                                final String filename =
                                                    jsonResponse['filename'];

                                                print(
                                                    '✅ Received Mobile Numbers: $mobileNumbers');
                                                print('✅ Filename: $filename');

                                                // --- Decoding and Saving the PDF File ---

                                                final String base64Pdf =
                                                    jsonResponse['pdf_data'];

                                                // 3. Base64 Decode the PDF string into raw bytes (Uint8List)
                                                final pdfBytes =
                                                    base64Decode(base64Pdf);
                                                final dir =
                                                    await getTemporaryDirectory();
                                                final filepath =
                                                    '${dir.path}/ItemDetail($_pjc)-${DateTime.now().millisecondsSinceEpoch}.pdf';
                                                File file = File(filepath);
                                                await file
                                                    .writeAsBytes(pdfBytes);
                                                Navigator.of(context)
                                                    .pop(); // Close the loading dialog
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        Pdfview(
                                                      file: file,
                                                      type: "Item Detail",
                                                      ac: _pjc,
                                                      mobileNumbers:
                                                          mobileNumbers,
                                                    ),
                                                  ),
                                                );

                                                // final body = json.decode(response.body);
                                                // String pdfurl = body['pdf_url'];
                                                // Utils.openUrl(pdfurl);
                                              }
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color.fromRGBO(
                                                      252, 101, 8, 1),
                                              foregroundColor: Colors.white),
                                          child: const Text("Search"))
                                    ],
                                  ),
                                )
                              : const Center(
                                  child: Text("Coming Soon..."),
                                ),
            )
          ],
        );
    return Background(
        appbar: true,
        appbartitle: const Text("My Transactions"),
        appbaractions: const [
          // if ((_type == "Outstanding") && (_ut.toLowerCase() == "admin" || _ut.toLowerCase() == "employee"))
          //   IconButton(
          //       onPressed: () async {
          //         TextEditingController amountcontroller = TextEditingController();
          //         List<String> filteredProducts = _filteredProducts;
          //         final result = await showModalBottomSheet(
          //           isScrollControlled: true,
          //           context: context,
          //           builder: (context) {
          //             return Scaffold(
          //               body: SafeArea(
          //                 child: StatefulBuilder(builder: (context, setstate) {
          //                   return Container(
          //                     padding: const EdgeInsets.all(10),
          //                     child: Column(
          //                       mainAxisSize: MainAxisSize.min,
          //                       children: [
          //                         Padding(
          //                           padding: const EdgeInsets.all(1.0),
          //                           child: DropdownSearch<String>.multiSelection(
          //                             selectedItems: filteredProducts,
          //                             items: filters["Product"],
          //                             onChanged: (value) {
          //                               setstate(() {
          //                                 filteredProducts = value;
          //                               });
          //                             },
          //                             popupProps:
          //                                 const PopupPropsMultiSelection.dialog(
          //                                     showSelectedItems: true,
          //                                     showSearchBox: true),
          //                             dropdownDecoratorProps:
          //                                 const DropDownDecoratorProps(
          //                               dropdownSearchDecoration: InputDecoration(
          //                                 labelText: "Product Type",
          //                                 hintText: "Select Product Type",
          //                               ),
          //                             ),
          //                             validator: (value) {
          //                               if (value == null) {
          //                                 return 'Please select an emplyee name';
          //                               }
          //                               return null;
          //                             },
          //                             autoValidateMode:
          //                                 AutovalidateMode.onUserInteraction,
          //                           ),
          //                         ),
          //                         Padding(
          //                           padding: const EdgeInsets.all(1.0),
          //                           child: InputField(label: "Amount greater than",controller: amountcontroller,keyboardtype: TextInputType.number,onChanged: (value){
          //                             setstate(() {
          //                               amountcontroller.text = value;
          //                             });
          //                           },),
          //                         ),
          //                         Row(
          //                           mainAxisAlignment:
          //                               MainAxisAlignment.spaceAround,
          //                           children: [
          //                             Expanded(
          //                                 child: ElevatedButton(
          //                                     onPressed: () {
          //                                       Navigator.of(context).pop();
          //                                     },
          //                                     child: const Text("Cancel"))),
          //                             Expanded(
          //                                 child: ElevatedButton(
          //                                     onPressed: () {
          //                                       Map<String, List<String>>
          //                                           filterval = {
          //                                         "Product": filteredProducts,
          //                                         "Project": amountcontroller.text.isEmpty ? [] : [amountcontroller.text]
          //                                       };
          //                                       filterlist(filterval);
          //                                       Navigator.of(context)
          //                                           .pop(filterval);
          //                                     },
          //                                     child: const Text("Apply"))),
          //                             Expanded(
          //                                 child: ElevatedButton(
          //                                     onPressed: () {
          //                                       setstate(() {
          //                                         filteredProducts = [];
          //                                         // filteredProjects = [];
          //                                         amountcontroller.text = "";
          //                                       });
          //                                     },
          //                                     child: const Text("Clear All"))),
          //                           ],
          //                         )
          //                       ],
          //                     ),
          //                   );
          //                 }),
          //               ),
          //             );
          //           },
          //         );
          //         if (result != null && mounted) {
          //           setState(() {
          //             _filteredProducts = result["Product"];
          //             _filteredProjects = result["Project"];
          //           });
          //         }
          //       },
          //       icon: const Icon(Icons.filter_list))
        ],
        childs: content);
  }
}
