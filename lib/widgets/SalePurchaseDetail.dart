import 'dart:convert';
import 'dart:io';

import 'package:business_app/constants.dart';
import 'package:business_app/models/utils.dart';
import 'package:business_app/services/network_provider.dart';
import 'package:business_app/widgets/background.dart';
import 'package:business_app/widgets/input_field.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/quickalert.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:share_plus/share_plus.dart';

class SalePurchaseDetail extends StatefulWidget {
  const SalePurchaseDetail({super.key});

  @override
  State<SalePurchaseDetail> createState() => _SalePurchaseDetailState();
}

class _SalePurchaseDetailState extends State<SalePurchaseDetail> {
  List<Amast> _company = [];
  List<InvItem> _items = [];
  List<InvItem> _selecteditems = [];
  List<InvItem> _hilightitems = [];
  List<Amast> _selectedcompany = [];
  List<String> _selectedtradetype = [];
  final List<String> _hilighttradetype = [];
  List<Amast> _hilightcompany = [];
  List<Amast> _selectedhilightcompany = [];
  DateTimeRange? _filteredDate;
  final TextEditingController _datecontroller = TextEditingController();
  int _selectedBillDetailType = 1;
  bool _onlySelcted = false;
  String _selectedhilighton = "None";
  List<String> _selectedhilighttradetype = [];
  List<InvItem> _selectedhilightitemshighlightitems = [];
  List<Amast> _selectedproject = [];
  List<Amast> _project = [];
  List<String> _liveTradeTypes = [];

  getproject() async {
    http.Response response;
    List<Amast> project = [Amast(ac: "00", name: "ALL")];

    response = await http.get(Uri.parse(
        '$baseuri/api/invprojectsalepurchaselist/?start=${_filteredDate!.start.toString().split(" ")[0]}&end=${_filteredDate!.end.toString().split(" ")[0]}&tt=${_selectedtradetype.join(",")}'));
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      for (var c in body) {
        project.add(Amast(ac: c["AC"], name: "${c["NAME"]}"));
      }
    } else {
      debugPrint('getproject status: ${response.statusCode}');
      debugPrint('getproject body: ${response.body}');
    }
    setState(() {
      _selectedproject = [project[0]];
      _project = project;
      getcompany();
    });
  }

  getcompany() async {
    http.Response response;
    List<Amast> company = [Amast(ac: "00", name: "ALL")];

    response = await http.get(Uri.parse(
        '$baseuri/api/invcompanysalepurchaselist/?start=${_filteredDate!.start.toString().split(" ")[0]}&end=${_filteredDate!.end.toString().split(" ")[0]}&ac=${_selectedproject.map((e) => e.ac).join(",")}&tt=${_selectedtradetype.join(",")}'));
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      for (var c in body) {
        // String name = c['PNAME'];
        // String ctype = c['CUSTTYPE'];
        company.add(Amast(ac: c["MC"], name: "${c["PNM"]} - ${c["FNM"]}"));
      }
    }
    setState(() {
      // _selectedcompany = [company[0]];
      _selecteditems = [];
      _company = company;
      getitemsforhilight();
    });
    // return company;
  }

  getitemsforhilight() async {
    http.Response response;
    List<InvItem> company = [InvItem(mc: "00", code: "00", name: "ALL")];

    response = await http.get(Uri.parse(
        '$baseuri/api/invhilightitemsalepurchase/?ac=${_selectedproject.map((e) => e.ac).join(",")}&start=${_filteredDate!.start.toString().split(" ")[0]}&end=${_filteredDate!.end.toString().split(" ")[0]}&mc=${_selectedcompany.map((e) => e.ac).join(",")}&tt=${_selectedtradetype.join(",")}'));
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      for (var c in body) {
        // String name = c['PNAME'];
        // String ctype = c['CUSTTYPE'];
        company.add(
            InvItem(mc: c["MC"].toString(), code: c["CODE"], name: c["F2"]));
      }
    }
    setState(() {
      _items = company;
    });
    // return company;
  }

  DateTimeRange getCurrentFinancialYear() {
    final now = DateTime.now();
    int startYear;
    int endYear;

    // Financial year starts in April (month 4)
    if (now.month >= 4) {
      // Current year is the start year
      startYear = now.year - 1;
      endYear = now.year + 1;
    } else {
      // Previous year is the start year
      startYear = now.year - 2;
      endYear = now.year;
    }

    // Financial year starts on April 1st and ends on March 31st
    final startDate = DateTime(startYear, 4, 1);
    final endDate = DateTime(endYear, 3, 31);

    return DateTimeRange(start: startDate, end: endDate);
  }

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    // final isConnected = Provider.of<NetworkProvider>(context).isOnline;
    if (_filteredDate == null) {
      _filteredDate = getCurrentFinancialYear();
      _datecontroller.text =
          "${DateFormat("dd/MM/yyyy").format(_filteredDate!.start)}-${DateFormat("dd/MM/yyyy").format(_filteredDate!.end)}";
      // getproject();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Background(
        appbar: true,
        appbartitle: Text("Sale and Purchase Report (item wise)"),
        appbaractions: const [],
        childs: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: InputField(
                    label: "Date Range",
                    controller: _datecontroller,
                    readOnly: true,
                    onTap: () async {
                      // var initdate = getCurrentFinancialYear();
                      var dr = await showOmniDateTimeRangePicker(
                          context: context,
                          barrierDismissible: true,
                          startInitialDate: _filteredDate?.start,
                          endInitialDate: _filteredDate?.end,
                          type: OmniDateTimePickerType.date,
                          isForceEndDateAfterStartDate: true);

                      setState(() {
                        _datecontroller.text = dr == null
                            ? ""
                            : "${DateFormat("dd/MM/yyyy").format(dr[0])}-${DateFormat("dd/MM/yyyy").format(dr[1])}";
                        if (dr != null) {
                          _filteredDate =
                              DateTimeRange(start: dr[0], end: dr[1]);
                        } else {
                          _filteredDate = null;
                        }
                      });
                      if (_filteredDate != null) {
                        getproject();
                      }
                      // if(_type == "Invoices"){
                      //   getshipto();
                      // }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: DropdownSearch<String>.multiSelection(
                    // key: _projectkey,
                    compareFn: (item1, item2) => item1 == item2,
                    popupProps: MultiSelectionPopupProps.dialog(
                      dialogProps: DialogProps(
                        barrierDismissible: true,
                        barrierLabel: "Dismiss",
                      ),
                      title: Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Select Trade Type",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                icon: const Icon(Icons.close))
                          ],
                        ),
                      ),
                      // showSelectedItems: true,
                      showSearchBox: true,
                      // 2. Check against _liveTradeTypes instead of _selectedtradetype
                      onDisplayed: () {
                        _liveTradeTypes = List.from(_selectedtradetype);
                      },
                      disabledItemFn: (String item) {
                        final bool hasSaleSelected =
                            _liveTradeTypes.contains("Sale") ||
                                _liveTradeTypes.contains("Sales Return");

                        if (hasSaleSelected &&
                            (item == "Purchase" || item == "Purchase Return")) {
                          return true;
                        }

                        final bool hasPurchaseSelected =
                            _liveTradeTypes.contains("Purchase") ||
                                _liveTradeTypes.contains("Purchase Return");

                        if (hasPurchaseSelected &&
                            (item == "Sale" || item == "Sales Return")) {
                          return true;
                        }

                        return false;
                      },

                      // 3. Update _liveTradeTypes the instant a checkbox is checked/unchecked
                      onItemAdded:
                          (List<String> selectedItems, String addedItem) {
                        setState(() {
                          _liveTradeTypes = List.from(selectedItems);
                        });
                      },
                      onItemRemoved:
                          (List<String> selectedItems, String removedItem) {
                        setState(() {
                          _liveTradeTypes = List.from(selectedItems);
                        });
                      },

                      // 4. Reset _liveTradeTypes if user taps outside the dialog to dismiss
                      
                    ),
                    filterFn: (item, filter) {
                      return item.toLowerCase().contains(filter.toLowerCase());
                    },
                    // filterFn: (item, filter) {
                    //   return item == "Add New" ||
                    //       item
                    //           .toLowerCase()
                    //           .contains(filter.toLowerCase());
                    // },
                    // mode: Mode.dialog,
                    // showSelectedItems: true,
                    items: (filter, infiniteScrollProps) =>
                        ["Sale", "Sales Return", "Purchase", "Purchase Return"],
                    itemAsString: (item) {
                      return item;
                    },
                    decoratorProps: const DropDownDecoratorProps(
                      decoration: InputDecoration(
                        labelText: "Select Trade Type",
                        hintText: "Select a Trade Type",
                      ),
                    ),
                    // decoration: const InputDecoration(
                    // labelText: "Menu mode",
                    // hintText: "country in menu mode",
                    // ),
                    // popupItemDisabled: isItemDisabled,
                    onSelected: (value) async {
                      setState(() {
                        // _projects.clear();
                        _selectedtradetype = value;
                        _liveTradeTypes = List.from(value);
                        // _pjc = value!.ac;
                        // _filteredDate =
                        //     getCurrentFinancialYear();
                        // _datecontroller.text =
                        //     "${DateFormat("dd/MM/yyyy").format(_filteredDate!.start)}-${DateFormat("dd/MM/yyyy").format(_filteredDate!.end)}";
                      });
                      getproject();
                    },
                    selectedItems: _selectedtradetype,
                    // showSearchBox: true,
                    // searchFieldProps: TextFieldProps(
                    //   cursorColor: Colors.blue,
                    // ),
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: DropdownSearch<Amast>.multiSelection(
                        // key: _projectkey,
                        compareFn: (item1, item2) => item1.ac == item2.ac,
                        popupProps: MultiSelectionPopupProps.dialog(
                          dialogProps: DialogProps(
                            barrierDismissible: true,
                            barrierLabel: "Dismiss",
                          ),
                          title: Padding(
                            padding: const EdgeInsets.all(1.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Select a Project",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    icon: const Icon(Icons.close))
                              ],
                            ),
                          ),
                          // showSelectedItems: true,
                          showSearchBox: true,
                        ),
                        filterFn: (item, filter) {
                          return item.name == "Add New" ||
                              item.name
                                  .toLowerCase()
                                  .contains(filter.toLowerCase()) ||
                              item.ac
                                  .toLowerCase()
                                  .contains(filter.toLowerCase());
                        },
                        // filterFn: (item, filter) {
                        //   return item == "Add New" ||
                        //       item
                        //           .toLowerCase()
                        //           .contains(filter.toLowerCase());
                        // },
                        // mode: Mode.dialog,
                        // showSelectedItems: true,
                        items: (filter, infiniteScrollProps) => _project,
                        itemAsString: (item) {
                          if (item.name == "Add New") {
                            return item.name;
                          } else {
                            return item.name;
                          }
                        },
                        decoratorProps: const DropDownDecoratorProps(
                          decoration: InputDecoration(
                            labelText: "Project",
                            hintText: "Select a Project",
                          ),
                        ),
                        // dropdownSearchDecoration: const InputDecoration(
                        // labelText: "Menu mode",
                        // hintText: "country in menu mode",
                        // ),
                        // popupItemDisabled: isItemDisabled,
                        onSelected: (value) async {
                          setState(() {
                            // _projects.clear();
                            _selectedproject = value;
                            getcompany();
                            _selecteditems = [];
                            // _pjc = value!.ac;
                          });
                        })), // _filteredDate
                Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: DropdownSearch<Amast>.multiSelection(
                      // key: _projectkey,
                      compareFn: (item1, item2) => item1.ac == item2.ac,
                      popupProps: MultiSelectionPopupProps.dialog(
                          dialogProps: DialogProps(
                            barrierDismissible: true,
                            barrierLabel: "Dismiss",
                          ),
                          title: Padding(
                            padding: const EdgeInsets.all(1.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Select a Company",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    icon: const Icon(Icons.close))
                              ],
                            ),
                          ),
                          // showSelectedItems: true,
                          showSearchBox: true),
                      filterFn: (item, filter) {
                        return item.name == "Add New" ||
                            item.name
                                .toLowerCase()
                                .contains(filter.toLowerCase()) ||
                            item.ac
                                .toLowerCase()
                                .contains(filter.toLowerCase());
                      },
                      // filterFn: (item, filter) {
                      //   return item == "Add New" ||
                      //       item
                      //           .toLowerCase()
                      //           .contains(filter.toLowerCase());
                      // },
                      // mode: Mode.dialog,
                      // showSelectedItems: true,
                      items: (filter, infiniteScrollProps) => _company,
                      itemAsString: (item) {
                        if (item.name == "Add New") {
                          return item.name;
                        } else {
                          return item.name;
                        }
                      },
                      decoratorProps: const DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: "Company",
                          hintText: "Select a Company",
                        ),
                      ),
                      // dropdownSearchDecoration: const InputDecoration(
                      // labelText: "Menu mode",
                      // hintText: "country in menu mode",
                      // ),
                      // popupItemDisabled: isItemDisabled,
                      onSelected: (value) async {
                        setState(() {
                          // _projects.clear();
                          _selectedcompany = value;
                          if (_selectedcompany
                              .any((value) => value.ac == "00")) {
                            _hilightcompany = _company
                                .where((element) => element.ac != "00")
                                .toList();
                          } else {
                            _hilightcompany = _selectedcompany;
                          }
                          getitemsforhilight();
                          _selecteditems = [];
                          // _pjc = value!.ac;
                          // _filteredDate =
                          //     getCurrentFinancialYear();
                          // _datecontroller.text =
                          //     "${DateFormat("dd/MM/yyyy").format(_filteredDate!.start)}-${DateFormat("dd/MM/yyyy").format(_filteredDate!.end)}";
                        });
                      },
                      selectedItems: _selectedcompany,
                      // showSearchBox: true,
                      // searchFieldProps: TextFieldProps(
                      //   cursorColor: Colors.blue,
                      // ),
                    )),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: DropdownSearch<InvItem>.multiSelection(
                    // key: _projectkey,
                    compareFn: (item1, item2) => item1.code == item2.code,
                    popupProps: MultiSelectionPopupProps.dialog(
                        dialogProps: DialogProps(
                          barrierDismissible: true,
                          barrierLabel: "Dismiss",
                        ),
                        title: Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Select Items",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  icon: const Icon(Icons.close))
                            ],
                          ),
                        ),
                        // showSelectedItems: true,
                        showSearchBox: true),
                    filterFn: (item, filter) {
                      return item.name == "Add New" ||
                          item.name
                              .toLowerCase()
                              .contains(filter.toLowerCase());
                    },
                    // filterFn: (item, filter) {
                    //   return item == "Add New" ||
                    //       item
                    //           .toLowerCase()
                    //           .contains(filter.toLowerCase());
                    // },
                    // mode: Mode.dialog,
                    // showSelectedItems: true,
                    items: (filter, infiniteScrollProps) => _items,
                    itemAsString: (item) {
                      if (item.name == "Add New") {
                        return item.name;
                      } else {
                        return item.name;
                      }
                    },
                    decoratorProps: const DropDownDecoratorProps(
                      decoration: InputDecoration(
                        labelText: "Select Items",
                        hintText: "Select an Item",
                      ),
                    ),
                    // decoration: const InputDecoration(
                    // labelText: "Menu mode",
                    // hintText: "country in menu mode",
                    // ),
                    // popupItemDisabled: isItemDisabled,
                    onSelected: (value) async {
                      setState(() {
                        // _projects.clear();
                        _selecteditems = value;
                        if (_selecteditems.any((value) => value.code == "00")) {
                          _hilightitems = _items
                              .where((element) => element.code != "00")
                              .toList();
                        } else {
                          _hilightitems = _selecteditems;
                        }
                        // _pjc = value!.ac;
                        // _filteredDate =
                        //     getCurrentFinancialYear();
                        // _datecontroller.text =
                        //     "${DateFormat("dd/MM/yyyy").format(_filteredDate!.start)}-${DateFormat("dd/MM/yyyy").format(_filteredDate!.end)}";
                      });
                    },
                    selectedItems: _selecteditems,
                    // showSearchBox: true,
                    // searchFieldProps: TextFieldProps(
                    //   cursorColor: Colors.blue,
                    // ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: DropdownSearch<String>(
                    popupProps: PopupProps.dialog(
                      dialogProps: DialogProps(
                        barrierDismissible: true,
                        barrierLabel: "Dismiss",
                      ),
                      title: const Text("Select Highlight on"),
                      showSearchBox: true,
                    ),
                    decoratorProps: const DropDownDecoratorProps(
                      decoration: InputDecoration(
                        labelText: "Highlight On",
                        hintText: "Select Highlight",
                      ),
                    ),
                    items: (filter, infiniteScrollProps) =>
                        ["None", "Company", "Trade Type", "Item"],
                    itemAsString: (item) => item,
                    selectedItem: _selectedhilighton,
                    onSelected: (value) {
                      setState(() {
                        _selectedhilighton = value!;
                      });
                    },
                  ),
                ),
                if (_selectedhilighton == "Company")
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: DropdownSearch<Amast>.multiSelection(
                      decoratorProps: const DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: "Highlight Company",
                          hintText: "Select Highlight Company",
                        ),
                      ),
                      compareFn: (item1, item2) => item1.ac == item2.ac,
                      popupProps: MultiSelectionPopupProps.dialog(
                        dialogProps: DialogProps(
                          barrierDismissible: true,
                          barrierLabel: "Dismiss",
                        ),
                        title: const Text("Select Companies"),
                        showSearchBox: true,
                      ),
                      items: (filter, infiniteScrollProps) => _hilightcompany,
                      itemAsString: (item) => item.name,
                      selectedItems: _selectedhilightcompany,
                      onSelected: (value) {
                        setState(() {
                          _selectedhilightcompany = value;
                        });
                      },
                    ),
                  ),
                if (_selectedhilighton == "Trade Type")
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: DropdownSearch<String>.multiSelection(
                      decoratorProps: const DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: "Highlight TT",
                          hintText: "Select Highlight TT",
                        ),
                      ),
                      compareFn: (item1, item2) => item1 == item2,
                      popupProps: MultiSelectionPopupProps.dialog(
                        dialogProps: DialogProps(
                          barrierDismissible: true,
                          barrierLabel: "Dismiss",
                        ),
                        title: const Text("Select Trade Types"),
                        showSearchBox: true,
                      ),
                      items: (filter, infiniteScrollProps) =>
                          _selectedtradetype,
                      itemAsString: (item) => item,
                      selectedItems: _selectedhilighttradetype,
                      onSelected: (value) {
                        setState(() {
                          _selectedhilighttradetype = value;
                        });
                      },
                    ),
                  ),
                if (_selectedhilighton == "Item")
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: DropdownSearch<InvItem>.multiSelection(
                      decoratorProps: const DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: "Highlight Items",
                          hintText: "Select Highlight Items",
                        ),
                      ),
                      compareFn: (item1, item2) => item1.code == item2.code,
                      popupProps: MultiSelectionPopupProps.dialog(
                        dialogProps: DialogProps(
                          barrierDismissible: true,
                          barrierLabel: "Dismiss",
                        ),
                        title: const Text("Select Items"),
                        showSearchBox: true,
                      ),
                      items: (filter, infiniteScrollProps) => _hilightitems,
                      itemAsString: (item) => item.name,
                      selectedItems: _selectedhilightitemshighlightitems,
                      onSelected: (value) {
                        setState(() {
                          _selectedhilightitemshighlightitems = value;
                        });
                      },
                    ),
                  ),
                if (_selectedhilighton != "None")
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: CheckboxListTile(
                        title: Text("Only Selected Items"),
                        tileColor: Colors.transparent,
                        value: _onlySelcted,
                        onChanged: (val) {
                          setState(() {
                            _onlySelcted = val!;
                          });
                        }),
                  ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        QuickAlert.show(
                            context: context,
                            type: QuickAlertType.loading,
                            text: "Preparing Report");
                        final resp = await http.post(
                          Uri.parse('$baseuri/api/generatesalepurchasereport/'),
                          headers: <String, String>{
                            'Content-Type': 'application/json; charset=UTF-8',
                          },
                          body: jsonEncode(<String, dynamic>{
                            'start_date':
                                _filteredDate?.start.toIso8601String(),
                            'end_date': _filteredDate?.end.toIso8601String(),
                            'selected_projects':
                                _selectedproject.map((e) => e.ac).toList(),
                            'selected_companies':
                                _selectedcompany.map((e) => e.ac).toList(),
                            'selected_trade_types': _selectedtradetype,
                            'selected_items':
                                _selecteditems.map((e) => e.code).toList(),
                            'hilight': _selectedhilighton != "None",
                            'highlight_on': _selectedhilighton,
                            'highlight_companies': _selectedhilightcompany
                                .map((e) => e.ac)
                                .toList(),
                            'highlight_trade_types': _selectedhilighttradetype,
                            'highlight_items':
                                _selectedhilightitemshighlightitems
                                    .map((e) => e.code)
                                    .toList(),
                            'only_selected': _onlySelcted,
                          }),
                        );

                        if (resp.statusCode == 200) {
                          // 1. Create a temporary .xlsx file from response bytes
                          final tempDir = await getTemporaryDirectory();
                          final fileName =
                              'Sale_Purchase_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
                          final tempFile = File('${tempDir.path}/$fileName');
                          await tempFile.writeAsBytes(resp.bodyBytes,
                              flush: true);

                          // 2. Get share origin for iPad / macOS compatibility
                          if (!context.mounted) return;
                          final box = context.findRenderObject() as RenderBox?;
                          final Rect? sharePositionOrigin = box != null
                              ? box.localToGlobal(Offset.zero) & box.size
                              : null;
                          Navigator.of(context).pop();
                          // 3. Share the Excel file via share_plus
                          await SharePlus.instance.share(
                            ShareParams(
                              files: [
                                XFile(
                                  tempFile.path,
                                  mimeType:
                                      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                                ),
                              ],
                              subject: 'Sale Purchase Report',
                              sharePositionOrigin: sharePositionOrigin,
                            ),
                          );
                        } else {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Failed to generate report: ${resp.statusCode}')),
                          );
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error sharing report: $e')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(252, 101, 8, 1),
                        foregroundColor: Colors.white),
                    child: const Text("Download Report"),
                  ),
                )
              ],
            ),
          ),
        ));
  }
}
