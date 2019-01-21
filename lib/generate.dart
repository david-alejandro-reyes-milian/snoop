import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:query_params/query_params.dart';
import 'package:snoop/scan.dart';

class GenerateScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => GenerateScreenState();
}

class Post {
  final int userId;
  final int id;
  final String title;
  final String body;

  Post({this.userId, this.id, this.title, this.body});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      userId: json['userId'],
      id: json['id'],
      title: json['title'],
      body: json['body'],
    );
  }
}

class GenerateScreenState extends State<GenerateScreen> {
  static const double _topSectionHeight = 50.0;
  final dateFormat = DateFormat("EEEE, MMMM d, yyyy 'at' h:mma");
  DateTime date;
  double money;

  GlobalKey globalKey = new GlobalKey();
  String _dataString = "Hello from this QR";
  String _inputErrorText;
  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code Generator'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _captureAndSharePng,
          )
        ],
      ),
      body: _contentWidget(),
    );
  }

  Future<Post> fetchPost() async {
    final response =
        await http.get('https://jsonplaceholder.typicode.com/posts/1');

    if (response.statusCode == 200) {
      // If server returns ans OK response, parse the JSON
      return Post.fromJson(json.decode(response.body));
    } else {
      // If that response was not OK, throw an error.
      throw Exception('Failed to load post');
    }
  }

  Future<Post> confirmTicket() async {
    URLQueryParams params = new URLQueryParams();
    params.append('date', date.millisecondsSinceEpoch);
    params.append('sellerId', "sellerID");
    params.append('concertId', "concertID");

    var server =
        'https://3yp9bwydxe.execute-api.eu-central-1.amazonaws.com/default';
    final response = await http.get("$server/ticket?$params");

    if (response.statusCode == 200) {
      // If server returns ans OK response, parse the JSON
      return Post.fromJson(json.decode(response.body));
    } else {
      // If that response was not OK, throw an error.
      throw Exception('Failed to load post');
    }
  }

  Future<void> _captureAndSharePng() async {
    try {
      RenderRepaintBoundary boundary =
          globalKey.currentContext.findRenderObject();
      var image = await boundary.toImage();
      ByteData byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await new File('${tempDir.path}/image.png').create();
      await file.writeAsBytes(pngBytes);

      final channel = const MethodChannel('channel:me.alfian.share/share');
      channel.invokeMethod('shareFile', 'image.png');
    } catch (e) {
      print(e.toString());
    }
  }

  createPdf() async {
    final pdf = new PDFDocument();
    final page = new PDFPage(pdf, pageFormat: PDFPageFormat.letter);
    final g = page.getGraphics();
    final font = new PDFFont(pdf);

    PDFImage image = await generateQrImage(pdf);

    var h = 20.0 * PDFPageFormat.mm;
    g.drawImage(image, h, h * 3, 500.0);

    g.setColor(new PDFColor(0.0, 1.0, 1.0));
    g.drawRect(h, h * 2, 500.0, 48.0);
    g.fillPath();

    g.setColor(new PDFColor(0.3, 0.3, 0.3));
    g.drawString(font, 48.0, "Casabe concert ticket!", h, h);

    var tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;

    var file = new File(tempPath + '/file.pdf');
    file.writeAsBytesSync(pdf.save());
    OpenFile.open(file.path);
  }

  Future<PDFImage> generateQrImage(PDFDocument pdf) async {
    RenderRepaintBoundary boundary =
        globalKey.currentContext.findRenderObject();
    var img = await boundary.toImage();
    ByteData byteData = await img.toByteData(format: ImageByteFormat.rawRgba);
    Uint8List pngBytes = byteData.buffer.asUint8List();
    PDFImage image = new PDFImage(pdf,
        image: pngBytes, width: img.width, height: img.height);
    return image;
  }

  _contentWidget() {
    final bodyHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).viewInsets.bottom;
    return Container(
      color: const Color(0xFFFFFFFF),
      child: Column(
        children: <Widget>[
          Padding(
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 10.0,
              ),
              child: Text(
                "\$$money",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 90),
              )),
          Padding(
            padding: const EdgeInsets.only(
              left: 20.0,
              right: 10.0,
            ),
            child: Container(
              height: _topSectionHeight,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onChanged: (text) => setState(() {
                            _dataString = _textController.text +
                                " " +
                                date.toIso8601String();
                            _inputErrorText = null;
                            money ??= 12.5;
                            money = money + 0.5;
                          }),
                      decoration: InputDecoration(
                        hintText: "Enter a custom message",
                        errorText: _inputErrorText,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: FlatButton(
                      child: Text("SCAN"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ScanScreen()),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: FlatButton(
                      child: Text("PDF"),
                      onPressed: () {
                        confirmTicket();
                        createPdf();
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
          Padding(
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
              ),
              child: DateTimePickerFormField(
                format: dateFormat,
                decoration: InputDecoration(labelText: 'Date'),
                onChanged: (dt) => setState(() {
                      date = dt;
                      _dataString =
                          _textController.text + " " + date.toIso8601String();
                      _inputErrorText = null;
                    }),
              )),
          Expanded(
            child: Center(
              child: RepaintBoundary(
                key: globalKey,
                child: QrImage(
                  data: _dataString,
                  size: 0.5 * bodyHeight,
                  onError: (ex) {
                    print("[QR] ERROR - $ex");
                    setState(() {
                      _inputErrorText =
                          "Error! Maybe your input value is too long?";
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
