import 'dart:convert';
import 'dart:math';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/auth/domain/models/signup_body_model.dart';
import 'package:sixam_mart/helper/custom_validator.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/helper/validate_check.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class SignUpScreen extends StatefulWidget {
  final bool exitFromApp;
  const SignUpScreen({super.key, this.exitFromApp = false});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _countryDialCode;
  GlobalKey<FormState>? _formKeySignUp;

  @override
  void initState() {
    super.initState();

    _formKeySignUp = GlobalKey<FormState>();
    _countryDialCode = CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).dialCode;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Get.back(),
            icon: Icon(Icons.arrow_back_ios_rounded, color: Theme.of(context).textTheme.bodyLarge!.color),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          actions: const [SizedBox()],
        ),
        backgroundColor: Theme.of(context).cardColor,
        endDrawer: const MenuDrawer(),
        endDrawerEnableOpenDragGesture: false,
        body: Center(
          child: Container(
            width: context.width > 700 ? 700 : context.width,
            padding: context.width > 700 ? const EdgeInsets.all(0) : const EdgeInsets.all(Dimensions.paddingSizeLarge),
            margin: context.width > 700 ? const EdgeInsets.all(Dimensions.paddingSizeDefault) : null,
            decoration: context.width > 700 ? BoxDecoration(
              color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            ) : null,
            child: GetBuilder<AuthController>(builder: (authController) {

              return SingleChildScrollView(
                child: Form(
                  key: _formKeySignUp,
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

                      Image.asset(Images.logo, width: 125),
                      const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                      Align(
                        alignment: Alignment.topLeft,
                        child: Text('sign_up'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      CustomTextField(
                        labelText: 'first_name'.tr,
                        titleText: 'name'.tr,
                        controller: _firstNameController,
                        focusNode: _firstNameFocus,
                        nextFocus: _phoneFocus,
                        inputType: TextInputType.name,
                        capitalization: TextCapitalization.words,
                        prefixIcon: Icons.person,
                        required: true,
                        labelTextSize: Dimensions.fontSizeDefault,
                        validator: (value) => ValidateCheck.validateEmptyText(value, null),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                      CustomTextField(
                        labelText: 'phone'.tr,
                        titleText: 'enter_phone_number'.tr,
                        controller: _phoneController,
                        focusNode: _phoneFocus,
                        inputType: TextInputType.phone,
                        isPhone: true,
                        onCountryChanged: (CountryCode countryCode) {
                          _countryDialCode = countryCode.dialCode;
                        },
                        countryDialCode: _countryDialCode != null
                            ? CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).code
                            : Get.find<LocalizationController>().locale.countryCode,
                        required: true,
                        validator: (value) => ValidateCheck.validatePhone(value, null),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                      CustomButton(
                        buttonText: 'sign_up'.tr,
                        isLoading: authController.isLoading,
                        onPressed: authController.acceptTerms ? () => _register(authController, _countryDialCode!) : null,
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('already_have_account'.tr, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),
                        InkWell(
                          onTap: () {
                            // Get.toNamed(RouteHelper.getSignInRoute(RouteHelper.signUp));
                            Get.toNamed(RouteHelper.getForgotPassRoute(false, null));                           
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                            child: Text('sign_in'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor)),
                          ),
                        ),
                      ]),
                    ]),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  void _register(AuthController authController, String countryCode) async {
    String firstName = _firstNameController.text.trim();
    String number = _phoneController.text.trim();
    String numberWithCountryCode = countryCode + number;
    String password = generateStrongPassword(12);
    PhoneValid phoneValid = await CustomValidator.isPhoneValid(numberWithCountryCode);
    numberWithCountryCode = phoneValid.phone;

    if (_formKeySignUp!.currentState!.validate()) {
      if (firstName.isEmpty) {
        showCustomSnackBar('enter_your_first_name'.tr);
      } else if (number.isEmpty) {
        showCustomSnackBar('enter_phone_number'.tr);
      } else if (!phoneValid.isValid) {
        showCustomSnackBar('invalid_phone_number'.tr);
      } else {
        String? deviceToken = await authController.saveDeviceToken();
        SignUpBodyModel signUpBody = SignUpBodyModel(
          fName: firstName,
          lName: '.',
          email: '$number@ladybugg.in',
          phone: numberWithCountryCode,
          password: password,
          refCode: '',
          deviceToken: deviceToken,
        );
        // authController.registration(signUpBody).then((status) async {
        //   if (status.isSuccess) {
        //     Get.find<LocationController>().navigateToLocationScreen(RouteHelper.signUp);
        //   } else {
        //     showCustomSnackBar(status.message);
        //   }
        // });
        authController.registration(signUpBody).then((status) async {
          if (status.isSuccess) {
            if(Get.find<SplashController>().configModel!.customerVerification!) {
              if(Get.find<SplashController>().configModel!.firebaseOtpVerification!) {
                Get.find<AuthController>().firebaseVerifyPhoneNumber(numberWithCountryCode, status.message, fromSignUp: true);
              } else {
                List<int> encoded = utf8.encode(password);
                String data = base64Encode(encoded);
                Get.toNamed(RouteHelper.getVerificationRoute(numberWithCountryCode, status.message, RouteHelper.signUp, data));
              }
            }else {
              Get.find<LocationController>().navigateToLocationScreen(RouteHelper.signUp);
              if(ResponsiveHelper.isDesktop(context)){
                Get.back();
              }
            }
          }else {
            showCustomSnackBar(status.message);
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
