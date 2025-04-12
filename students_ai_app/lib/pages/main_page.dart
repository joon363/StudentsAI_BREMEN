import 'package:flutter/material.dart';
import 'package:students_ai_app/themes.dart';
import 'package:students_ai_app/widgets/prompt_help.dart';
import 'package:students_ai_app/widgets/chatbot_widget.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  String selectedField = 'Electric Engineering';
  String selectedInstitute = 'IEEE';

  final List<String> fields = [
    'Electric Engineering',
    'Biology',
    'Mechanical Engineering',
  ];

  final List<String> institutes = [
    'IEEE',
    'IEE/IET',
    'ECS',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 사이드바
          Container(
            width: 257,
            color: primaryColor,
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/icons/file icon.png',
                      height: 20,
                      fit: BoxFit.cover,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      spacing: 10,
                      children: [
                        Image.asset(
                          'assets/icons/magnifying glass_.png',
                          height: 20,
                          fit: BoxFit.cover,
                        ),
                        Image.asset(
                          'assets/icons/Vectorpen.png',
                          height: 20,
                          fit: BoxFit.cover,
                        ),
                      ],
                    )
                  ],
                ),
                SizedBox(height: 10,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Field',
                      style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                      ),
                    ),
                    Image.asset(
                      'assets/icons/plus icon.png',
                      height: 20,
                      fit: BoxFit.cover,
                    ),
                  ],
                ),
                ...fields.map((field) => ListTile(
                  leading: Image.asset(
                    field == selectedField?
                    'assets/icons/VectorHamburger_purple.png'
                      :'assets/icons/VectorHamburger.png',
                    height: 20,
                    fit: BoxFit.cover,
                  ),
                  title: Text(
                    field,
                    style: TextStyle(
                      color: field == selectedField
                          ? primaryColorDark
                          : Colors.white,
                    ),
                  ),
                  onTap: () => setState(() => selectedField = field),
                )),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Institute',
                      style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                      ),
                    ),
                    Image.asset(
                      'assets/icons/plus icon.png',
                      height: 20,
                      fit: BoxFit.cover,
                    ),
                  ],
                ),
                ...institutes.map((inst) => ListTile(
                  leading: Image.asset(
                    inst == selectedInstitute?
                    'assets/icons/VectorHamburger_purple.png'
                        :'assets/icons/VectorHamburger.png',
                    height: 20,
                    fit: BoxFit.cover,
                  ),
                  title: Text(
                    inst,
                    style: TextStyle(
                      color: inst == selectedInstitute
                          ? primaryColorDark
                          : Colors.white,
                    ),
                  ),
                  onTap: () => setState(() => selectedInstitute = inst),
                )),
              ],
            ),
          ),
          // 본문 영역
          Expanded(
              child: Padding(
                  padding: EdgeInsets.all(12),
                  child:ChatbotWidget()
              )
          )
        ],
      ),
    );
  }
}