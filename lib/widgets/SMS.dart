import 'dart:convert';

import 'package:business_app/constants.dart';
import 'package:business_app/models/utils.dart';
import 'package:business_app/widgets/background.dart';
import 'package:business_app/widgets/input_field.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';

class Sms extends StatefulWidget {
  const Sms({super.key});

  @override
  State<Sms> createState() => _SmsState();
}

class _SmsState extends State<Sms> {
  List<LeadProduct> comp = [];
  LeadProduct? selectedItem;
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _increasepController = TextEditingController();
  final TextEditingController _hikedateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(DateTime.now()));
  final TextEditingController _billdaysController = TextEditingController();

  Future<List<LeadProduct>>? getcomp() async {
    List<LeadProduct> data = [];
    var response = await http.get(Uri.parse("$baseuri/api/getmmastcomp/"));
    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body);
      // data.add(LeadProduct(company: "Add New", product: "Add New", mc: "Add New"));
      data.addAll((jsonData as List)
          .map((e) =>
              LeadProduct(company: e["FNM"], product: e["PNM"], mc: e["MC"]))
          .toList());
      var uniqueData =
          {for (var item in data) item.company: item}.values.toList();
      setState(() {
        comp = uniqueData;
      });
    }
    return data;
  }

  Future<void> showPriceHikeDialog() async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(builder: (context, setstate) {
        // Future<void> pickImage() async {
        //   final picker = ImagePicker();
        //   final pickedFile = await picker.pickImage(
        //       source: ImageSource.camera,
        //       imageQuality: 5); // Or ImageSource.camera

        //   if (pickedFile != null) {
        //     setstate(() {
        //       _selectedImage = File(pickedFile.path);
        //     });
        //   }
        // }

        return AlertDialog(
          title: Text("Price Hike Message"),

          // content: InputField(label: lablel, controller: _emailotpcontroller),
          content: SingleChildScrollView(
            // Use SingleChildScrollView for scrollability if content gets long
            child: Column(
              mainAxisSize: MainAxisSize.min, // Make column wrap its content
              children: [
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: DropdownSearch<LeadProduct>(
                      // key: _projectkey,
                      // controller
                      compareFn: (item1, item2) => item1.mc == item2.mc,
                      popupProps: PopupProps.dialog(
                        dialogProps: DialogProps(
                          barrierDismissible: true,
                          barrierLabel: "Dismiss",
                        ),
                        // showSelectedItems: true,
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: const InputDecoration(
                            labelText: "Search for an item*",
                          ),
                        ),
                      ),
                      // mode: Mode.dialog,
                      // showSelectedItems: true,

                      items: (filter, infiniteScrollProps) => comp,
                      itemAsString: (item) {
                        return item.company;
                      },
                      filterFn: (item, filter) {
                        // This function determines which items are shown in the dropdown
                        // based on the user's input (the 'filter' string).
                        // It's case-insensitive for better UX.
                        // print(
                        //     'filterFn - item: "$item", filter: "$filter"');
                        return item.company == "Add New" ||
                            item.company
                                .toLowerCase()
                                .contains(filter.toLowerCase());
                      },
                      decoratorProps: const DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: "Company*",
                          hintText: "Select a Company",
                        ),
                      ),
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a company from the List or enter a new name"';
                        }
                        return null;
                      },
                      autoValidateMode: AutovalidateMode.onUserInteraction,
                      // dropdownSearchDecoration: const InputDecoration(
                      // labelText: "Menu mode",
                      // hintText: "country in menu mode",
                      // ),
                      // popupItemDisabled: isItemDisabled,
                      onSelected: (data) {
                        setState(() {
                          selectedItem = data;
                        });
                        // getprojdetail(data);
                      },
                      selectedItem: selectedItem
                      // showSearchBox: true,
                      // searchFieldProps: TextFieldProps(
                      //   cursorColor: Colors.blue,
                      // ),
                      ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: InputField(
                      label: "Reason", controller: _reasonController),
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: InputField(
                      label: "Increase Percent",
                      controller: _increasepController),
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: InputField(
                    label: "Date Effective",
                    controller: _hikedateController,
                    readOnly: true,
                    onTap: () => showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    ).then((selectedDate) {
                      if (selectedDate != null) {
                        setState(() {
                          _hikedateController.text =
                              "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";
                        });
                      }
                    }),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: InputField(
                      label: "No. of Days of Billing",
                      keyboardtype: TextInputType.number,
                      controller: _billdaysController),
                ),
                const SizedBox(height: 20),
                // ElevatedButton.icon(
                //   onPressed: pickImage,
                //   icon: const Icon(Icons.image),
                //   label: const Text('Pick Image'),
                // ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // setstate(() {
                //   _selectedImage = null;
                //   _kmController.text = '';
                // });
                Navigator.of(context).pop(null); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // final String enteredText = _kmController.text;
                // _selectedImage contains the File object

                // Example of how to return data
                Navigator.of(context).pop({
                  'company': selectedItem?.company,
                  'mc': selectedItem?.mc,
                  'reason': _reasonController.text,
                  'increasep':
                      _increasepController.text, // Pass the File object
                  "eff_date": _hikedateController.text,
                  "bill_days": _billdaysController.text
                });
              },
              child: const Text('Send Message'),
            ),
          ],
        );
      }),
    );
    if (kDebugMode) {
      print(result);
    }
    if (result != null) {
      //call api to send the message
      QuickAlert.show(
          context: context,
          type: QuickAlertType.loading,
          title: "Price Hike Message",
          text: "Preparing Numbers to send message");
      var response = await http.post(Uri.parse("$baseuri/api/pricehikemsg/"),
          body: result);
      if (response.statusCode == 202) {
        var body = json.decode(response.body);
        Navigator.of(context).pop();
        QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            title: "Price Hike Message",
            text: "Strated sending ${body['no_of_messages']} Messages");
      }
    }
  }

  @override
  void initState() {
    getcomp();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Background(
        childs: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(252, 101, 8, 1),
                        foregroundColor: Colors.white),
                    onPressed: showPriceHikeDialog,
                    child: Text('Price Hike'))
              ],
            ),
          ),
        ),
        appbartitle: Text("SMS Services"),
        appbar: true,
        appbaractions: []);
  }
}
