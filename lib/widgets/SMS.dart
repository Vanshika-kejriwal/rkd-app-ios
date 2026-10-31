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
  List<CommonWAMsg> watemplates = [];
  LeadProduct? selectedItem;
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _increasepController = TextEditingController();
  final TextEditingController _hikedateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(DateTime.now()));
  final TextEditingController _billdaysController = TextEditingController();
  CommonWAMsg? selectedtemplate;

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

  Future<List<CommonWAMsg>>? getcommonwatemplates() async {
    List<CommonWAMsg> data = [];
    var response = await http.get(Uri.parse("$baseuri/api/commonwamsglist/"));
    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body);
      // data.add(LeadProduct(company: "Add New", product: "Add New", mc: "Add New"));
      print(jsonData);
      data.addAll((jsonData as List)
          .map((e) => CommonWAMsg(
              name: e['name'],
              category: e['category'],
              requiresheader: e['requires_header'],
              headertype: e['header_type'],
              endpointsuffix: e['endpoint_suffix']))
          .toList());

      setState(() {
        watemplates = data;
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
            text: "Strated sending ${body['no_of_messages']} Messages",
            textColor: Colors.black87);
      }
    }
    setState(() {
      selectedItem = null;
      _reasonController.clear();
      _increasepController.clear();
      _hikedateController.clear();
      _billdaysController.clear();
    });
  }

  Future<void> showCommonMsgDialog() async {
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
          title: Text("Common List Message"),

          // content: InputField(label: lablel, controller: _emailotpcontroller),
          content: SingleChildScrollView(
            // Use SingleChildScrollView for scrollability if content gets long
            child: Column(
              mainAxisSize: MainAxisSize.min, // Make column wrap its content
              children: [
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: DropdownSearch<CommonWAMsg>(
                      // key: _projectkey,
                      // controller
                      compareFn: (item1, item2) => item1.name == item2.name,
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

                      items: (filter, infiniteScrollProps) => watemplates,
                      itemAsString: (item) {
                        return item.name;
                      },
                      filterFn: (item, filter) {
                        // This function determines which items are shown in the dropdown
                        // based on the user's input (the 'filter' string).
                        // It's case-insensitive for better UX.
                        // print(
                        //     'filterFn - item: "$item", filter: "$filter"');
                        return item.name
                            .toLowerCase()
                            .contains(filter.toLowerCase());
                      },
                      decoratorProps: const DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: "Template*",
                          hintText: "Select a Template",
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
                        setstate(() {
                          selectedtemplate = data;
                        });
                        // getprojdetail(data);
                      },
                      selectedItem: selectedtemplate
                      // showSearchBox: true,
                      // searchFieldProps: TextFieldProps(
                      //   cursorColor: Colors.blue,
                      // ),
                      ),
                ),
                if (selectedtemplate?.requiresheader == true)
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: InputField(
                        label: selectedtemplate?.headertype?.toLowerCase() ==
                                "text"
                            ? "Header Text"
                            : 
                                 "Header ${selectedtemplate?.headertype?.toLowerCase()} link"
                               ,
                        controller: _reasonController),
                  ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: InputField(
                      label: "Paste Data CSV file link",
                      controller: _increasepController),
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
                  'template': selectedtemplate,

                  'header': _reasonController.text,
                  'file_link':
                      _increasepController.text, // Pass the File object
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
      final CommonWAMsg selectedTemplateObj = result['template'];
      
      // Formulate the precise JSON payload matching the DRF expectations
      final Map<String, dynamic> requestPayload = {
        "excel_url": result['file_link'],
        "template_name": selectedTemplateObj.name,
        "category": selectedTemplateObj.category,
        "header_type": selectedTemplateObj.headertype,
        "header_variable": selectedTemplateObj.headertype?.toLowerCase() == "text" 
            ? result['header'] 
            : null,
        "media_url": selectedTemplateObj.headertype?.toLowerCase() != "text" 
            ? result['header'] 
            : null,
        "language_code": "en_US" // Fallback default or change dynamically if needed
      };

      QuickAlert.show(
          context: context,
          type: QuickAlertType.loading,
          title: "${selectedTemplateObj.name} Message",
          text: "Preparing Numbers to send message");

      // Execute POST request explicitly sending jsonEncoded payload structure
      var response = await http.post(
        Uri.parse("$baseuri/api/sendcommonmsg/"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(requestPayload),
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        var body = json.decode(response.body);
        
        // Dismiss loading alerts safely
        Navigator.of(context).pop(); 
        
        QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            title: "${selectedTemplateObj.name} Message",
            text: "Campaign broadcast process initiated successfully.",
            textColor: Colors.black87);
      } else {
        // Handle failed requests
        Navigator.of(context).pop();
        print("Meta Dispatch Pipeline Error: ${response.body}");
      }

    }
    setState(() {
      selectedtemplate = null;
      _reasonController.clear();
      _increasepController.clear();
    });
  }

  Future<void> showFestivalWishDialog() async {
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
          title: Text("Festival Wish Message"),

          // content: InputField(label: lablel, controller: _emailotpcontroller),
          content: SingleChildScrollView(
            // Use SingleChildScrollView for scrollability if content gets long
            child: Column(
              mainAxisSize: MainAxisSize.min, // Make column wrap its content
              children: [
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: InputField(
                      label: "Message", controller: _reasonController),
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: InputField(
                      label: "Festival", controller: _increasepController),
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
                  'message': _reasonController.text,
                  'festival': _increasepController.text, // Pass the File object

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
          title: "Festival Wish Message",
          text: "Preparing Numbers to send message");
      var response = await http.post(Uri.parse("$baseuri/api/festivalwishmsg/"),
          body: result);
      if (response.statusCode == 202) {
        var body = json.decode(response.body);
        Navigator.of(context).pop();
        QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            title: "Festival Wish Message",
            text: "Strated sending ${body['no_of_messages']} Messages",
            textColor: Colors.black87);
      }
    }
    setState(() {
      _reasonController.clear();
      _increasepController.clear();
      _billdaysController.clear();
    });
  }

  @override
  void initState() {
    getcomp();
    getcommonwatemplates();
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
                    child: Text('Price Hike')),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(252, 101, 8, 1),
                        foregroundColor: Colors.white),
                    onPressed: showFestivalWishDialog,
                    child: Text('Festival Wish')),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(252, 101, 8, 1),
                        foregroundColor: Colors.white),
                    onPressed: showCommonMsgDialog,
                    child: Text('Common List Messeges'))
              ],
            ),
          ),
        ),
        appbartitle: Text("SMS Services"),
        appbar: true,
        appbaractions: []);
  }
}
