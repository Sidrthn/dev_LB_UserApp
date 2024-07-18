import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/data/api/api_checker.dart';
import 'package:sixam_mart/data/model/response/leaderboard_model.dart';
import 'package:sixam_mart/data/repository/leaderboard_repo.dart';
import 'package:sixam_mart/util/app_constants.dart';

class LeaderboardController extends GetxController implements GetxService {
  final LeaderboardRepo leaderboardRepo;

  LeaderboardController({required this.leaderboardRepo});

  String userId = '';
  RxInt userRank = 0.obs;
  RxInt userPoints = 0.obs;

  final RxList<LeaderboardResponse> _leaderboardList =
      <LeaderboardResponse>[].obs;
  final RxList<DataModel> _filterLeaderboardList = <DataModel>[].obs;
  final RxList<String> _filterCategory = <String>[].obs;
  final Map<String, dynamic> _filterCategoryValue = <String, dynamic>{}.obs;
  final RxBool _isLoading = false.obs;
  final RxString _dropdownValue = ''.obs;

  RxList<LeaderboardResponse> get leaderboardList => _leaderboardList;

  RxList<String> get filterCategory => _filterCategory;

  Map<String, dynamic> get filterCategoryValue => _filterCategoryValue;

  RxList<DataModel> get filterLeaderboardList => _filterLeaderboardList;

  RxBool get isLoading => _isLoading;

  RxString get dropdownValue => _dropdownValue;

  Future<void> postLeaderboardDetails(String selectedMonth) async {
    _isLoading.value = true;
    Response response =
        await leaderboardRepo.postLeaderboardDetails(selectedMonth);
    if (response.statusCode == 200) {
      _leaderboardList.value = [];
      _filterCategory.value = [];
      _filterCategoryValue.clear();
      Map<String, dynamic> jsonData = response.body;
      jsonData.forEach((key, value) {
        if (value != null && value.isNotEmpty) {
          _filterCategory.add(key);
          _filterCategoryValue.addAll({key: value});
        }
      });
      if (_filterCategory.isNotEmpty) {
        filterLeaderboard(title: _filterCategory.first);
        _dropdownValue.value = _filterCategory.first;
      } else {
        _filterLeaderboardList.value = [];
      }
      _leaderboardList.add(LeaderboardResponse.fromJson(response.body));
      _isLoading.value = false;
    } else {
      ApiChecker.checkApi(response);
    }
    update();
  }

  void filterLeaderboard({required String title}) {
    _isLoading.value = true;
    _filterLeaderboardList.value = [];
    _filterCategoryValue.forEach((key, value) {
      if (key == title) {
        if (value is List) {
          for (var item in value) {
            if (item is Map<String, dynamic>) {
              DataModel itemData = DataModel.fromJson(item);
              _filterLeaderboardList.add(itemData);
            }
          }
        }
      }
    });
    try {
      var element = _filterLeaderboardList
          .firstWhere((element) => element.id.toString() == userId);
      userRank.value = element.rank!;
      userPoints.value = double.parse(element.points!).toInt();
    } catch (e) {
      userRank.value = 0;
      userPoints.value = 0;
    }
    _isLoading.value = false;
    update();
  }

  void onChange(String? category) {
    dropdownValue.value = category!;
    filterLeaderboard(title: category);
    update();
  }

  Future<void> getUserId() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    userId = sharedPreferences.getString(AppConstants.id) ?? '';
  }
}
