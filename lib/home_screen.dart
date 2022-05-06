import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Create/Join a room to play!',
            style: TextStyle(color: Colors.black, fontSize: 24),
          ),
          SizedBox(
            height: size.height * 0.1,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {},
                child: const Text(
                  'Create',
                  style: TextStyle(fontSize:16),
                ),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.blue),
                  textStyle: MaterialStateProperty.all(const TextStyle(color:Colors.white),),
                  minimumSize: MaterialStateProperty.all(Size(size.width/2.5,50,),),
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                child: const Text(
                  'Join',
                  style: TextStyle(fontSize:16),
                ),
                style:ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.blue),
                  textStyle: MaterialStateProperty.all(const TextStyle(color:Colors.white),),
                  minimumSize: MaterialStateProperty.all(Size(size.width/2.5,50,),),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
