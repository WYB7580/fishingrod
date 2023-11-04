import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'devicepage.dart';

class ScanScreen extends StatefulWidget {

  final String deviceID;

  const ScanScreen({Key? key, required this.deviceID}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<BluetoothDevice> _connectedDevices = [];
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  @override
  void initState() {
    super.initState();

    FlutterBluePlus.systemDevices.then((devices) {
      _connectedDevices = devices;
      setState(() {});
    });

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results;
      setState(() {});
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      _isScanning = state;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }


  void NavigateToDevicePage(BluetoothDevice device){

    try {
      FlutterBluePlus.stopScan();
    } catch (e) {

    }


    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DevicePage(device: device))
    ).then( (value) async{
      if(device.isConnected){
        await device.disconnect();
        print('disconnect');
      }
    });
  }


  String prettyException(String prefix, dynamic e) {
    if (e is FlutterBluePlusException) {
      return "$prefix ${e.description}";
    } else if (e is PlatformException) {
      return "$prefix ${e.message}";
    }
    return prefix + e.toString();
  }

  void showSnackBar(String message, bool success){
    GlobalKey<ScaffoldMessengerState> snackBarKey = GlobalKey<ScaffoldMessengerState>();
    SnackBar snackbar = SnackBar(
      content: Text(message),
      backgroundColor: success? Colors.blue : Colors.red
    );
    snackBarKey.currentState?.removeCurrentSnackBar();
    snackBarKey.currentState?.showSnackBar(snackbar);
  }


  Future onScanPressed() async {
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      showSnackBar(prettyException("Start Scan Error:", e), false);
    }
    setState(() {}); // force refresh of systemDevices
  }

  Future onStopPressed() async {
    try {
      FlutterBluePlus.stopScan();
    } catch (e) {
      showSnackBar(prettyException("Stop Scan Error:", e), false);
    }
  }


  Future onRefresh() {
    if (_isScanning == false) {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    }
    setState(() {});
    return Future.delayed(Duration(milliseconds: 500));
  }

  Widget buildScanButton(BuildContext context) {
    if (FlutterBluePlus.isScanningNow) {
      return FloatingActionButton(
        child: const Icon(Icons.stop),
        onPressed: onStopPressed,
        backgroundColor: Colors.red,
      );
    } else {
      return FloatingActionButton(child: const Text("SCAN"), onPressed: onScanPressed);
    }
  }


  void onDevicePress(BluetoothDevice device) async {

    await device.connect();



    if(device.isConnected){
      print('connected');
      NavigateToDevicePage(device);
    }
    else{
      print('error connecting');
    }
  }

  Widget deviceListViewBuilder(){

    List<ScanResult> results = [];
    for(ScanResult r in _scanResults){
      if(r.advertisementData.localName.contains(widget.deviceID)){
        results.add(r);
      }
    }

    return ListView.builder(
        shrinkWrap: true,
        itemCount: results.length,
        itemBuilder: (context, index){
          print('Name: ${results[index].rssi.toString()}');
          print('advertisementData: ${results[index].advertisementData}');
          var adv = results[index].advertisementData;
          BluetoothDevice device = results[index].device;
          return Card(child:
          ListTile(
            title: Text(adv.localName),
            trailing: const Icon(Icons.chevron_right),
            onTap: (){ onDevicePress(device); },
          ),
          );
        }
    );
  }




  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
            onPressed: onRefresh,
            child: const Text('Refresh')
        ),
        Expanded(child: deviceListViewBuilder()),
      ],
    );

  }
}