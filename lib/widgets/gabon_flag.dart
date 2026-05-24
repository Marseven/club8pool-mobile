import 'package:flutter/material.dart';

class GabonFlag extends StatelessWidget {
  final double width;
  final double height;
  const GabonFlag({super.key, this.width = 24, this.height = 17});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0x26FFFFFF), width: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Column(
          children: [
            Expanded(child: Container(color: const Color(0xFF3A9D23))),
            Expanded(child: Container(color: const Color(0xFFFCD116))),
            Expanded(child: Container(color: const Color(0xFF3B7DC4))),
          ],
        ),
      ),
    );
  }
}
