import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:business_app/constants.dart';
import 'package:business_app/models/leads.dart';
import 'package:business_app/screens/lead_detail.dart';
import 'package:business_app/services/network_provider.dart';
import 'package:business_app/widgets/input_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListLeads extends StatefulWidget {
  String leadtype;
  String? type;
  List<String>? leadbyn;
  List<String>? leadton;
  String? searchQuery;
  final ValueChanged<Map<String, dynamic>> onfilterChange;
  final ValueChanged<int> listcountChange;
  final Function(dynamic assignExisting, dynamic leadinfo)? assignlead;
  Map<String, List<String>>? selectedfilters;

  ListLeads({
    super.key,
    required this.leadtype,
    this.type,
    this.leadbyn,
    this.leadton,
    this.searchQuery,
    required this.onfilterChange,
    this.assignlead,
    required this.listcountChange,
    this.selectedfilters,
  });

  @override
  State<ListLeads> createState() => _ListLeadsState();
}

class _ListLeadsState extends State<ListLeads> {
  static const int _pageSize = 20;

  final TextEditingController _searchController = TextEditingController();
  int _totalPages = 1;
  bool _hasInitialized = false;
  Timer? _reloadTimer;
  Timer? _searchDebounce;

  late final PagingController<int, Lead> _pagingController =
      PagingController<int, Lead>(
    getNextPageKey: (state) {
      if (state.pages == null || state.pages!.isEmpty) {
        return 1;
      }
      if (state.lastPageIsEmpty) {
        return null;
      }
      final nextKey = (state.keys?.last ?? 0) + 1;
      if (nextKey > _totalPages) {
        return null;
      }
      return nextKey;
    },
    fetchPage: (pageKey) => _fetchDrfPage(pageKey),
  );

  Future<List<Lead>> _fetchDrfPage(int pageKey) async {
    // if (pageKey == 1) {
    //   _totalPages = 1;
    // }

    final sharedpref = await SharedPreferences.getInstance();
    final mob = sharedpref.getString("Mobile");
    final ut = sharedpref.getString("UT") ?? "";
    final connectivityProvider =
        Provider.of<NetworkProvider>(context, listen: false);

    final String searchText = _searchController.text.trim();
    final Map<String, List<String>> activeFilters = widget.selectedfilters ?? {};
    final List<String> projectFilters = activeFilters["Project"] ?? [];
    final List<String> productFilters = activeFilters["Product"] ?? [];
    final List<String> leadtypeFilters = activeFilters["Leadtype"] ?? [];
    final List<String> dateFilters = activeFilters["Date"] ?? [];

    try {
      http.Response response;
      final bool isExternalUser = ut.toLowerCase() == "consumer" ||
          ut.toLowerCase() == "contractor" ||
          ut.toLowerCase() == "supplier" ||
          (widget.leadbyn == null && widget.leadton == null);

      if (isExternalUser) {
        final uri = Uri.parse('$baseuri/api/complain_list/').replace(
          queryParameters: {
            'page': pageKey.toString(),
            'page_size': _pageSize.toString(),
          },
        );
        final Map<String, dynamic> query = {
          'catagory': widget.leadtype,
          'mob': mob,
          
          if (searchText.isNotEmpty) 'search': searchText,
          if (projectFilters.isNotEmpty) 'projects': projectFilters,
          if (productFilters.isNotEmpty) 'products': productFilters,
          if (leadtypeFilters.isNotEmpty) 'leadtypes': leadtypeFilters,
          if (dateFilters.length >= 2) 'start_date': dateFilters[0],
          if (dateFilters.length >= 2) 'end_date': dateFilters[1],
        };
        response = await http.post(
          uri,
          body: jsonEncode(query),
          headers: {"Content-Type": "application/json"},
        );
      } else if (widget.leadtype == "Unassigned") {
        final uri = Uri.parse('$baseuri/api/leads_list/').replace(
          queryParameters: {
            'type': 'unassigned',
            'page': pageKey.toString(),
            'page_size': _pageSize.toString(),
            if (searchText.isNotEmpty) 'search': searchText,
            if (projectFilters.isNotEmpty) 'projects': projectFilters.join(','),
            if (productFilters.isNotEmpty) 'products': productFilters.join(','),
            if (leadtypeFilters.isNotEmpty) 'leadtypes': leadtypeFilters.join(','),
            if (dateFilters.length >= 2) 'start_date': dateFilters[0],
            if (dateFilters.length >= 2) 'end_date': dateFilters[1],
          },
        );
        response = await http.get(
          uri,
          headers: {"Content-Type": "application/json"},
        );
      } else {
        final uri = Uri.parse('$baseuri/api/leads_list/').replace(
          queryParameters: {
            'page': pageKey.toString(),
            'page_size': _pageSize.toString(),
          },
        );
        print("Lead Type: ${widget.leadtype}, Lead By: ${widget.leadbyn}, Lead To: ${widget.leadton}, Type: ${widget.type}");
        final Map<String, dynamic> query = {
          'catagory': widget.leadtype,
          'leadbyn': widget.leadbyn,
          'leadton': widget.leadton,
          'type': widget.type,
          if (searchText.isNotEmpty) 'search': searchText,
          if (projectFilters.isNotEmpty) 'projects': projectFilters,
          if (productFilters.isNotEmpty) 'products': productFilters,
          if (leadtypeFilters.isNotEmpty) 'leadtypes': leadtypeFilters,
          if (dateFilters.length >= 2) 'start_date': dateFilters[0],
          if (dateFilters.length >= 2) 'end_date': dateFilters[1],
        };
        response = await http.post(
          uri,
          body: jsonEncode(query),
          headers: {"Content-Type": "application/json"},
        );
      }

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (kDebugMode) {
          print(decoded);
        }

        final List<dynamic> rawItems = decoded is Map<String, dynamic>
            ? (decoded['results'] ?? [])
            : decoded;
        _totalPages = decoded is Map<String, dynamic>
            ? (decoded['total_pages'] ?? 1)
            : 1;
        final int totalCount = decoded is Map<String, dynamic>
            ? (decoded['count'] ?? rawItems.length)
            : rawItems.length;

        if (decoded is Map<String, dynamic> && decoded['filter_options'] != null) {
          final opts = decoded['filter_options'];
          widget.onfilterChange({
            "Product": List<String>.from(opts['Product'] ?? []),
            "Project": List<String>.from(opts['Project'] ?? []),
            "Leadtype": List<String>.from(opts['Leadtype'] ?? []),
          });
        }

        final List<Lead> newLeads = rawItems.map<Lead>((lead) {
          final String lastFollowup =
              (lead['LAST_FOLLOWUP'] == null || lead['LAST_FOLLOWUP'] == "")
                  ? "OPEN"
                  : lead['LAST_FOLLOWUP'].toString();

          return Lead(
            pjc: lead['PJC'],
            pname: lead['PNAME'] ?? "",
            leadtype: lead['LEAD_TYPE'] ?? "",
            lastfollowup: lastFollowup,
            custtype: lead['CUSTTYPE'],
            products: lead['PRODUCTS'] ?? [],
          );
        }).toList();

        widget.listcountChange(totalCount);
        _hasInitialized = true;
        return newLeads;
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception("Server error code: ${response.statusCode}");
      }
    } on SocketException catch (_) {
      connectivityProvider.setConnected(false);
      rethrow;
    } on http.ClientException catch (_) {
      connectivityProvider.setConnected(false);
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isConnected = Provider.of<NetworkProvider>(context).isOnline;

    if (isConnected && _hasInitialized && _pagingController.value.error != null) {
      _reloadTimer?.cancel();
      _reloadTimer = Timer(const Duration(seconds: 2), () {
        _pagingController.fetchNextPage();
      });
    }

    if (!isConnected) {
      _reloadTimer?.cancel();
    }
  }

  @override
  void didUpdateWidget(covariant ListLeads oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.leadbyn != widget.leadbyn ||
        oldWidget.leadton != widget.leadton ||
        oldWidget.leadtype != widget.leadtype ||
        oldWidget.type != widget.type ||
        oldWidget.selectedfilters != widget.selectedfilters) {
      _pagingController.refresh();
    }
  }

  @override
  void dispose() {
    _reloadTimer?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(5),
          child: InputField(
            controller: _searchController,
            label: "Search",
            suff: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                _searchDebounce?.cancel();
                _pagingController.refresh();
              },
            ),
            onChanged: (value) {
              _searchDebounce?.cancel();
              _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                _pagingController.refresh();
              });
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => Future.sync(() => _pagingController.refresh()),
            child: PagingListener<int, Lead>(
              controller: _pagingController,
              builder: (context, state, fetchNextPage) =>
                  PagedListView<int, Lead>(
                state: state,
                fetchNextPage: fetchNextPage,
                builderDelegate: PagedChildBuilderDelegate<Lead>(
                  firstPageProgressIndicatorBuilder: (_) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  newPageProgressIndicatorBuilder: (_) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  noItemsFoundIndicatorBuilder: (_) => const Center(
                    child: Text("No Leads to Show"),
                  ),
                  firstPageErrorIndicatorBuilder: (_) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Failed to load leads."),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => fetchNextPage(),
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                  itemBuilder: (context, lead, index) {
                    return Card(
                      color: Colors.transparent,
                      child: ListTile(
                        title: Text(
                          lead.pname,
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Row(
                          children: [
                            Text(
                              lead.leadtype ?? "",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                backgroundColor: lead.leadtype == "INSTALLATION"
                                    ? Colors.orange[700]
                                    : lead.leadtype == "COMPLAIN"
                                        ? Colors.green[400]
                                        : lead.leadtype == "SERVICE"
                                            ? Colors.yellow
                                            : Colors.white,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Text(
                              lead.lastfollowup ?? "",
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Text(
                                (lead.products ?? []).join(","),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        tileColor: Colors.transparent,
                        onTap: () {
                          if (widget.leadtype == "Unassigned") {
                            widget.assignlead!(true, {
                              "pjc": lead.pjc,
                              "pname": lead.pname,
                              "custtype": lead.custtype,
                              "leadtype": lead.leadtype,
                              "products": lead.products,
                            });
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LeadDetail(
                                  currentlead: lead,
                                  type: widget.type,
                                ),
                              ),
                            ).then((_) {
                              _pagingController.refresh();
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
