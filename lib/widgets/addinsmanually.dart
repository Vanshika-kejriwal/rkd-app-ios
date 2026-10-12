import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:business_app/constants.dart';

class InstallationSelectionDialog extends StatefulWidget {
  // final String apiUrl; // Pass your backend endpoint URL here

  const InstallationSelectionDialog({super.key});

  @override
  InstallationSelectionDialogState createState() =>
      InstallationSelectionDialogState();
}

class InstallationSelectionDialogState
    extends State<InstallationSelectionDialog> {
  final TextEditingController _daysController =
      TextEditingController();
  bool _isLoading = false;

  Map<String, dynamic>? apiResponse;

  // Selected values
  Map<String, dynamic>? selectedProject;
  List<String> selectedProductTypes = [];
  List<String> selectedCnames = [];
  List<Map<String, dynamic>> selectedItems = [];

  // Fetch API function (resets selections on every new fetch)
  Future<void> _fetchInstallations() async {
    final days = int.tryParse(_daysController.text) ?? 20;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      selectedProject = null;
      selectedProductTypes.clear();
      selectedCnames.clear();
      selectedItems.clear();
    });

    try {
      final response = await http.post(
        Uri.parse('$baseuri/api/getinstfrominv/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"days": days}),
      );

      if (response.statusCode == 200) {
        setState(() {
          apiResponse = jsonDecode(response.body);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch data from server")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Data helpers derived from selections
  List<dynamic> get projects => apiResponse?['data'] ?? [];

  List<String> get availableProductTypes {
    if (selectedProject == null) return [];
    List products = selectedProject!['Products'] ?? [];
    return products
        .map<String>((p) => p['Product-Type'].toString())
        .toSet()
        .toList();
  }

  List<String> get availableCnames {
    if (selectedProject == null || selectedProductTypes.isEmpty) return [];
    List products = selectedProject!['Products'] ?? [];
    return products
        .where(
            (p) => selectedProductTypes.contains(p['Product-Type'].toString()))
        .map<String>((p) => p['CNAME'].toString())
        .toSet()
        .toList();
  }

  List<Map<String, dynamic>> get availableItems {
    if (selectedProject == null ||
        selectedProductTypes.isEmpty ||
        selectedCnames.isEmpty) {
      return [];
    }
    List products = selectedProject!['Products'] ?? [];
    List<Map<String, dynamic>> items = [];

    for (var p in products) {
      if (selectedProductTypes.contains(p['Product-Type'].toString()) &&
          selectedCnames.contains(p['CNAME'].toString())) {
        List pItems = p['Items'] ?? [];
        for (var item in pItems) {
          items.add(Map<String, dynamic>.from(item));
        }
      }
    }
    return items;
  }

  Future<void> _submitSelections() async {
    List<Map<String, dynamic>> combinations = [];

    // If a project is selected, traverse through its products
    if (selectedProject != null) {
      List products = selectedProject!['Products'] ?? [];
      for (var prod in products) {
        String productCname = prod['CNAME'].toString();
        int mc = prod['MC'];

        // Check if this product's CNAME matches user selection
        if (selectedCnames.contains(productCname)) {
          List items = prod['Items'] ?? [];
          for (var item in items) {
            // Check if this item is in the selectedItems list
            bool isItemSelected = selectedItems
                .any((selected) => selected['CODE'] == item['CODE']);

            if (isItemSelected) {
              combinations.add({
                "MC": mc,
                "Product-Type": prod['Product-Type'],
                'VNO': item['VNO'],
                'CDATE': item['DATE'],
                "CNAME": productCname,
                "CODE": item['CODE'],
                "NAME": item['NAME'],
                "QTY": item['QTY'],
              });
            }
          }
        }
      }
    }

    // Construct final request body
    final payload = {
      "AC": selectedProject?['AC'],
      "PJC": selectedProject?['PJC'],
      "selections": combinations,
    };

    print("Payload to send: ${jsonEncode(payload)}");

    // Send to backend
    try {
      setState(() => _isLoading = true);
      final response = await http.post(
        Uri.parse("$baseuri/api/submitinst/"), // Adjust endpoint as needed
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Submitted successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Submission failed.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Installation from Invoice"),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Always Accessible Numeric Input & Fetch Button Row ---
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _daysController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Days Range",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _fetchInstallations,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text("Fetch"),
                  ),
                ],
              ),
              const Divider(height: 30),

              // --- Dependent Dropdowns (Visible once data is loaded) ---
              if (apiResponse != null) ...[
                // 1. PROJECT DROPDOWN (Single Selection)
                DropdownSearch<Map<String, dynamic>>(
                  items: (filter, infiniteScrollProps) => projects
                      .map<Map<String, dynamic>>(
                          (e) => Map<String, dynamic>.from(e))
                      .toList(),
                  itemAsString: (item) =>
                      "${item['PNAME']} (${item['CUSTTYPE']})",
                  compareFn: (item1, item2) => item1['PJC'] == item2['PJC'],
                  selectedItem: selectedProject,
                  popupProps: const PopupProps.dialog(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(labelText: "Search Project"),
                    ),
                  ),
                  decoratorProps: const DropDownDecoratorProps(
                    decoration: InputDecoration(labelText: "Project"),
                  ),
                  onSelected: (val) {
                    setState(() {
                      selectedProject = val;
                      selectedProductTypes = [];
                      selectedCnames = [];
                      selectedItems = [];
                    });
                  },
                ),
                const SizedBox(height: 16),

                // 2. PRODUCT TYPE DROPDOWN (Multi-Selection)
                DropdownSearch<String>.multiSelection(
                  items: (filter, infiniteScrollProps) => availableProductTypes,
                  selectedItems: selectedProductTypes,
                  compareFn: (item1, item2) => item1 == item2,
                  enabled: selectedProject != null,
                  popupProps: const MultiSelectionPopupProps.dialog(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration:
                          InputDecoration(labelText: "Search Product Type"),
                    ),
                  ),
                  decoratorProps: const DropDownDecoratorProps(
                    decoration: InputDecoration(labelText: "Product Type"),
                  ),
                  onSelected: (val) {
                    setState(() {
                      selectedProductTypes = val;
                      selectedCnames = [];
                      selectedItems = [];
                    });
                  },
                ),
                const SizedBox(height: 16),

                // 3. CNAME DROPDOWN (Multi-Selection)
                DropdownSearch<String>.multiSelection(
                  items: (filter, infiniteScrollProps) => availableCnames,
                  selectedItems: selectedCnames,
                  compareFn: (item1, item2) => item1 == item2,
                  enabled: selectedProductTypes.isNotEmpty,
                  popupProps: const MultiSelectionPopupProps.dialog(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(labelText: "Search CNAME"),
                    ),
                  ),
                  decoratorProps: const DropDownDecoratorProps(
                    decoration: InputDecoration(labelText: "CNAME"),
                  ),
                  onSelected: (val) {
                    setState(() {
                      selectedCnames = val;
                      selectedItems = [];
                    });
                  },
                ),
                const SizedBox(height: 16),

                // 4. ITEMS DROPDOWN (Multi-Selection)
                DropdownSearch<Map<String, dynamic>>.multiSelection(
                  items: (filter, infiniteScrollProps) => availableItems,
                  selectedItems: selectedItems,
                  enabled: selectedCnames.isNotEmpty,
                  compareFn: (item1, item2) => item1 == item2,
                  itemAsString: (item) => "${item['NAME']}",
                  popupProps: const MultiSelectionPopupProps.dialog(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(labelText: "Search Items"),
                    ),
                  ),
                  decoratorProps: const DropDownDecoratorProps(
                    decoration: InputDecoration(labelText: "Items"),
                  ),
                  onSelected: (val) {
                    setState(() {
                      selectedItems = val;
                    });
                  },
                ),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("Enter days and tap 'Fetch' to load data."),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed:(apiResponse == null || selectedProject == null || selectedItems.isEmpty) 
              ? null 
              : _submitSelections,
          child: const Text("Submit"),
        ),
      ],
    );
  }
}
