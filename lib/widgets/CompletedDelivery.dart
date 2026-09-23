import 'dart:convert';

import 'package:business_app/constants.dart';
import 'package:business_app/models/utils.dart';
import 'package:business_app/widgets/background.dart';
import 'package:business_app/widgets/input_field.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class CompletedDelivery extends StatefulWidget {
  const CompletedDelivery({super.key});

  @override
  State<CompletedDelivery> createState() => _CompletedDeliveryState();
}

class _CompletedDeliveryState extends State<CompletedDelivery> {
  final TextEditingController _searchcontroller = TextEditingController();
  final TextEditingController _billnosearchcontroller = TextEditingController();

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
            'billno': _billnosearchcontroller.text
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
                          style: const TextStyle(fontSize: 13),
                        ),
                        tileColor: Colors.transparent,
                        onTap: () {
                          // Handle item interaction
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
        appbaractions: const [],
        appbar: true,
        appbartitle: Text('Completed Deliveries'));
  }
}
