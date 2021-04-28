import 'package:YOURDRS_FlutterAPP/common/app_text.dart';
import 'package:flutter/material.dart';

class TransactionGroupSeparator extends StatelessWidget {
  final String practice;
  int appointmentsCount;
  final String locationName;
  TransactionGroupSeparator(
      {this.practice, this.appointmentsCount, this.locationName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${this.practice}-${this.locationName} (${this.appointmentsCount}) ",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
