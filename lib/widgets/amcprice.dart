import 'dart:convert';
import 'dart:io';

import 'package:business_app/constants.dart';
import 'package:business_app/models/utils.dart';
import 'package:business_app/screens/pdfview.dart';
import 'package:business_app/widgets/background.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AMCRate extends StatefulWidget {
  const AMCRate({super.key});

  @override
  State<AMCRate> createState() => _AMCRateState();
}

class _AMCRateState extends State<AMCRate> {

  LeadProduct? _selectedproduct;
  List<LeadProduct> _products = [];

  Future<void> getProducts() async {
    
    http.Response response;

    try {
      response = await http.get(
        Uri.parse('$baseuri/api/amc_products/'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> productList = json.decode(response.body);
        setState(() {
          _products = productList
              .map((product) => LeadProduct(
                    company: product['Company'],
                    product: product['Product_Type'],
                  ))
              .toList();
        });
      } else {
        if (kDebugMode) {
          print('Failed to load products. Status code: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching products: $e');
      }
    }
  }

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    getProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      appbar: true,
      appbartitle: Text("AMC Rate"),
      appbaractions: [],
      childs: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.all(5.0), 
          child: DropdownSearch<LeadProduct>(
            compareFn: (LeadProduct? a, LeadProduct? b) => a?.hashCode == b?.hashCode,
            decoratorProps:
                                        const DropDownDecoratorProps(
                                      decoration: InputDecoration(
                                        labelText: "Product",
                                        hintText: "Select a Product",
                                      ),
                                    ),
            items: ((filter, loadProps) => _products),
            itemAsString: (LeadProduct? product) => "${product?.product} - ${product?.company}",
            onSelected: (LeadProduct? selectedProduct) {
              setState(() {
                _selectedproduct = selectedProduct;
              });
            },
          ),
          ),
          
          Center(
            child: ElevatedButton(
              onPressed: () {
                // Navigate to the AMC Price screen
                QuickAlert.show(
                                          context: context,
                                          type: QuickAlertType.loading,
                                          title: 'Generating Rate List...',
                                          barrierDismissible: false,
                                        );
                                        var query = {
                                          "product": _selectedproduct?.product,
                                          "company": _selectedproduct?.company,
                                        };
                                        http.post(
                                          Uri.parse('$baseuri/api/amcpriceprint/'),
                                          body: json.encode(query),
                                          headers: {
                                            "Content-Type": "application/json"
                                          },
                                        ).then((response) async {
                                          if (response.statusCode == 200) {
                                            final jsonResponse =
                                                jsonDecode(response.body);
            
                                            // --- Extracting Mobile Numbers and Filename ---
            
                                            final List<String> mobileNumbers = await SharedPreferences.getInstance()
                .then((prefs) {
                  final String? mobile = prefs.getString('Mobile');
                  return mobile != null && mobile.isNotEmpty ? [mobile] : [];
                });
                                            final String filename =
                                                jsonResponse['filename'];
            
                                            if (kDebugMode) {
                                              print(
                                                '✅ Received Mobile Numbers: $mobileNumbers');
                                                print('✅ Filename: $filename');
                                            }
                                            
            
                                            // --- Decoding and Saving the PDF File ---
            
                                            final String base64Pdf =
                                                jsonResponse['pdf_data'];
            
                                            // 3. Base64 Decode the PDF string into raw bytes (Uint8List)
                                            final pdfBytes =
                                                base64Decode(base64Pdf);
                                            final dir =
                                                await getTemporaryDirectory();
                                            final filepath =
                                                '${dir.path}/AMC Price(${_selectedproduct?.product}-${_selectedproduct?.company})-${DateTime.now().millisecondsSinceEpoch}.pdf';
                                            File file = File(filepath);
                                            await file.writeAsBytes(pdfBytes);
                                            Navigator.of(context)
                                                .pop(); // Close the loading dialog
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => Pdfview(
                                                  file: file,
                                                  type: "AMC Price",
                                                  ac: "${_selectedproduct?.company}-${_selectedproduct?.product}",
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
                                    backgroundColor:
                                        const Color.fromRGBO(252, 101, 8, 1),
                                    foregroundColor: Colors.white),
              child: const Text("View AMC Price"),
            ),
          ),
        ],
      ),
    );
  }
}