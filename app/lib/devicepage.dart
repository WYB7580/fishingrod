import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DevicePage extends StatefulWidget{

  final BluetoothDevice device;

  const DevicePage({super.key, required this.device});

  @override
  State createState() => _State();

}

class _State extends State<DevicePage>{

  double SHAKEVALUE = 1.5;

  bool shaken = false;

  ValueNotifier<double> avg_value = ValueNotifier(-1);


  @override
  void initState() {
    super.initState();
    widget.device.connectionState.listen((BluetoothConnectionState state) async {
      if (state == BluetoothConnectionState.disconnected) {
        // Navigator.pop(context);
      }
    });
  }

  int bytesToInteger(List<int> bytes) {
    String charValues = '';
    for(int i in bytes){
      charValues = charValues + String.fromCharCode(i) ;
    }

    print(charValues);
    return 11;
    return int.parse(charValues);
  }

  List<double> bytesToDoubleList(List<int> bytes) {
    String charValues = '';
    for(int i in bytes){
      charValues = charValues + String.fromCharCode(i) ;
    }

    print(charValues);
    List<String> splitVals = charValues.split(',');
    print(charValues.split(','));
    double currentVal =  double.parse(splitVals[0]);
    double avgVal =  double.parse(splitVals[0]);

    return [currentVal, avgVal];
  }


  Future<bool> getValueChangeFromCharacteristics(BluetoothService service) async {
    // print('Future getValueChange');
    var characteristics = service.characteristics;


    for(BluetoothCharacteristic characteristic in characteristics) {
      // print('characteristic: $characteristic');
      await characteristic.setNotifyValue(true);
      StreamSubscription<dynamic> stream = characteristic.lastValueStream.listen((value) {

        print(value);

        List<double> data = bytesToDoubleList(value);
        print("Incoming Data: $data");
        avg_value.value = data.last;
        if(avg_value.value >= SHAKEVALUE){
          shaken = true;
          setState(() {});
        }

      });
    }
    // print('done getValueChange');
    return true;
  }


  Widget bodyView(){
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
          child: Card(
            child: Column(
              children: [
                Row(),
                Text(
                  "Shake Reading",
                  style: Theme.of(context).textTheme.titleLarge,
                ),

                ValueListenableBuilder<double>(
                    valueListenable: avg_value,
                    builder: (context, value, child){
                      double percent = (avg_value.value / 3.3) * 100;

                      return avg_value.value >= 0 ?
                      Text('${percent.toStringAsFixed(2)} % ',
                        style: Theme.of(context).textTheme.displayMedium,
                      ) :
                      Text('LOADING...');

                    }
                ),


                //
                // Text(
                //   co2_value.value > 0 ? Text('$co2_value') : Text('LOADING...'),
                //   style: Theme.of(context).textTheme.titleLarge,
                // )


              ],
            ),
          ),
        ),

        shaken ?
          Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
            child: Text( 'Fish Detected',
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ) :
          Container(),

        shaken ? ElevatedButton(
                onPressed: (){
                  setState(() {
                    shaken = false;
                  });
                },
                child: const Text('Dismissed')
              )
            :
            Container()
      ],
    );
  }


  FutureBuilder bluetoothBody(){
    String uart_uuid = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";

    return FutureBuilder<List<BluetoothService>>(
        future: widget.device.discoverServices(),
        builder: (BuildContext context, AsyncSnapshot<List<BluetoothService>> snapshot){
          if (snapshot.hasData){
            List<BluetoothService> services = snapshot.data!;
            bool found = false;
            services.forEach((service) {
              // do something with service
              if(found){ return; }
              if(uart_uuid == service.uuid.toString()){
                print(service.uuid);
                getValueChangeFromCharacteristics(service);
                found = true;
              }
            });
            return bodyView();

          }
          else if (snapshot.hasError){
            return const Center(child: Text('An Error Has Occurred'));
          }

          return Center(child: CircularProgressIndicator());

        }
    );
  }


  @override
  Widget build(context){
    return Scaffold(
      appBar: AppBar(
          title: const Text('Device')
      ),
      body: Column(
        children: [
          // ElevatedButton(
          //   onPressed: () async {
          //     // Note: You must call discoverServices after every re-connection!
          //     List<BluetoothService> services = await widget.device.discoverServices();
          //     services.forEach((service) {
          //       // do something with service
          //       print(service);
          //     });
          //   },
          //   child: const Text('wer')
          // ),

          bluetoothBody(),
        ],
      ),
    );
  }


}