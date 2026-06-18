import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:business_app/constants.dart';
import 'package:business_app/models/leads.dart';
import 'package:business_app/services/network_provider.dart';
import 'package:business_app/widgets/background.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart'; // Ensure NewLeadForm is imported

class UnassignedLeads extends StatefulWidget {
  final Widget? child;
  final Function(bool assignExisting, Map<String, dynamic> leadinfo) assignlead;
  const UnassignedLeads({super.key, required this.assignlead, this.child});

  @override
  State<UnassignedLeads> createState() => _UnassignedLeadsState();
}

class _UnassignedLeadsState extends State<UnassignedLeads> {
  bool _isDataLoaded = false;
  List<UnassignedLead> leads = [];
  Timer? _reloadTimer;

    Future<void> getleads() async {
    setState(() {
      _isDataLoaded = false;
      leads = [];
    });
    final connectivityProvider =
        Provider.of<NetworkProvider>(context, listen: false);
    // var sharedpref = await SharedPreferences.getInstance();
    // var username = sharedpref.getString('NAME')!;
    // if (widget.leadton != null) {
    //   _leadtoname = widget.leadton;
    //   _leadbyname = '';
    // }
    // if (widget.leadbyn == true) {
    //   _leadtoname = '';
    //   _leadbyname = username;
    // }
    // final Map<String, dynamic> query = {
    //   'catagory': widget.leadtype,
    //   'leadbyn': widget.leadbyn,
    //   'leadton': widget.leadton
    // };
    try {
      final response =
          await http.get(Uri.parse('$baseuri/api/leads_list/?type=unassigned'));
      final body = json.decode(response.body);
      if (kDebugMode) {
        print(body);
      }
      if (response.statusCode == 200) {
        // initleads = leads;
        // filtervalues();
        setState(() {
          if (body.isEmpty) {
            leads = [];
          } else {
            body.forEach((lead) {
              leads.add(UnassignedLead(
                company: lead['LEADFORC'],
                pjc: lead['PJC'],
                pname: lead["PNAME"],
                custtype: lead["CUSTTYPE"],
                leaddate: lead['LEAD_DATE'],
                product: lead["LEADFORP"],
              ));
            });
          }
          _isDataLoaded = true;
        });
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print(e);
      }
      connectivityProvider.setConnected(false);
    } on http.ClientException catch (_) {
      connectivityProvider.setConnected(false);
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
    if (isConnected && !_isDataLoaded) {
      _reloadTimer?.cancel();

      // Start a new timer to delay the API call
      _reloadTimer = Timer(const Duration(seconds: 2), () {
        getleads(); // Call _fetchData() after a 3-second delay
      });
    }

    // Update the previous state for the next check
    // _lastConnectivityStatus = isConnected;

    // If we lose connection, reset _dataLoaded so it will fetch again
    if (!isConnected) {
      _reloadTimer?.cancel();
      setState(() {
        _isDataLoaded = false;
      });
    }
  }

  @override
  void dispose() {
    // It's crucial to cancel the timer when the widget is disposed
    _reloadTimer?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Background(childs: !_isDataLoaded? 
       const Center(child: CircularProgressIndicator()):
    leads.isEmpty? 
      const Center(child: Text("No Leads to Show")):
    ListView.builder(
      itemCount: leads.length,
      itemBuilder: (context, index) {
        return Card(
          color: Colors.transparent,
          child: ListTile(
            title: Text(leads[index].pname),
            subtitle: Text(leads[index].product),
            trailing: Text(leads[index].leaddate),
            tileColor: Colors.transparent,
            onTap: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => NewLeadForm(
              //       assignExisting: true,
              //       leadinfo: {
              //         'pjc': leads[index].pjc,
              //         "pname": leads[index].pname,
              //         "custtype": leads[index].custtype,
              //         "product": leads[index].product,
              //         "company": leads[index].company
              //       },
              //     ),
              //   ),
              // );
              widget.assignlead(
                 true,
                 {
                  'pjc': leads[index].pjc,
                  "pname": leads[index].pname,
                  "custtype": leads[index].custtype,
                  "product": leads[index].product,
                  "company": leads[index].company
                },
              );
            },
          ),
        );
      },
    ),appbar: true, appbartitle: const Text("Unassigned Leads"), appbaractions: const [],);
  }
}
