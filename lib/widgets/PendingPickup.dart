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
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
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
    // getleads(isRefresh: true);
  }

  @override
  void dispose() {
    _reloadTimer?.cancel();
    super.dispose();
  }

  void showOldBillDialog(BuildContext context) async {
    final TextEditingController billController = TextEditingController();

    // Example dummy lists and states (Replace with your actual API integration)
    bool isLoading = false;
    Invoice? selectedInvoice;
    List<dynamic> fetchedItems = [];

    var result = await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Function to handle your API call
            Future<void> fetchItemsFromApi(String billNo) async {
              if (billNo.isEmpty) return;

              setState(() {
                isLoading = true;
                selectedInvoice = null;
              });

              try {
                // TODO: Replace this with your actual HTTP/Dio API call
                final response = await http
                    .get(Uri.parse('$baseuri/api/inv_list/?billno=$billNo'));
                var body = json.decode(response.body);
                print(body);
                var invoices = [];
                // await Future.delayed(
                //     const Duration(seconds: 1)); // Simulating network delay
                for (var c in body) {
                  invoices.add(Invoice(
                      ac: c['AC'],
                      tt: c['TT'],
                      gstvno: c['GSTVNO'],
                      date: c['DATE'],
                      amount:
                          c['AMOUNT'] == null ? "" : c['AMOUNT'].toString()));
                }
                // Dummy fetched data results
                setState(() {
                  fetchedItems = invoices;
                  isLoading = false;
                });
              } catch (e) {
                setState(() {
                  isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to fetch items: $e')),
                  // print(body);
                );
              }
            }

            return AlertDialog(
              title: const Text('Enter Old Bill Number'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. TextField for entering bill number
                      TextField(
                        controller: billController,
                        decoration: InputDecoration(
                          labelText: 'Bill Number',
                          hintText: 'Type bill number...',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () =>
                                fetchItemsFromApi(billController.text.trim()),
                          ),
                        ),
                        onSubmitted: (value) => fetchItemsFromApi(value.trim()),
                      ),
                      const SizedBox(height: 16),

                      // 3. API Response Section (Items List)
                      const Text(
                        'Fetched Items:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : fetchedItems.isEmpty
                              ? const Text('No items loaded yet.',
                                  style: TextStyle(color: Colors.grey))
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: fetchedItems.length,
                                  itemBuilder: (context, index) {
                                    final bool isSelected =
                                        selectedInvoice == fetchedItems[index];
                                    return ListTile(
                                      selected: isSelected,
                                      selectedTileColor: Colors.blue[100],
                                      onTap: () {
                                        setState(() {
                                          selectedInvoice = fetchedItems[
                                              index]; // Update selected item
                                        });
                                      },
                                      leading: Icon(
                                        isSelected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.grey,
                                      ),
                                      title: Text(fetchedItems[index].gstvno),
                                      subtitle: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(fetchedItems[index].date),
                                          Text(fetchedItems[index].amount)
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedInvoice == null
                      ? null // Disable 'Done' button if no invoice is selected
                      : () {
                          // Return the selected single Invoice object back
                          Navigator.pop(context, selectedInvoice);
                        },
                  child: const Text('Proceed'),
                ),
              ],
            );
          },
        );
      },
    );
    print('Returned invoice: ${result}');
    if (result != null) {
      print(result);
      // process cancel api
      QuickAlert.show(
          context: context,
          type: QuickAlertType.loading,
          title: "Cancel Pickup",
          text: "Processing Cancellation of pickup");
      var response =
          await http.post(Uri.parse('$baseuri/api/cancel_pickup/'), body: {
        'old_vno': result.gstvno,
        'old_date': result.date,
        'new_vno': _controller.getSelectedItems()[0].gstvno,
        'new_date': _controller.getSelectedItems()[0].date
      });
      if (response.statusCode == 404) {
        Navigator.of(context).pop();
        QuickAlert.show(
            context: context,
            type: QuickAlertType.error,
            title: "Cancel Pickup",
            text:
                "The Selected old bill ${result.gstvno} has not been delivered. Please select a valid old bill.");
      }else if(response.statusCode == 200){
        Navigator.of(context).pop();
        QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            title: "Cancel Pickup",
            text:
                "Pickup for new bill ${_controller.getSelectedItems()[0].gstvno} has been cencelled successfully.");
      }
    }
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
                              if (selectedinv.length > 1) {
                                QuickAlert.show(
                                    context: context,
                                    type: QuickAlertType.error,
                                    title: "Cancel Pickup",
                                    text:
                                        "Please Select any one single bill to cancel");
                              } else {
                                showOldBillDialog(context);
                              }
                            },
                            icon: const Icon(Icons.cancel_outlined),
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
