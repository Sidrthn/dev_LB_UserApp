import 'package:flutter/material.dart';
import 'package:sixam_mart/util/app_constants.dart';

ThemeData light({Color color = const Color(0xFFFF2969)}) => ThemeData(
      fontFamily: AppConstants.fontFamily,
      primaryColor: color,
      secondaryHeaderColor: const Color(0xFFFF2969),
      disabledColor: const Color(0xFFBABFC4),
      brightness: Brightness.light,
      hintColor: const Color(0xFF9F9F9F),
      cardColor: Colors.white,
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: color)),
      colorScheme: ColorScheme.light(primary: color, secondary: color)
          .copyWith(background: const Color(0xFFFCFCFC))
          .copyWith(error: const Color(0xFFE84D4F)),
    );
