import "package:business_app/services/notification_service.dart";
import "package:business_app/widgets/background.dart";
import "package:business_app/widgets/completed_ins.dart";
import "package:business_app/widgets/completed_service.dart";
import "package:business_app/widgets/installationAsiggn.dart";
import "package:business_app/widgets/installation_master.dart";
import "package:business_app/widgets/pending_ins.dart";
import "package:business_app/widgets/pending_service.dart";
import "package:business_app/widgets/serviceedit.dart";
import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";
// Removed go_router import

class Service extends StatefulWidget {
  bool? fromForm;
  bool assignExisting;
 
  Map<String, dynamic>? leadinfo;
  Service(
      {super.key,
      this.fromForm = false,
      this.assignExisting = false,
      this.leadinfo});

  @override
  State<Service> createState() => _ServiceState();
}

class _ServiceState extends State<Service> {
  bool _assignExisting = false;
  Map<String, dynamic>? _leadinfo;
  NotificationService notificationService = NotificationService();
  final List<Widget> _appbaraction = [];
  String _loginut = "";
  int _currentidx = 0;
 @override
  void initState() {
    super.initState();
    _loadUserType(); // renamed for clarity
  }

  Future<void> _loadUserType() async {
    final prefs = await SharedPreferences.getInstance();
    final ut = prefs.getString("UT") ?? "";
    if (mounted) {
      setState(() {
        _loginut = ut;
      });
    }
    print("Login User Type: $_loginut");
  }

  // Generate destinations dynamically
  List<NavigationDestination> _getDestinations() {
    return [
      const NavigationDestination(icon: Icon(Icons.assignment), label: "Pending"),
      const NavigationDestination(icon: Icon(Icons.done_all), label: "Completed"),
      if (_loginut.toLowerCase() == "admin")
        const NavigationDestination(icon: Icon(Icons.settings), label: "Inst Mast"),
    ];
  }

  // Generate pages dynamically to match destinations
  List<Widget> _getPages() {
    return [
      PendingIns(assignlead: (assignExisting, leadinfo) => _navigateToAssign(assignExisting, leadinfo)),
      CompletedIns(assignlead: (assignExisting, leadinfo) => _navigateToAssign(assignExisting, leadinfo)),
      if ((_loginut.toLowerCase() == "admin") || (_loginut.toLowerCase() == "employee"))
         InstMast(service: true),
    ];
  }

  void _navigateToAssign(bool existing, Map<String, dynamic>? info) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Installationasiggn(assignExisting: existing, leadinfo: info),
      ),
    );
  }

 @override
Widget build(BuildContext context) {
  // Define these INSIDE build so they refresh when _loginut updates
  final List<NavigationDestination> destinations = [
    const NavigationDestination(icon: Icon(Icons.assignment), label: "Pending"),
    const NavigationDestination(icon: Icon(Icons.done_all), label: "Completed"),
  ];

  final List<Widget> pageList = [
    // const Center(child: Text("Coming Soon")), 
    // const Center(child: Text("Coming Soon")), // Placeholder for PendingIns
    PendingService(assignlead: (assign, info) => _handleNav(assign, info)),
    CompletedService(assignlead: (assign, info) => _handleNav(assign, info)),
  ];

  // Add the Admin specific items only if condition is met
  if ((_loginut.toLowerCase() == "admin") || (_loginut.toLowerCase() == "employee")) {
    destinations.add(const NavigationDestination(icon: Icon(Icons.add), label: " New Service"));
    pageList.add( ServiceEdit());
    destinations.add(const NavigationDestination(icon: Icon(Icons.settings), label: "Service Mast"));
    pageList.add( InstMast(service: true,));
  }

  return Background(
    appbaractions: const [],
    appbartitle: const Text(""),
    appbar: false,
    bottomvav: true,
    bottomNav: NavigationBar(
      selectedIndex: _currentidx >= destinations.length ? 0 : _currentidx,
      backgroundColor: Color(0xFFFFBF4D),
      onDestinationSelected: (value) {
        setState(() {
          _currentidx = value;
        });
      },
      destinations: destinations,
    ),
    // Show a small loader if _loginut is still empty (optional)
    childs: pageList[_currentidx],
  );
}

// Helper for your navigation logic
void _handleNav(bool assignExisting, Map<String, dynamic>? leadinfo) {
  setState(() {
    _assignExisting = assignExisting;
    _leadinfo = leadinfo;
  });
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Installationasiggn(
          assignExisting: _assignExisting, leadinfo: _leadinfo),
    ),
  );
}
}
