import 'dart:convert';
import 'dart:io';

import 'package:blue_print_pos/blue_print_pos.dart';
import 'package:blue_print_pos/models/blue_device.dart';
import 'package:blue_print_pos/models/connection_status.dart';
import 'package:blue_print_pos/receipt/receipt_section_text.dart';
import 'package:blue_print_pos/receipt/receipt_text_size_type.dart';
import 'package:blue_print_pos/receipt/receipt_text_style_type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Print Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Bluetooth Print Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final BluePrintPos _bluePrintPos = BluePrintPos.instance;
  List<BlueDevice> _blueDevices = <BlueDevice>[];
  BlueDevice? _selectedDevice;
  bool _isLoading = false;
  int _loadingAtIndex = -1;

  Future<void> _onScanPressed() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
      if (statuses[Permission.bluetoothScan] != PermissionStatus.granted ||
          statuses[Permission.bluetoothConnect] != PermissionStatus.granted) {
        return;
      }
    }

    setState(() => _isLoading = true);
    _bluePrintPos.scan().then((List<BlueDevice> devices) {
      if (devices.isNotEmpty) {
        setState(() {
          _blueDevices = devices;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    });
  }

  void _onDisconnectDevice() {
    _bluePrintPos.disconnect().then((ConnectionStatus status) {
      if (status == ConnectionStatus.disconnect) {
        setState(() {
          _selectedDevice = null;
        });
      }
    });
  }

  void _onSelectDevice(int index) {
    setState(() {
      _isLoading = true;
      _loadingAtIndex = index;
    });
    final BlueDevice blueDevice = _blueDevices[index];
    _bluePrintPos.connect(blueDevice).then((ConnectionStatus status) {
      if (status == ConnectionStatus.connected) {
        setState(() => _selectedDevice = blueDevice);
      } else if (status == ConnectionStatus.timeout) {
        _onDisconnectDevice();
      } else {
        if (kDebugMode) {
          print('$runtimeType - something wrong');
        }
      }
      setState(() => _isLoading = false);
    });
  }

  Future<void> _onPrintReceipt() async {
    /// Example for Print Image
    final ByteData logoBytes = await rootBundle.load(
      'assets/images/img2.png',
    );

    /// Example for Print Text
    final ReceiptSectionText receiptText = ReceiptSectionText();
    receiptText.addImage(
      base64.encode(Uint8List.view(logoBytes.buffer)),
      width: 300,
    );
    receiptText.addSpacer();
    receiptText.addText(
      'EXCEED YOUR VISION',
      size: ReceiptTextSizeType.medium,
      style: ReceiptTextStyleType.bold,
    );
    receiptText.addText(
      'MC Koo',
      size: ReceiptTextSizeType.small,
    );
    receiptText.addSpacer(useDashed: true);
    receiptText.addLeftRightText('Time', '04/06/22, 10:30');
    receiptText.addSpacer(useDashed: true);
    receiptText.addLeftRightText(
      'Apple 4pcs',
      '\$ 10.00',
      leftStyle: ReceiptTextStyleType.normal,
      rightStyle: ReceiptTextStyleType.bold,
    );
    receiptText.addSpacer(useDashed: true);
    receiptText.addLeftRightText(
      'TOTAL',
      '\$ 10.00',
      leftStyle: ReceiptTextStyleType.normal,
      rightStyle: ReceiptTextStyleType.bold,
    );
    receiptText.addSpacer(useDashed: true);
    receiptText.addLeftRightText(
      'Payment',
      'Cash',
      leftStyle: ReceiptTextStyleType.normal,
      rightStyle: ReceiptTextStyleType.normal,
    );
    receiptText.addSpacer(count: 2);

    await _bluePrintPos.printReceiptText(receiptText);

    /// Example for print QR
    await _bluePrintPos.printQR('https://www.google.com/', size: 250);

    /// Text after QR
    final ReceiptSectionText receiptSecondText = ReceiptSectionText();
    receiptSecondText.addText('Powered by Google',
        size: ReceiptTextSizeType.small);
    receiptSecondText.addSpacer();
    await _bluePrintPos.printReceiptText(receiptSecondText, feedCount: 1);
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: _isLoading && _blueDevices.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              )
            : _blueDevices.isNotEmpty
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Column(
                          children: List<Widget>.generate(_blueDevices.length,
                              (int index) {
                            return Row(
                              children: <Widget>[
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _blueDevices[index].address ==
                                            (_selectedDevice?.address ?? '')
                                        ? _onDisconnectDevice
                                        : () => _onSelectDevice(index),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            _blueDevices[index].name,
                                            style: TextStyle(
                                              color: _selectedDevice?.address ==
                                                      _blueDevices[index]
                                                          .address
                                                  ? Colors.blue
                                                  : Colors.black,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            _blueDevices[index].address,
                                            style: TextStyle(
                                              color: _selectedDevice?.address ==
                                                      _blueDevices[index]
                                                          .address
                                                  ? Colors.blueGrey
                                                  : Colors.grey,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (_loadingAtIndex == index && _isLoading)
                                  Container(
                                    height: 24.0,
                                    width: 24.0,
                                    margin: const EdgeInsets.only(right: 8.0),
                                    child: const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue,
                                      ),
                                    ),
                                  ),
                                if (!_isLoading &&
                                    _blueDevices[index].address ==
                                        (_selectedDevice?.address ?? ''))
                                  TextButton(
                                    onPressed: _onPrintReceipt,
                                    style: ButtonStyle(
                                      backgroundColor: MaterialStateProperty
                                          .resolveWith<Color>(
                                        (Set<MaterialState> states) {
                                          if (states.contains(
                                              MaterialState.pressed)) {
                                            return Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.5);
                                          }
                                          return Theme.of(context).primaryColor;
                                        },
                                      ),
                                    ),
                                    child: Container(
                                      color: _selectedDevice == null
                                          ? Colors.grey
                                          : Colors.blue,
                                      padding: const EdgeInsets.all(8.0),
                                      child: const Text(
                                        'Test Print',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const <Widget>[
                        Text(
                          'Scan bluetooth device',
                          style: TextStyle(fontSize: 24, color: Colors.blue),
                        ),
                        Text(
                          'Press button scan',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _onScanPressed,
        backgroundColor: _isLoading ? Colors.grey : Colors.blue,
        child: const Icon(Icons.search),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}


// import 'package:bluetooth_printer/home.dart';
// import 'package:flutter/material.dart';

// void main() => runApp(const MyApp());

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});

//   @override
//   MyAppState createState() => MyAppState();
// }

// class MyAppState extends State<MyApp> {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(primarySwatch: Colors.purple),
//       home: CustomHome(),
//     );
//   }
// }

// class MyApp extends StatefulWidget {
//   @override
//   MyAppState createState() => MyAppState();
// }

// class MyAppState extends State<MyApp> {
//   BluetoothPrint bluetoothPrint = BluetoothPrint.instance;

//   bool _connected = false;
//   BluetoothDevice? _device;
//   String tips = 'no device connect';

//   @override
//   void initState() {
//     super.initState();

//     WidgetsBinding.instance.addPostFrameCallback((_) => initBluetooth());
//   }

//   // Platform messages are asynchronous, so we initialize in an async method.
//   Future<void> initBluetooth() async {
//     bluetoothPrint.startScan(timeout: Duration(seconds: 4));

//     bool isConnected = await bluetoothPrint.isConnected ?? false;

//     bluetoothPrint.state.listen((state) {
//       print('******************* cur device status: $state');

//       switch (state) {
//         case BluetoothPrint.CONNECTED:
//           setState(() {
//             _connected = true;
//             tips = 'connect success';
//           });
//           break;
//         case BluetoothPrint.DISCONNECTED:
//           setState(() {
//             _connected = false;
//             tips = 'disconnect success';
//           });
//           break;
//         default:
//           break;
//       }
//     });

//     if (!mounted) return;

//     if (isConnected) {
//       setState(() {
//         _connected = true;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: const Text('BluetoothPrint example app'),
//         ),
//         body: RefreshIndicator(
//           onRefresh: () =>
//               bluetoothPrint.startScan(timeout: Duration(seconds: 4)),
//           child: SingleChildScrollView(
//             child: Column(
//               children: <Widget>[
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: <Widget>[
//                     Padding(
//                       padding:
//                           EdgeInsets.symmetric(vertical: 10, horizontal: 10),
//                       child: Text(tips),
//                     ),
//                   ],
//                 ),
//                 Divider(),
//                 StreamBuilder<List<BluetoothDevice>>(
//                   stream: bluetoothPrint.scanResults,
//                   initialData: [],
//                   builder: (c, snapshot) => Column(
//                     children: snapshot.data!
//                         .map((d) => ListTile(
//                               title: Text(d.name ?? ''),
//                               subtitle: Text(d.address ?? ''),
//                               onTap: () async {
//                                 setState(() {
//                                   _device = d;
//                                 });
//                               },
//                               trailing: _device != null &&
//                                       _device!.address == d.address
//                                   ? Icon(
//                                       Icons.check,
//                                       color: Colors.green,
//                                     )
//                                   : null,
//                             ))
//                         .toList(),
//                   ),
//                 ),
//                 Divider(),
//                 Container(
//                   padding: EdgeInsets.fromLTRB(20, 5, 20, 10),
//                   child: Column(
//                     children: <Widget>[
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: <Widget>[
//                           OutlinedButton(
//                             child: Text('connect'),
//                             onPressed: _connected
//                                 ? null
//                                 : () async {
//                                     if (_device != null &&
//                                         _device!.address != null) {
//                                       setState(() {
//                                         tips = 'connecting...';
//                                       });
//                                       await bluetoothPrint.connect(_device!);
//                                     } else {
//                                       setState(() {
//                                         tips = 'please select device';
//                                       });
//                                       print('please select device');
//                                     }
//                                   },
//                           ),
//                           SizedBox(width: 10.0),
//                           OutlinedButton(
//                             child: Text('disconnect'),
//                             onPressed: _connected
//                                 ? () async {
//                                     setState(() {
//                                       tips = 'disconnecting...';
//                                     });
//                                     await bluetoothPrint.disconnect();
//                                   }
//                                 : null,
//                           ),
//                         ],
//                       ),
//                       Divider(),
//                       OutlinedButton(
//                         child: Text('print receipt(esc)'),
//                         onPressed: _connected
//                             ? () async {
//                                 Map<String, dynamic> config = Map();

//                                 List<LineText> list = [];

//                                 list.add(LineText(
//                                     type: LineText.TYPE_TEXT,
//                                     content:
//                                         '**********************************************',
//                                     weight: 1,
//                                     align: LineText.ALIGN_CENTER,
//                                     linefeed: 1));
//                                 list.add(LineText(
//                                     type: LineText.TYPE_TEXT,
//                                     content: '打印单据头',
//                                     weight: 1,
//                                     align: LineText.ALIGN_CENTER,
//                                     fontZoom: 2,
//                                     linefeed: 1));
//                                 list.add(LineText(linefeed: 1));

//                                 list.add(LineText(
//                                     type: LineText.TYPE_TEXT,
//                                     content:
//                                         '----------------------明细---------------------',
//                                     weight: 1,
//                                     align: LineText.ALIGN_CENTER,
//                                     linefeed: 1));
//                                 list.add(LineText(
//                                     type: LineText.TYPE_TEXT,
//                                     content: '物资名称规格型号',
//                                     weight: 1,
//                                     align: LineText.ALIGN_LEFT,
//                                     x: 0,
//                                     relativeX: 0,
//                                     linefeed: 0));
//                                 list.add(LineText(
//                                     type: LineText.TYPE_TEXT,
//                                     content: '单位',
//                                     weight: 1,
//                                     align: LineText.ALIGN_LEFT,
//                                     x: 350,
//                                     relativeX: 0,
//                                     linefeed: 0));
//                                 list.add(LineText(
//                                     type: LineText.TYPE_TEXT,
//                                     content: '数量',
//                                     weight: 1,
//                                     align: LineText.ALIGN_LEFT,
//                                     x: 500,
//                                     relativeX: 0,
//                                     linefeed: 1));

//                                 list.add(LineText(
//                                     type: LineText.TYPE_TEXT,
//                                     content: '混凝土C30',
//                                     align: LineText.ALIGN_LEFT,
//                                     x: 0,
//                                     relativeX: 0,
//                                     linefeed: 0));
//                                 list.add(LineText(
//                                     type: LineText.TYPE_TEXT,
//                                     content: '吨',
//                                     align: LineText.ALIGN_LEFT,
//                                     x: 350,
//                                     relativeX: 0,
//                                     linefeed: 0));
//                                 list.add(LineText(
//                                     type: LineText.TYPE_TEXT,
//                                     content: '12.0',
//                                     align: LineText.ALIGN_LEFT,
//                                     x: 500,
//                                     relativeX: 0,
//                                     linefeed: 1));

//                                 list.add(LineText(
//                                     type: LineText.TYPE_TEXT,
//                                     content:
//                                         '**********************************************',
//                                     weight: 1,
//                                     align: LineText.ALIGN_CENTER,
//                                     linefeed: 1));
//                                 list.add(LineText(linefeed: 1));

//                                 ByteData data = await rootBundle
//                                     .load("assets/images/img1.png");
//                                 List<int> imageBytes = data.buffer.asUint8List(
//                                     data.offsetInBytes, data.lengthInBytes);
//                                 String base64Image = base64Encode(imageBytes);
//                                 list.add(LineText(
//                                     type: LineText.TYPE_IMAGE,
//                                     content: base64Image,
//                                     align: LineText.ALIGN_CENTER,
//                                     linefeed: 1));
//                                 await bluetoothPrint.printReceipt(config, list);
//                               }
//                             : null,
//                       ),
//                       OutlinedButton(
//                         onPressed: _connected
//                             ? () async {
//                                 Map<String, dynamic> config = Map();
//                                 config['width'] = 40; // 标签宽度，单位mm
//                                 config['height'] = 70; // 标签高度，单位mm
//                                 config['gap'] = 2; // 标签间隔，单位mm

//                                 // x、y坐标位置，单位dpi，1mm=8dpi
//                                 List<LineText> list = [];
//                                 list.add(LineText(
//                                     type: LineText.TYPE_TEXT,
//                                     x: 10,
//                                     y: 10,
//                                     content: 'A Title'));
//                                 list.add(LineText(
//                                     type: LineText.TYPE_TEXT,
//                                     x: 10,
//                                     y: 40,
//                                     content: 'this is content'));
//                                 list.add(LineText(
//                                     type: LineText.TYPE_QRCODE,
//                                     x: 10,
//                                     y: 70,
//                                     content: 'qrcode i\n'));
//                                 list.add(LineText(
//                                     type: LineText.TYPE_BARCODE,
//                                     x: 10,
//                                     y: 190,
//                                     content: 'qrcode i\n'));

//                                 List<LineText> list1 = [];
//                                 ByteData data = await rootBundle
//                                     .load("assets/images/img1.png");
//                                 List<int> imageBytes = data.buffer.asUint8List(
//                                     data.offsetInBytes, data.lengthInBytes);
//                                 String base64Image = base64Encode(imageBytes);
//                                 list1.add(LineText(
//                                   type: LineText.TYPE_IMAGE,
//                                   x: 10,
//                                   y: 10,
//                                   content: base64Image,
//                                 ));

//                                 await bluetoothPrint.printLabel(config, list);
//                                 await bluetoothPrint.printLabel(config, list1);
//                               }
//                             : null,
//                         child: Text('print label(tsc)'),
//                       ),
//                       OutlinedButton(
//                         child: Text('print selftest'),
//                         onPressed: _connected
//                             ? () async {
//                                 await bluetoothPrint.printTest();
//                               }
//                             : null,
//                       )
//                     ],
//                   ),
//                 )
//               ],
//             ),
//           ),
//         ),
//         floatingActionButton: StreamBuilder<bool>(
//           stream: bluetoothPrint.isScanning,
//           initialData: false,
//           builder: (c, snapshot) {
//             if (snapshot.data == true) {
//               return FloatingActionButton(
//                 child: Icon(Icons.stop),
//                 onPressed: () => bluetoothPrint.stopScan(),
//                 backgroundColor: Colors.red,
//               );
//             } else {
//               return FloatingActionButton(
//                   child: Icon(Icons.search),
//                   onPressed: () =>
//                       bluetoothPrint.startScan(timeout: Duration(seconds: 4)));
//             }
//           },
//         ),
//       ),
//     );
//   }
// }
