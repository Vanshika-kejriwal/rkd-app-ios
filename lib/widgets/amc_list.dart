import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:business_app/constants.dart';
import 'package:business_app/models/leads.dart';
import 'package:business_app/screens/amcdetail.dart';
import 'package:business_app/services/network_provider.dart';
import 'package:business_app/widgets/background.dart';
import 'package:business_app/widgets/input_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AMCList extends StatefulWidget {
  const AMCList({super.key});

  @override
  State<AMCList> createState() => _AMCListState();
}

class _AMCListState extends State<AMCList> {

  bool _isDataLoaded = false;

  List<Lead> leads = []; // Assuming Lead is a defined class
  List<Lead> _foundleads = [];
  List<Lead> initleads = [];
  Timer? _reloadTimer;
  
  Future<void> getleads() async {
    setState(() {
      _isDataLoaded = false;
      leads = [];
      _foundleads = [];
    });
    var sharedpref = await SharedPreferences.getInstance();
    var mob = sharedpref.getString("Mobile");
    var ut = sharedpref.getString("UT");
    http.Response response;
    // Removed unused username variable
    // if (widget.leadton != null) {
    //   _leadtoname = widget.leadton;
    //   _leadbyname = '';
    // }
    // if (widget.leadbyn == true) {
    //   _leadtoname = '';
    //   _leadbyname = username;
    // }

    final connectivityProvider =
        Provider.of<NetworkProvider>(context, listen: false);
    try {

        response = await http.get(Uri.parse('$baseuri/api/amc_list/?mob=$mob&ut=$ut'),
            headers: {"Content-Type": "application/json"});
      
      // print(response.headers);
      // if (kDebugMode) {
      //   print(response.body);
      // }
      final body = json.decode(response.body);
      if (kDebugMode) {
        print(body);
      }
      if (response.statusCode == 200) {
        if (body.isEmpty) {
          leads = [];
          // widget.listcountChange(0);
        } else {
          body.forEach((lead) {
           
              leads.add(Lead(
                  pjc: lead['PJC'],
                  pname: "${lead['PNAME']} (${lead['CUSTTYPE']})" ,
                  ));
            
              // DateTime followup = DateFormat('yyyy-MM-ddTHH:mm:ss.SSSSSS')
              // .parse(lead['LAST_FOLLOWUP']);
              
          });
        }
        // leads.remove(value)
        initleads = leads;
        _foundleads = leads;
        
        // filtervalues();
        if (mounted) {
          setState(() {
            _isDataLoaded = true;
          });
        }
      }
    } on SocketException catch (_) {
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
        getleads();
        // Call _fetchData() after a 3-second delay
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
  Widget build(BuildContext context) {
    return Background(childs: !_isDataLoaded
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : leads.isEmpty
            ? const Center(
                child: Text("AMCs to Show"),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: InputField(
                      label: "Search",
                      onChanged: (value) {
                        List<Lead> results = [];
                        if (value.isEmpty) {
                          results = leads;
                        } else {
                          results = leads.where((lead) {
                            return value
                                    .toLowerCase()
                                    .split(" ")
                                    .where((word) => word.isNotEmpty)
                                    .toList()
                                    .every((word) => lead.pname
                                        .toLowerCase()
                                        .contains(word)) ;
                          }).toList();
                        }
                        setState(() {
                          _foundleads = results;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                        itemCount: _foundleads.length,
                        itemBuilder: (context, index) {
                          return Card(
                              color: Colors.transparent,
                              child: ListTile(
                                title: Text(_foundleads[index].pname,
                                    style: const TextStyle(fontSize: 13)),
                                
                                // isThreeLine: true,
                                // trailing: Text(_foundleads[index].lastfollowup),
                                tileColor: Colors.transparent,
                                onTap: () {
                                  // Use Navigator.push for navigation
                                  
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>AMCDetail(
                                            currentlead: _foundleads[index]),
                                      ),
                                    ).then((_) {
                                      // Refresh the leads list when returning
                                      getleads();
                                    });
                                  
                                },
                              ));
                        }),
                  ),
                ],
              ), appbartitle: const Text("AMC List"), appbaractions: const [], appbar: true, );
  }
}