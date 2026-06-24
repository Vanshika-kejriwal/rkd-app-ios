import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:business_app/constants.dart';
import 'package:business_app/models/leads.dart';
import 'package:business_app/screens/service_detail.dart';
import 'package:business_app/services/network_provider.dart';
import 'package:business_app/widgets/background.dart';
import 'package:business_app/widgets/input_field.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
// import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompletedService extends StatefulWidget {
  CompletedService({super.key, this.assignlead});
  Function(bool assignExisting, Map<String, dynamic> leadinfo)? assignlead;

  @override
  State<CompletedService> createState() => _CompletedServiceState();
}

class _CompletedServiceState extends State<CompletedService> {
  bool _isDataLoaded = false;
  List<PendingInst> leads = [];
  Timer? _reloadTimer;
  Map<String, dynamic> filters = {};
  List<String> _filteredCusttype = [];
  DateTimeRange? _filteredDate;
  List<String> _filteredProducts = [];
  List<String> _admins = [];
  Map<String, dynamic>? _selectedfiltervalues;
  List<PendingInst> initleads = [];
  List<PendingInst> _foundleads = [];
  final _dobcontroller = TextEditingController();
  final _sharemobcontroller = TextEditingController();
  bool _isAdmin = false;
  bool _summary = false;
  String? _selectedadmin;
  String? _selectedPhoneNumber;
  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();


  Future<void> getleads() async {
    setState(() {
      _isDataLoaded = false;
      leads = [];
    });
    final connectivityProvider =
        Provider.of<NetworkProvider>(context, listen: false);
    // var sharedpref = await SharedPreferences.getInstance();
    // var username = sharedpref.getString('NAME')!;
    // if (widget.leadton != null) {
    //   _leadtoname = widget.leadton;
    //   _leadbyname = '';
    // }
    // if (widget.leadbyn == true) {
    //   _leadtoname = '';
    //   _leadbyname = username;
    // }
    // final Map<String, dynamic> query = {
    //   'catagory': widget.leadtype,
    //   'leadbyn': widget.leadbyn,
    //   'leadton': widget.leadton
    // };
    try {
      var sharedpref = await SharedPreferences.getInstance();
      var ut = sharedpref.getString('UT');
      var mob = sharedpref.getString('Mobile');
      var name = sharedpref.getString('NAME');
      final response =
          await http.get(Uri.parse('$baseuri/api/service_list/?type=completed&mob=$mob&ut=$ut'));
      final body = json.decode(response.body);
      // print(body);
      if (response.statusCode == 200) {
        // initleads = leads;
       if (mounted){
         setState(() {
          if (body.isEmpty) {
            leads = [];
          } else {
            leads.clear();
            body.forEach((lead) {
              leads.add(PendingInst(
                  pjc: lead['PJC'],
                  pname: lead["PNAME"],
                  custtype: lead["CUSTTYPE"],
                  products: lead["PRODUCTS"],
                  cdate: lead['DATE']));
            });
          }
          leads.sort((a, b) {
            if (leads.isNotEmpty) {
              // print(b.lastfollowup);
              // b.lastfollowup = b.lastfollowup.replaceAll('\u202f', ' ');
              // String yourDateString = a.lastfollowup;
              // for (int i = 0; i < yourDateString.length; i++) {
              //   print(
              //       "Char at $i: '${yourDateString[i]}' (Code: ${yourDateString.codeUnitAt(i)})");
              // }
              // var dateb =
              // DateFormat("dd/MM/yyyy").parse(b.cdate);
              // a.lastfollowup = a.lastfollowup.replaceAll('\u202f', ' ');
              // var datea =
              // DateFormat("dd/MM/yyyy").parse(a.cdate);
              return a.pname.compareTo(b.pname);
            }
            // 7/10/1996 5:08 PM
            return 0;
          });
          _isAdmin = ut == 'ADMIN';
          if(_isAdmin){
            _selectedadmin = name!;
          }
          _isDataLoaded = true;
        });
       }
        initleads = leads;
        _foundleads = leads;
        filtervalues();
        if (_isAdmin) {
          getnames();
        }
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print(e);
      }
      connectivityProvider.setConnected(false);
    } on http.ClientException catch (_) {
      connectivityProvider.setConnected(false);
    }
  }

  Future<void> getnames() async {
    final response =
        await http.get(Uri.parse('$baseuri/api/leadnames/?custtype=admin'));
    final body = json.decode(response.body);
    List<String> names = [];
    if (response.statusCode == 200) {
      for (var c in body) {
        names.add(c["NAME"]);
      }
    }
    setState(() {
      _admins = names;
    });
  }

  @override
  void initState() {
    super.initState();
    // getleads();
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
    if (isConnected && !_isDataLoaded) {
      _reloadTimer?.cancel();

      // Start a new timer to delay the API call
      _reloadTimer = Timer(const Duration(seconds: 2), () {
        getleads();
        // Call _fetchData() after a 3-second delay
      });
    }

    // Update the previous state for the next check
    // _lastConnectivityStatus = isConnected;

    // If we lose connection, reset _dataLoaded so it will fetch again
    if (!isConnected) {
      _reloadTimer?.cancel();
      setState(() {
        _isDataLoaded = false;
      });
    }
  }

  void filtervalues() {
    // Map<String, dynamic> filters = {};
    Set<String> uniqueProjects = {};
    Set<String> uniqueProducts = {};
    for (var lead in leads) {
      uniqueProducts.addAll(List<String>.from(lead.products));
      uniqueProjects.add(lead.custtype);
    }
    setState(() {
      filters["Product"] = uniqueProducts.toList();
      filters["Project"] = uniqueProjects.toList();
    });
  }

  void filterlist(Map<String, dynamic> filterval) {
    // print(filterval);
    setState(() {
      _selectedfiltervalues = filterval;
      List<PendingInst> filterLeads = initleads.where((lead) {
        bool shouldConsiderProject =
            _selectedfiltervalues!["Project"]!.isNotEmpty;
        bool shouldConsiderProduct =
            _selectedfiltervalues!["Product"]!.isNotEmpty;
        bool shouldConsiderdate = _selectedfiltervalues!["Date"] != null;
        bool projectmatches;
        if (shouldConsiderProject) {
          projectmatches =
              _selectedfiltervalues!["Project"]!.contains(lead.custtype);
        } else {
          projectmatches = true;
        }
        bool productmatches;
        if (shouldConsiderProduct) {
          productmatches = lead.products.any((product) =>
              _selectedfiltervalues!["Product"]!.contains(product));
        } else {
          productmatches = true;
        }
        bool datematches;
        if (shouldConsiderdate) {
          var idate = DateFormat("dd/MM/yyyy").parse(lead.cdate);
          datematches = (idate.isAfter(_selectedfiltervalues!["Date"].start) ||
                  idate.isAtSameMomentAs(
                      _selectedfiltervalues!["Date"].start)) &&
              (idate.isBefore(_selectedfiltervalues!["Date"].end) ||
                  idate.isAtSameMomentAs(_selectedfiltervalues!["Date"].end));
        } else {
          datematches = true;
        }
        return productmatches & projectmatches & datematches;
      }).toList();
      filterLeads.sort(
        (a, b) {
          if (filterLeads.isNotEmpty) {
            // print(filterval);

            return a.pname.compareTo(b.pname);
          }
          return 0;
        },
      );
      leads = filterLeads;
      _foundleads = filterLeads;
    });
  }

  @override
  void dispose() {
    // It's crucial to cancel the timer when the widget is disposed
    _reloadTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      appbar: true,
      appbartitle: const Text("Completed Services"),
      floatbutton: false,
      floatbtn: FloatingActionButton(
        onPressed: () async {
          var filter = _filteredProducts.isNotEmpty;
          // print(filter);
          if (filter) {
            var sharelist = await showDialog(
              barrierDismissible: false,
              context: context,
              builder: (context) {
                return StatefulBuilder(builder: (context, sharestate) {
                  return AlertDialog(
                    title: const Text("Share Data"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                                value: _summary,
                                onChanged: (value) {
                                  // print(value);
                                  sharestate(() {
                                    _summary = value!;
                                  });
                                }),
                            const Text("Summary Only")
                          ],
                        ),
                        Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: DropdownSearch<String>(
                              // enabled: _isenabled,
                              popupProps: const PopupProps.dialog(
                                dialogProps: DialogProps(barrierDismissible: true,),
                                  showSelectedItems: true, showSearchBox: true),
                              // mode: Mode.dialog,
                              // showSelectedItems: true,
                              items: (filter, infiniteScrollProps)=>_admins,
                              decoratorProps:
                                  const DropDownDecoratorProps(
                                decoration: InputDecoration(
                                  labelText: "Share with Admin",
                                  hintText: "Select an Admin",
                                ),
                              ),

                              onSelected: (value) {
                                sharestate(() {
                                  _selectedadmin = value;
                                });
                              },
                              selectedItem: _selectedadmin,
                            )),
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: InputField(
                            label: "Mobile Number to Share",
                            controller: _sharemobcontroller,
                            keyboardtype: TextInputType.phone,
                            sufficon: IconButton(
                                                            onPressed:
                                                                () async {
                                                              Contact? contact =
                                                                  await _contactPicker
                                                                      .selectPhoneNumber();
                                                              setState(() {
                                                                _selectedPhoneNumber =
                                                                    contact
                                                                        ?.selectedPhoneNumber;
                                                                if (_selectedPhoneNumber !=
                                                                    null) {
                                                                  var phno = _selectedPhoneNumber!
                                                                      .replaceAll(
                                                                          " ",
                                                                          "");
                                                                  _sharemobcontroller
                                                                          .text =
                                                                      phno.substring(
                                                                          phno.length -
                                                                              10);
                                                                  _selectedPhoneNumber =
                                                                      null;
                                                                }
                                                              });
                                                            },
                                                            icon: const Icon(
                                                                Icons
                                                                    .contacts)),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        child: const Text("Send"),
                      ),
                    ],
                  );
                });
              },
            );
            if (sharelist == true) {
              if (context.mounted) {
                QuickAlert.show(
                    context: context,
                    type: QuickAlertType.loading,
                    title: "Sending Message",
                    barrierDismissible: false);
              }
              final Map<String, dynamic> query = {
                "summary": _summary,
                "admin": _selectedadmin,
                "mobile": _sharemobcontroller.text,
                'projects': leads.map((e) => e.pjc).toSet().toList(),
                'products': _filteredProducts,
                'date': _filteredDate == null
                    ? null
                    : {
                        'start': _filteredDate!.start.toString().split(" ")[0],
                        'end': _filteredDate!.end.toString().split(" ")[0]
                      }
              };
              final response = await http.post(
                  Uri.parse(
                    '$baseuri/api/ins_share/',
                  ),
                  body: json.encode(query),
                  headers: {"Content-Type": "application/json"});
              if (context.mounted) {
                Navigator.pop(context);
              }
              if (response.statusCode == 200 || response.statusCode == 201) {
                if (context.mounted) {
                  QuickAlert.show(
                      context: context,
                      type: QuickAlertType.success,
                      title: "Message Sent",
                      text: "Successfully sent Message");
                }
                _sharemobcontroller.clear();
                //successfully sent message
              } else {
                //something went wrong
                if (context.mounted) {
                  QuickAlert.show(
                      context: context,
                      type: QuickAlertType.error,
                      title: "Could not send Message",
                      text: "Something went Wrong");
                }
              }
            }
          } else {
            QuickAlert.show(
                context: context,
                type: QuickAlertType.error,
                title: "No Products Filtered",
                text: "Please select at least one product to share.");
          }
        },
        child: const Icon(Icons.share),
      ),
      appbaractions: [
        IconButton(
            onPressed: () async {
              {
                List<String> filteredProjects = _filteredCusttype;
                List<String> filteredProducts = _filteredProducts;
                DateTimeRange? filterdate = _filteredDate;
                final result = await showModalBottomSheet(
                  isScrollControlled: true,
                  context: context,
                  builder: (context) {
                    return SafeArea(
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
                                  items: (filter, infiniteScrollProps) => filters["Product"],
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
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: InputField(
                                  label: "Date Range",
                                  controller: _dobcontroller,
                                  readOnly: true,
                                  onTap: () async {
                                    var dr = await showDateRangePicker(
                                        context: context,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2100));
                                    setstate(() {
                                      _dobcontroller.text = dr == null
                                          ? ""
                                          : "${DateFormat("dd/MM/yyyy").format(dr.start)}-${DateFormat("dd/MM/yyyy").format(dr.end)}";
                                      filterdate = dr;
                                    });
                                  },
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
                                            Map<String, dynamic> filterval = {
                                              "Product": filteredProducts,
                                              "Project": filteredProjects,
                                              "Date": filterdate
                                            };
                                            // if (kDebugMode) {
                                            //   print(filterval);
                                            // }
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
                                              filterdate = null;
                                              _dobcontroller.clear();
                                            });
                                          },
                                          child: const Text("Clear All"))),
                                ],
                              )
                            ],
                          ),
                        );
                      }),
                    );
                  },
                );
                if (result != null) {
                  setState(() {
                    _filteredProducts = result["Product"];
                    _filteredCusttype = result["Project"];
                    _filteredDate = result["Date"];
                  });
                }
              }
            },
            icon: const Icon(Icons.filter_alt))
      ],
      childs: !_isDataLoaded
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : leads.isEmpty
              ? const Center(
                  child: Text("No Completed Services"),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: InputField(
                        label: "Search",
                        onChanged: (value) {
                          List<PendingInst> results = [];
                          if (value.isEmpty) {
                            results = leads;
                          } else {
                            results = leads.where((lead) {
                              return value
                                      .toLowerCase()
                                      .split(" ")
                                      .where((word) => word.isNotEmpty)
                                      .toList()
                                      .every((word) => lead.pname
                                          .toLowerCase()
                                          .contains(word)) ||
                                  value
                                      .toLowerCase()
                                      .split(" ")
                                      .where((word) => word.isNotEmpty)
                                      .toList()
                                      .every((word) => lead.custtype
                                          .toLowerCase()
                                          .contains(word)) ||
                                  value
                                      .toLowerCase()
                                      .split(" ")
                                      .where((word) => word.isNotEmpty)
                                      .toList()
                                      .every((word) => lead.products.any(
                                          (product) => product
                                              .toString()
                                              .toLowerCase()
                                              .contains(word)));
                            }).toList();
                          }
                          setState(() {
                            _foundleads = results;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                          itemCount: _foundleads.length,
                          itemBuilder: (context, index) {
                            return Card(
                                color: Colors.transparent,
                                child: ListTile(
                                  title: Text(_foundleads[index].pname),
                                  subtitle: Text(
                                      "${_foundleads[index].custtype}\n${_foundleads[index].products.join(",")}"),
                                  isThreeLine: true,
                                  trailing: Text(_foundleads[index].cdate),
                                  tileColor: Colors.transparent,
                                  onTap: () {
                                    Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (context) => ServiceDetail(
                                                currentinst:
                                                    _foundleads[index])));
                                  },
                                ));
                          }),
                    ),
                  ],
                ),
    );
  }
}
