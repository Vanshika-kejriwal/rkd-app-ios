import 'package:business_app/widgets/SalePurchaseDetail.dart';
import 'package:business_app/widgets/SaltBillingDetail.dart';
import 'package:business_app/widgets/background.dart';
import 'package:flutter/material.dart';

class SaleReportList extends StatelessWidget {
  const SaleReportList({super.key});

  @override
  Widget build(BuildContext context) {
    return Background(
        appbar: true,
        childs: Column(
          children: [
            Expanded(
                child: ListView(
              children: [
                Card(
                  color: Colors.transparent,
                  child: ListTile(
                    // leading: CircleAvatar(child: Text('${item.id}')),
                    title: Text(
                      "Salt Report",
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    tileColor: Colors.transparent,
                    onTap: () {
                      // Handle item interaction
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SaltBillingDetail(),
                        ),
                      );
                    },
                  ),
                ),
                Card(
                  color: Colors.transparent,
                  child: ListTile(
                    // leading: CircleAvatar(child: Text('${item.id}')),
                    title: Text(
                      "Sale and Purchase Report (item wise)",
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    tileColor: Colors.transparent,
                    onTap: () {
                      // Handle item interaction
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SalePurchaseDetail(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ))
          ],
        ),
        appbartitle: Text("Sale Report"),
        appbaractions: const []);
  }
}
