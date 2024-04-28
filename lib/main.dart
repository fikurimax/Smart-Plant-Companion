import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:spc/widgets/device_item.dart';

void main() {
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SPC Client',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Perangkat Anda'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Logger logger = Logger();
  final List<DeviceItem> connectedDevices = [];
  final List<String> pairedDevices = [];
  bool isScanning = false;

  @override
  void initState() {
    super.initState();

    determineBluetoothState().then((value) => !value ? setState(() {}) : initBle());
  }

  void _addDeviceToList(DeviceItem device) {
    if (!pairedDevices.contains(device.device.remoteId.str)) {
      setState(() {
        connectedDevices.add(device);
        pairedDevices.add(device.device.remoteId.str);
      });
    }
  }

  void initBle() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();

    FlutterBluePlus.connectedDevices.asMap().forEach((key, BluetoothDevice device) {
      _addDeviceToList(DeviceItem(device: device));
    });

    startScanning();
  }

  Future determineBluetoothState() async {
    if (await FlutterBluePlus.isSupported == false) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Perangkat anda tidak mendukung Bluetooth LE")));
        return false;
      } else {
        logger.w("Perangkat tidak mendukung Bluetooth LE");
      }
    }

    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }

    var subscribeState = FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      logger.d(state);
      if (state == BluetoothAdapterState.off) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bluetooth sedang mati")));
        } else {
          logger.e("Bluetooth sedang mati");
        }
      } else {
        logger.d("Bluetooth sedang berjalan");
        // start scanning
      }
    });

    subscribeState.cancel();
    return true;
  }

  Future startScanning() async {
    if (isScanning) {
      return;
    }

    var subscription = FlutterBluePlus.onScanResults.listen((result) {
      if (result.isNotEmpty) {
        ScanResult r = result.last;
        _addDeviceToList(DeviceItem(device: r.device));
      }
    });

    subscription.onDone(() {
      setState(() {
        isScanning = false;
      });
    });

    FlutterBluePlus.cancelWhenScanComplete(subscription);
    await FlutterBluePlus.startScan(
      withKeywords: List.of(["SPC_"]),
      timeout: const Duration(seconds: 10),
    );
  }

  // ===================================== WIDGETS =====================================

  ListView _buildListViewOfDevices() => ListView(padding: const EdgeInsets.all(8), children: <Widget>[...connectedDevices]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: RefreshIndicator(
        onRefresh: startScanning,
        child: _buildListViewOfDevices(),
      ),
    );
  }
}
