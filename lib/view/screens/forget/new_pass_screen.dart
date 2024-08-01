import 'package:sixam_mart/controller/auth_controller.dart';
import 'package:sixam_mart/controller/location_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/view/base/custom_app_bar.dart';
import 'package:sixam_mart/view/base/custom_button.dart';
import 'package:sixam_mart/view/base/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/view/base/footer_view.dart';
import 'package:sixam_mart/view/base/menu_drawer.dart';
import 'dart:math';

class NewPassScreen extends StatefulWidget {
  final String? resetToken;
  final String? number;
  final bool fromPasswordChange;
  const NewPassScreen({Key? key, required this.resetToken, required this.number, required this.fromPasswordChange}) : super(key: key);

  @override
  State<NewPassScreen> createState() => _NewPassScreenState();
}

class _NewPassScreenState extends State<NewPassScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      // appBar: CustomAppBar(title: widget.fromPasswordChange ? 'change_password'.tr : 'reset_password'.tr),
      endDrawer: const MenuDrawer(), endDrawerEnableOpenDragGesture: false,
      body: SafeArea(child: Center(child: Scrollbar(child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: FooterView(child: Container(
          width: context.width > 700 ? 700 : context.width,
          padding: context.width > 700 ? const EdgeInsets.all(Dimensions.paddingSizeDefault) : null,
          margin: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: context.width > 700 ? BoxDecoration(
            color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            boxShadow: [BoxShadow(color: Colors.grey[Get.isDarkMode ? 700 : 300]!, blurRadius: 5, spreadRadius: 1)],
          ) : null,
          child: Column(children: [
            Image.asset(Images.forgetIcon, width: 100),
            const SizedBox(height: Dimensions.paddingSizeExtraLarge),
            Text(
              'click_below_to_proceed'.tr, textAlign: TextAlign.center,
              style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeDefault),
            ),
            const SizedBox(height: 50),
            GetBuilder<LocationController>(builder: (locationController) {
              return CustomButton(
                buttonText: 'Start Shopping'.tr,
                onPressed: () => _resetPassword(),
              );
            }),
          ]),
        )),
      )))),
    );
  }

  void _resetPassword() {
    String numberWithCountryCode = '+${widget.number!.trim()}';
    String password = generateStrongPassword(12); // Replace with the actual password if you have one.
    
    Get.find<AuthController>().resetPassword(widget.resetToken, '+${widget.number!.trim()}', password, password).then((value) {
      if (value.isSuccess) {
        Get.find<AuthController>().login(numberWithCountryCode, password).then((value) async {
          Get.find<LocationController>().navigateToLocationScreen('reset-password');
        });
      } else {
        showCustomSnackBar(value.message);
      }
    });

    // Get.find<AuthController>().login(numberWithCountryCode, password).then((value) {
    //   if (value.isSuccess) {
    //     // Get.find<LocationController>().navigateToLocationScreen('sign-in');
    //     Get.find<LocationController>().navigateToLocationScreen('reset-password');
    //   } else {
    //     showCustomSnackBar(value.message);
    //   }
    // });
  }

  String generateStrongPassword(int length) {
    const String lowerCaseLetters = 'abcdefghijklmnopqrstuvwxyz';
    const String upperCaseLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String numbers = '0123456789';
    const String specialCharacters = '!@#%^&*()_+[]{}|;:,.<>?';
    const String allCharacters = '$lowerCaseLetters$upperCaseLetters$numbers$specialCharacters';

    Random random = Random.secure();
    String password = '';

    // Ensure the password includes at least one character from each set
    password += lowerCaseLetters[random.nextInt(lowerCaseLetters.length)];
    password += upperCaseLetters[random.nextInt(upperCaseLetters.length)];
    password += numbers[random.nextInt(numbers.length)];
    password += specialCharacters[random.nextInt(specialCharacters.length)];

    // Fill the rest of the password length with random characters from all sets
    for (int i = 4; i < length; i++) {
      password += allCharacters[random.nextInt(allCharacters.length)];
    }

    // Shuffle the characters to ensure randomness
    List<String> passwordChars = password.split('')..shuffle(Random.secure());
    return passwordChars.join('');
  }
}
