import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'bluetoothoffscreen.dart';
import 'scanscreen.dart';


class HomePage extends StatefulWidget{
  @override
  State createState() => _State();
}

class _State extends State{
  final String deviceIDSubstring = 'fishingRod';

  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

  @override
  void initState() {
    super.initState();
    _adapterStateStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      print(_adapterState);
      setState(() {});
    });
  }


  @override
  void dispose() {
    _adapterStateStateSubscription.cancel();
    super.dispose();
  }


  // void navigateToFAQPage(){
  //   Navigator.of(context).push(
  //       MaterialPageRoute(builder: (context) => FAQPage())
  //   );
  // }


  Widget scanWidget(){
    return ElevatedButton(
        onPressed: (){

          Navigator.push(context,
              MaterialPageRoute(builder: (context)=> BluetoothOffScreen())
          );
        },
        child: const Text('Scan')
    );
  }

  Widget blueToothOffWidget(){

    if (Platform.isAndroid) {
      return Column(
        children: [
          ElevatedButton(
              onPressed: () async {
                try {
                  if (Platform.isAndroid) {
                    await FlutterBluePlus.turnOn();
                  }
                } catch (e) {
                  print(e);
                  // Snackbar.show(ABC.a, prettyException("Error Turning On:", e), success: false);
                }
              },
              child: const Text("Turn Bluetooth On"))
        ],
      );
    }

    return Text(
      'Turn on your bluetooth.',
      style: Theme.of(context).textTheme.titleMedium,
    );

  }


  Widget HomeBody(){
    return Center(
      child:
      _adapterState == BluetoothAdapterState.on ? ScanScreen(deviceID: deviceIDSubstring,) : blueToothOffWidget(),

    );

  }

  @override
  Widget build(context){
    return Scaffold(
      appBar: AppBar(title: Text('Welcome to The Fishing app'),),
      body: HomeBody(),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: navigateToFAQPage,
      //   child: const Icon(Icons.question_mark),
      // ),
    );
  }
}