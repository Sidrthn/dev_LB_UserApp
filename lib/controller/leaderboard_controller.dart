import 'package:get/get.dart';
import 'package:sixam_mart/data/api/api_checker.dart';
import 'package:sixam_mart/data/model/response/leaderboard_model.dart';
import 'package:sixam_mart/data/repository/leaderboard_repo.dart';

class LeaderboardController extends GetxController implements GetxService {
  final LeaderboardRepo leaderboardRepo;

  LeaderboardController({required this.leaderboardRepo});

  String userId = '';
  RxInt userRank = 0.obs;
  RxInt userPoints = 0.obs;
  final RxList<DataModel> leaderboardData = <DataModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedMonth = 'current'.obs;

  Future<void> postLeaderboardDetails(String month) async {
    isLoading.value = true;
    try {
      Response response = await leaderboardRepo.postLeaderboardDetails(month);

      if (response.statusCode == 200) {
        leaderboardData.value = [];
        Map<String, dynamic> jsonData = response.body;

        if (jsonData.containsKey('overall')) {
          leaderboardData.value = (jsonData['overall'] as List)
              .map((item) => DataModel.fromJson(item))
              .toList();
        }

        if (jsonData.containsKey('user')) {
          // Convert user rank and points to int, if needed
          userRank.value = jsonData['user']['rank'];
          userPoints.value = jsonData['user']['points'];
        }
      } else {
        ApiChecker.checkApi(response);
      }
    } catch (e) {
      print('Error fetching leaderboard details: $e');
    } finally {
      isLoading.value = false;
    }
    update();
  }

  void updateMonth(String month) {
    selectedMonth.value = month;
    postLeaderboardDetails(month);
  }
}
