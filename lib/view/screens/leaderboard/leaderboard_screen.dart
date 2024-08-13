// ChatGPT design
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/controller/leaderboard_controller.dart';
import 'package:sixam_mart/controller/splash_controller.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/view/base/custom_image.dart';
import 'package:sixam_mart/data/model/response/leaderboard_model.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String selectedTab = "Current Month";

  @override
  void initState() {
    super.initState();
    initCall();
  }

  initCall() async {
    LeaderboardController leaderboardController = Get.find<LeaderboardController>();
    await leaderboardController.postLeaderboardDetails("current");
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: Colors.pinkAccent,
      ),
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
                    Get.find<LeaderboardController>().postLeaderboardDetails("current");
                    setState(() {
                      selectedTab = "Current Month";
                    });
                  },
                  isSelected: selectedTab == "Current Month",
                  context: context,
                  screenWidth: screenWidth,
                ),
                tapBarButton(
                  text: "Last Month",
                  onTap: () {
                    Get.find<LeaderboardController>().postLeaderboardDetails("previous");
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
            const SizedBox(height: 10),
            Expanded(
              child: GetBuilder<LeaderboardController>(
                  builder: (leaderboardController) {
                return leaderboardController.isLoading.value
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).primaryColor,
                        ),
                      )
                    : leaderboardController.leaderboardData.isEmpty
                        ? Center(
                            child: customText(text: "No Rank Holder Found"),
                          )
                        : ListView.builder(
                            itemCount: leaderboardController.leaderboardData.length > 50 
                                ? 50 
                                : leaderboardController.leaderboardData.length,
                            itemBuilder: (context, index) {
                              final data = leaderboardController.leaderboardData[index];
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
    LeaderboardController leaderboardController = Get.find<LeaderboardController>();
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(15),
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Colors.deepPurple, Colors.pinkAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15)),
        child: Row(
          children: [
            const Image(image: AssetImage(Images.leaderboardIcon)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  customText(
                      text: "Your Points",
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Colors.white),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Flexible(
                        child: rankMarks(
                            marks: '${leaderboardController.userRank}',
                            text: 'Rank',
                            textColor: Colors.white),
                      ),
                      Flexible(
                        child: rankMarks(
                            marks: '${leaderboardController.userPoints}',
                            text: 'Points',
                            textColor: Colors.white),
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

  Widget customText({required String text, double? fontSize, FontWeight? fontWeight, Color? color}) {
    return Text(
      text,
      style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color),
    );
  }

  Widget rankMarks({required String marks, required String text, Color? textColor}) {
    return Column(
      children: [
        SizedBox(
          height: 40,
          child: FittedBox(
            child: customText(
                text: marks, fontWeight: FontWeight.w800, fontSize: 30, color: Colors.white),
          ),
        ),
        const SizedBox(height: 2),
        customText(
            text: text,
            color: textColor,
            fontWeight: FontWeight.w700,
            fontSize: 16),
      ],
    );
  }

  Widget individualRankHolder({required DataModel data}) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              child: customText(text: data.rank.toString(), color: Colors.white),
            ),
            const SizedBox(width: 3),
            Container(
              padding: const EdgeInsets.all(5),
              height: 50,
              width: 50,
              child: ClipOval(
                  child: data.pic != null
                      ? CustomImage(
                          placeholder: Images.guestIconLight,
                          image: '${Get.find<SplashController>().configModel!.baseUrls!.customerImageUrl}/${data.pic}',
                          height: 50,
                          width: 50,
                          fit: BoxFit.cover,
                        )
                      : const Image(
                          image: AssetImage('assets/image/guest_icon_light.png'),
                        )),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 20,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    child: customText(
                        text: data.name ?? '',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Flexible(
              child: FittedBox(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    customText(
                        text: data.points ?? '',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.white),
                    const SizedBox(width: 3),
                    customText(text: "Points", fontSize: 12, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


Widget tapBarButton({
  required String text,
  required double screenWidth,
  required bool isSelected,
  required void Function() onTap,
  required BuildContext context,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: screenWidth / 2.37,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: isSelected 
            ? const LinearGradient(
                colors: [Colors.deepPurple, Colors.pinkAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected ? null : Colors.grey[300],
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    ),
  );
}
