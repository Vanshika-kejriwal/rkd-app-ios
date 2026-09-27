import 'dart:convert';

import 'package:business_app/constants.dart';
import 'package:business_app/models/utils.dart';
import 'package:business_app/screens/CompletedDeliveryDetail.dart';
import 'package:business_app/widgets/background.dart';
import 'package:business_app/widgets/input_field.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';

class CompletedDelivery extends StatefulWidget {
  const CompletedDelivery({super.key});

  @override
  State<CompletedDelivery> createState() => _CompletedDeliveryState();
}

class _CompletedDeliveryState extends State<CompletedDelivery> {
  final TextEditingController _searchcontroller = TextEditingController();
  final TextEditingController _billnosearchcontroller = TextEditingController();
  Map<String, dynamic> filters = {};
  // final List<String> _filteredCusttype = [];
  DateTimeRange? _filteredDate;
  List<LeadProduct> _filteredProducts = [];
  List<LeadProduct> comp = [];
  final _dobcontroller = TextEditingController();
  // Map<String, dynamic>? _selectedfiltervalues;
  late final PagingController<int, Amast> _pagingController =
      PagingController<int, Amast>(
    getNextPageKey: (state) {
      if (state.pages == null || state.pages!.isEmpty) {
        return 1;
      }

      if (state.lastPageIsEmpty) {
        return null;
      }

      return (state.keys?.last ?? 0) + 1;
    },
    fetchPage: (pageKey) {
      // print('🔥 FETCH PAGE CALLED WITH KEY = $pageKey');
      return _fetchDrfPage(pageKey);
    },
  );

  // Change return type to Future<List<Amast>>
  Future<List<Amast>> _fetchDrfPage(int pageKey) async {
    // print('🚨 _fetchDrfPage ENTERED: pageKey=$pageKey');
    try {
      final Uri url = Uri.parse('$baseuri/api/completed_deliveries/').replace(
        queryParameters: {
          'page': pageKey.toString(),
          if (_searchcontroller.text.isNotEmpty)
            'search': _searchcontroller.text,
          if (_billnosearchcontroller.text.isNotEmpty)
            'billno': _billnosearchcontroller.text,
          if (_filteredDate != null)
            "start_date": _filteredDate?.start.toString().split(" ")[0],
          if (_filteredDate != null)
            "end_date": _filteredDate?.end.toString().split(" ")[0],
          if (_filteredProducts.isNotEmpty)
            "mcs": _filteredProducts.map(((e) => e.mc)).toList().join(",")
        },
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        final List<dynamic> results = decodedData['results'] ?? [];

        // Return the parsed list directly
        // print(results);
        // print('PAGE $pageKey RESULTS:');

        // for (int i = 0; i < results.length; i++) {
        //   print(
        //     'PAGE $pageKey [$i] '
        //     'AC=${results[i]['AC']} '
        //     'NAME=${results[i]['Customer_Name']}',
        //   );
        // }
        return results
            .map((item) => Amast(ac: item['AC'], name: item['Customer_Name']))
            .toList();
      } else if (response.statusCode == 404) {
        // DRF returns 404 when you hit the end.
        // Return an empty list to signal that there are no more pages.
        return [];
      } else {
        throw Exception('Server error code: ${response.statusCode}');
      }
    } catch (error) {
      // Re-throw the error so the PagingController automatically catches it
      // and shifts your UI into the error/retry state.
      rethrow;
    }
  }

  Future<void> fetchcomp() async {
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
  }

  @override
  void initState() {
    fetchcomp();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Background(
        childs: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: InputField(
                      controller: _searchcontroller,
                      label: "Search Project",
                      suff: IconButton(
                          onPressed: () {
                            setState(() {
                              _billnosearchcontroller.clear();
                            });
                            _pagingController.refresh();
                          },
                          icon: const Icon(Icons.search)),
                    ),
                  ),
                ),
                Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: InputField(
                        controller: _billnosearchcontroller,
                        label: "Search Bill No.",
                        suff: IconButton(
                            onPressed: () {
                              setState(() {
                                _searchcontroller.clear();
                              });
                              _pagingController.refresh();
                            },
                            icon: const Icon(Icons.search)),
                      ),
                    ))
              ],
            ),
            Expanded(
              child: PagingListener<int, Amast>(
                controller: _pagingController,
                builder: (context, state, fetchNextPage) =>
                    PagedListView<int, Amast>(
                  state: state, // <-- Now Required
                  fetchNextPage: fetchNextPage, // <-- Now Required
                  builderDelegate: PagedChildBuilderDelegate<Amast>(
                    itemBuilder: (context, item, index) => Card(
                      color: Colors.transparent,
                      child: ListTile(
                        // leading: CircleAvatar(child: Text('${item.id}')),
                        title: Text(
                          item.name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        tileColor: Colors.transparent,
                        onTap: () {
                          // Handle item interaction
                          Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CompletedDeliveryDetail(
                                           
                                            currentlead: item),
                                      ),
                                    ).then((_) {
                                      // Refresh the leads list when returning
                                    _pagingController.refresh();
                                    });
                        },
                      ),
                    ),
                    noItemsFoundIndicatorBuilder: (context) => const Center(
                      child: Text('No results match your search filter.'),
                    ),
                    firstPageErrorIndicatorBuilder: (context) => Center(
                      child: ElevatedButton(
                        // In v5, you can use the fetchNextPage callback to retry
                        onPressed: () => fetchNextPage(),
                        child: const Text('Failed to load. Retry?'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        appbaractions: [
          IconButton(
              onPressed: (() async {
                {
                  // List<String> filteredProjects = _filteredCusttype;
                  List<LeadProduct> filteredProducts = _filteredProducts;
                  DateTimeRange? filterdate = _filteredDate;
                  final result = await showModalBottomSheet(
                    isScrollControlled: true,
                    context: context,
                    builder: (context) {
                      return SafeArea(
                        child: StatefulBuilder(builder: (context, setstate) {
                          return Container(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(1.0),
                                  child: DropdownSearch<
                                      LeadProduct>.multiSelection(
                                    selectedItems: filteredProducts,
                                    items: (filter, infiniteScrollProps) =>
                                        comp,
                                    compareFn: (item1, item2) {
                                      return item1.mc == item2.mc;
                                    },
                                    itemAsString: (item) {
                                      return "${item.company} (${item.product})";
                                    },
                                    onSelected: (value) {
                                      setstate(() {
                                        filteredProducts = value;
                                      });
                                    },
                                    popupProps:
                                        const MultiSelectionPopupProps.dialog(
                                            dialogProps: DialogProps(
                                                barrierDismissible: true,
                                                barrierLabel: "Dismiss"),
                                            showSelectedItems: true,
                                            showSearchBox: true),
                                    decoratorProps:
                                        const DropDownDecoratorProps(
                                      decoration: InputDecoration(
                                        labelText: "Company",
                                        hintText: "Select Company",
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Please select an emplyee name';
                                      }
                                      return null;
                                    },
                                    autoValidateMode:
                                        AutovalidateMode.onUserInteraction,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: InputField(
                                    label: "Date Range",
                                    controller: _dobcontroller,
                                    readOnly: true,
                                    onTap: () async {
                                      var dr =
                                          await showOmniDateTimeRangePicker(
                                              context: context,
                                              barrierDismissible: true,
                                              startInitialDate:
                                                  filterdate?.start,
                                              endInitialDate: filterdate?.end,
                                              type: OmniDateTimePickerType.date,
                                              isForceEndDateAfterStartDate:
                                                  true);

                                      setstate(() {
                                        _dobcontroller.text = dr == null
                                            ? ""
                                            : "${DateFormat("dd/MM/yyyy").format(dr[0])}-${DateFormat("dd/MM/yyyy").format(dr[1])}";
                                        if (dr != null) {
                                          filterdate = DateTimeRange(
                                              start: dr[0], end: dr[1]);
                                        } else {
                                          filterdate = null;
                                        }
                                      });
                                    },
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Expanded(
                                        child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text("Cancel"))),
                                    Expanded(
                                        child: ElevatedButton(
                                            onPressed: () {
                                              Map<String, dynamic> filterval = {
                                                "Product": filteredProducts,
                                                // "Project": filteredProjects,
                                                "Date": filterdate
                                              };
                                              // if (kDebugMode) {
                                              //   print(filterval);
                                              // }
                                              // filterlist(filterval);
                                              Navigator.of(context)
                                                  .pop(filterval);
                                            },
                                            child: const Text("Apply"))),
                                    Expanded(
                                        child: ElevatedButton(
                                            onPressed: () {
                                              setstate(() {
                                                filteredProducts = [];
                                                // filteredProjects = [];
                                                filterdate = null;
                                                _dobcontroller.clear();
                                              });
                                            },
                                            child: const Text("Clear All"))),
                                  ],
                                )
                              ],
                            ),
                          );
                        }),
                      );
                    },
                  );
                  if (result != null) {
                    setState(() {
                      _filteredProducts = result["Product"];
                      // _filteredCusttype = result["Project"];
                      _filteredDate = result["Date"];
                    });
                    _pagingController.refresh();
                  }
                }
              }),
              icon: Icon(Icons.filter_list_rounded))
        ],
        appbar: true,
        appbartitle: Text('Completed Deliveries'));
  }
}
