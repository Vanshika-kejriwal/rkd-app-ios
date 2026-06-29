import "package:business_app/screens/all_leads.dart";
import "package:business_app/widgets/background.dart";
import "package:business_app/widgets/leadgenform.dart";
import "package:flutter/material.dart";
// Removed go_router import
// Removed go_router import

class LeadGeneration extends StatefulWidget {
  final Widget? child;
  bool? fromForm;
  bool assignExisting;
  Map<String, dynamic>? leadinfo;
  LeadGeneration({
    super.key,
    this.child,
    this.fromForm = false,
    this.assignExisting = false,
    this.leadinfo,
  });

  @override
  State<LeadGeneration> createState() => _LeadGenerationState();
}

class _LeadGenerationState extends State<LeadGeneration> {
  int _currentidx = 0;
  bool _assignExisting = false;
  Map<String, dynamic>? _leadinfo;

  List<Widget> get pages => [
        AllLeads(key: const ValueKey("Unassigned"),leadtype: "Unassigned", assignlead: (assignExisting, leadinfo) {
          setState(() {
            _assignExisting = assignExisting;
            _leadinfo = leadinfo;
            _currentidx = 2;
          });
        }),
        const AllLeads(key: ValueKey("Open"), leadtype: "Open"),
        NewLeadForm(assignExisting: _assignExisting, leadinfo: _leadinfo),
        const AllLeads(key: ValueKey("Closed"), leadtype: "Closed"),
         const AllLeads(key: ValueKey("All"), leadtype: "All"),
      ];
  
  @override
  void initState() {
   if (widget.fromForm != null && widget.fromForm == true) {
     setState(() {
        _currentidx = 1;
     });
   }
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Background(
      appbartitle: [
        const Text("Unassigned Leads"),
        const Text("Open Leads"),
        const Text("Add New Lead"),
        const Text("All Leads"),
        const Text("Closed Leads"),
      ][_currentidx],
      appbar: false,
      appbaractions: [
        const <Widget>[],
        const <Widget>[
          IconButton(icon: Icon(Icons.filter_list), onPressed: null)
        ],
        const <Widget>[],
        const <Widget>[
          IconButton(icon: Icon(Icons.filter_list), onPressed: null)
        ],
        const <Widget>[
          IconButton(icon: Icon(Icons.filter_list), onPressed: null)
        ],
      ][_currentidx],
      bottomvav: true,
      bottomNav: NavigationBar(
        selectedIndex: _currentidx,
        backgroundColor: Color(0xFFFFBF4D),
        onDestinationSelected: (value) {
          setState(() {
            _currentidx = value;
          });
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.assignment), label: "Unassigned"),
          NavigationDestination(
              icon: Icon(Icons.mark_as_unread), label: "Open Leads"),
          NavigationDestination(icon: Icon(Icons.add), label: "Add New"),
          NavigationDestination(icon: Icon(Icons.block), label: "Closed"),
          NavigationDestination(
              icon: Icon(Icons.assignment), label: "All Leads"),
          
        ],
      ),
      childs: pages[_currentidx],
    );
  }
}
