import 'package:auto_size_text/auto_size_text.dart';
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
        childs: SafeArea(
          child: Center(
            child: GridView.count(
              crossAxisCount: 3,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                if (!["consumer", "contractor", "supplier"]
                    .contains(widget.ut.toLowerCase()))
                  _buildDesignGridTile(
                    title: "Attendance",
                    icon: Icons.how_to_reg, // Replaced with matching Flutter material icons
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Attendence()),
                    ),
                  ),
                _buildDesignGridTile(
                  title: "Project Registration",
                  icon: Icons.assignment_ind_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProjectRegistration()),
                  ),
                ),
                if (!["consumer", "contractor", "supplier"]
                    .contains(widget.ut.toLowerCase()))
                  _buildDesignGridTile(
                    title: "Lead Generation",
                    icon: Icons.chat_bubble_outline_rounded,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LeadGeneration()),
                    ),
                  ),
                _buildDesignGridTile(
                  title: "Complains",
                  icon: Icons.sms_failed_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ComplainNav()),
                  ),
                ),
                _buildDesignGridTile(
                  title: "Installation",
                  icon: Icons.construction_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Installation()),
                  ),
                ),
                _buildDesignGridTile(
                  title: "My Transactions",
                  icon: Icons.assignment_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MyTransactions()),
                  ),
                ),
                _buildDesignGridTile(
                  title: "Service",
                  icon: Icons.build_circle_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Service()),
                  ),
                ),
                if (["admin"].contains(widget.ut.toLowerCase()))
                  _buildDesignGridTile(
                    title: "Manufacturer Master",
                    icon: Icons.assignment_turned_in_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Mmast()),
                    ),
                  ),
              ],
            ),
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
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
            child: AutoSizeText(
              title,
              textAlign: TextAlign.center,
              maxLines: 2, // Limits layout to exactly 2 lines maximum
              minFontSize:
                  9, // Prevents it from shrinking to an unreadable size
              stepGranularity: 1, // Decrements smoothly by 1px steps to fit
              style: const TextStyle(
                fontSize: 12, // Preferred starting size for larger displays
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesignGridTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFC8C7CC), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      color: const Color(0xFFFFF2D6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              // Top Section: Centered Icon
              Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Dynamically calculate icon size as 45% of the available box height
                  // On smaller screens, this scales down automatically.
                  final iconSize = constraints.maxHeight * 0.50;
                  
                  return Center(
                    child: Icon(
                      icon,
                      size: iconSize,
                      color: Colors.black87,
                    ),
                    /* If you are using Material Icons instead, use this:
                    child: Icon(
                      icon,
                      size: iconSize,
                      color: Colors.black87,
                    ),
                    */
                  );
                },
              ),
            ),
              // Bottom Section: Solid orange title banner
              Container(
                width: double.infinity,
                height:
                    40, // Fixed height ensures all bottom banners match fgvperfectly
                padding:
                    const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                color: const Color(0xFFFFBF4D),
                child: Center(
                  child: AutoSizeText(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2, // Allows it to drop cleanly into two lines
                    minFontSize:
                        9, // Safely scales down on devices like iPhone mini
                    stepGranularity: 0.5, // Smooth downscaling
                    style: const TextStyle(
                      fontSize: 12, // Base size matching Figma design
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.1, // Tightens line spacing for 2 lines
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
