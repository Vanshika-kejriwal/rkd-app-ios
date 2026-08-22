import "package:business_app/screens/project_registration.dart";
import "package:business_app/services/notification_service.dart";
import "package:business_app/widgets/amc_booking.dart";
import "package:business_app/widgets/amc_list.dart";
import "package:business_app/widgets/amcprice.dart";
import "package:business_app/widgets/background.dart";
import "package:business_app/widgets/siteinfo.dart";
import "package:flutter/material.dart";
// Removed go_router import

class Projects extends StatefulWidget {
  bool? fromForm;
  bool assignExisting;
  Map<String, dynamic>? leadinfo;
  Projects(
      {super.key,
      this.fromForm = false,
      this.assignExisting = false,
      this.leadinfo});

  @override
  State<Projects> createState() => _ProjectsState();
}

class _ProjectsState extends State<Projects> {
  final bool _assignExisting = false;
  Map<String, dynamic>? _leadinfo;
  NotificationService notificationService = NotificationService();
  final List<Widget> _appbaraction = [];

  @override
  void initState() {
    super.initState();
    // notificationService.firebaseInit(context);
    // notificationService.setupInteractMessage(context);
    // pages = [
    //   UnassignedLeads(assignlead: (assignExisting, leadinfo) {
    //     setState(() {
    //       _assignExisting = assignExisting;
    //       _leadinfo = leadinfo;
    //       _currentidx = 2;
    //     });
    //   }),
    //   const AllLeads(
    //     key: ValueKey("Open"),
    //     leadtype: "Open",
    //   ),
    //   NewLeadForm(assignExisting: _assignExisting,leadinfo: _leadinfo),
    //   const AllLeads(
    //     key: ValueKey("All"),
    //     leadtype: "All",
    //   ),
    //   const AllLeads(
    //     key: ValueKey("Closed"),
    //     leadtype: "Closed",
    //   ),
    // ];
    // No need to set _currentidx, routing will handle page selection
  }

  int _currentidx = 0;

  List<Widget> get pages => [
        // PendingIns(assignlead: (assignExisting, leadinfo) {
        //   setState(() {
        //     _assignExisting = assignExisting;
        //     _leadinfo = leadinfo;
        //     _currentidx = 1;
        //   });
        //   // Navigator.push(
        //   //   context,
        //   //   MaterialPageRoute(
        //   //     builder: (context) => Installationasiggn(
        //   //         assignExisting: _assignExisting, leadinfo: _leadinfo),
        //   //   ),
        //   // );
        // }),
        ProjectRegistration(),
        SiteInfo()
        // AMC(),
        // AMCList(pending: true,),
        // const AMCRate()
      ];

  @override
  Widget build(BuildContext context) {
    return Background(
      appbartitle: const Text(""),
      appbar: false,
      appbaractions: const [],
      bottomvav: true,
      bottomNav: NavigationBar(
        selectedIndex: _currentidx,
        backgroundColor: Color(0xFFFFBF4D),
        onDestinationSelected: (value) {
          
          // Navigator.pushReplacementNamed(context, _routes[value]);
          setState(() {
            _currentidx = value;
          });
        },
        destinations: const [
          // NavigationDestination(icon: Icon(Icons.assignment), label: "Pending"),
          NavigationDestination(icon: Icon(Icons.new_label), label: "Project"),
          NavigationDestination(icon: Icon(Icons.info), label: "Site Info"),
          // NavigationDestination(icon: Icon(Icons.pending), label: " Pending AMC"),
          // NavigationDestination(icon: Icon(Icons.price_check), label: "AMC Rate"),
        ],
      ),
      childs: pages[_currentidx],
    );
  }
}
