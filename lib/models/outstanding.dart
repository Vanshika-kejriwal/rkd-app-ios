class Outstanding {
  String? nAME;
  String? aC;
  String? bAM;
  String? sm;
  String? od;
  List<BILLS>? bILLS;

  Outstanding({this.nAME, this.aC, this.bAM, this.bILLS, this.sm, this.od});

  Outstanding.fromJson(Map<String, dynamic> json) {
    nAME = json['NAME'];
    aC = json['AC'];
    bAM = json['BAM'];
    sm = json['SM'];
    od = json['OD'];
    if (json['BILLS'] != null) {
      bILLS = <BILLS>[];
      json['BILLS'].forEach((v) {
        bILLS!.add(BILLS.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['NAME'] = nAME;
    data['AC'] = aC;
    data['BAM'] = bAM;
    if (bILLS != null) {
      data['BILLS'] = bILLS!.map((v) => v.toJson()).toList();
    }
    data['SM'] = sm;
    data['OD'] = od;
    return data;
  }
}

class BILLS {
  String? nAME;
  String? oS;
  String? oD;
  String? pARTPAY;
  String? bAM;

  BILLS({this.nAME, this.oS, this.oD, this.pARTPAY, this.bAM});

  BILLS.fromJson(Map<String, dynamic> json) {
    nAME = json['NAME'];
    oS = json['OS'];
    oD = json['OD'];
    pARTPAY = json['PARTPAY'];
    bAM = json['BAM'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['NAME'] = nAME;
    data['OS'] = oS;
    data['OD'] = oD;
    data['PARTPAY'] = pARTPAY;
    data['BAM'] = bAM;
    return data;
  }
}
