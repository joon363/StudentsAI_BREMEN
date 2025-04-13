import 'package:flutter/material.dart';
import 'package:students_ai_app/themes.dart';

class PaperInfo{
  final String title;
  final int year;
  final String pub;

  PaperInfo({
    required this.title,
    this.year=0,
    this.pub="",
  });
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isLoading;
  final bool isEnding;
  final String loadingMessage;
  final List<PaperInfo> files;

  ChatMessage({
    required this.text,
    this.isUser = false,
    this.isLoading = false,
    this.isEnding = false,
    this.loadingMessage = "",
    this.files = const[],
  });
}