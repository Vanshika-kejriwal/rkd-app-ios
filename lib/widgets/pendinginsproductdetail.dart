import 'dart:convert';

import 'package:business_app/constants.dart';
import 'package:business_app/models/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/models/quickalert_type.dart';
// import 'package:quickalert/widgets/quickalert_dialog.dart' show QuickAlert;
import 'package:quickalert/widgets/quickalert_dialog.dart';

class ProductDetailsDialog extends StatefulWidget {
  final String pjc;
  final List<String> value;

  const ProductDetailsDialog({
    super.key,
    required this.pjc,
    required this.value,
  });

  @override
  State<ProductDetailsDialog> createState() => _ProductDetailsDialogState();
}

class _ProductDetailsDialogState extends State<ProductDetailsDialog> {
  // Store the future to prevent duplicate API hits on UI rebuilds
  late Future<List<ProductAggregation>> _productDetailsFuture;
  final Set<String> _selectedItemKeys = {};

  Future<List<ProductAggregation>>? fetchInstProductDetails(
      String pjc, List<String> value) async {
    final response = await http.post(
        Uri.parse('$baseuri/api/instproductdetail/'),
        body: jsonEncode({"pjc": pjc, "productlist": value}),
        headers: {"Content-Type": "application/json"});
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      List<ProductAggregation> products = [];
      for (var item in body) {
        products.add(ProductAggregation.fromJson(item));
      }
      return products;
    } else {
      throw Exception('Failed to load installation product details');
    }
  }

  @override
  void initState() {
    super.initState();
    _productDetailsFuture = fetchInstProductDetails(widget.pjc, widget.value)!;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return AlertDialog(
      title: const Text("Pending Product Details"),
      content: SizedBox(
        // Dynamic, responsive bounds for the inner view
        width: screenSize.width * 0.85,
        height: screenSize.height * 0.65,
        child: FutureBuilder<List<ProductAggregation>>(
          future: _productDetailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No data found'));
            }

            final products = snapshot.data!;

            // Outer primary scroll view for moving down through multiple tables
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: products.map((product) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Header Banner above its respective table
                        Text(
                          "${product.product} — ${product.company}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Inner horizontal scroll view unique to this product's data table
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              Colors.grey.shade100,
                            ),
                            columns: const [
                              DataColumn(label: Text('Select')),
                              DataColumn(label: Text('Item Name')),
                              DataColumn(label: Text('Quantity')),
                              DataColumn(label: Text('Bill Date')),
                            ],
                            rows: product.items.map((item) {
                              final itemKey = "${product.mc}_${item.code}";
                              if (kDebugMode) {
                                print("Item Key: $itemKey");
                              } // Debugging line to check the unique key
                              final isSelected =
                                  _selectedItemKeys.contains(itemKey);
                              return DataRow(
                                selected: isSelected,
                                cells: [
                                  DataCell(
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedItemKeys.add(itemKey);
                                          } else {
                                            _selectedItemKeys.remove(itemKey);
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  DataCell(Text(item.name.toString())),
                                  DataCell(Text(item.quantity.toString())),
                                  DataCell(Text(item.billdate.toString())),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            // Return selected item keys (or custom objects) back to the parent screen
            // Navigator.of(context).pop(_selectedItemKeys.toList());
            // api for deletion
            _deleteSelectedItems();
          },
          child: Text('Delete (${_selectedItemKeys.length})'),
        ),
      ],
    );
  }

  void _deleteSelectedItems() {
    if (_selectedItemKeys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items selected for deletion.')),
      );
      return;
    }
    QuickAlert.show(
      context:context,
      title: 'Confirm Deletion',
      text: 'Are you sure you want to delete the selected items?',
      type: QuickAlertType.confirm,
      confirmBtnText: 'Yes, Delete',
      cancelBtnText: 'Cancel',
      onConfirmBtnTap: () {
        Navigator.of(context).pop(); // Close the alert
        QuickAlert.show(
          context: context,
          type: QuickAlertType.loading,
          text: 'Deleting items...',
          barrierDismissible: false,
        );
        // Prepare the payload for the API call
        final payload = {
          "pjc": widget.pjc,
          "items": _selectedItemKeys.toList(),
        };

        // Make the API call to delete the selected items
        http.post(
          Uri.parse('$baseuri/api/deleteinstitems/'),
          body: jsonEncode(payload),
          headers: {"Content-Type": "application/json"},
        ).then((response) {
          if (response.statusCode == 200) {
            Navigator.of(context).pop(); // Close the loading alert
            // Optionally, you can refresh the data or close the dialog
            setState(() {
              _productDetailsFuture =
                  fetchInstProductDetails(widget.pjc, widget.value)!;
              _selectedItemKeys.clear(); // Clear selection after deletion
            });
          } else {
            // Handle error response
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Failed to delete items: ${response.body}')),
            );
          }
        }).catchError((error) {
          // Handle network or other errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error occurred: $error')),
          );
        });
      },
    );
  }
}
