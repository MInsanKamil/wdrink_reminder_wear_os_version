import 'package:flutter/material.dart';

class IntakeRecord extends StatelessWidget {
  final String intake;
  final String time;

  IntakeRecord({required this.intake, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.blue[400],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            intake,
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          Text(
            time,
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
