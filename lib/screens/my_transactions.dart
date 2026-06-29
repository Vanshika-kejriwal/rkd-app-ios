import "package:business_app/screens/all_trans.dart";
import "package:business_app/widgets/background.dart";
import "package:flutter/material.dart";
// Removed go_router import
// Removed go_router import

class MyTransactions extends StatefulWidget {
  const MyTransactions({
    super.key,
    
  });

  @override
  State<MyTransactions> createState() => _MyTransactionsState();
}

class _MyTransactionsState extends State<MyTransactions> {
  int _currentidx = 0;
  

  List<Widget> get pages => [
        const AllTrans(key: ValueKey("Outstanding"), leadtype: "Outstanding"),
        const AllTrans(key: ValueKey("Ledger"), leadtype: "Ledger"),
        const AllTrans(key: ValueKey("Invoices"), leadtype: "Invoices"),
        const AllTrans(key: ValueKey("BillDetail"), leadtype: "BillDetail"),
        // const AllTrans(key: ValueKey("Sales Return"), leadtype: "Sales Return"),
        const AllTrans(key: ValueKey("CNDN"), leadtype: "CNDN"),
      ];
  
  @override
  void initState() {
  
   
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
              icon: Icon(Icons.receipt_long), label: "O/S"),
          NavigationDestination(
              icon: Icon(Icons.account_balance_wallet), label: "Ledger"),
          NavigationDestination(icon: Icon(Icons.description), label: "Bills"),
          NavigationDestination(icon: Icon(Icons.details), label: "Bill Detail"),
          // NavigationDestination(
          //     icon: Icon(Icons.assignment_return), label: "Sales Return"),
          NavigationDestination(icon: Icon(Icons.note_alt), label: "CN/DN"),
        ],
      ),
      childs: pages[_currentidx],
    );
  }
}
