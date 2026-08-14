import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_datagrid_export/export.dart';
import 'package:business_app/models/outstanding.dart';
import 'package:business_app/screens/pdfview.dart';

class SummaryTileWidget extends StatelessWidget {
  final Outstanding outstandingData;
  final GlobalKey<SfDataGridState>? dataGridKey;

  const SummaryTileWidget({
    super.key,
    required this.outstandingData,
    this.dataGridKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // 1. ALLOW DYNAMIC HEIGHT: Use minHeight instead of fixed height
      constraints: const BoxConstraints(minHeight: 60.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center, // Keeps icon centered vertically
        children: [
          // 2. EXPANDED: Forces column to wrap within remaining width
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hotel Name + AC Code (Wraps to next line naturally)
                Text(
                  '${outstandingData.nAME} (${outstandingData.aC})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                // Net Due Amount (Wraps to next line if needed)
                Text(
                  'Net Due Amount: ${outstandingData.bAM}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // const SizedBox(width: 8),

          // Download Icon
          // IconButton(
          //   constraints: const BoxConstraints(),
          //   padding: EdgeInsets.zero,
          //   icon: const Icon(Icons.download),
          //   onPressed: () async {
          //     if (dataGridKey?.currentState == null) return;

          //     final document = dataGridKey!.currentState?.exportToPdfDocument(exportStackedHeaders: true, canRepeatHeaders: true, fitAllColumnsInOnePage: true);
          //          List<int> bytes = document!.saveSync();
          //         //  File('OutstandingReport.pdf').writeAsBytes(bytes, flush: true);
          //          document.dispose();
          //         final dir = await getTemporaryDirectory();
          //         // dir.delete(recursive: true);

          //         final file = File('${dir.path}/Outstanding${outstandingData.aC}.pdf');
          //         await file.writeAsBytes(bytes, flush: true);
          //         // OpenFilex.open(file.path);
          //         Navigator.push(
          //           context,
          //           MaterialPageRoute(
          //             builder: (context) => Pdfview(file: file,type: "Outstanding",ac: outstandingData.aC,),
          //           ),
          //         );
          //       }
            
          // ),
        ],
      ),
    );
  }
}