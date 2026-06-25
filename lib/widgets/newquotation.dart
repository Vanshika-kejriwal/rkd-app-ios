import 'dart:convert';

import 'package:business_app/constants.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NewQuotation extends StatefulWidget {
  const NewQuotation({super.key});

  @override
  State<NewQuotation> createState() => _NewQuotationState();
}

class _NewQuotationState extends State<NewQuotation> {
  String? _selectedfilter1;
  String? _selectedfilter2;
  String? _selectedfilter3;
  String? _selectedfilter4;

  Future<List<String>> getfilter1() async {
    final response = await http.get(Uri.parse('$baseuri/api/leadnames/'));
    final body = json.decode(response.body);
    List<String> names = [];
    if (response.statusCode == 200) {
      for (var c in body) {
        names.add(c["NAME"]);
      }
    }
    return names;
  }

  Future<List<String>> getfilter2() async {
    final response = await http.get(Uri.parse('$baseuri/api/leadnames/'));
    final body = json.decode(response.body);
    List<String> names = [];
    if (response.statusCode == 200) {
      for (var c in body) {
        names.add(c["NAME"]);
      }
    }
    return names;
  }

  Future<List<String>> getfilter3() async {
    final response = await http.get(Uri.parse('$baseuri/api/leadnames/'));
    final body = json.decode(response.body);
    List<String> names = [];
    if (response.statusCode == 200) {
      for (var c in body) {
        names.add(c["NAME"]);
      }
    }
    return names;
  }

  Future<List<String>> getfilter4() async {
    final response = await http.get(Uri.parse('$baseuri/api/leadnames/'));
    final body = json.decode(response.body);
    List<String> names = [];
    if (response.statusCode == 200) {
      for (var c in body) {
        names.add(c["NAME"]);
      }
    }
    return names;
  }

  @override
  Widget build(BuildContext context) {
    double swidth = MediaQuery.of(context).size.width;
    return Center(
      child: SizedBox(
          width: swidth * 0.9,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: FutureBuilder<List<String>>(
                              future: getfilter1(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
                                  return DropdownSearch<String>(
                                    popupProps: const PopupProps.dialog(
                                      dialogProps: DialogProps(barrierDismissible: true,barrierLabel: "Dismiss"),
                                        showSelectedItems: true,
                                        showSearchBox: true),
                                    // mode: Mode.dialog,
                                    // showSelectedItems: true,
                                    items: (filter, infiniteScrollProps) => snapshot.data!,
                                    decoratorProps:
                                        const DropDownDecoratorProps(
                                      decoration: InputDecoration(
                                        labelText: "Next Follow-up By",
                                        hintText: "Select a Name",
                                      ),
                                    ),

                                    onSelected: (value) {
                                      setState(() {
                                        _selectedfilter1 = value;
                                      });
                                    },
                                    selectedItem: _selectedfilter1,
                                  );
                                } else {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                              }),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: FutureBuilder<List<String>>(
                              future: getfilter1(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
                                  return DropdownSearch<String>(
                                    popupProps: const PopupProps.dialog(
                                        dialogProps: DialogProps(barrierDismissible: true,barrierLabel: "Dismiss"),
                                        showSelectedItems: true,
                                        showSearchBox: true),
                                    // mode: Mode.dialog,
                                    // showSelectedItems: true,
                                    items: (filter, infiniteScrollProps) => snapshot.data!,
                                    decoratorProps:
                                        const DropDownDecoratorProps(
                                      decoration: InputDecoration(
                                        labelText: "Next Follow-up By",
                                        hintText: "Select a Name",
                                      ),
                                    ),

                                    onSelected: (value) {
                                      setState(() {
                                        _selectedfilter2 = value;
                                      });
                                    },
                                    selectedItem: _selectedfilter2,
                                  );
                                } else {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                              }),
                        ),
                      )
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: FutureBuilder<List<String>>(
                              future: getfilter1(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
                                  return DropdownSearch<String>(
                                    popupProps: const PopupProps.dialog(
                                        dialogProps: DialogProps(barrierDismissible: true,barrierLabel: "Dismiss"),
                                        showSelectedItems: true,
                                        showSearchBox: true),
                                    // mode: Mode.dialog,
                                    // showSelectedItems: true,
                                    items: (filter, infiniteScrollProps) => snapshot.data!,
                                    decoratorProps:
                                        const DropDownDecoratorProps(
                                      decoration: InputDecoration(
                                        labelText: "Next Follow-up By",
                                        hintText: "Select a Name",
                                      ),
                                    ),

                                    onSelected: (value) {
                                      setState(() {
                                        _selectedfilter3 = value;
                                      });
                                    },
                                    selectedItem: _selectedfilter3,
                                  );
                                } else {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                              }),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: FutureBuilder<List<String>>(
                              future: getfilter1(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
                                  return DropdownSearch<String>(
                                    popupProps: const PopupProps.dialog(
                                        dialogProps: DialogProps(barrierDismissible: true,barrierLabel: "Dismiss"),
                                        showSelectedItems: true,
                                        showSearchBox: true),
                                    // mode: Mode.dialog,
                                    // showSelectedItems: true,
                                    items: (filter, infiniteScrollProps) => snapshot.data!,
                                    decoratorProps:
                                        const DropDownDecoratorProps(
                                      decoration: InputDecoration(
                                        labelText: "Next Follow-up By",
                                        hintText: "Select a Name",
                                      ),
                                    ),

                                    onSelected: (value) {
                                      setState(() {
                                        _selectedfilter4 = value;
                                      });
                                    },
                                    selectedItem: _selectedfilter4,
                                  );
                                } else {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                              }),
                        ),
                      )
                    ],
                  ),
                ),
                // DataTable(columns: columns, rows: rows)
              ])),
    );
  }
}
