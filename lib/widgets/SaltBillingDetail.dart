import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:business_app/constants.dart';
import 'package:business_app/models/saltbillreport.dart';
import 'package:business_app/services/network_provider.dart';
import 'package:business_app/widgets/background.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class SaltBillingDetail extends StatefulWidget {
  const SaltBillingDetail({super.key});

  @override
  State<SaltBillingDetail> createState() => _SaltBillingDetailState();
}

class _SaltBillingDetailState extends State<SaltBillingDetail> {
  bool _isDataLoaded = false;
  bool _isFetching =
      false; // Tracks background page loading without blanking UI
  Timer? _reloadTimer;
  // SaltBillDataSource? _employeeDataSource;
  final SaltBillDataSource _employeeDataSource = SaltBillDataSource(employeeData: []);
  int _totalRecords = 0;
  int _rowsPerPage = 10;

  // @override
  // void initState() {
  //   super.initState();
  //   fetchSaltData(page: 1, isInitial: true);
  // }

  Future<void> fetchSaltData({int page = 1, bool isInitial = false}) async {
    final connectivityProvider =
        Provider.of<NetworkProvider>(context, listen: false);

    try {
      setState(() {
        if (isInitial) {
          _isDataLoaded = false;
        }
        _isFetching = true;
      });

      final response =
          await http.get(Uri.parse('$baseuri/api/saltbilling/?page=$page'));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        // print('Fetched Salt Billing Data: $body');
        _totalRecords = body.length; // Assuming the API returns a list of records
        final List results = body;

        final List<Saltbilling> outstanding = results.map<Saltbilling>((e) {
          return Saltbilling.fromJson(e as Map<String, dynamic>);
        }).toList();

        if (mounted) {
          setState(() {
            _employeeDataSource.updateData(outstanding);
            _isDataLoaded = true;
            _isFetching = false;
            if (isInitial) {
              _rowsPerPage = results.length;
            } // Reset rows per page if needed
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isDataLoaded = true;
            _isFetching = false;
          });
        }
      }
    } on SocketException catch (_) {
      connectivityProvider.setConnected(false);
      setState(() => _isFetching = false);
    } on http.ClientException catch (_) {
      connectivityProvider.setConnected(false);
      setState(() => _isFetching = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isConnected = Provider.of<NetworkProvider>(context).isOnline;

    if (isConnected && !_isDataLoaded) {
      _reloadTimer?.cancel();
      _reloadTimer = Timer(const Duration(seconds: 2), () {
        fetchSaltData(page: 1, isInitial: true);
      });
    }

    if (!isConnected) {
      _reloadTimer?.cancel();
      setState(() {
        _isDataLoaded = false;
      });
    }
  }

  @override
  void dispose() {
    _reloadTimer?.cancel();
    super.dispose();
  }

  Future<List<Saltbilling>> _fetchAllDataForExport() async {
    try {
      final response =
          await http.get(Uri.parse('$baseuri/api/saltbilling/?export=true'));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List results = body is List ? body : (body['results'] ?? []);
        return results
            .map<Saltbilling>(
                (e) => Saltbilling.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching all data for export: $e');
    }
    return [];
  }

  String _generateExportCSVString(List<Saltbilling> allData) {
    StringBuffer csvBuffer = StringBuffer();
    csvBuffer.writeln(
        'AC,NAME,TEL1,TEL2,TEL3,Installation Date,Last Service Date,Last Salt Billing Date,Last Salt Billed Qty,Average Monthly Consumption (kg),Days Left');

    for (var e in allData) {
      List<String> rowValues = [
        e.ac ?? '',
        e.name ?? '',
        e.tel1 ?? '',
        e.tel2 ?? '',
        e.tel3 ?? '',
        e.installationDate ?? '',
        e.lastServiceDate ?? '',
        e.lastSaltBillingDate ?? '',
        e.lastSaltBilledQty?.toString() ?? '',
        e.avgSaltConsumption?.toString() ?? '',
        e.saltLeftDays?.toString() ?? '',
      ];

      final rowString =
          rowValues.map((val) => val.contains(',') ? '"$val"' : val).join(',');
      csvBuffer.writeln(rowString);
    }
    return csvBuffer.toString();
  }

  Future<void> _shareCSV() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing complete CSV for sharing...')),
    );

    final allData = await _fetchAllDataForExport();
    if (allData.isEmpty) return;

    try {
      final csvString = _generateExportCSVString(allData);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/salt_billing_data_all.csv');

      await tempFile.writeAsString(csvString);
      final box = context.findRenderObject() as RenderBox?;
      final Rect? sharePositionOrigin =
          box != null ? box.localToGlobal(Offset.zero) & box.size : null;

      SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path, mimeType: 'text/csv')],
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (e) {
      debugPrint('Error sharing file: $e');
    }
  }

  Future<void> _downloadCSV(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing complete CSV for download...')),
    );

    final allData = await _fetchAllDataForExport();
    if (allData.isEmpty) return;

    try {
      final csvString = _generateExportCSVString(allData);

      String? outputFile = await FilePicker.saveFile(
        dialogTitle: 'Save Complete CSV File',
        fileName: 'salt_billing_data_all.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: const Latin1Codec().encode(csvString),
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(csvString);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Complete file downloaded successfully!')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error downloading file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      appbar: true,
      childs: !_isDataLoaded
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // Non-intrusive loading bar at the top during page transitions
                  if (_isFetching)
                    const LinearProgressIndicator(minHeight: 3)
                  else
                    const SizedBox(height: 3),

                  Expanded(
                    child: SfDataGrid(
                      source: _employeeDataSource,
                      rowHeight: 55,
                      headerRowHeight: 55,
                      columnWidthMode: ColumnWidthMode.none,
                      columns: <GridColumn>[
                        GridColumn(
                          columnName: 'AC',
                          width: 80,
                          label: Container(
                            padding: const EdgeInsets.all(8.0),
                            alignment: Alignment.centerLeft,
                            child: const Text('AC',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        GridColumn(
                          columnName: 'NAME',
                          width: 180,
                          label: Container(
                            padding: const EdgeInsets.all(8.0),
                            alignment: Alignment.centerLeft,
                            child: const Text('Name',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        GridColumn(
                          columnName: 'TEL1',
                          width: 110,
                          label: Container(
                            padding: const EdgeInsets.all(8.0),
                            alignment: Alignment.center,
                            child: const Text('TEL1',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        GridColumn(
                          columnName: 'TEL2',
                          width: 110,
                          label: Container(
                            padding: const EdgeInsets.all(8.0),
                            alignment: Alignment.center,
                            child: const Text('TEL2',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        GridColumn(
                          columnName: 'TEL3',
                          width: 110,
                          label: Container(
                            padding: const EdgeInsets.all(8.0),
                            alignment: Alignment.center,
                            child: const Text('TEL3',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        GridColumn(
                          columnName: 'Installation Date',
                          width: 140,
                          label: Container(
                            padding: const EdgeInsets.all(8.0),
                            alignment: Alignment.center,
                            child: const Text('Installation Date',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        GridColumn(
                          columnName: 'Last Service Date',
                          width: 140,
                          label: Container(
                            padding: const EdgeInsets.all(8.0),
                            alignment: Alignment.center,
                            child: const Text('Last Service Date',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        GridColumn(
                          columnName: 'Last Salt Billing Date',
                          width: 150,
                          label: Container(
                            padding: const EdgeInsets.all(8.0),
                            alignment: Alignment.center,
                            child: const Text('Last Salt Billing Date',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        GridColumn(
                          columnName: 'Last Salt Billed Qty',
                          width: 130,
                          label: Container(
                            padding: const EdgeInsets.all(8.0),
                            alignment: Alignment.center,
                            child: const Text('Last Salt Billed Qty',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        GridColumn(
                          columnName: 'Average Monthly Consumption (kg)',
                          width: 180,
                          label: Container(
                            padding: const EdgeInsets.all(8.0),
                            alignment: Alignment.center,
                            child: const Text('Avg Monthly Consumption (kg)',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        GridColumn(
                          columnName: 'Days Left',
                          width: 100,
                          label: Container(
                            padding: const EdgeInsets.all(8.0),
                            alignment: Alignment.center,
                            child: const Text('Days Left',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: Colors.grey[100],
                    height: 60.0,
                    child: SfDataPager(
                      delegate: _employeeDataSource,
                      pageCount:
                          (_totalRecords / _rowsPerPage).ceil().toDouble(),
                      direction: Axis.horizontal,
                      onPageNavigationStart: (int pageIndex) {
                        // print('Navigating to page: ${pageIndex}');
                        int targetPage = pageIndex + 1;
                        fetchSaltData(page: targetPage, isInitial: false);
                      },
                    ),
                  ),
                ],
              ),
            ),
      appbartitle: const Text("Salt Billing Data"),
      appbaractions: [
        IconButton(
          icon: const Icon(Icons.download),
          tooltip: 'Download CSV File',
          onPressed: () => _downloadCSV(context),
        ),
        IconButton(
          icon: const Icon(Icons.share),
          tooltip: 'Share CSV File',
          onPressed: _shareCSV,
        ),
      ],
    );
  }
}
