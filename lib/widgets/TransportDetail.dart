import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:business_app/constants.dart';
import 'package:business_app/models/utils.dart';
import 'package:business_app/services/network_provider.dart';
import 'package:business_app/widgets/TransportForm.dart';
import 'package:business_app/widgets/background.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_select_items/flutter_multi_select_items.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransportDetail extends StatefulWidget {
  const TransportDetail({super.key});

  @override
  State<TransportDetail> createState() => _TransportDetailState();
}

class _TransportDetailState extends State<TransportDetail> {

  bool _isDataLoaded = false;

  List<PendingTransport> leads = []; // Assuming PendingTransport is a defined class
  List<PendingTransport> _foundleads = [];
  List<PendingTransport> initleads = [];
  Timer? _reloadTimer;
  final bool _selectAll = false;
  final MultiSelectController<PendingTransport> _controller =
      MultiSelectController<PendingTransport>();

  Future<void> getleads() async {
    if (mounted) {
      setState(() {
        _isDataLoaded = false;
        leads = [];
        _foundleads = [];
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
        final Map<String, String> queryParameters = {};
        if (ut!.toLowerCase() == "employee" && mob != null && mob.isNotEmpty) {
          queryParameters['mob'] = mob;
        }
        response = await http.get(
            Uri.parse(
                '$baseuri/api/pendingtransport/').replace(queryParameters: queryParameters.isNotEmpty ? queryParameters : null),
            headers: {"Content-Type": "application/json"});

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
            leads = [];
            _foundleads = [];
            body.forEach((lead) {
              leads.add(PendingTransport(
                pickupno: lead['Pickup_no'] as String,
                name: lead['Customer_Name'] as String,
                city: lead['City'] as String,
                deltype: lead['Deliverytype'] as String?, // Optional field
                extramob: lead['EXTRA_MOB'] as String?,
                invoices: lead['invoices'],
                gstvno: lead['gstvno'],
                emobile: lead["EMOBILE"],
                ename: lead["ENAME"],
                ac: lead["AC"],
                pickuptime: lead["PICKUPDATETIME"]
              ));

              // DateTime followup = DateFormat('yyyy-MM-ddTHH:mm:ss.SSSSSS')
              // .parse(lead['LAST_FOLLOWUP']);
            });
          }
          // leads.remove(value)
          initleads = leads;
          _foundleads = leads;

          // filtervalues();
          if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    return Background(
      childs: !_isDataLoaded
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : leads.isEmpty
              ? const Center(
                  child: Text("No Pending Pickups to Show"),
                )
              : Column(
                children: [
                  // Padding(
                  //   padding: const EdgeInsets.all(5),
                  //   child: InputField(
                  //     label: "Search",
                  //     onChanged: (value) {
                  //       List<Invoice> results = [];
                  //       if (value.isEmpty) {
                  //         results = leads;
                  //       } else {
                  //         results = leads.where((lead) {
                  //           return value
                  //                   .toLowerCase()
                  //                   .split(" ")
                  //                   .where((word) => word.isNotEmpty)
                  //                   .toList()
                  //                   .every((word) => lead.gstvno
                  //                       .toLowerCase()
                  //                       .contains(word)) ||
                  //               value
                  //                   .toLowerCase()
                  //                   .split(" ")
                  //                   .where((word) => word.isNotEmpty)
                  //                   .toList()
                  //                   .every((word) => lead.date
                  //                       .toLowerCase()
                  //                       .contains(word)) ||
                  //               value
                  //                   .toLowerCase()
                  //                   .split(" ")
                  //                   .where((word) => word.isNotEmpty)
                  //                   .toList()
                  //                   .every((word) =>  lead.amount
                  //                       .toLowerCase()
                  //                       .contains(word));
                  //         }).toList();
                  //       }
                  //       setState(() {
                  //         _foundleads = results;
                  //       });
                  //     },
                  //   ),
                  // ),
                  // Row(
                  //   children: [
                  //     Expanded(
                  //       flex: 4,
                  //       child: CheckboxListTile(
                  //           controlAffinity: ListTileControlAffinity.leading,
                  //           value: _selectAll,
                  //           onChanged: (value) {
                  //             setState(() {
                  //               if (value == true) {
                  //                 _controller.selectAll();
                  //               } else {
                  //                 _controller.deselectAll();
                  //               }
                  //               _selectAll = value ?? false;
                  //             });
                  //           },
                  //           title: const Text("Select All")),
                  //     ),
                  //     Expanded(
                  //       flex: 1,
                  //       child: IconButton(
                  //           onPressed: () {
                  //             var selectedinv = _controller.getSelectedItems();
                  //             print("Selected Invoices: $selectedinv");
                              
                                
                              
                  //           },
                  //           icon: const Icon(Icons.note_add_outlined)),
                  //     )
                  //   ],
                  // ),
                  Expanded(
                    // child: MultiSelectCheckList<PendingTransport>(
                    //   itemsDecoration: MultiSelectDecorations(
                    //     // selectedColor: Colors.deepOrange.shade100,
                    //     decoration: BoxDecoration(
                    //       color: Colors.grey.shade200,
                    //       borderRadius: BorderRadius.circular(8),
                    //       border: Border.all(
                    //         color: Colors.grey,
                    //         width: 1,
                    //       ),
                    //     ),
                    //     selectedDecoration: BoxDecoration(
                    //       color: Colors.deepOrange.shade200,
                    //       borderRadius: BorderRadius.circular(8),
                    //       border: Border.all(
                    //         color: Colors.deepOrange,
                    //         width: 1,
                    //       ),
                    //     ),
                    //     // textStyle: const TextStyle(
                    //     //   fontSize: 16,
                    //     // ),
                    //   ),
                    //   items: _foundleads
                    //       .map((e) => CheckListCard<PendingTransport>(
                    //             selectedColor: Colors.deepOrange[400],
                    //             value: e,
                    //             title: Row(
                    //               mainAxisAlignment:
                    //                   MainAxisAlignment.spaceBetween,
                    //               children: [
                    //                 Expanded(
                    //                   child: Text(
                    //                           "${e.name}",
                    //                           style: const TextStyle(
                    //                               fontWeight: FontWeight.bold),
                    //                               softWrap: true,
                    //                         ),
                    //                 ),
                                        
                    //                 // : const Text(
                    //                 //     "Sale Invoice",
                    //                 //     style: TextStyle(
                    //                 //         fontWeight: FontWeight.bold),
                    //                 //   ),
                                    
                                      
                                    
                    //               ],
                    //             ),
                    //             subtitle: Text(
                    //                   e.city,
                    //                   textAlign: TextAlign.left,
                    //                   style: const TextStyle(fontSize: 14),
                    //                 ),
                    //             // controller: _controller,
                    //           ))
                    //       .toList(),
                    //   onChange: (allSelectedItems, selectedItem) {
                    //     // Handle selection changes here

                    //     if (kDebugMode) {
                    //       print('Selected items: ${allSelectedItems.length}');
                    //       print(selectedItem.pickupno);
                    //     }
                    //   },
                    //   controller: _controller,
                    //   // You can customize other properties as needed
                    // ),
                    child: ListView.builder(
                        itemCount: _foundleads.length,
                        itemBuilder: (context, index) {
                          return Card(
                              color: Colors.transparent,
                              child: ListTile(
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                     Text(
                                            _foundleads[index].name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          )
                                        
                                    // : const Text(
                                    //     "Sale Invoice",
                                    //     style: TextStyle(
                                    //         fontWeight: FontWeight.bold),
                                    //   ),
                                    
                                  ],
                                ),
                                subtitle: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _foundleads[index].city,
                                      textAlign: TextAlign.left,
                                    ),
                                    Text(
                                      _foundleads[index].deltype!,
                                      textAlign: TextAlign.left,
                                    ),
                                    // const Spacer(),
                                    // Text(DateFormat("dd/MM/yyyy").format(
                                    //     DateFormat("yyyy-MM-dd")
                                    //         .parse(_foundleads[index].date)), textAlign: TextAlign.center,),
                                    
                                  ],
                                ),
                                // isThreeLine: true,
                                // trailing: Text(DateFormat("dd/MM/yyyy").format(
                                //         DateFormat("yyyy-MM-dd")
                                //             .parse(_foundleads[index].date)),),
                                tileColor: Colors.transparent,
                                onTap: () {
                                  Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TransportForm(
                                      selectedInvoices: [_foundleads[index]]),
                                ),
                              ).then((value) {
                                getleads();
                              });
                                  // Use Navigator.push for navigation
                                  // Navigator.push(
                                  //   context,
                                  //   MaterialPageRoute(
                                  //     builder: (context) => LeadDetail(
                                  //         currentlead: _foundleads[index]),
                                  //   ),
                                  // );
                                },
                              ));
                        }),
                  ),
                ],
              ),
      appbar: true,
      appbaractions: const [],
      appbartitle: Text('Transport Detail'),
    );
  }
}