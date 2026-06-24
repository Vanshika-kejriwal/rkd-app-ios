import 'dart:convert';

// import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:business_app/constants.dart';
import 'package:business_app/widgets/background.dart';
import 'package:business_app/widgets/list_leads.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllLeads extends StatefulWidget {
  final String leadtype;
  final Widget? child;
  final Function(dynamic assignExisting, dynamic leadinfo)? assignlead;

  const AllLeads(
      {super.key, required this.leadtype, this.child, this.assignlead});

  @override
  State<AllLeads> createState() => _AllLeadsState();
}

class _AllLeadsState extends State<AllLeads> with TickerProviderStateMixin {
  final String _name = '';
  String _type = "";
  String searchQuery = '';
  late final SearchQueryModel _searchQueryModel;
  List<String> _selectedItemsassignedby = ["ALL"];
  List<String> _empnames = ["ALL"];
  List<String> _selectedItemsassignedto = [];
  Map<String, dynamic> filters = {};
  Map<String, List<String>>? _selectedfiltervalues;
  List<String> _filteredProjects = [];
  List<String> _filteredProducts = [];
  List<String> _filteredLeadtypes = [];
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
    final response =
        await http.get(Uri.parse('$baseuri/api/leadnames/?leadslist=true'));
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
    if (widget.leadtype != "Unassigned") {
      getnames();
    }
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
            if (_type != "Unassigned")
              Container(
                padding: const EdgeInsets.all(0.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: DropdownSearch<String>.multiSelection(
                          selectedItems: _selectedItemsassignedby,
                          items: (filter, infiniteScrollProps) => _empnames,
                          onSelected: (value) {
                            if (value.isEmpty) {
                              QuickAlert.show(
                                  context: context,
                                  type: QuickAlertType.error,
                                  title: "No name Selected",
                                  text: "Please select atleast one name.");
                            }
                            setState(() {
                              _selectedItemsassignedby = value;
                            });
                          },
                          popupProps: const MultiSelectionPopupProps.dialog(
                            dialogProps: DialogProps(
                              barrierDismissible: true,),
                              showSelectedItems: true, showSearchBox: true),
                          decoratorProps: const DropDownDecoratorProps(
                            decoration: InputDecoration(
                                labelText: "Leads Assigned By*",
                                labelStyle: TextStyle(fontSize: 12),
                                hintText: "Select Employee",
                                contentPadding:
                                    EdgeInsets.fromLTRB(12, 12, 12, 0)),
                          ),
                          validator: (value) {
                            if (value == null) {
                              return 'Please select an emplyee name';
                            }
                            return null;
                          },
                          autoValidateMode: AutovalidateMode.onUserInteraction,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: DropdownSearch<String>.multiSelection(
                          selectedItems: _selectedItemsassignedto,
                          items: (filter, infiniteScrollProps) => _empnames,
                          onSelected: (value) {
                            if (value.isEmpty) {
                              QuickAlert.show(
                                  context: context,
                                  type: QuickAlertType.error,
                                  title: "No name Selected",
                                  text: "Please select atleast one name.");
                            }
                            setState(() {
                              _selectedItemsassignedto = value;
                            });
                          },
                          popupProps: const MultiSelectionPopupProps.dialog(
                            dialogProps: DialogProps(
                              barrierDismissible: true,),
                              showSelectedItems: true, showSearchBox: true),
                          decoratorProps: const DropDownDecoratorProps(
                            decoration: InputDecoration(
                                labelText: "Leads Assigned To*",
                                labelStyle: TextStyle(fontSize: 12),
                                hintText: "Select Employee",
                                contentPadding:
                                    EdgeInsets.fromLTRB(12, 12, 12, 0)),
                          ),
                          validator: (value) {
                            if (value == null) {
                              return 'Please select an emplyee name';
                            }
                            return null;
                          },
                          autoValidateMode: AutovalidateMode.onUserInteraction,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListLeads(
                leadtype: _type,
                leadton: _selectedItemsassignedto,
                leadbyn: _selectedItemsassignedby,
                selectedfilters: _selectedfiltervalues,
                assignlead: widget.assignlead,
                listcountChange: (count) {
                  if (mounted) {
                    setState(() {
                      // filters = value;
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
        appbartitle: const Text("Leads"),
        appbaractions: [
          if (_listcount != 0)
            Badge(
              largeSize: 25,
              label: Text(
                '$_listcount',
                style: const TextStyle(color: Colors.black, fontSize: 14),
              ),
              backgroundColor: Colors.white,
            ),
          IconButton(
              onPressed: () async {
                List<String> filteredProjects = _filteredProjects;
                List<String> filteredProducts = _filteredProducts;
                List<String> filteredLeadtypes = _filteredLeadtypes;
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
                                    items: (filter, infiniteScrollProps)=>filters["Product"],
                                    onSelected: (value) {
                                      setstate(() {
                                        filteredProducts = value;
                                      });
                                    },
                                    popupProps:
                                        const MultiSelectionPopupProps.dialog(
                                          dialogProps: DialogProps(
                                            barrierDismissible: true,),
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
                                    items: (filter, infiniteScrollProps)=>filters["Project"],
                                    onSelected: (value) {
                                      setstate(() {
                                        filteredProjects = value;
                                      });
                                    },
                                    popupProps:
                                        const MultiSelectionPopupProps.dialog(
                                          dialogProps: DialogProps(
                                            barrierDismissible: true,),
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
                                Padding(
                                  padding: const EdgeInsets.all(1.0),
                                  child: DropdownSearch<String>.multiSelection(
                                    selectedItems: filteredLeadtypes,
                                    items: (filter, infiniteScrollProps)=>filters["Leadtype"],
                                    onSelected: (value) {
                                      setstate(() {
                                        filteredLeadtypes = value;
                                      });
                                    },
                                    popupProps:
                                        const MultiSelectionPopupProps.dialog(
                                            dialogProps: DialogProps(
                                              barrierDismissible: true,),
                                            showSelectedItems: true,
                                            showSearchBox: true),
                                    decoratorProps:
                                        const DropDownDecoratorProps(
                                      decoration: InputDecoration(
                                        labelText: "Lead Type",
                                        hintText: "Select Lead Type",
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
                                                "Project": filteredProjects,
                                                "Leadtype": filteredLeadtypes
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
                                                filteredLeadtypes = [];
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
                    _filteredLeadtypes = result["Leadtype"] ?? [];
                  });
                }
              },
              icon: const Icon(Icons.filter_list))
        ],
        childs: content);
  }
}
