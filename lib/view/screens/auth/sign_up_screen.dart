import 'dart:convert';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:sixam_mart/controller/auth_controller.dart';
import 'package:sixam_mart/controller/localization_controller.dart';
import 'package:sixam_mart/controller/location_controller.dart';
import 'package:sixam_mart/controller/splash_controller.dart';
import 'package:sixam_mart/data/model/body/signup_body.dart';
import 'package:sixam_mart/helper/custom_validator.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/view/base/custom_button.dart';
import 'package:sixam_mart/view/base/custom_snackbar.dart';
import 'package:sixam_mart/view/base/custom_text_field.dart';
import 'package:sixam_mart/view/base/menu_drawer.dart';
import 'package:sixam_mart/view/screens/auth/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _countryDialCode;

  @override
  void initState() {
    super.initState();
    _countryDialCode = CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).dialCode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ResponsiveHelper.isDesktop(context) ? Colors.transparent : Theme.of(context).cardColor,
      endDrawer: const MenuDrawer(), endDrawerEnableOpenDragGesture: false,
      body: SafeArea(child: Scrollbar(
        child: Center(
          child: Container(
            width: context.width > 700 ? 700 : context.width,
            padding: context.width > 700 ? const EdgeInsets.all(0) : const EdgeInsets.all(Dimensions.paddingSizeLarge),
            margin: context.width > 700 ? const EdgeInsets.all(Dimensions.paddingSizeDefault) : null,
            decoration: context.width > 700 ? BoxDecoration(
              color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            ) : null,
            child: GetBuilder<AuthController>(builder: (authController) {
              return SingleChildScrollView(
                child: Stack(
                  children: [

                    ResponsiveHelper.isDesktop(context) ? Positioned(
                      top: 0,
                      right: 0,
                      child: Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.clear),
                        ),
                      ),
                    ) : const SizedBox(),

                    Padding(
                      padding: ResponsiveHelper.isDesktop(context) ? const EdgeInsets.all(40) : EdgeInsets.zero,
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

                        Image.asset(Images.logo, width: 125),
                        const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                        Align(
                          alignment: Alignment.topLeft,
                          child: Text('sign_up'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),

                        Row(children: [
                          Expanded(
                            child: CustomTextField(
                              titleText: 'name'.tr,
                              hintText: 'ex_jhon'.tr,
                              controller: _firstNameController,
                              focusNode: _firstNameFocus,
                              nextFocus: _phoneFocus,
                              inputType: TextInputType.name,
                              capitalization: TextCapitalization.words,
                              prefixIcon: Icons.person,
                              showTitle: ResponsiveHelper.isDesktop(context),
                            ),
                          ),
                        ]),
                        const SizedBox(height: Dimensions.paddingSizeLarge),

                        Row(children: [
                          Expanded(
                            child: CustomTextField(
                              titleText: ResponsiveHelper.isDesktop(context) ? 'phone'.tr : 'enter_phone_number'.tr,
                              controller: _phoneController,
                              focusNode: _phoneFocus,
                              inputType: TextInputType.phone,
                              isPhone: true,
                              showTitle: ResponsiveHelper.isDesktop(context),
                              onCountryChanged: (CountryCode countryCode) {
                                _countryDialCode = countryCode.dialCode;
                              },
                              countryDialCode: _countryDialCode != null ? CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).code
                                  : Get.find<LocalizationController>().locale.countryCode,
                            ),
                          ),
                        ]),
                        const SizedBox(height: Dimensions.paddingSizeLarge),

                        CustomButton(
                          height: ResponsiveHelper.isDesktop(context) ? 45 : null,
                          width:  ResponsiveHelper.isDesktop(context) ? 180 : null,
                          radius: ResponsiveHelper.isDesktop(context) ? Dimensions.radiusSmall : Dimensions.radiusDefault,
                          isBold: !ResponsiveHelper.isDesktop(context),
                          fontSize: ResponsiveHelper.isDesktop(context) ? Dimensions.fontSizeExtraSmall : null,
                          buttonText: 'Create New Account',
                          isLoading: authController.isLoading,
                          onPressed: () => _register(authController, _countryDialCode!),
                        ),

                        const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('already_have_account'.tr, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),

                          InkWell(
                            onTap: () {
                              if(ResponsiveHelper.isDesktop(context)){
                                Get.back();
                                Get.dialog(const SignInScreen(exitFromApp: false, backFromThis: false));
                              }else{
                                // Get.toNamed(RouteHelper.getSignInRoute(RouteHelper.signUp));
                                Get.toNamed(RouteHelper.getForgotPassRoute(false, null));
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                              child: Text('login'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor)),
                            ),
                          ),
                        ]),

                      ]),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      )),
    );
  }

  void _register(AuthController authController, String countryCode) async {
    String firstName = _firstNameController.text.trim();
    String number = _phoneController.text.trim();

    String numberWithCountryCode = countryCode + number;
    PhoneValid phoneValid = await CustomValidator.isPhoneValid(numberWithCountryCode);
    numberWithCountryCode = phoneValid.phone;

    if (firstName.isEmpty) {
      showCustomSnackBar('enter_your_first_name'.tr);
    } else if (number.isEmpty) {
      showCustomSnackBar('enter_phone_number'.tr);
    } else if (!phoneValid.isValid) {
      showCustomSnackBar('invalid_phone_number'.tr);
    } else {
      SignUpBody signUpBody = SignUpBody(
        fName: firstName, lName: '🐞', email: '$number@ladybugg.in', phone: numberWithCountryCode,
        password: '', refCode: '',
      );
      authController.registration(signUpBody).then((status) async {
        if (status.isSuccess) {
          if(Get.find<SplashController>().configModel!.customerVerification!) {
            // Get.find<LocationController>().navigateToLocationScreen(RouteHelper.signUp);
            print('This is the status.message');
            print(status.message);
            Get.toNamed(RouteHelper.getVerificationRoute(numberWithCountryCode, status.message, RouteHelper.signUp, ''));
          } else {
            Get.find<LocationController>().navigateToLocationScreen(RouteHelper.signUp);
          }
        } else {
          showCustomSnackBar(status.message);
        }
      });
    }
  }
}