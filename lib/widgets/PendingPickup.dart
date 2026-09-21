import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:business_app/constants.dart';
import 'package:business_app/models/utils.dart';
import 'package:business_app/services/network_provider.dart';
import 'package:business_app/widgets/background.dart';
import 'package:business_app/widgets/pickup.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_select_items/flutter_multi_select_items.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PendingPickup extends StatefulWidget {
  const PendingPickup({super.key});

  @override
  State<PendingPickup> createState() => _PendingPickupState();
}

class _PendingPickupState extends State<PendingPickup> {
  bool _isDataLoaded = false;

  List<Invoice> leads = [];
  List<Invoice> _foundleads = [];
  Timer? _reloadTimer;
  bool _selectAll = false;
  final MultiSelectController<Invoice> _controller =
      MultiSelectController<Invoice>();

  // Pagination variables
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    getleads(isRefresh: true);
  }

  @override
  void dispose() {
    _reloadTimer?.cancel();
    super.dispose();
  }

  Future<void> getleads({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _hasMoreData = true;
    }

    if (_isLoadingMore || !_hasMoreData) return;

    if (mounted) {
      setState(() {
        if (_currentPage == 1) {
          _isDataLoaded = false;
          leads = [];
          _foundleads = [];
        }
        _isLoadingMore = true;
      });
    }

    var sharedpref = await SharedPreferences.getInstance();
    var mob = sharedpref.getString("Mobile");
    var ut = sharedpref.getString("UT");
    http.Response response;

    final connectivityProvider =
        Provider.of<NetworkProvider>(context, listen: false);
    try {
      response = await http.get(
        Uri.parse('$baseuri/api/pendingpickup/?page=$_currentPage'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        List fetchedData = body is List ? body : (body['results'] ?? []);
        print(body);
        if (fetchedData.isEmpty) {
          _hasMoreData = false;
        } else {
          List<Invoice> newInvoices = fetchedData.map((lead) {
            // print(lead['AMOUNT']);
            return Invoice(
              ac: lead['AC'],
              gstvno: lead['GSTVNO'],
              date: lead['DATE'],
              amount: lead['AMOUNT'],
              tt: lead['TT'],
              name: lead['NAME'],
            );
          }).toList();

          if (mounted) {
            setState(() {
              if (_currentPage == 1) {
                leads = newInvoices;
              } else {
                // Prevent duplicate appending if the scroll trigger fires twice quickly
                leads.addAll(newInvoices);
              }
              
              // Create a brand new list reference so Flutter detects the change
              _foundleads = List.from(leads); 
              // _controller.setItems(_foundleads);
              _currentPage++;
              _isDataLoaded = true;
              _isLoadingMore = false;
            });
          }
        }

        if (mounted) {
          setState(() {
            _isDataLoaded = true;
            _isLoadingMore = false;
          });
        }
      } else if (response.statusCode == 404) {
        // Handle when page exceeds total pages available on backend
        setState(() {
          _hasMoreData = false;
          _isLoadingMore = false;
          _isDataLoaded = true;
        });
      } else {
        setState(() {
          _isLoadingMore = false;
          _isDataLoaded = true;
        });
      }
    } on SocketException catch (_) {
      connectivityProvider.setConnected(false);
      setState(() {
        _isLoadingMore = false;
        _isDataLoaded = true;
      });
    } on http.ClientException catch (_) {
      connectivityProvider.setConnected(false);
      setState(() {
        _isLoadingMore = false;
        _isDataLoaded = true;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final isConnected = Provider.of<NetworkProvider>(context).isOnline;

    if (isConnected && !_isDataLoaded) {
      _reloadTimer?.cancel();
      _reloadTimer = Timer(const Duration(seconds: 2), () {
        getleads(isRefresh: true);
      });
    }

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
      childs: !_isDataLoaded && leads.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : leads.isEmpty
              ? const Center(
                  child: Text("No Pending Pickups to Show"),
                )
              : Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: CheckboxListTile(
                            controlAffinity: ListTileControlAffinity.leading,
                            value: _selectAll,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _controller.selectAll();
                                } else {
                                  _controller.deselectAll();
                                }
                                _selectAll = value ?? false;
                              });
                            },
                            title: const Text("Select All"),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: IconButton(
                            onPressed: () {
                              var selectedinv = _controller.getSelectedItems();
                              if (kDebugMode) {
                                print("Selected Invoices: $selectedinv");
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PickupForm(selectedInvoices: selectedinv),
                                ),
                              ).then((value) {
                                // Refresh the leads after returning from the PickupForm
                                getleads(isRefresh: true);
                              });
                            },
                            icon: const Icon(Icons.local_shipping),
                          ),
                        )
                      ],
                    ),
                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (scrollInfo) {
                          // Trigger pagination fetch when scrolled within 200 pixels of the bottom
                          if (scrollInfo.metrics.pixels >=
                              scrollInfo.metrics.maxScrollExtent - 100) {
                            if (!_isLoadingMore && _hasMoreData) {
                              getleads();
                            }
                          }
                          return false;
                        },
                        child: MultiSelectCheckList<Invoice>(
                          key: ValueKey(_foundleads.length),
                          itemsDecoration: MultiSelectDecorations(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey,
                                width: 1,
                              ),
                            ),
                            selectedDecoration: BoxDecoration(
                              color: Colors.deepOrange.shade200,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.deepOrange,
                                width: 1,
                              ),
                            ),
                          ),
                          items: _foundleads
                              .map((e) => CheckListCard<Invoice>(
                                    selectedColor: Colors.deepOrange[400],
                                    value: e,
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "${e.name}",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                            softWrap: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Row(
                                      children: [
                                        Text(
                                          e.gstvno,
                                          textAlign: TextAlign.left,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const Spacer(),
                                        Text(
                                          DateFormat("dd/MM/yyyy").format(
                                              DateFormat("yyyy-MM-dd")
                                                  .parse(e.date)),
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const Spacer(),
                                        Text(
                                          e.amount,
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChange: (allSelectedItems, selectedItem) {
                            if (kDebugMode) {
                              print(
                                  'Selected items: ${allSelectedItems.length}');
                              print(selectedItem.gstvno);
                            }
                          },
                          controller: _controller,
                        ),
                      ),
                    ),
                    if (_isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
      appbartitle: const Text("Pending Pickup"),
      appbaractions: const [],
      appbar: true,
    );
  }
}
