import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:business_app/constants.dart';
import 'package:business_app/models/utils.dart';
import 'package:business_app/screens/project_registration.dart';
import 'package:business_app/services/network_provider.dart';
import 'package:business_app/widgets/input_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Customerbusinessprofile extends StatefulWidget {
  const Customerbusinessprofile({super.key});

  @override
  State<Customerbusinessprofile> createState() =>
      _CustomerbusinessprofileState();
}

class _CustomerbusinessprofileState extends State<Customerbusinessprofile> {
  Timer? _reloadTimer;
  List<CustProj> _projects = [];
  List<CustProj> _owned = [];
  List<CustProj> _associated = [];
  bool _isDataLoaded = false;
  bool _isUserLink = false;
  bool _otploading = false;
  final _mobilecontroller = TextEditingController();
  final _linkotpcontroller = TextEditingController();
  final _searchcontroller = TextEditingController();
  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();
  List<Contact>? _contacts;
  String? _selectedPhoneNumber;
  String _otpstatus = "";
  Future<List<Project>>? _searchedProj;

  Future<void> getprojects() async {
    try {
      var sharedpref = await SharedPreferences.getInstance();
      var mob = sharedpref.getString("Mobile");
      final response =
          await http.get(Uri.parse('$baseuri/api/custprojlist/?mob=$mob'));

      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);
        final projects = body
            .map((e) => CustProj.fromJson(e as Map<String, dynamic>))
            .toList();

        setState(() {
          _projects = projects;
          _owned = projects.where((p) {
            return p.tYPE == "Owned";
          }).toList();
          _associated = projects.where((p) {
            return p.tYPE == "Associated";
          }).toList();
          _isDataLoaded = true;
        });
      } else {
        setState(() {
          _projects = [];
          _isDataLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _projects = [];
          _isDataLoaded = true;
        });
      }
    }
  }

  Future<List<Project>> getallprojects({String? searchterm}) async {
    // setState(() {
    //   _projects.clear();
    // });
    Uri uri;
    if (kDebugMode) {
      uri = Uri.http(
        searchdevbaseuri,
        '/api/pnamelist/',
      );
    } else {
      uri = Uri.https(
        searchprodbaseuri,
        '/api/pnamelist/',
      );
    }

    Map<String, String> newQueryParams = {};
    List<Project> proj = [];
    // proj.add(Project(pjc: "Add New", pname: "Add New", custtype: ""));
    if (searchterm != null && searchterm.isNotEmpty) {
      var searchlist =
          searchterm.split(" ").where((term) => term.isNotEmpty).toList();
      // print(searchlist);
      // searchterm.split(" ").forEach((item) {
      //   if (item.isNotEmpty) {
      //     newQueryParams["searchterm"] =
      //         item;
      //   }
      // });
      if (kDebugMode) {
        uri = Uri.http(searchdevbaseuri, '/api/pnamelist/', {
          'searchterm': searchlist, // The correct way to pass a list
        });
      } else {
        uri = Uri.http(searchprodbaseuri, '/api/pnamelist/', {
          'searchterm': searchlist, // The correct way to pass a list
        });
      }
      // var params =
      //     searchlist.map((term) => MapEntry('searchterm', term)).toList();
      // newQueryParams = Map.fromEntries(params);
      // print(newQueryParams);
    } else {
      // proj.add(Project(pjc: "Add New", pname: "Add New", custtype: ""));
    }
    // if (newQueryParams.isNotEmpty) {
    //   uri = uri.replace(queryParameters: newQueryParams);
    // }
    final response = await http.get(uri);
    final body = json.decode(response.body);

    if (response.statusCode == 200 && body is List && body.isNotEmpty) {
      for (var c in body) {
        String name = c['PNAME'];
        String pjc = c["PJC"];
        proj.add(Project(pjc: pjc, pname: name, custtype: c["CUSTTYPE"]));
      }
    }
    return proj;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final isConnected = Provider.of<NetworkProvider>(context).isOnline;

    if (isConnected && !_isDataLoaded) {
      _reloadTimer?.cancel();
      _reloadTimer = Timer(const Duration(seconds: 2), () {
        getprojects();
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

  @override
  Widget build(BuildContext context) {
    double sheight = MediaQuery.of(context).size.height;
    return Column(
      children: [
        // Heading Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Your Owned Projects",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () {
                  // Add project action
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProjectRegistration(),
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Add"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
              ),
            ],
          ),
        ),

        // Content area
        Expanded(
          child: !_isDataLoaded
              ? const Center(child: CircularProgressIndicator())
              : _owned.isEmpty
                  ? const Center(child: Text("No Owned Projects"))
                  : ListView.builder(
                      itemCount: _owned.length,
                      itemBuilder: (context, index) {
                        final project = _owned[index];
                        return ExpansionTile(
                          trailing: _isUserLink
                              ? const SizedBox(
                                  width:
                                      24, // Give it a fixed size to avoid layout shifts
                                  height: 24,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : TextButton.icon(
                                  onPressed: () async {
                                    // Add project action
                                    var mob =
                                        await custmobdialog(project.tYPE!);
                                    if (mob != null) {
                                      linktoproject(
                                          mob["mob"], project.pJC, null);
                                    }
                                  },
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text("Add User"),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.orange,
                                  ),
                                ),
                          leading: const Icon(Icons.folder),
                          title: Text(project.pNAME!),
                          children: [
                            ListView.builder(
                              shrinkWrap:
                                  true, // important so it doesn’t take infinite height
                              physics:
                                  const NeverScrollableScrollPhysics(), // avoid nested scrolling
                              itemCount: project.pEOPLE!.length,
                              itemBuilder: (context, i) {
                                final person = project.pEOPLE![i].nAME;
                                return ListTile(
                                  leading: const Icon(Icons.person),
                                  title: Text(person!),
                                  trailing: _isUserLink
                                      ? const SizedBox(
                                          width:
                                              24, // Give it a fixed size to avoid layout shifts
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : IconButton(
                                          icon: const Icon(Icons.delete),
                                          color: Colors.red,
                                          onPressed: () {
                                            QuickAlert.show(
                                              context: context,
                                              type: QuickAlertType.confirm,
                                              title:
                                                  'Are you sure you want to unlink $person?',
                                              confirmBtnText: 'Yes',
                                              cancelBtnText: 'No',
                                              onConfirmBtnTap: () async {
                                                Navigator.of(context).pop();
                                                dlink(
                                                    project.pEOPLE![i].mOBILE1!,
                                                    project.pJC,
                                                    null,
                                                    project.pEOPLE![i].nAME!);
                                              },
                                              onCancelBtnTap: () {
                                                Navigator.of(context).pop();
                                              },
                                            );
                                          },
                                        ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Your Associated Projects",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () async {
                  // Add project action
                  var sharedpref = await SharedPreferences.getInstance();
                  var mob = sharedpref.getString("Mobile");
                  Project? selectedproj;
                  var result = await showDialog(
                    context: context,
                    builder: (context) => StatefulBuilder(
                      builder: (context, searchstate) {
                        return AlertDialog(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Search Projects"),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close),
                              )
                            ],
                          ),
                          content: SizedBox(
                            // 1. Provide a fixed width to prevent "intrinsic dimensions" errors
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InputField(
                                    controller: _searchcontroller,
                                    label: "Search Here",
                                    suff: IconButton(
                                      onPressed: () {
                                        searchstate(() {
                                          _searchedProj = getallprojects(
                                            searchterm: _searchcontroller.text,
                                          );
                                        });
                                      },
                                      icon: const Icon(Icons.search),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  FutureBuilder<List<Project>>(
                                    future: _searchedProj,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const CircularProgressIndicator();
                                      } else if (snapshot.hasData) {
                                        final dataList = snapshot.data ?? [];
                                        if (dataList.isEmpty) {
                                          return const Text(
                                              'No Projects Found');
                                        }
                                        // 2. Use a Container with a fixed height limit for the list
                                        return Container(
                                          constraints: BoxConstraints(
                                            maxHeight: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.3,
                                          ),
                                          child: ListView.builder(
                                            shrinkWrap: true, // Keep this
                                            physics:
                                                const NeverScrollableScrollPhysics(), // Let the outer SingleChildScrollView handle scrolling
                                            itemCount: dataList.length,
                                            itemBuilder: (context, index) {
                                              return ListTile(
                                                title:
                                                    Text(dataList[index].pname),
                                                onTap: () {
                                                  selectedproj =
                                                      dataList[index];
                                                  _sendlinkotp(
                                                      mob!,
                                                      searchstate,
                                                      selectedproj!.pjc);
                                                },
                                              );
                                            },
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                  if (_otploading)
                                    const CircularProgressIndicator(),
                                  Text(_otpstatus),
                                  const SizedBox(height: 10),
                                  InputField(
                                    label: "Enter OTP",
                                    controller: _linkotpcontroller,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop({
                                  'pjc': selectedproj?.pjc,
                                  "otp": _linkotpcontroller.text
                                });
                              },
                              child: const Text("Link to Project"),
                            )
                          ],
                        );
                      },
                    ),
                  );
                  if (result != null) {
                    // setState(() {
                    //   selectedItem = result;
                    // });
                    // getprojdetail(result);

                    // _sendlinkotp(mob, setstate)
                    linktoproject(mob!, result['pjc'], _linkotpcontroller.text);
                  }
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Add"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: !_isDataLoaded
              ? const Center(child: CircularProgressIndicator())
              : _associated.isEmpty
                  ? const Center(child: Text("No Associated Projects"))
                  : ListView.builder(
                      itemCount: _associated.length,
                      itemBuilder: (context, index) {
                        final project = _associated[index];
                        return ExpansionTile(
                          trailing: _isUserLink
                              ? const SizedBox(
                                  width:
                                      24, // Give it a fixed size to avoid layout shifts
                                  height: 24,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : TextButton.icon(
                                  onPressed: () async {
                                    // Add project action
                                    var mob =
                                        await custmobdialog(project.tYPE!);
                                    if (mob != null) {
                                      linktoproject(
                                          mob["mob"], project.pJC, mob["otp"]);
                                    }
                                  },
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text("Add User"),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.orange,
                                  ),
                                ),
                          leading: const Icon(Icons.folder),
                          title: Text(project.pNAME!),
                          children: [
                            ListView.builder(
                              shrinkWrap:
                                  true, // important so it doesn’t take infinite height
                              physics:
                                  const NeverScrollableScrollPhysics(), // avoid nested scrolling
                              itemCount: project.pEOPLE!.length,
                              itemBuilder: (context, i) {
                                final person = project.pEOPLE![i].nAME;
                                return ListTile(
                                  leading: const Icon(Icons.person),
                                  title: Text(person!),
                                  trailing: _isUserLink
                                      ? const SizedBox(
                                          width:
                                              24, // Give it a fixed size to avoid layout shifts
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : IconButton(
                                          icon: const Icon(Icons.delete),
                                          color: Colors.red,
                                          onPressed: () async {
                                            QuickAlert.show(
                                              context: context,
                                              type: QuickAlertType.confirm,
                                              title:
                                                  'Are you sure you want to unlink $person?',
                                              confirmBtnText: 'Yes',
                                              cancelBtnText: 'No',
                                              onConfirmBtnTap: () async {
                                                Navigator.of(context).pop();
                                                var sharedpref =
                                                    await SharedPreferences
                                                        .getInstance();
                                                var name = sharedpref
                                                    .getString("NAME");
                                                if (person != name) {
                                                  _sendlinkotp(
                                                      project
                                                          .pEOPLE![i].mOBILE1!,
                                                      setState,
                                                      "");
                                                  var mobandotp =
                                                      await dlinkotpdialog();
                                                  if (mobandotp != null) {
                                                    dlink(
                                                        project.pEOPLE![i]
                                                            .mOBILE1!,
                                                        project.pJC,
                                                        mobandotp["otp"],
                                                        project
                                                            .pEOPLE![i].nAME!);
                                                  }
                                                } else {
                                                  dlink(
                                                      project
                                                          .pEOPLE![i].mOBILE1!,
                                                      project.pJC,
                                                      null,
                                                      project.pEOPLE![i].nAME!);
                                                }
                                              },
                                              onCancelBtnTap: () {
                                                Navigator.of(context).pop();
                                              },
                                            );
                                          },
                                        ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void dlink(String person, String? pJC, String? otp, String name) async {
    setState(() {
      _isUserLink = true;
    });
    final Map<String, dynamic> query = {
      'person': person,
      'pjc': pJC,
      "otp": otp,
      "name": name
    };
    final connectivityProvider =
        Provider.of<NetworkProvider>(context, listen: false);
    try {
      final response = await http.post(Uri.parse('$baseuri/api/custdlink/'),
          body: jsonEncode(query),
          headers: {"Content-Type": "application/json"});
      // print(response.headers);
      // if (kDebugMode) {
      //   print(response.body);
      // }
      // final body = json.decode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _isUserLink = false;
        });
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("$person Unlinked")));
      } else {
        setState(() {
          _isUserLink = false;
        });
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Something went Wrong. Please try again")));
      }
    } on SocketException catch (_) {
      connectivityProvider.setConnected(false);
    } on http.ClientException catch (_) {
      connectivityProvider.setConnected(false);
    }
  }

  void linktoproject(String mob, String? pJC, String? otp) async {
    setState(() {
      _isUserLink = true;
    });
    final Map<String, dynamic> query = {'mob': mob, 'pjc': pJC, "otp": otp};
    final connectivityProvider =
        Provider.of<NetworkProvider>(context, listen: false);
    try {
      final response = await http.post(Uri.parse('$baseuri/api/custlink/'),
          body: jsonEncode(query),
          headers: {"Content-Type": "application/json"});
      // print(response.headers);
      // if (kDebugMode) {
      //   print(response.body);
      // }
      // final body = json.decode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _isUserLink = false;
        });
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("$mob Linked")));
      } else if (response.statusCode == 400) {
        setState(() {
          _isUserLink = false;
        });
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid OTP. Please try again")));
      } else if (response.statusCode == 404) {
        setState(() {
          _isUserLink = false;
        });
        // Navigator.of(context).pop();
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title:
              'The number $mob is not registered on RKD app. Send the below link to the number to download RKD app and register.',
          confirmBtnText: 'Send Invite',
          onConfirmBtnTap: () {
            Navigator.of(context).pop();
            sendInviteSMS(mob);
            Navigator.of(context).pop();
            // Builder(
            //   builder: (context) {
            //
            //      Scaffold.of(context).pop();
            //     return const SizedBox.shrink();
            //   },
            // );
          },
          showCancelBtn: true,
          cancelBtnText: 'Cancel',
          onCancelBtnTap: () {
            Navigator.of(context).pop();
          },
        );
      } else {
        setState(() {
          _isUserLink = false;
        });
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Something went Wrong. Please try again")));
      }
    } on SocketException catch (_) {
      connectivityProvider.setConnected(false);
    } on http.ClientException catch (_) {
      connectivityProvider.setConnected(false);
    }
  }

  Future<Map<String, dynamic>?> custmobdialog(String type) async {
    final Map<String, dynamic>? mobandotp = await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(builder: (context, setstate) {
              return AlertDialog(
                title: const Text("Phone Number to link"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InputField(
                      // readOnly: !_editmode,
                      label: "Mobile Number",
                      controller: _mobilecontroller,
                      keyboardtype: TextInputType.phone,
                      onChanged: (value) async {
                        if (value.length == 10) {}
                      },

                      sufficon: IconButton(
                          onPressed: () async {
                            Contact? contact =
                                await _contactPicker.selectPhoneNumber();
                            setstate(() {
                              _selectedPhoneNumber =
                                  contact?.selectedPhoneNumber;
                              if (_selectedPhoneNumber != null) {
                                var phno =
                                    _selectedPhoneNumber!.replaceAll(" ", "");
                                _mobilecontroller.text =
                                    phno.substring(phno.length - 10);

                                _selectedPhoneNumber = null;
                              }
                            });
                            if (_mobilecontroller.text.length == 10) {}
                          },
                          icon: const Icon(Icons.contacts)),
                    ),
                    if (type == "Associated")
                      ElevatedButton(
                        onPressed: () {
                          _sendlinkotp(_mobilecontroller.text, setstate, "");
                        },
                        child: _otploading
                            ? const CircularProgressIndicator()
                            : const Text("Send OTP"),
                      ),
                    if (type == "Associated") Text(_otpstatus),
                    if (type == "Associated")
                      InputField(
                        // readOnly: !_editmode,
                        label: "Enter OTP",
                        controller: _linkotpcontroller,
                        keyboardtype: TextInputType.number,
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop({
                          'mob': _mobilecontroller.text,
                          "otp": _linkotpcontroller.text
                        });
                      },
                      child: const Text("Link to Project"))
                ],
              );
            }));
    return mobandotp;
  }

  Future<Map<String, dynamic>?> dlinkotpdialog() async {
    final Map<String, dynamic>? mobandotp = await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(builder: (context, setstate) {
              return AlertDialog(
                title: const Text("OTP to Unlink"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_otpstatus),
                    InputField(
                      // readOnly: !_editmode,
                      label: "Enter OTP",
                      controller: _linkotpcontroller,
                      keyboardtype: TextInputType.number,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pop({"otp": _linkotpcontroller.text});
                      },
                      child: const Text("Unlink"))
                ],
              );
            }));
    return mobandotp;
  }

  void _sendlinkotp(String mob, setstate, String? pjc) async {
    try {
      setstate(() {
        _otploading = true;
      });
      final response = await http
          .get(Uri.parse('$baseuri/api/sendlinkotp/?mob=$mob&pjc=$pjc'));

      if (response.statusCode == 200) {
        setstate(() {
          _otpstatus = "OTP Sent Successfully";
          _otploading = false;
        });
      } else if (response.statusCode == 404) {
        setstate(() {
          _otpstatus = "No Account Exists";
          _otploading = false;
        });
        Navigator.of(context).pop();
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title:
              'The number $mob is not registered on RKD app. Send the below link to the number to download RKD app and register.',
          confirmBtnText: 'Send Invite',
          onConfirmBtnTap: () {
            Navigator.of(context).pop();
            sendInviteSMS(mob);
            Navigator.of(context).pop();
            // Builder(
            //   builder: (context) {
            //
            //      Scaffold.of(context).pop();
            //     return const SizedBox.shrink();
            //   },
            // );
          },
          showCancelBtn: true,
          cancelBtnText: 'Cancel',
          onCancelBtnTap: () {
            Navigator.of(context).pop();
          },
        );
      } else {
        setstate(() {
          _otpstatus = "No Account Exists";
          _otploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setstate(() {
          _otploading = false;
        });
      }
    }
  }

  void sendInviteSMS(String mob) {
    final Map<String, dynamic> query = {'mob': mob};
    http.post(Uri.parse('$baseuri/api/invitetorkd/'),
        body: jsonEncode(query), headers: {"Content-Type": "application/json"});
  }
}
