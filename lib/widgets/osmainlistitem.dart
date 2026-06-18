import 'dart:io';

import 'package:business_app/models/outstanding.dart';
import 'package:business_app/screens/pdfview.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_datagrid_export/export.dart';

class HotelTileWidget extends StatelessWidget {
  final Outstanding item;

  const HotelTileWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(7.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER ROW (Hotel Name and Total Amount)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  '${item.nAME} (${item.aC})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Amt: ${item.bAM}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // const Divider(height: 12, thickness: 1),

          // 2. COLUMN HEADERS (Bill, OD, BAM, etc.)
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                  width: 70,
                  child: Text('BillNo',
                      style: TextStyle(fontWeight: FontWeight.w600))),
              SizedBox(
                  width: 50,
                  child: Text('OD',
                      style: TextStyle(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center)),
              SizedBox(
                  width: 70,
                  child: Text('BAM',
                      style: TextStyle(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.right)),
              SizedBox(
                  width: 70,
                  child: Text('PARTPAY',
                      style: TextStyle(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.right)),
              SizedBox(
                  width: 70,
                  child: Text('OS',
                      style: TextStyle(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.right)),
            ],
          ),

          const SizedBox(height: 8),

          // 3. DYNAMIC BILL ROWS
          // Using a Column with a list of widgets generated from the data
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                item.bILLS!.map((bill) => BillRowWidget(bill: bill)).toList(),
          ),
        ],
      ),
    );
  }
}

class BillRowWidget extends StatelessWidget {
  final BILLS bill;

  const BillRowWidget({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    // You might use Expanded widgets here to ensure columns align nicely.
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // BillNo
          SizedBox(
            width: 70, // Fixed width for alignment
            child: Text(
              bill.nAME!,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          // OD Days
          SizedBox(
            width: 50,
            child: Text(
              bill.oD!,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          // BAM
          SizedBox(
            width: 70,
            child: Text(
              double.tryParse(bill.bAM ?? '0.0')!.toStringAsFixed(2),
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
          // PARTPAY
          SizedBox(
            width: 70,
            child: Text(
              double.tryParse(bill.pARTPAY ?? '0.0')!.toStringAsFixed(2),
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
          // OS (Outstanding)
          SizedBox(
            width: 70,
            child: Text(
              double.tryParse(bill.oS ?? '0.0')!.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red, // Highlight OS
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class BillDataSource extends DataGridSource {
  BillDataSource({required List<BILLS> billDetails}) {
    _billDataList = billDetails;

    _dataGridRows = _billDataList
        .map<DataGridRow>((e) => DataGridRow(cells: [
              // Mapping fields to columns based on the observed data:
              DataGridCell<String>(
                  columnName: 'Bill No & Date', value: e.nAME), // BillNo is NAME
              DataGridCell<String>(
                columnName: 'Days',
                value: "${e.oD} DAYS",
              ), // Days is OD
              DataGridCell<String>(
                  columnName: 'Bill Amt', value: double.tryParse(e.bAM ?? '0.0')!.toStringAsFixed(2)), // BAM is BAM
              DataGridCell<String>(
                  columnName: 'Part Pay',
                  value: double.tryParse(e.pARTPAY ?? '0.0')!.toStringAsFixed(2)), // PARTPAY is PARTPAY
              DataGridCell<String>(columnName: 'Net Bal', value: double.tryParse(e.oS ?? '0.0')!.toStringAsFixed(2)), // OS is OS
            ]))
        .toList();
  }

  List<BILLS> _billDataList = [];
  List<DataGridRow> _dataGridRows = [];

  @override
  List<DataGridRow> get rows => _dataGridRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((e) {
        return Container(
          alignment: (e.columnName == 'Bill No & Date' || e.columnName == 'Days')
              ? Alignment.centerLeft
              : Alignment.centerRight,
          padding: const EdgeInsets.all(8.0),
          // Use e.value.toString() to safely display String or double
          child: Text(e.value.toString()),
        );
      }).toList(),
    );
  }
}

// --- The SfDataGrid Widget with Synced Scroll ---
class CustomDataGridItem extends StatefulWidget {
  final Outstanding outstandingData;

  const CustomDataGridItem({
    super.key,
    required this.outstandingData,
  });

  @override
  State<CustomDataGridItem> createState() => _CustomDataGridItemState();
}

class _CustomDataGridItemState extends State<CustomDataGridItem> {
  // Controllers and Constants
  late BillDataSource _billDataSource;
  final ScrollController _externalHeaderController = ScrollController();
  final ScrollController _gridHorizontalController = ScrollController();
  static const double _totalGridWidth = 700.0; // Sum of minimum column widths
  final GlobalKey<SfDataGridState> dataGridKey = GlobalKey<SfDataGridState>();

  @override
  void initState() {
    super.initState();
    // Use the BILLS list directly from the Outstanding object
    _billDataSource =
        BillDataSource(billDetails: widget.outstandingData.bILLS ?? []);
    _gridHorizontalController.addListener(_syncScroll);
    _externalHeaderController.addListener(_syncGridScroll);
  }

  void _syncScroll() {
    if (_gridHorizontalController.hasClients &&
        _externalHeaderController.hasClients) {
      _externalHeaderController.jumpTo(_gridHorizontalController.offset);
    }
  }

  void _syncGridScroll() {
    // FIX 2: Check if the scroll is coming from the header. If so, move the grid.
    if (_gridHorizontalController.hasClients &&
        _externalHeaderController.hasClients) {
      if (_externalHeaderController.offset !=
          _gridHorizontalController.offset) {
        // Use jumpTo for instant sync
        _gridHorizontalController.jumpTo(_externalHeaderController.offset);
      }
    }
  }

  @override
  void dispose() {
    _gridHorizontalController.removeListener(_syncScroll);
    _externalHeaderController.removeListener(_syncGridScroll);
    _externalHeaderController.dispose();
    _gridHorizontalController.dispose();
    super.dispose();
  }

  Widget _buildSyncingHeader() {
    // Safely parse the total amount (BAM field) for the header, defaulting to 0.0
    final totalAmt =
        double.tryParse(widget.outstandingData.bAM ?? '0.0') ?? 0.0;

    // LINE 1: The Scrollable Header (Synchronized with the grid)
    return SingleChildScrollView(
      controller: _externalHeaderController,
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: _totalGridWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IntrinsicWidth(
                child: Row(
                  children: [
                    Text(
                      '${widget.outstandingData.nAME} (${widget.outstandingData.aC})', // Use NAME field
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              Text(
                'Amt: ${totalAmt.toStringAsFixed(2)}', // Use parsed BAM field
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getRequiredGridHeight() {
    // Uses the length of the billDetails list from the single input object
    final int dataRowCount = widget.outstandingData.bILLS!.length;
    // Height = (Number of Data Rows * Data Row Height) + Header Height
    return (dataRowCount * 40) + 50 + 40;
  }

  @override
  Widget build(BuildContext context) {
    final double gridHeight = _getRequiredGridHeight();
    // if (widget.outstandingData.bILLS != null &&
    //     widget.outstandingData.bILLS!.isNotEmpty) {
      return Center(
        child: SizedBox(
          height: gridHeight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0),
            child: SfDataGrid(
              key: dataGridKey,
              rowHeight: 40,
              source: _billDataSource,
              verticalScrollPhysics: const NeverScrollableScrollPhysics(),
              horizontalScrollController: _gridHorizontalController,
              columnWidthMode: ColumnWidthMode.fill,
              headerRowHeight: 50,
              stackedHeaderRows: [
                StackedHeaderRow(cells: [
                  StackedHeaderCell(
                    text: '${widget.outstandingData.nAME} (${widget.outstandingData.aC})\nNet Due Amount: ${widget.outstandingData.bAM}',
                    columnNames: ['Bill No & Date', 'Days', 'Bill Amt', 'Part Pay', 'Net Bal'],
                    child: Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.all(4.0),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.outstandingData.nAME} (${widget.outstandingData.aC})',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Net Due Amount: ${widget.outstandingData.bAM}',
                                textAlign: TextAlign.start,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          IconButton(onPressed: () async{
                 final document = dataGridKey.currentState?.exportToPdfDocument(exportStackedHeaders: true, canRepeatHeaders: true, fitAllColumnsInOnePage: true);
                   List<int> bytes = document!.saveSync();
                  //  File('OutstandingReport.pdf').writeAsBytes(bytes, flush: true);
                   document.dispose();
                  final dir = await getTemporaryDirectory();
                  // dir.delete(recursive: true);

                  final file = File('${dir.path}/Outstanding${widget.outstandingData.aC}.pdf');
                  await file.writeAsBytes(bytes, flush: true);
                  // OpenFilex.open(file.path);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Pdfview(file: file,type: "Outstanding",ac: widget.outstandingData.aC,),
                    ),
                  );
                }, icon: const Icon(Icons.download)),
                        ],
                      ),
                    ),
                  ),
                ]),
              ],
              // isScrollbarAlwaysShown: true,

              // Standard Grid Columns (Visual Line 2: BillNo:, Days, etc.)
              columns: <GridColumn>[
                GridColumn(
                  columnWidthMode: ColumnWidthMode.fitByCellValue,
                    columnName: 'Bill No & Date',
                    label: Container(
                        alignment: Alignment.center,
                        child: const Text('Bill No & Date')),
                    minimumWidth: 200),
                GridColumn(
                  columnWidthMode: ColumnWidthMode.fitByCellValue,
                    columnName: 'Days',
                    label: Container(
                        alignment: Alignment.centerLeft,
                        child: const Text('Days')),
                    minimumWidth: 90),
                GridColumn(
                  // columnWidthMode: ColumnWidthMode.fitByCellValue,
                    columnName: 'Bill Amt',
                    label: Container(
                        alignment: Alignment.centerRight,
                        child: const Text('Bill Amt')),
                    minimumWidth: 100),
                GridColumn(
                  // columnWidthMode: ColumnWidthMode.fitByCellValue,
                    columnName: 'Part Pay',
                    label: Container(
                        alignment: Alignment.centerRight,
                        child: const Text('Part Pay')),
                    minimumWidth: 100),
                GridColumn(
                  // columnWidthMode: ColumnWidthMode.fitByCellValue,
                    columnName: 'Net Bal',
                    label: Container(
                        alignment: Alignment.center,
                        child: const Text('Net Bal')),
                    minimumWidth: 100),
              ],
            ),
          ),
        ),
      );
    // } else {
    //   return const SizedBox
    //       .shrink(); // Return an empty widget if there are no bills
    // }
  }
}
