import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceItem extends StatefulWidget {
  const DeviceItem({super.key, required this.device});

  final BluetoothDevice device;

  @override
  State<DeviceItem> createState() => _DeviceItemState();
}

class _DeviceItemState extends State<DeviceItem> {
  final StreamController<String> moistureNotification = StreamController();
  final StreamController<String> lightNotification = StreamController();
  bool isConnected = false;
  bool isConnecting = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      isConnected = widget.device.isConnected;
    });
  }

  @override
  void dispose() {
    moistureNotification.close();
    lightNotification.close();
    super.dispose();
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect(
      timeout: const Duration(seconds: 10),
    );

    setState(() {
      isConnected = true;
      isConnecting = false;
    });

    subscribeToNotifications(
        device, Guid.fromString("beb5483e-36e1-4688-b7f5-ea07361b26a8"), Guid.fromString("4af306e2-2e5e-40b3-b448-f9937ba4557a"));
  }

  void subscribeToNotifications(BluetoothDevice device, Guid moistureCharacteristicId, Guid lightCharacteristicId) async {
    List<BluetoothService> services = await device.discoverServices();

    for (BluetoothService service in services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.uuid == moistureCharacteristicId) {
          await characteristic.setNotifyValue(true);
          characteristic.lastValueStream.listen((value) {
            moistureNotification.add(String.fromCharCodes(value));
          });
        } else if (characteristic.uuid == lightCharacteristicId) {
          await characteristic.setNotifyValue(true);
          characteristic.lastValueStream.listen((value) {
            lightNotification.add(String.fromCharCodes(value));
          });
        }
      }
    }
  }

  // =========================================================================
  Widget _buildItemView() {
    if (!isConnected) {
      return const Center(child: Text("Silakan ketuk untuk menghubungkan", style: TextStyle(color: Colors.white, fontSize: 14)));
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Row(
                children: [
                  Icon(Icons.sunny, color: Colors.white),
                  SizedBox(width: 2),
                  Text("Pencahayaan", style: TextStyle(color: Colors.white, fontSize: 12))
                ],
              ),
              StreamBuilder(
                stream: lightNotification.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    var indicator = "Mengambil Data";
                    double data = 0;
                    if (snapshot.data != "" && snapshot.data != null) {
                      data = double.parse(snapshot.data as String);
                      indicator = (data < 500) ? "Baik" : "Kurang baik";
                    }

                    return Column(
                      children: [
                        Text(indicator, style: const TextStyle(color: Colors.white, fontSize: 24)),
                        Text(snapshot.data as String, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                      ],
                    );
                  }

                  return const Text("-", style: TextStyle(color: Colors.white, fontSize: 24));
                },
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Row(
                children: [
                  ImageIcon(AssetImage("assets/icons/moisture.png"), color: Colors.white),
                  SizedBox(width: 2),
                  Text("Kelembaban", style: TextStyle(color: Colors.white, fontSize: 12))
                ],
              ),
              StreamBuilder(
                stream: moistureNotification.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    var indicator = "Mengambil Data";
                    double data = 0;
                    if (snapshot.data != "" && snapshot.data != null) {
                      data = double.parse(snapshot.data as String);
                      indicator = (data < 500) ? "Baik" : "Kurang baik";
                    }

                    return Column(
                      children: [
                        Text(indicator, style: const TextStyle(color: Colors.white, fontSize: 24)),
                        Text(snapshot.data as String, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                      ],
                    );
                  }

                  return const Text("-", style: TextStyle(color: Colors.white, fontSize: 24));
                },
              ),
            ],
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) {
        if (!isConnected) {
          setState(() {
            isConnecting = true;
          });

          connectToDevice(widget.device);
        }
      },
      onLongPress: () {
        if (widget.device.isDisconnected) {
          return;
        }

        showBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return Container(
              padding: const EdgeInsets.all(8),
              height: 200,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(8.0), topRight: Radius.circular(8.0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Detail perangkat", style: TextStyle(fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("ID: ${widget.device.remoteId.str}", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text("Nama: ${widget.device.advName}", style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  Text("Terhubung : ${widget.device.isConnected}", style: const TextStyle(fontSize: 14)),
                ],
              ),
            );
          },
        );
      },
      child: Card(
          margin: const EdgeInsets.only(
            left: 10,
            right: 10,
            top: 8.0,
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: Stack(
            fit: StackFit.loose,
            children: [
              Image.network(
                "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ0tuMb-bZmOshTO2DUBUezGvIIdpmjmKGGoOGd9Bdgb2lAOOo1",
              ),
              Positioned(
                top: 5,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.only(left: 8, right: 8, top: 2, bottom: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        color: (isConnecting)
                            ? Colors.orange
                            : (isConnected)
                                ? Colors.green
                                : Colors.red,
                        size: 10,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        (isConnecting)
                            ? "Menghubungkan"
                            : (isConnected)
                                ? "Terhubung"
                                : "Tidak terhubung",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                    color: Colors.black.withOpacity(0.7),
                    width: double.infinity,
                    height: isConnected ? 100 : 50,
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: _buildItemView()),
              )
            ],
          )),
    );
  }
}
