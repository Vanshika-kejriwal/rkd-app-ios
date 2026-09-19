import 'package:business_app/widgets/PendingDelivery.dart';
import 'package:business_app/widgets/PendingPickup.dart';
import 'package:business_app/widgets/TransportDetail.dart';
import 'package:business_app/widgets/background.dart';
import 'package:flutter/material.dart';

class PickupDelivery extends StatefulWidget {
  const PickupDelivery({super.key});

  @override
  State<PickupDelivery> createState() => _PickupDeliveryState();
}

class _PickupDeliveryState extends State<PickupDelivery> {
  final bool _assignExisting = false;
  Map<String, dynamic>? _leadinfo;
  // NotificationService notificationService = NotificationService();
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
        PendingPickup(),
        TransportDetail(),
        PendingDelivery(),
        // CompletedDelivery()
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
          NavigationDestination(icon: Icon(Icons.new_label), label: "Pending Pickup"),
          NavigationDestination(icon: Icon(Icons.info), label: "Transport Detail"),
          NavigationDestination(icon: Icon(Icons.delivery_dining), label: " Pending Delivery"),
          // NavigationDestination(icon: Icon(Icons.price_check), label: "AMC Rate"),
        ],
      ),
      childs: pages[_currentidx],
    );
  }
}