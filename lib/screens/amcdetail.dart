import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:business_app/screens/pdfview.dart';
import 'package:business_app/widgets/amc_booking.dart';
import 'package:business_app/widgets/input_field.dart';
import 'package:dropdown_search/dropdown_search.dart';
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
  bool? pending;
  Lead? currentlead; // Assuming Lead is a defined class
  AMCDetail({super.key, this.currentlead, this.pending});

  @override
  State<AMCDetail> createState() => _AMCDetailState();
}

class _AMCDetailState extends State<AMCDetail> {
  List<AMCDetailModel> meeting = [];
  List<AMCDetailModel> filtermeeting = [];
  bool _isdataLoaded = false;
  Timer? _reloadTimer;
  final TextEditingController _cashGiverNameController =
      TextEditingController();
  final TextEditingController _cashGiverContactController =
      TextEditingController();
  final TextEditingController _jcccontroller = TextEditingController();
  String? _selectedpaymentmethod;
  final TextEditingController _documentNumberController =
      TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();

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
  Widget _buildInfoRow(
      String label1, String value1, String label2, String value2) {
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
              '$baseuri/api/amcbookinglist/?pjc=${widget.currentlead?.pjc}&pending=${widget.pending}'),
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
                .format(parsedStartDate.add(Duration(days: days * 30)));

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

  Future<String?> openDialog(title, lablel) => showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: InputField(label: lablel, controller: _jcccontroller),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(_jcccontroller.text);
                },
                child: const Text("SUBMIT"))
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Background(
      appbar: true,
      appbartitle: Text(widget.currentlead?.pname ?? 'AMC Details'),
      appbaractions: const [],
      childs: !_isdataLoaded
          ? const Center(child: CircularProgressIndicator())
          : filtermeeting.isEmpty
              ? const Center(
                  child: Text("No data found",
                      style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  itemCount: filtermeeting.length,
                  itemBuilder: (context, index) {
                    final item = filtermeeting[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
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

                            // --- CONDITIONAL BUTTON AREA ---
                            if (widget.pending == true) ...[
                              Row(
                                children: [
                                  // 1. Share Link Button
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.share, size: 16),
                                      label: const Text(
                                        "Share Link",
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        side: BorderSide(
                                            color:
                                                Theme.of(context).primaryColor),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed:null
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // 2. Add Payment Detail Button
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.payment, size: 16),
                                      label: const Text(
                                        "Add Payment",
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        side: BorderSide(
                                            color:
                                                Theme.of(context).primaryColor),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () async {
                                        var sharedpref = await SharedPreferences
                                            .getInstance();
                                        var username =
                                            sharedpref.getString('NAME');
                                        var usermobile =
                                            sharedpref.getString('Mobile');
                                        var res = await showDialog(
                                          barrierDismissible: true,
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text(
                                                "Payment Handover Confirmation"),
                                            content: StatefulBuilder(
                                              // 1. Wrap with StatefulBuilder
                                              builder: (BuildContext context,
                                                  StateSetter setDialogState) {
                                                return SingleChildScrollView(
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(5.0),
                                                        child: DropdownSearch<
                                                            String>(
                                                          popupProps:
                                                              const PopupProps
                                                                  .dialog(
                                                            dialogProps:
                                                                DialogProps(
                                                              barrierDismissible:
                                                                  true,
                                                              barrierLabel:
                                                                  "Dismiss",
                                                            ),
                                                            showSelectedItems:
                                                                true,
                                                            showSearchBox: true,
                                                          ),
                                                          items: (filter,
                                                                  infiniteScrollProps) =>
                                                              [
                                                            "Cash",
                                                            "Cheque",
                                                            "NEFT/RTGS"
                                                          ],
                                                          decoratorProps:
                                                              const DropDownDecoratorProps(
                                                            decoration:
                                                                InputDecoration(
                                                              labelText:
                                                                  "Payment Method",
                                                              hintText:
                                                                  "Select Payment Method",
                                                            ),
                                                          ),
                                                          onSelected: (value) {
                                                            // 2. Use setDialogState to rebuild the dialog internally
                                                            setDialogState(() {
                                                              _selectedpaymentmethod =
                                                                  value!;
                                                            });

                                                            // Also update the parent view state if needed outside the dialog
                                                            setState(() {
                                                              _selectedpaymentmethod =
                                                                  value!;
                                                            });
                                                          },
                                                          selectedItem:
                                                              _selectedpaymentmethod,
                                                        ),
                                                      ),

                                                      // 3. This condition will now actively re-evaluate inside the dialog!
                                                      if (_selectedpaymentmethod ==
                                                              "Cheque" ||
                                                          _selectedpaymentmethod ==
                                                              "NEFT/RTGS") ...[
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(5.0),
                                                          child: InputField(
                                                            label:
                                                                "Document Number",
                                                            controller:
                                                                _documentNumberController,
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(5.0),
                                                          child: InputField(
                                                            label: "Bank Name",
                                                            controller:
                                                                _bankNameController,
                                                          ),
                                                        ),
                                                      ],

                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(5.0),
                                                        child: InputField(
                                                          label:
                                                              "Payment Giver Name",
                                                          controller:
                                                              _cashGiverNameController,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(5.0),
                                                        child: InputField(
                                                          label:
                                                              "Payment Giver Contact",
                                                          controller:
                                                              _cashGiverContactController,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, {
                                                  "receiver_name": username,
                                                  "receiver_contact":
                                                      usermobile,
                                                  "giver_name":
                                                      _cashGiverNameController
                                                          .text,
                                                  "giver_contact":
                                                      _cashGiverContactController
                                                          .text,
                                                  "payment_method":
                                                      _selectedpaymentmethod,
                                                  'document_number':
                                                      _documentNumberController
                                                          .text,
                                                  'bank_name':
                                                      _bankNameController.text,
                                                }),
                                                child: const Text("OK"),
                                              )
                                            ],
                                          ),
                                        );
                                        if (res != null) {
                                          // You can now use the res map to access the entered details
                                          print("Cash Handover Details: $res");
                                          // Here you can send this data to your backend or perform any other action
                                          QuickAlert.show(
                                            context: context,
                                            type: QuickAlertType.loading,
                                            text:
                                                'Sending OTP to ${res["giver_contact"]}',
                                          );
                                          var resp = await http.post(
                                              Uri.parse(
                                                  '$baseuri/api/amcpayment/'),
                                              body: jsonEncode({
                                                "amc_number":
                                                    filtermeeting[index].amcno,
                                                "payment_mode":
                                                    _selectedpaymentmethod,
                                                "receiver_name":
                                                    res["receiver_name"],
                                                "receiver_contact":
                                                    res["receiver_contact"],
                                                "giver_name": res["giver_name"],
                                                "giver_contact":
                                                    res["giver_contact"],
                                                'document_number':
                                                    res['document_number'],
                                                'bank_name': res['bank_name'],
                                              }),
                                              headers: {
                                                "Content-Type":
                                                    "application/json"
                                              });
                                          if (resp.statusCode == 200) {
                                            // enter otp dialog
                                            Navigator.of(context)
                                                .pop(); // Close the loading dialog
                                            var jcc = await openDialog(
                                                " Cash Recieve OTP",
                                                "Enter OTP");
                                            var otpverifyresp = await http.post(
                                                Uri.parse(
                                                    '$baseuri/api/amcpaymentverify/'),
                                                body: jsonEncode({
                                                  "amc_number":
                                                      filtermeeting[index]
                                                          .amcno,
                                                  "otp": jcc,
                                                  // 'item_codes':
                                                  //     _selectedamcitemdetail
                                                  //         .map((item) =>
                                                  //             item.code)
                                                  //         .toList(),
                                                }),
                                                headers: {
                                                  "Content-Type":
                                                      "application/json"
                                                });
                                            if (otpverifyresp.statusCode ==
                                                200) {
                                              QuickAlert.show(
                                                  context: context,
                                                  type: QuickAlertType.success,
                                                  title: "AMC Payment",
                                                  text:
                                                      "OTP Verified successfully and payment details added");
                                            }else{
                                              QuickAlert.show(
                                                  context: context,
                                                  type: QuickAlertType.error,
                                                  title: "AMC Payment",
                                                  text:
                                                      "OTP could not be verified. Please try again");
                                            }
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // 3. Edit Button
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.edit, size: 16),
                                      label: const Text(
                                        "Edit",
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        side: BorderSide(
                                            color:
                                                Theme.of(context).primaryColor),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AMC(edit: true, amcno:filtermeeting[index]
                                                          .amcno),
                                      ),
                                    ).then((_) {
                                      // Refresh the leads list when returning
                                      getmeetingdetail();
                                    });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              // View Receipt Button (Original)
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: OutlinedButton.icon(
                                  icon:
                                      const Icon(Icons.receipt_long, size: 18),
                                  label: const Text(
                                    "View Receipt",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: Theme.of(context).primaryColor),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () async {
                                    if (context.mounted) {
                                      QuickAlert.show(
                                          context: context,
                                          type: QuickAlertType.loading,
                                          title: "Generating Receipt...",
                                          barrierDismissible: false);
                                    }
                                    var respcode = await http
                                        .get(Uri.parse(
                                            '$baseuri/api/amcreceipt/?amc_number=${item.amcno}'))
                                        .timeout(const Duration(seconds: 120));

                                    if (respcode.statusCode == 200 ||
                                        respcode.statusCode == 201) {
                                      final jsonResponse =
                                          jsonDecode(respcode.body);

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

                                      final String base64Pdf =
                                          jsonResponse['pdf_data'];

                                      final pdfBytes = base64Decode(base64Pdf);
                                      final dir = await getTemporaryDirectory();
                                      final filepath =
                                          '${dir.path}/AMC Receipt (${widget.currentlead?.pjc})-${DateTime.now().millisecondsSinceEpoch}.pdf';
                                      File file = File(filepath);
                                      await file.writeAsBytes(pdfBytes);

                                      if (context.mounted) {
                                        Navigator.of(context)
                                            .pop(); // Close loading dialog
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
                                      }
                                    } else {
                                      if (context.mounted) {
                                        Navigator.of(context)
                                            .pop(); // Close loading dialog
                                        QuickAlert.show(
                                            context: context,
                                            type: QuickAlertType.error,
                                            title: "Could not generate receipt",
                                            text: "Something went Wrong");
                                      }
                                    }
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
