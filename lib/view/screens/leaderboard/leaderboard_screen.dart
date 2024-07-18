import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/controller/leaderboard_controller.dart';
import 'package:sixam_mart/controller/splash_controller.dart';
import 'package:sixam_mart/data/model/response/leaderboard_model.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/view/base/custom_app_bar.dart';
import 'package:sixam_mart/view/base/custom_image.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String selectedTab = "Current Month";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initCall();
  }

  initCall() async {
    LeaderboardController leaderboardController =
        Get.find<LeaderboardController>();
    await leaderboardController.getUserId();
    leaderboardController.postLeaderboardDetails("current").then((value) {
      leaderboardController.filterLeaderboard(
          title: leaderboardController.dropdownValue.value);
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.red[50],
      appBar: CustomAppBar(title: 'leader_board'.tr),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            rankCard(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                tapBarButton(
                    text: "Current Month",
                    onTap: () {
                      Get.find<LeaderboardController>()
                          .postLeaderboardDetails("current");
                      setState(() {
                        selectedTab = "Current Month";
                      });
                    },
                    isSelected: selectedTab == "Current Month",
                    context: context,
                    screenWidth: screenWidth),
                tapBarButton(
                  text: "Last Month",
                  onTap: () {
                    Get.find<LeaderboardController>()
                        .postLeaderboardDetails("previous");
                    setState(() {
                      selectedTab = "Last Month";
                    });
                  },
                  context: context,
                  screenWidth: screenWidth,
                  isSelected: selectedTab == "Last Month",
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Row(
                children: [
                  customText(
                      text: "Rank History",
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                  const Spacer(),
                  Obx(() {
                    LeaderboardController leaderboardController =
                        Get.find<LeaderboardController>();
                    return Container(
                      height: 30,
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.all(2),
                      child: DropdownButton<String>(
                        value: leaderboardController.dropdownValue.value ??
                            'overall',
                        icon: const Icon(Icons.arrow_drop_down),
                        iconSize: 24,
                        elevation: 16,
                        padding: const EdgeInsets.all(0.0),
                        style: const TextStyle(color: Colors.black),
                        underline: Container(
                          color: Colors.transparent,
                        ),
                        onChanged: leaderboardController.onChange,
                        items: leaderboardController.filterCategory
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(value),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  })
                ],
              ),
            ),
            Expanded(
              child: GetBuilder<LeaderboardController>(
                  builder: (leaderboardController) {
                return leaderboardController.isLoading.value
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).primaryColor,
                        ),
                      )
                    : leaderboardController.filterLeaderboardList.isEmpty
                        ? Center(
                            child: customText(text: "No Rank Holder Found"),
                          )
                        : ListView.builder(
                            itemCount: leaderboardController
                                        .filterLeaderboardList.length >
                                    10
                                ? 10
                                : leaderboardController
                                    .filterLeaderboardList.length,
                            itemBuilder: (context, index) {
                              final data = leaderboardController
                                  .filterLeaderboardList[index];
                              return individualRankHolder(data: data);
                            });
              }),
            )
          ],
        ),
      ),
    );
  }

  Widget rankCard() {
    LeaderboardController leaderboardController =
        Get.find<LeaderboardController>();
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(15),
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15)),
        child: Row(
          children: [
            const Image(image: AssetImage(Images.leaderboard)),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  customText(
                      text: "Your Points",
                      fontWeight: FontWeight.w600,
                      fontSize: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SizedBox(
                        width: 80,
                        child: rankMarks(
                            marks: '${leaderboardController.userRank}',
                            text: 'Rank',
                            textColor: Colors.red),
                      ),
                      SizedBox(
                        width: 100,
                        child: rankMarks(
                            marks: '${leaderboardController.userPoints}',
                            text: 'Points',
                            textColor: Colors.green),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget customText(
      {required String text,
      double? fontSize,
      FontWeight? fontWeight,
      Color? color}) {
    return Text(
      text,
      style:
          TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color),
    );
  }

  Widget rankMarks(
      {required String marks, required String text, Color? textColor}) {
    return Column(
      children: [
        SizedBox(
          height: 40,
          child: FittedBox(
            child: customText(
                text: marks, fontWeight: FontWeight.w800, fontSize: 30),
          ),
        ),
        const SizedBox(
          height: 2,
        ),
        customText(
            text: text,
            color: textColor,
            fontWeight: FontWeight.w700,
            fontSize: 16),
      ],
    );
  }

  Widget individualRankHolder({
    required DataModel data,
  }) {
    return Card(
        child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: customText(
              text: data.rank.toString(),
            ),
          ),
          const SizedBox(
            width: 3,
          ),
          Container(
            padding: const EdgeInsets.all(5),
            height: 50,
            width: 50,
            child: ClipOval(
                child: data.pic != null
                    ? CustomImage(
                        placeholder: Images.guestIconLight,
                        image:
                            '${Get.find<SplashController>().configModel!.baseUrls!.customerImageUrl}/${data.pic}',
                        height: 50,
                        width: 50,
                        fit: BoxFit.cover,
                      )
                    : const Image(
                        image: AssetImage('assets/image/person_icon.png'),
                      )),
          ),
          const SizedBox(
            width: 10,
          ),
          SizedBox(
            height: 20,
            width: 110,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                child: customText(
                    text: data.name ?? '',
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 100,
            child: FittedBox(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  customText(
                      text: data.points ?? '',
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                  const SizedBox(
                    width: 3,
                  ),
                  customText(text: "Points", fontSize: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }
}

Widget tapBarButton(
    {required String text,
    required double screenWidth,
    required bool isSelected,
    required void Function() onTap,
    required BuildContext context}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: screenWidth / 2.37,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300],
      ),
      child: Center(
          child: Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
      )),
    ),
  );
}
