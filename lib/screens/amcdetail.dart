import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:business_app/screens/pdfview.dart';
import 'package:intl/intl.dart';
import 'package:business_app/constants.dart';
import 'package:business_app/models/leads.dart';
import 'package:business_app/models/utils.dart';
import 'package:business_app/services/network_provider.dart';
import 'package:business_app/widgets/background.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AMCDetail extends StatefulWidget {
  Lead? currentlead; // Assuming Lead is a defined class
  AMCDetail({super.key, this.currentlead});

  @override
  State<AMCDetail> createState() => _AMCDetailState();
}

class _AMCDetailState extends State<AMCDetail> {
  List<AMCDetailModel> meeting = [];
  List<AMCDetailModel> filtermeeting = [];
  bool _isdataLoaded = false;
  Timer? _reloadTimer;

  Widget _buildDataColumn(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 10,
              color: Colors.grey[700],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Combines two data columns into a cleanly separated row
  Widget _buildInfoRow(String label1, String value1, String label2, String value2) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDataColumn(label1, value1),
        const SizedBox(width: 16), // Clear gap between columns
        _buildDataColumn(label2, value2),
      ],
    );
  }

  Future<void> getmeetingdetail() async {
    String pjc = widget.currentlead?.pjc ?? '';
    final connectivityProvider =
        Provider.of<NetworkProvider>(context, listen: false);

    try {
      var sharedpref = await SharedPreferences.getInstance();
      var ut = sharedpref.getString('UT');
      final response = await http.get(
          Uri.parse(
              '$baseuri/api/amcbookinglist/?pjc=${widget.currentlead?.pjc}'),
          headers: {"Content-Type": "application/json"});

      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);

        if (kDebugMode) {
          print(body);
        }

        // 1. Create a local temporary list to hold our mapped data safely
        List<AMCDetailModel> parsedMeetings = [];

        if (body.isNotEmpty) {
          for (var meet in body) {
            // if (meet['CHECKIN'] != null) {
            //   visitdate = DateFormat('dd/MM/yyyy h:mm a')
            //       .format(DateTime.parse(meet['CHECKIN']));
            // }
            DateFormat inputFormat = DateFormat('dd/MM/yyyy');

            // 2. Safely parse the non-standard date string
            DateTime parsedStartDate =
                inputFormat.parse(meet['AMC_Start_Date'].toString().trim());

            // 3. Extract the days count safely
            int days = int.parse(meet['AMC_Period'].toString().split(' ')[0]);

            // 4. Add duration and format back into the desired display string
            var amcenddate = DateFormat('dd/MM/yyyy')
                .format(parsedStartDate.add(Duration(days: days)));

            // Push into our temporary local list
            parsedMeetings.add(AMCDetailModel(
              amcno: meet['AMC_no'] ?? '',
              amcdate: meet['AMC_Date'] ?? '',
              amctype: meet['AMC_Type'] ?? '',
              amount: meet['Amount'] ?? '',
              producttype: meet['Product_Type'] ?? '',
              company: meet['Company'] ?? '',
              amcperiod: amcenddate ?? '',
              amcstartdate: meet['AMC_Start_Date'] ?? '',
              warantytill: meet['Waranty_till'] ?? '',
              cashrecievername: meet['CashRecieverName'] ?? '',
              idatec: meet['IDATEC'] ?? '',
            ));
          }
        }

        // 2. Trigger UI render ONCE with clean, un-duplicated data
        setState(() {
          meeting =
              parsedMeetings; // Replaces list completely, preventing duplication
          filtermeeting = parsedMeetings;
          // _isAdmin = ut == 'ADMIN';
          _isdataLoaded = true;
        });
      } else {
        setState(() {
          meeting = [];
          _isdataLoaded = true;
        });
      }
    } on SocketException catch (_) {
      connectivityProvider.setConnected(false);
    } on http.ClientException catch (_) {
      connectivityProvider.setConnected(false);
    } catch (e, stackTrace) {
      // THIS WILL CATCH JSON MAPPING OR UNEXPECTED SERVER ERRORS
      debugPrint("Unexpected error in getmeetingdetail: $e");
      debugPrint("Stacktrace: $stackTrace");
      setState(() {
        _isdataLoaded = true;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get the current connectivity status using listen: true
    // This tells Flutter to call didChangeDependencies when the provider changes
    final isConnected = Provider.of<NetworkProvider>(context).isOnline;

    // Condition to restart API call:
    // 1. Internet is currently connected
    // 2. The previous state was NOT connected
    // 3. We are not in the middle of a fetch
    if (isConnected && !_isdataLoaded) {
      _reloadTimer?.cancel();

      // Start a new timer to delay the API call
      _reloadTimer = Timer(const Duration(seconds: 2), () {
        getmeetingdetail(); // Call _fetchData() after a 3-second delay
      });
    }

    // Update the previous state for the next check
    // _lastConnectivityStatus = isConnected;

    // If we lose connection, reset _dataLoaded so it will fetch again
    if (!isConnected) {
      _reloadTimer?.cancel();
      setState(() {
        _isdataLoaded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      appbar: true,
      appbartitle: Text(widget.currentlead?.pname ?? 'AMC Details'),
      appbaractions: const [],
      childs: !_isdataLoaded
          ? const Center(child: CircularProgressIndicator())
          : filtermeeting.isEmpty
              ? const Center(child: Text("No data found", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  itemCount: filtermeeting.length,
                  itemBuilder: (context, index) {
                    final item = filtermeeting[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        // Gives a soft transparent overlay over the background
                        color: Colors.transparent, 
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: Colors.grey,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              'Product Type',
                              "${item.company} ${item.producttype}",
                              'AMC Start Date',
                              item.amcstartdate,
                            ),
                            const Divider(height: 24, thickness: 0.5),
                            _buildInfoRow(
                              'Installation Date',
                              item.idatec!,
                              'AMC End Date',
                              item.amcperiod,
                            ),
                            const Divider(height: 24, thickness: 0.5),
                            _buildInfoRow(
                              'Warranty Valid Till',
                              item.warantytill,
                              'AMC Type',
                              item.amctype,
                            ),
                            const Divider(height: 24, thickness: 0.5),
                            _buildInfoRow(
                              'AMC Sold By',
                              item.cashrecievername,
                              'Amount',
                              "₹${item.amount}",
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.receipt_long, size: 18),
                                label: const Text(
                                  "View Receipt",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Theme.of(context).primaryColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () async{
                                if (context.mounted) {
                                QuickAlert.show(
                                    context: context,
                                    type: QuickAlertType.loading,
                                    title: "Generating Receipt...",
                                    barrierDismissible: false);
                              }
                              // String queryparam = "ino=$ino&mob=$mob";
                              var respcode = await http.get(Uri.parse(
                                  '$baseuri/api/amcreceipt/?amc_number=${item.amcno}')).timeout(const Duration(seconds: 120));
                              // if (context.mounted) {
                              //   Navigator.pop(context);
                              // }
                              if (respcode.statusCode == 200 ||
                                  respcode.statusCode == 201) {
                                // Navigator.of(context).pop();
                                final jsonResponse = jsonDecode(respcode.body);

                                // --- Extracting Mobile Numbers and Filename ---

                                final List<String> mobileNumbers =
                                    jsonResponse['mobile_numbers']
                                        .where((item) => item != null)
                                        .toList()
                                        .cast<String>();
                                final String filename =
                                    jsonResponse['filename'];

                                print(
                                    '✅ Received Mobile Numbers: $mobileNumbers');
                                print('✅ Filename: $filename');

                                // --- Decoding and Saving the PDF File ---

                                final String base64Pdf =
                                    jsonResponse['pdf_data'];

                                // 3. Base64 Decode the PDF string into raw bytes (Uint8List)
                                final pdfBytes = base64Decode(base64Pdf);
                                final dir = await getTemporaryDirectory();
                                final filepath =
                                    '${dir.path}/AMC Receipt (${widget.currentlead?.pjc})-${DateTime.now().millisecondsSinceEpoch}.pdf';
                                File file = File(filepath);
                                await file.writeAsBytes(pdfBytes);
                                Navigator.of(context)
                                    .pop(); // Close the loading dialog
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => Pdfview(
                                      file: file,
                                      type: "AMC Receipt",
                                      ac: widget.currentlead?.pjc,
                                      mobileNumbers: mobileNumbers,
                                      sno: item.amcno,
                                    ),
                                  ),
                                );
                                // if (context.mounted) {
                                //   QuickAlert.show(
                                //       context: context,
                                //       type: QuickAlertType.success,
                                //       title: "Report Generated",
                                //       text: "Successfully generated Report");
                                // }
                                // _mobcontroller.clear();
                                //successfully sent message
                              } else {
                                //something went wrong
                                if (context.mounted) {
                                  QuickAlert.show(
                                      context: context,
                                      type: QuickAlertType.error,
                                      title: "Could not generate receipt",
                                      text: "Something went Wrong");
                                }
                              }
                                },
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
