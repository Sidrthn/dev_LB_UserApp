import 'dart:async';
import 'dart:io';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class SignInScreen extends StatefulWidget {
  final bool exitFromApp;
  final bool backFromThis;
  const SignInScreen({super.key, required this.exitFromApp, required this.backFromThis});

  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  bool _canExit = GetPlatform.isWeb ? true : false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvoked: (value) async {
        if(widget.exitFromApp) {
          if (_canExit) {
            if (GetPlatform.isAndroid) {
              SystemNavigator.pop();
            } else if (GetPlatform.isIOS) {
              exit(0);
            } else {
              Navigator.pushNamed(context, RouteHelper.getInitialRoute());
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('back_press_again_to_exit'.tr, style: const TextStyle(color: Colors.white)),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            ));
            _canExit = true;
            Timer(const Duration(seconds: 2), () {
              _canExit = false;
            });
          }
        } else {
          return;
        }
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Theme.of(context).cardColor,
          appBar: widget.exitFromApp ? null : AppBar(
            leading: IconButton(
              onPressed: () => Get.back(),
              icon: Icon(Icons.arrow_back_ios_rounded, color: Theme.of(context).textTheme.bodyLarge!.color),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            actions: const [SizedBox()],
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Text('sign_in'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
                  Image.asset(Images.logo, width: 125),
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                  CustomButton( // Or use ElevatedButton if preferred
                    buttonText: 'login'.tr,
                    onPressed: () => Get.toNamed(RouteHelper.getForgotPassRoute(false, null)),
                    isBold: true,
                    radius: Dimensions.radiusSmall,
                  ),

                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  
                  // New Sign Up Button
                  CustomButton(
                    buttonText: 'sign_up'.tr,
                    onPressed: () => Get.toNamed(RouteHelper.getSignUpRoute()),
                    isBold: true,
                    radius: Dimensions.radiusSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
