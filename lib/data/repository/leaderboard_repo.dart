import 'package:get/get.dart';
import 'package:sixam_mart/data/api/api_client.dart';
import 'package:sixam_mart/util/app_constants.dart';

class LeaderboardRepo extends GetxService {
  final ApiClient apiClient;

  LeaderboardRepo({required this.apiClient});

  Future<Response> postLeaderboardDetails(String selectedMonth) async {
    return apiClient.postData(AppConstants.getLeaderboardUri, {"month": selectedMonth});
  }
}
