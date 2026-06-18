import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:business_app/models/leads.dart';
import 'package:business_app/screens/lead_detail.dart';
import 'package:business_app/services/network_provider.dart';
import 'package:business_app/widgets/input_field.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:business_app/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Removed go_router import

class ListLeads extends StatefulWidget {
  String leadtype;
  List<String>? leadbyn;
  List<String>? leadton;
  String? searchQuery;
  // final SearchQueryModel searchQueryModel;
  final ValueChanged<Map<String, dynamic>> onfilterChange;
  final ValueChanged<int> listcountChange;
  final Function(dynamic assignExisting, dynamic leadinfo)? assignlead;
  Map<String, List<String>>? selectedfilters;

  ListLeads(
      {super.key,
      required this.leadtype,
      this.leadbyn,
      this.leadton,
      this.searchQuery,
      required this.onfilterChange,
      this.assignlead,
      required this.listcountChange,
      this.selectedfilters});

  @override
  State<ListLeads> createState() => _ListLeadsState();
}

class _ListLeadsState extends State<ListLeads> {
  List<Lead> leads = [];
  List<Lead> _foundleads = [];
  List<Lead> initleads = [];
  // String? _leadbyname = '';
  // String? _leadtoname = '';
  bool _isDataLoaded = false;
  Timer? _reloadTimer;
  // Removed unused _listener field

  Future<void> getleads() async {
    setState(() {
      _isDataLoaded = false;
      leads = [];
    });
    var sharedpref = await SharedPreferences.getInstance();
    var mob = sharedpref.getString("Mobile");
    var ut = sharedpref.getString("UT");
    http.Response response;
    // Removed unused username variable
    // if (widget.leadton != null) {
    //   _leadtoname = widget.leadton;
    //   _leadbyname = '';
    // }
    // if (widget.leadbyn == true) {
    //   _leadtoname = '';
    //   _leadbyname = username;
    // }

    final connectivityProvider =
        Provider.of<NetworkProvider>(context, listen: false);
    try {
      if (ut!.toLowerCase() == "consumer" || ut.toLowerCase() == "contractor" || ut.toLowerCase() == "supplier" || (widget.leadbyn == null && widget.leadton == null)) {
        final Map<String, dynamic> query = {
          'catagory': widget.leadtype,
          "mob": mob,
        };
         response = await http.post(Uri.parse('$baseuri/api/complain_list/'),
            body: jsonEncode(query),
            headers: {"Content-Type": "application/json"});
      } else {
        final Map<String, dynamic> query = {
          'catagory': widget.leadtype,
          'leadbyn': widget.leadbyn,
          'leadton': widget.leadton
        };

         response = await http.post(Uri.parse('$baseuri/api/leads_list/'),
            body: jsonEncode(query),
            headers: {"Content-Type": "application/json"});
      }
      // print(response.headers);
      // if (kDebugMode) {
      //   print(response.body);
      // }
      final body = json.decode(response.body);
      if (kDebugMode) {
        print(body);
      }
      if (response.statusCode == 200) {
        if (body.isEmpty) {
          leads = [];
          // widget.listcountChange(0);
        } else {
          body.forEach((lead) {
            if (lead['LAST_FOLLOWUP'] == null) {
              leads.add(Lead(
                  pjc: lead['PJC'],
                  pname: lead['PNAME'],
                  leadtype: lead['LEAD_TYPE'],
                  lastfollowup: "OPEN",
                  products: lead["PRODUCTS"]));
            } else {
              // DateTime followup = DateFormat('yyyy-MM-ddTHH:mm:ss.SSSSSS')
              // .parse(lead['LAST_FOLLOWUP']);
              String lastFollowup = lead["LAST_FOLLOWUP"];
              // DateFormat("dd/MM/yyyy").add_jm().format(followup);
              leads.add(Lead(
                  pjc: lead['PJC'],
                  pname: lead['PNAME'],
                  leadtype: lead['LEAD_TYPE'] ?? "",
                  lastfollowup: lastFollowup,
                  products: lead["PRODUCTS"]));
            }
          });
        }
        // leads.remove(value)
        leads.sort((a, b) {
          if (leads.isNotEmpty && (a.lastfollowup != "") && (b.lastfollowup != "")) {
            // print(b.lastfollowup);
            b.lastfollowup = b.lastfollowup.replaceAll('\u202f', ' ');
            // String yourDateString = a.lastfollowup;
            // for (int i = 0; i < yourDateString.length; i++) {
            //   print(
            //       "Char at $i: '${yourDateString[i]}' (Code: ${yourDateString.codeUnitAt(i)})");
            // }
            var dateb =
                DateFormat("dd/MM/yyyy h:mm a", "en_US").parse(b.lastfollowup);
            a.lastfollowup = a.lastfollowup.replaceAll('\u202f', ' ');
            var datea =
                DateFormat("dd/MM/yyyy h:mm a", "en_US").parse(a.lastfollowup);
            if (widget.leadtype == "Closed") {
              return dateb.compareTo(datea);
            } else {
              return datea.compareTo(dateb);
            }
          }
          // 7/10/1996 5:08 PM
          return 0;
        });
        initleads = leads;
        _foundleads = leads;
        widget.listcountChange(leads.length);
        filtervalues();
        if(mounted){
          setState(() {
          _isDataLoaded = true;
        });
        }
      }
    } on SocketException catch (_) {
      connectivityProvider.setConnected(false);
    } on http.ClientException catch (_) {
      connectivityProvider.setConnected(false);
    }
  }

  Future<void> getunassignedleads() async {
    setState(() {
      _isDataLoaded = false;
      leads = [];
    });
    var sharedpref = await SharedPreferences.getInstance();
    var mob = sharedpref.getString("Mobile");
    var ut = sharedpref.getString("UT");
    http.Response response;
    // Removed unused username variable
    // if (widget.leadton != null) {
    //   _leadtoname = widget.leadton;
    //   _leadbyname = '';
    // }
    // if (widget.leadbyn == true) {
    //   _leadtoname = '';
    //   _leadbyname = username;
    // }

    final connectivityProvider =
        Provider.of<NetworkProvider>(context, listen: false);
    try {
      if (ut!.toLowerCase() == "consumer" || ut.toLowerCase() == "contractor" || ut.toLowerCase() == "supplier" || (widget.leadbyn == null && widget.leadton == null)) {
        final Map<String, dynamic> query = {
          'catagory': widget.leadtype,
          "mob": mob,
        };
         response = await http.post(Uri.parse('$baseuri/api/complain_list/'),
            body: jsonEncode(query),
            headers: {"Content-Type": "application/json"});
      } else {
        final Map<String, dynamic> query = {
          'catagory': widget.leadtype,
          'leadbyn': widget.leadbyn,
          'leadton': widget.leadton
        };

         response = await http.get(Uri.parse('$baseuri/api/leads_list/?type=unassigned'),
            headers: {"Content-Type": "application/json"});
      }
      // print(response.headers);
      // if (kDebugMode) {
      //   print(response.body);
      // }
      final body = json.decode(response.body);
      if (kDebugMode) {
        print(body);
      }
      if (response.statusCode == 200) {
        if (body.isEmpty) {
          leads = [];
        } else {
          body.forEach((lead) {
            if (lead['LAST_FOLLOWUP'] == null) {
              leads.add(Lead(
                  pjc: lead['PJC'],
                  pname: lead['PNAME'],
                  leadtype: lead['LEAD_TYPE'],
                  lastfollowup: "OPEN",
                  custtype: lead['CUSTTYPE'],
                  products: lead["PRODUCTS"]));
            } else {
              // DateTime followup = DateFormat('yyyy-MM-ddTHH:mm:ss.SSSSSS')
              // .parse(lead['LAST_FOLLOWUP']);
              String lastFollowup = lead["LAST_FOLLOWUP"];
              // DateFormat("dd/MM/yyyy").add_jm().format(followup);
              leads.add(Lead(
                  pjc: lead['PJC'],
                  pname: lead['PNAME'],
                  leadtype: lead['LEAD_TYPE'] ?? "",
                  lastfollowup: lastFollowup,
                  custtype: lead['CUSTTYPE'],
                  products: lead["PRODUCTS"]));
            }
          });
        }
        // leads.remove(value)
        leads.sort((a, b) {
          if (leads.isNotEmpty && (a.lastfollowup != "") && (b.lastfollowup != "")) {
            // print(b.lastfollowup);
            b.lastfollowup = b.lastfollowup.replaceAll('\u202f', ' ');
            // String yourDateString = a.lastfollowup;
            // for (int i = 0; i < yourDateString.length; i++) {
            //   print(
            //       "Char at $i: '${yourDateString[i]}' (Code: ${yourDateString.codeUnitAt(i)})");
            // }
            var dateb =
                DateFormat("dd/MM/yyy", "en_US").parse(b.lastfollowup);
            a.lastfollowup = a.lastfollowup.replaceAll('\u202f', ' ');
            var datea =
                DateFormat("dd/MM/yyy", "en_US").parse(a.lastfollowup);
            if (widget.leadtype == "Closed") {
              return dateb.compareTo(datea);
            } else {
              return datea.compareTo(dateb);
            }
          }
          // 7/10/1996 5:08 PM
          return 0;
        });
        initleads = leads;
        _foundleads = leads;
        widget.listcountChange(leads.length);
        filtervalues();
        if(mounted) {
          setState(() {
          _isDataLoaded = true;
        });
        }
      }
    } on SocketException catch (_) {
      connectivityProvider.setConnected(false);
    } on http.ClientException catch (_) {
      connectivityProvider.setConnected(false);
    }
  }

  @override
  void initState() {
    // getleads();
    super.initState();
    // _listener = () {
    //   // Define the callback
    //   // _filterData();
    // };

    // widget.searchQueryModel.addListener(_listener);
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
        if (widget.leadtype == "Unassigned") {
          getunassignedleads();
        } else {
          getleads();
        } // Call _fetchData() after a 3-second delay
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

  @override
  void dispose() {
    // It's crucial to cancel the timer when the widget is disposed
    _reloadTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ListLeads oldWidget) {
    super.didUpdateWidget(oldWidget);
    // if (oldWidget.searchQueryModel != widget.searchQueryModel) {
    //   oldWidget.searchQueryModel.removeListener(_listener);
    //   widget.searchQueryModel.addListener(_listener);
    // }
    // print(widget.selectedfilters);
    if (oldWidget.leadbyn != widget.leadbyn ||
        oldWidget.leadton != widget.leadton) {
      getleads();
    }
    if ((oldWidget.selectedfilters != widget.selectedfilters)) {
      // getleads();
      List<Lead> filterLeads = initleads.where((lead) {
        bool shouldConsiderProject =
            widget.selectedfilters!["Project"]!.isNotEmpty;
        bool shouldConsiderProduct =
            widget.selectedfilters!["Product"]!.isNotEmpty;
            bool shouldConsiderLeadtype =
            widget.selectedfilters!["Leadtype"]!.isNotEmpty;
        bool projectmatches;
        if (shouldConsiderProject) {
          projectmatches =
              widget.selectedfilters!["Project"]!.contains(lead.pname);
        } else {
          projectmatches = true;
        }
        bool leadtypematches;
        if (shouldConsiderLeadtype) {
          leadtypematches =
              widget.selectedfilters!["Leadtype"]!.contains(lead.leadtype);
        } else {
          leadtypematches = true;
        }
        bool productmatches;
        if (shouldConsiderProduct) {
          productmatches = lead.products.any((product) =>
              widget.selectedfilters!["Product"]!.contains(product));
        } else {
          productmatches = true;
        }
        return productmatches & projectmatches & leadtypematches;
      }).toList();
      leads = filterLeads;
      _foundleads = filterLeads;
    }
    // if (oldWidget.searchQuery != widget.searchQuery) {
    //   print(widget.searchQuery);
    //   leads = leads
    //       .where((lead) => lead.pname
    //           .toLowerCase()
    //           .contains(widget.searchQuery!.toLowerCase()))
    //       .toList();
    // }
  }

  // void _filterData() {
  //   final searchQuery = widget.searchQueryModel.searchQuery;
  //   // ... filtering logic
  //   leads = leads
  //       .where((lead) =>
  //           lead.pname.toLowerCase().contains(searchQuery.toLowerCase()))
  //       .toList();
  //   setState(() {});
  // }

  @override
  Widget build(BuildContext context) {
    // if (kDebugMode) {
    //   print(widget.searchQuery);
    // }
    return !_isDataLoaded
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : leads.isEmpty
            ? const Center(
                child: Text("No Leads to Show"),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: InputField(
                      label: "Search",
                      onChanged: (value) {
                        List<Lead> results = [];
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
                                    .every((word) => lead.leadtype
                                        .toLowerCase()
                                        .contains(word)) ||
                                value
                                    .toLowerCase()
                                    .split(" ")
                                    .where((word) => word.isNotEmpty)
                                    .toList()
                                    .every((word) => lead.products.any((product) => product
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
                                title: Text(_foundleads[index].pname,
                                    style: const TextStyle(
                                        fontSize: 13)),
                                subtitle: Row(
                                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        _foundleads[index].leadtype,style: TextStyle(fontSize: 12,fontWeight: FontWeight.bold,backgroundColor: _foundleads[index].leadtype=="INSTALLATION"? Colors.orange[700]: _foundleads[index].leadtype=="COMPLAIN"? Colors.green[400]: _foundleads[index].leadtype=="SERVICE"? Colors.yellow: Colors.white),),
                                        const SizedBox(width: 20),
                                        Text(
                                        _foundleads[index].lastfollowup,style: const TextStyle(fontSize: 12),),
                                        const SizedBox(width: 20),
                                        Expanded(
                                          child: Text(
                                          _foundleads[index].products.join(","), overflow: TextOverflow.ellipsis,style: const TextStyle(fontSize: 12),),
                                        )
                                  ],
                                ),
                                // isThreeLine: true,
                                // trailing: Text(_foundleads[index].lastfollowup),
                                tileColor: Colors.transparent,
                                onTap: () {
                                  // Use Navigator.push for navigation
                                  if (widget.leadtype == "Unassigned") {
                                    widget.assignlead!(true, {
                                      "pjc": _foundleads[index].pjc,
                                      "pname": _foundleads[index].pname,
                                      "custtype": _foundleads[index].custtype,
                                      "leadtype": _foundleads[index].leadtype,
                                      "products": _foundleads[index].products,
                                    });
                                  } else {
                                    Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LeadDetail(
                                          currentlead: _foundleads[index]),
                                    ),
                                  ).then((_) {
                                    // Refresh the leads list when returning
                                    getleads();
                                  });
                                  }
                                },
                              ));
                        }),
                  ),
                ],
              );
  }

  void filtervalues() {
    Map<String, dynamic> filters = {};
    Set<String> uniqueProjects = {};
    Set<String> uniqueProducts = {};
    Set<String> uniqueLeadtypes = {};
    for (var lead in leads) {
      uniqueProducts.addAll(List<String>.from(lead.products));
      uniqueProjects.add(lead.pname);
      uniqueLeadtypes.add(lead.leadtype);
    }
    filters["Product"] = uniqueProducts.toList();
    filters["Project"] = uniqueProjects.toList();
    filters["Leadtype"] = uniqueLeadtypes.toList();
    widget.onfilterChange(filters);
  }
}
