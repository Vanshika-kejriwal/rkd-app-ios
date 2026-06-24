import 'dart:convert';

// import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:business_app/constants.dart';
import 'package:business_app/widgets/background.dart';
import 'package:business_app/widgets/list_leads.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ComplainsList extends StatefulWidget {
  final String leadtype;
  final Widget? child;
  const ComplainsList({super.key, required this.leadtype, this.child});

  @override
  State<ComplainsList> createState() => _ComplainsListState();
}

class _ComplainsListState extends State<ComplainsList> with TickerProviderStateMixin {
  final String _name = '';
  String _type = "";
  String searchQuery = '';
  late final SearchQueryModel _searchQueryModel;
  final List<String> _selectedItemsassignedby = ["ALL"];
  List<String> _empnames = ["ALL"];
  final List<String> _selectedItemsassignedto = [];
  Map<String, dynamic> filters = {};
  Map<String, List<String>>? _selectedfiltervalues;
  List<String> _filteredProjects = [];
  List<String> _filteredProducts = [];
  int _listcount = 0;

  Future<String> loggedInUser() async {
    var sharedpref = await SharedPreferences.getInstance();
    var username = sharedpref.getString('NAME')!;
    // if (kDebugMode) {
    //   print(username);
    // }
    return username;
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

  @override
  void initState() {
    super.initState();
    _searchQueryModel = SearchQueryModel();
    // getnames();
    if (kDebugMode) {
      print(widget.leadtype);
    }
    setState(() {
      _type = widget.leadtype;
      // _selectedItemsassignedto.add();
    });
    // fetchuser();
  }

  @override
  Widget build(BuildContext context) {
    // Use navigationShell from StatefulShellRoute for tab content
    final navigationShell = widget.child;
    Widget content = navigationShell ??
        Column(
          children: [
            
            Expanded(
              child: ListLeads(
                leadtype: _type,
                selectedfilters: _selectedfiltervalues,
                listcountChange: (count) {
                  if (mounted) {
                    setState(() {
                      _listcount = count;
                    });
                  }
                },
                onfilterChange: (value) {
                  if (mounted) {
                    setState(() {
                      filters = value;
                    });
                  }
                },
              ),
            )
          ],
        );
    return Background(
        appbar: true,
        appbartitle: const Text("Complains"),
        appbaractions: [
          if (_listcount != 0)
          Badge(
            label: Text(
              '$_listcount',
              style: const TextStyle(color: Colors.black),
            ),
           backgroundColor: Colors.white,
          ),
          IconButton(
              onPressed: () async {
                List<String> filteredProjects = _filteredProjects;
                List<String> filteredProducts = _filteredProducts;
                final result = await showModalBottomSheet(
                  isScrollControlled: true,
                  context: context,
                  builder: (context) {
                    return Scaffold(
                      body: SafeArea(
                        child: StatefulBuilder(builder: (context, setstate) {
                          return Container(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(1.0),
                                  child: DropdownSearch<String>.multiSelection(
                                    selectedItems: filteredProducts,
                                    items: (filter, infiniteScrollProps) =>   filters["Product"],
                                    onSelected: (value) {
                                      setstate(() {
                                        filteredProducts = value;
                                      });
                                    },
                                    popupProps:
                                        const MultiSelectionPopupProps.dialog(
                                          dialogProps: DialogProps(barrierDismissible: true,),
                                            showSelectedItems: true,
                                            showSearchBox: true),
                                    decoratorProps:
                                        const DropDownDecoratorProps(
                                      decoration: InputDecoration(
                                        labelText: "Product Type",
                                        hintText: "Select Product Type",
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Please select an emplyee name';
                                      }
                                      return null;
                                    },
                                    autoValidateMode:
                                        AutovalidateMode.onUserInteraction,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(1.0),
                                  child: DropdownSearch<String>.multiSelection(
                                    selectedItems: filteredProjects,
                                    items: (filter, infiniteScrollProps) => filters["Project"],
                                    onSelected: (value) {
                                      setstate(() {
                                        filteredProjects = value;
                                      });
                                    },
                                    popupProps:
                                        const MultiSelectionPopupProps.dialog(
                                            dialogProps: DialogProps(barrierDismissible: true,),
                                            showSelectedItems: true,
                                            showSearchBox: true),
                                    decoratorProps:
                                        const DropDownDecoratorProps(
                                      decoration: InputDecoration(
                                        labelText: "Project",
                                        hintText: "Select Project",
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Please select an emplyee name';
                                      }
                                      return null;
                                    },
                                    autoValidateMode:
                                        AutovalidateMode.onUserInteraction,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Expanded(
                                        child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text("Cancel"))),
                                    Expanded(
                                        child: ElevatedButton(
                                            onPressed: () {
                                              Map<String, List<String>>
                                                  filterval = {
                                                "Product": filteredProducts,
                                                "Project": filteredProjects
                                              };
                                              filterlist(filterval);
                                              Navigator.of(context)
                                                  .pop(filterval);
                                            },
                                            child: const Text("Apply"))),
                                    Expanded(
                                        child: ElevatedButton(
                                            onPressed: () {
                                              setstate(() {
                                                filteredProducts = [];
                                                filteredProjects = [];
                                              });
                                            },
                                            child: const Text("Clear All"))),
                                  ],
                                )
                              ],
                            ),
                          );
                        }),
                      ),
                    );
                  },
                );
                if (result != null && mounted) {
                  setState(() {
                    _filteredProducts = result["Product"];
                    _filteredProjects = result["Project"];
                  });
                }
              },
              icon: const Icon(Icons.filter_list))
        ],
        childs: content);
  }
}
