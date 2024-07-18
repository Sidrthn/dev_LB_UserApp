class LeaderboardResponse {
  List<DataModel>? overall;
  List<DataModel>? demModule;
  List<DataModel>? food;
  List<DataModel>? superModule;
  List<DataModel>? grocery;
  List<DataModel>? pharmacy;
  List<DataModel>? jewellery;
  List<DataModel>? aariWork;
  List<DataModel>? bakery;
  List<DataModel>? meat;
  List<DataModel>? iceCream;
  List<DataModel>? maligai;

  LeaderboardResponse(
      {this.overall,
        this.demModule,
        this.food,
        this.superModule,
        this.grocery,
        this.pharmacy,
        this.jewellery,
        this.aariWork,
        this.bakery,
        this.meat,
        this.iceCream,
        this.maligai,
      });

  LeaderboardResponse.fromJson(Map<String, dynamic> json) {

    if (json['overall'] != null) {
      overall = <DataModel>[];
      json['overall'].forEach((v) {
        overall!.add(DataModel.fromJson(v));
      });
    }
    if (json['Dem Module'] != null) {
      demModule = <DataModel>[];
      json['Dem Module'].forEach((v) {
        demModule!.add(DataModel.fromJson(v));
      });
    }
    if (json['Food'] != null) {
      food = <DataModel>[];
      json['Food'].forEach((v) {
        food!.add(DataModel.fromJson(v));
      });
    }
    if (json['super module'] != null) {
      superModule = <DataModel>[];
      json['super module'].forEach((v) {
        superModule!.add(DataModel.fromJson(v));
      });
    }
    if (json['Grocery'] != null) {
      grocery = <DataModel>[];
      json['Grocery'].forEach((v) {
        grocery!.add(DataModel.fromJson(v));
      });
    }
    if (json['Pharmacy'] != null) {
      pharmacy = <DataModel>[];
      json['Pharmacy'].forEach((v) {
        pharmacy!.add(DataModel.fromJson(v));
      });
    }
    if (json['Jewellery'] != null) {
      jewellery = <DataModel>[];
      json['Jewellery'].forEach((v) {
        jewellery!.add(DataModel.fromJson(v));
      });
    }
    if (json['Aari Work'] != null) {
      aariWork = <DataModel>[];
      json['Aari Work'].forEach((v) {
        aariWork!.add(DataModel.fromJson(v));
      });
    }
    if (json['Bakery'] != null) {
      bakery = <DataModel>[];
      json['Bakery'].forEach((v) {
        bakery!.add(DataModel.fromJson(v));
      });
    }
    if (json['Meat'] != null) {
      meat = <DataModel>[];
      json['Meat'].forEach((v) {
        meat!.add(DataModel.fromJson(v));
      });
    }
    if (json['Ice Cream'] != null) {
      iceCream = <DataModel>[];
      json['Ice Cream'].forEach((v) {
        iceCream!.add(DataModel.fromJson(v));
      });
    }
    if (json['Grocery / மளிகை'] != null) {
      maligai = <DataModel>[];
      json['Grocery / மளிகை'].forEach((v) {
        maligai!.add(DataModel.fromJson(v));
      });
    }
  }
}

class DataModel {
  int? id;
  int? rank;
  String? pic;
  String? name;
  String? points;

  DataModel({this.id, this.rank, this.pic, this.name, this.points});

  DataModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    rank = json['rank'];
    pic = json['pic'];
    name = json['name'];
    points = json['points'].toString();
  }
}
