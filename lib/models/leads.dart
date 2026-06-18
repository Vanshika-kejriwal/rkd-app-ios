class Lead {
  String pjc;
  String pname;
  String leadtype;
  String lastfollowup;
  String? custtype;
  List<dynamic> products;
  Lead(
      {required this.pjc,
      required this.pname,
      required this.leadtype,
      required this.lastfollowup,
      this.custtype,
      required this.products});
}

class PendingInst {
  String pjc;
  String pname;
  String custtype;
  List<dynamic> products;
  String cdate;
  PendingInst(
      {required this.pjc,
      required this.pname,
      required this.custtype,
      required this.products,
      required this.cdate});
}

class UnassignedLead {
  String pjc;
  String pname;
  String company;
  String custtype;
  String leaddate;
  String product;
  UnassignedLead(
      {required this.company,
      required this.pjc,
      required this.pname,
      required this.custtype,
      required this.leaddate,
      required this.product});
}

class Meeting {
  String leadid;
  String product;
  String leadton;
  String leadbyn;
  String message;
  String scheduleMeeting;
  String checkout;
  String nextMeeting;
  String comments;
  String open;
  String visitdate;
  String createddate;
  String leadtype;
  String checkinloca;
  String checkoutloca;
  final Map<String, dynamic>? reportlink;
  bool? imagelink;
  Meeting(
      {required this.leadid,
      required this.product,
      required this.leadton,
      required this.leadbyn,
      required this.message,
      required this.scheduleMeeting,
      required this.checkout,
      required this.nextMeeting,
      required this.comments,
      required this.open,
      required this.visitdate,
      required this.createddate,
      required this.leadtype,
      required this.checkinloca,
      required this.checkoutloca,
      this.reportlink,
      this.imagelink});
}
