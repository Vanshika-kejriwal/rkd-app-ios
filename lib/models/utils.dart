import 'dart:convert';

class UT {
  late String uT;

  UT({required this.uT});

  UT.fromJson(Map<String, dynamic> json) {
    uT = json['UT'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['UT'] = uT;
    return data;
  }
}

class CustType {
  late String custtype;

  CustType({required this.custtype});

  CustType.fromJson(Map<String, dynamic> json) {
    custtype = json['CUSTTYPE'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['CUSTTYPE'] = custtype;
    return data;
  }
}

class Project {
  String pjc;
  String pname;
  String custtype;

  Project({required this.pjc, required this.pname, required this.custtype});

  // @override
  // String toString() {
  //   return pname;
  // }
}

class Product {
  String leadid;
  String product;
  String leadtype;
  String? wpm;

  Product(
      {required this.leadid,
      required this.product,
      required this.leadtype,
      this.wpm});

  @override
  String toString() {
    return product;
  }
}

class LeadProduct {
  String company;
  String product;
  String? mc;

  LeadProduct({required this.company, required this.product, this.mc});

  Map<String, dynamic> toJson() {
    return {"product": product, "company": company, "mc": mc};
  }
}

class Amast {
  String ac;
  String name;

  Amast({required this.ac, required this.name});

  Map<String, dynamic> toJson() {
    return {"name": name, "ac": ac};
  }
}

class InvItem {
  String mc;
  String code;
  String name;
  String? id;

  InvItem({required this.mc, required this.code, required this.name, this.id});
  Map<String, dynamic> toJson() {
    return {"name": name, "mc": mc, "code": code, "id": id};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InvItem) return false;
    return mc == other.mc &&
        code == other.code &&
        name == other.name &&
        id == other.id;
  }

  @override
  int get hashCode => Object.hash(mc, code, name, id);
}

class InsDetail {
  String ino;
  String idatec;
  String ibyour;
  List<dynamic> products;

  InsDetail(
      {required this.ino,
      required this.idatec,
      required this.ibyour,
      required this.products});
}

class CustProj {
  String? pNAME;
  String? cUSTTYPE;
  String? pJC;
  String? tYPE;
  List<PEOPLE>? pEOPLE;
  String? oWNER;

  CustProj(
      {this.pNAME,
      this.cUSTTYPE,
      this.pJC,
      this.tYPE,
      this.pEOPLE,
      this.oWNER});

  CustProj.fromJson(Map<String, dynamic> json) {
    pNAME = json['PNAME'];
    cUSTTYPE = json['CUSTTYPE'];
    pJC = json['PJC'];
    tYPE = json['TYPE'];
    if (json['PEOPLE'] != null) {
      pEOPLE = <PEOPLE>[];
      json['PEOPLE'].forEach((v) {
        pEOPLE!.add(PEOPLE.fromJson(v));
      });
    }
    oWNER = json['OWNER'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['PNAME'] = pNAME;
    data['CUSTTYPE'] = cUSTTYPE;
    data['PJC'] = pJC;
    data['TYPE'] = tYPE;
    if (pEOPLE != null) {
      data['PEOPLE'] = pEOPLE!.map((v) => v.toJson()).toList();
    }
    data['OWNER'] = oWNER;
    return data;
  }
}

class PEOPLE {
  String? nAME;
  String? mOBILE1;

  PEOPLE({this.nAME, this.mOBILE1});

  PEOPLE.fromJson(Map<String, dynamic> json) {
    nAME = json['NAME'];
    mOBILE1 = json['MOBILE1'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['NAME'] = nAME;
    data['MOBILE1'] = mOBILE1;
    return data;
  }
}

class Invoice {
  String ac;
  String gstvno;
  String date;
  String amount;
  String tt;
  String? name;

  Invoice(
      {required this.ac,
      required this.gstvno,
      required this.date,
      required this.amount,
      required this.tt,
      this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Invoice &&
          runtimeType == other.runtimeType &&
          gstvno == other.gstvno; // Use your unique identifier here

  @override
  int get hashCode => gstvno.hashCode;
}

class ItemDetail {
  final String name;
  final String quantity;
  final String billdate;

  ItemDetail(
      {required this.name, required this.quantity, required this.billdate});

  // Factory to create ItemDetail from the concatenated string "item name|||quantity"
  factory ItemDetail.fromConcatenatedString(String concatenatedString) {
    final parts = concatenatedString.split('|||');
    return ItemDetail(
      name: parts[0].trim(),
      billdate: parts[2].trim(),
      quantity: parts.length > 1
          ? parts[1].trim()
          : 'N/A', // Handle case where quantity might be missing
    );
  }
}

class ProductAggregation {
  final String product;
  final String company;
  final List<ItemDetail> items; // <--- List of ItemDetail objects

  // ... (Constructor remains the same) ...
  ProductAggregation({
    required this.product,
    required this.company,
    required this.items,
  });

  factory ProductAggregation.fromJson(Map<String, dynamic> json) {
    final String itemsJsonString = json['Items'];
    final List<dynamic> decodedList = jsonDecode(itemsJsonString);

    // CRITICAL: Map the raw string list to List<ItemDetail>
    final List<ItemDetail> itemsList = decodedList
        .cast<String>()
        .map((s) => ItemDetail.fromConcatenatedString(s))
        .toList();

    return ProductAggregation(
      product: json['product'] as String,
      company: json['Company'] as String,
      items: itemsList,
    );
  }
}

class Institem {
  String code;
  String item;
  bool instremoved;
  bool serviceremoved;

  Institem(
      {required this.code,
      required this.item,
      required this.instremoved,
      required this.serviceremoved});
}

class ServiceDetailModel {
  String sno;
  String servicedate;
  String producttype;
  String company;

  ServiceDetailModel(
      {required this.sno,
      required this.servicedate,
      required this.producttype,
      required this.company});
}

class AMCModel {
  String item;
  String code;
  String idatec;

  AMCModel({required this.item, required this.code, required this.idatec});
}

class AMCDetailModel {
  String amcno;
  String amctype;
  String amcdate;
  String producttype;
  String company;
  String amount;
  String amcperiod;
  String amcstartdate;
  String warantytill;
  String cashrecievername;
  String? idatec;

  AMCDetailModel(
      {required this.amcno,
      required this.amctype,
      required this.amcdate,
      required this.producttype,
      required this.company,
      required this.amount,
      required this.amcperiod,
      required this.amcstartdate,
      required this.warantytill,
      required this.cashrecievername,
      this.idatec});
}

class LeadCategory {
  String ddl12;
  bool enabled;
  String? extrainfo;

  LeadCategory({required this.ddl12, required this.enabled, this.extrainfo});
}

class PaidRowData {
  final String col1;
  final String col2;
  final String col3;
  final String col4;
  final String col5;
  final String col6;

  PaidRowData({
    required this.col1,
    required this.col2,
    required this.col3,
    required this.col4,
    required this.col5,
    required this.col6,
  });

  factory PaidRowData.fromJson(Map<String, dynamic> json) {
    return PaidRowData(
      col1: json['Product_Type']?.toString() ?? '',
      col2: json['Company']?.toString() ?? '',
      col3: json['Model']?.toString() ?? '',
      col4: json['F1']?.toString() ?? '',
      col5: json['F2']?.toString() ?? '',
      col6: json['_12_MONTHS']?.toString() ??
          '', //"Product_Type", "Company", "Model","F1", "F2","_12_MONTHS"
    );
  }
}

class PendingTransport {
  String pickupno;
  String name;
  String city;
  String? deltype; // Optional field for delivery type

  PendingTransport(
      {required this.pickupno, required this.name, required this.city, this.deltype});
}
