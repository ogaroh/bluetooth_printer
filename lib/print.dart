import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PrintPage extends StatefulWidget {
  const PrintPage({super.key, required this.data});

  final List<Map<String, dynamic>> data;

  @override
  State<PrintPage> createState() => _PrintPageState();
}

class _PrintPageState extends State<PrintPage> {
  BluetoothPrint bluetoothPrint = BluetoothPrint.instance;
  List<BluetoothDevice> devices = [];
  String devicesMsg = "";

  final f = NumberFormat("\$###,###.00", "en_US");

  // initialize printer setup
  Future<void> initPrinter() async {
    bluetoothPrint.startScan(timeout: const Duration(seconds: 3));

    if (!mounted) return;
    bluetoothPrint.scanResults.listen((value) {
      if (!mounted) return;
      setState(() {
        devices = value;
      });

      if (devices.isEmpty) {
        setState(() {
          devicesMsg = "No bluetooth devices found";
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => {initPrinter()});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Printer"),
      ),
      body: devices.isEmpty
          ? Center(child: Text(devicesMsg))
          : ListView.builder(
              itemCount: devices.length,
              itemBuilder: (c, i) {
                return ListTile(
                  leading: const Icon(Icons.print),
                  title: Text(
                    devices[i].name ?? 'Device name not available',
                  ),
                  subtitle: Text(
                    devices[i].address ?? 'Bluetooth MAC address not available',
                  ),
                  onTap: () {
                    startPrint(devices[i]);
                  },
                );
              },
            ),
    );
  }

  // start print
  Future<void> startPrint(BluetoothDevice device) async {
    if (device.address != null) {
      await bluetoothPrint.connect(device);

      Map<String, dynamic> config = {};
      config['width'] = 40;
      config['height'] = 70;
      config['gap'] = 2;
      List<LineText> list = [];

      list.add(
        LineText(
          type: LineText.TYPE_TEXT,
          content: "EBM Suite",
          weight: 2,
          height: 2,
          width: 2,
          align: LineText.ALIGN_CENTER,
          linefeed: 1,
        ),
      );

      for (var i = 0; i < widget.data.length; i++) {
        // add title
        list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: widget.data[i]['title'],
          weight: 0,
          align: LineText.ALIGN_LEFT,
          linefeed: 1,
        ));
        // add title
        list.add(LineText(
          type: LineText.TYPE_TEXT,
          content:
              "${f.format(widget.data[i]['price'])} x ${widget.data[i]['qty']}",
          align: LineText.ALIGN_LEFT,
          linefeed: 1,
        ));
      }

      await bluetoothPrint.printReceipt(config, list);
      await bluetoothPrint.disconnect();
    }
  }
}
