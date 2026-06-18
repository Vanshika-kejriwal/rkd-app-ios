import "package:business_app/widgets/background.dart";
import "package:business_app/widgets/newquotation.dart";
import "package:flutter/material.dart";

class BuyOnline extends StatefulWidget {
  const BuyOnline({super.key});

  @override
  State<BuyOnline> createState() => _BuyOnlineState();
}

class _BuyOnlineState extends State<BuyOnline> {

  int _currentidx = 0;

   List<Widget>  pages = [
    const NewQuotation(),
    // const AllLeads(leadtype: "All",),
    // const AllLeads(leadtype: "Open",),
    // const AllLeads(leadtype: "Closed",),
  ];

  @override
  Widget build(BuildContext context) {
    return  Background(
      appbaractions: const [],
      appbar: true,
      appbartitle: const Text("Online Orders"),
      bottomvav: true,
      bottomNav: NavigationBar(
        selectedIndex: _currentidx,
        backgroundColor: Colors.deepOrange,
        onDestinationSelected: (value) {
          setState(() {
            _currentidx = value;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.add), label: "Create New"),
          NavigationDestination(
              icon: Icon(Icons.assignment), label: "All Leads"),
          NavigationDestination(
              icon: Icon(Icons.mark_as_unread), label: "Open Leads"),
          NavigationDestination(icon: Icon(Icons.block), label: "Closed Leads")
        ],
      ),
      childs: pages[_currentidx],
    );
  }
}