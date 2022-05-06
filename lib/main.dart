import 'package:flutter/material.dart';
import 'package:skribbl_clone/home_screen.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
      title: 'Skribbl Clone',
    ),
  );
}
