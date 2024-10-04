import 'dart:math';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/profile/domain/models/userinfo_model.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/verification/controllers/verification_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';

class NewPassScreen extends StatefulWidget {
  final String? resetToken;
  final String? number;
  final bool fromPasswordChange;
  const NewPassScreen({super.key, required this.resetToken, required this.number, required this.fromPasswordChange});

  @override
  State<NewPassScreen> createState() => _NewPassScreenState();
}

class _NewPassScreenState extends State<NewPassScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      endDrawer: const MenuDrawer(),endDrawerEnableOpenDragGesture: false,
      body: SafeArea(child: Center(child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: FooterView(child: Container(
          width: context.width > 700 ? 700 : context.width,
          padding: context.width > 700 ? const EdgeInsets.all(Dimensions.paddingSizeDefault) : null,
          margin: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: context.width > 700 ? BoxDecoration(
            color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
          ) : null,
          child: Column(children: [
            Image.asset(Images.forgetIcon, width: 100),
            const SizedBox(height: Dimensions.paddingSizeExtraLarge),
            GetBuilder<VerificationController>(builder: (verificationController) {
              return GetBuilder<ProfileController>(builder: (profileController) {
                return GetBuilder<AuthController>(builder: (authBuilder) {
                  return CustomButton(
                    buttonText: 'Proceed',
                    isLoading: (authBuilder.isLoading || profileController.isLoading || verificationController.isLoading),
                    onPressed: () => _resetPassword(),
                  );
                });
              });
            }),
          ]),
        )),
      ))),
    );
  }

  void _resetPassword() {
    String numberWithCountryCode = '+${widget.number!.trim()}';
    String password = generateStrongPassword(12); // Replace with the actual password if you have one.
    String confirmPassword = password;
    if (password.isEmpty) {
      showCustomSnackBar('enter_password'.tr);
    }else if (password.length < 6) {
      showCustomSnackBar('password_should_be'.tr);
    }else if(password != confirmPassword) {
      showCustomSnackBar('confirm_password_does_not_matched'.tr);
    }else {
      if(widget.fromPasswordChange) {
        UserInfoModel user = Get.find<ProfileController>().userInfoModel!;
        user.password = password;
        Get.find<ProfileController>().changePassword(user).then((response) {
          if(response.isSuccess) {
            Get.back();
            showCustomSnackBar('password_updated_successfully'.tr, isError: false);
          }else {
            showCustomSnackBar(response.message);
          }
        });
      }else {
        Get.find<VerificationController>().resetPassword(widget.resetToken, '+${widget.number!.trim()}', password, confirmPassword).then((value) {
          if (value.isSuccess) {
            if(!ResponsiveHelper.isDesktop(context)) {
              Get.find<AuthController>().login(numberWithCountryCode, password).then((loginValue) async {
                if (loginValue.isSuccess) {
                  Get.find<LocationController>().navigateToLocationScreen('sign-in', offNamed: true);
                }
              }).catchError((error) {
                // After getting null exception but logged in
                Get.find<LocationController>().navigateToLocationScreen('sign-in', offNamed: true);
              });
            }
          }
        });
      }
    }
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
