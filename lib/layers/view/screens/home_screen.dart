import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoColors.darkBackgroundGray,
      body: Stack(
        children: [
          Column(
            children: [
              Row(
                children: [
                  SizedBox(height: 70, width: 20),
                  const Icon(Icons.sort, color: Colors.white),
                  SizedBox(width: 130),
                  const Text(
                    'Index',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  Spacer(),
                  const Icon(Icons.circle, size: 40, color: Colors.white),
                ],
              ),
              SizedBox(height: 50),
              Column(
                children: [
                  SizedBox(
                    width: 227,
                    height: 227,
                    child: Image.asset('assets/photo/homescreenpicture.png'),
                  ),
                  Text(
                    'What do you want to do today?',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Tap + to add your tasks',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
              SizedBox(height: 360),
              Positioned(
                child: FloatingActionButton.large(
                  backgroundColor: Colors.deepPurpleAccent,
                  child: Icon(CupertinoIcons.plus, color: Colors.white),
                  onPressed: () {
                    showModalBottomSheet(
                      backgroundColor: Color.fromARGB(255, 54, 54, 54),
                      context: context,
                      builder: (BuildContext context) {
                        return Column(
                          children: [
                            Container(
                              margin: EdgeInsets.only(right: 280, top: 30),
                              child: Text(
                                'Add task',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: 12,),
                            Container(
                              height: 228,
                              width: double.infinity,
                              child: TextField(
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
