import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WhatsAppLogo extends StatelessWidget {
  const WhatsAppLogo({super.key, this.size = 18});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/ic_whatsapp.svg',
      width: size,
      height: size,
    );
  }
}
