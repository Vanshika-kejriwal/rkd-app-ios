import 'package:business_app/permissions/permitrequest.dart';
import 'package:business_app/screens/attendence.dart';
import 'package:business_app/screens/complainnav.dart';
import 'package:business_app/screens/installation.dart';
import 'package:business_app/screens/lead_gen.dart';
import 'package:business_app/screens/mmast.dart';
import 'package:business_app/screens/my_transactions.dart';
import 'package:business_app/screens/project_registration.dart';
import 'package:business_app/screens/service_head.dart';
import 'package:business_app/screens/splash_screen.dart';
import 'package:business_app/screens/user_registration.dart';
import 'package:business_app/services/notification_service.dart';
import 'package:business_app/widgets/background.dart';
import 'package:business_app/widgets/customer_business_profile.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:business_app/widgets/input_field.dart';
import 'package:flutter/material.dart';
// Removed go_router import
import 'package:shared_preferences/shared_preferences.dart';

class Dashboard extends StatefulWidget {
  final String ut;
  const Dashboard({super.key, required this.ut});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Permitrequest permitrequest = Permitrequest();
  NotificationService notificationService = NotificationService();
  String loginut = '';
  String loginname = '';
  String loginuc = '';
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // checkNotifPermission();
    notificationService.requestNotificationPermission();
    notificationService.firebaseInit(context);
    notificationService.setupInteractMessage(context);
    // print("Dashboard UT: ${widget.ut}");
    getusertype();
    // print("Login UT in dashboard: $loginut");
    // if (loginut.toLowerCase() == "consumer" || loginut.toLowerCase() == "contractor" || loginut.toLowerCase() == "supplier") {
    //   FirebaseMessaging.instance.unsubscribeFromTopic("all");
    // }
  }

  getusertype() async {
    var sharedpref = await SharedPreferences.getInstance();
    var ut = sharedpref.getString("UT");
    var name = sharedpref.getString("NAME");
    var uc = sharedpref.getString("UC");
    // print("Fetched UT: $ut, NAME: $name");
    setState(() {
      loginut = ut!;
      loginname = name!;
      loginuc = uc ?? '';
    });
    // print("Login UT in getusertype: $loginut");
    if (["consumer", "contractor", "supplier"]
        .contains(widget.ut.toLowerCase())) {
      FirebaseMessaging.instance.unsubscribeFromTopic("all");
    }
  }

  @override
  Widget build(BuildContext context) {
    // print("Login UT in dashboard: $loginut");
    return Background(
        showDrawer: true,
        appbarleading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.account_circle_outlined, size: 30),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          );
        }),
        drawer: Drawer(
            width: MediaQuery.of(context).size.width * 0.9,
            backgroundColor: const Color(0xffffe6bd),
            child: Scaffold(
              backgroundColor: const Color(0xffffe6bd),
              body: SafeArea(
                child: Column(
                  children: [
                    // Drawer Header
                    Container(
                      color: Colors.orange[500],
                      padding: const EdgeInsets.only(top: 40, bottom: 16),
                      child: Column(
                        children: [
                          Text(
                            "Welcome\n $loginname",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text("User Code: $loginuc",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              )),
                          const SizedBox(height: 12),

                          // Segmented Button (Personal / Business)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SegmentedButton<int>(
                              segments: const [
                                ButtonSegment(
                                  value: 0,
                                  label: Text("Personal"),
                                ),
                                ButtonSegment(
                                  value: 1,
                                  label: Text("Business"),
                                ),
                              ],
                              selected: {selectedIndex},
                              onSelectionChanged: (newSelection) {
                                setState(() {
                                  selectedIndex = newSelection.first;
                                });
                              },
                              style: ButtonStyle(
                                backgroundColor:
                                    WidgetStateProperty.resolveWith<Color?>(
                                  (states) =>
                                      states.contains(WidgetState.selected)
                                          ? Colors.white
                                          : Colors.transparent,
                                ),
                                foregroundColor:
                                    WidgetStateProperty.resolveWith<Color?>(
                                  (states) =>
                                      states.contains(WidgetState.selected)
                                          ? Colors.blue
                                          : Colors.white,
                                ),
                                side: WidgetStateProperty.all(BorderSide.none),
                                shape: WidgetStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                padding: WidgetStateProperty.all(
                                  const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Drawer Content (changes with segment)
                    Expanded(
                      child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: selectedIndex == 0
                              ? UserRegistration()
                              : const Customerbusinessprofile()),
                    ),
                  ],
                ),
              ),
            )),
        appbar: true,
        childs: Center(
          child: GridView.count(
            crossAxisCount: 3,
            padding: const EdgeInsets.all(16),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              if (!["consumer", "contractor", "supplier"]
                  .contains(widget.ut.toLowerCase()))
                _buildGridTile(
                  title: "Attendance",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Attendence()),
                  ),
                ),
              _buildGridTile(
                title: "Project Registration",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProjectRegistration()),
                ),
              ),
              if (!["consumer", "contractor", "supplier"]
                  .contains(widget.ut.toLowerCase()))
                _buildGridTile(
                  title: "Lead Generation",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LeadGeneration()),
                  ),
                ),
              _buildGridTile(
                title: "Complains",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ComplainNav()),
                ),
              ),
              _buildGridTile(
                title: "Installation",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Installation()),
                ),
              ),
              _buildGridTile(
                title: "My Transactions",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MyTransactions()),
                ),
              ),
              _buildGridTile(
                title: "Service",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Service()),
                ),
              ),
              if (["admin"].contains(widget.ut.toLowerCase()))
                _buildGridTile(
                  title: "Manufacturer Master",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Mmast()),
                  ),
                ),
            ],
          ),
        ),
        appbartitle: const Text("R K Distributors"),
        appbaractions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              var sharedpref = await SharedPreferences.getInstance();
              await sharedpref.clear();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SplashScreen(),
                  ),
                );
              }
            },
          )
        ]);
  }

  Future<void> checkNotifPermission() async {
    await permitrequest.askNotificationPermission();
  }

  Widget _buildGridTile({required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Ink(
        color: Colors.orangeAccent,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(
                8.0), // Padding to prevent text touching borders
            child: FittedBox(
              fit: BoxFit
                  .scaleDown, // Force text to shrink rather than breaking into ugly lines
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14, // Maximum preferred size for larger screens
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
