import 'dart:async';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:query_params/query_params.dart';
import 'dart:convert';

class ScanScreen extends StatefulWidget {
  @override
  _ScanState createState() => new _ScanState();
}

class _ScanState extends State<ScanScreen> {
  String barcode = "";

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: new AppBar(
          title: new Text('QR Code Scanner'),
        ),
        body: new Center(
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: RaisedButton(
                    color: Colors.blue,
                    textColor: Colors.white,
                    splashColor: Colors.blueGrey,
                    onPressed: scan,
                    child: const Text('START CAMERA SCAN')),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  barcode,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ));
  }

  Future scan() async {
    try {
      String barcode = await BarcodeScanner.scan();
      setState(() => this.barcode = barcode);
      analyze(barcode);
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        setState(() {
          this.barcode = 'The user did not grant the camera permission!';
        });
      } else {
        setState(() => this.barcode = 'Unknown error: $e');
      }
    } on FormatException {
      setState(() => this.barcode =
          'null (User returned using the "back"-button before scanning anything. Result)');
    } catch (e) {
      setState(() => this.barcode = 'Unknown error: $e');
    }
  }

  void analyze(String barcode) {
    var barcodeJson = json.decode(barcode);
    var ticket = Ticket.fromJson(barcodeJson);
    confirmTicket(ticket);
  }

  Future<Ticket> confirmTicket(Ticket ticket) async {
    URLQueryParams params = new URLQueryParams();
    params.append('date', ticket.date);
    params.append('sellerId', ticket.sellerId);
    params.append('concertId', ticket.concertId);

    var server =
        'https://3yp9bwydxe.execute-api.eu-central-1.amazonaws.com/default';
    final response = await http.get("$server/ticket?$params");

    if (response.statusCode == 200) {
      // If server returns ans OK response, parse the JSON
      return Ticket.fromJson(json.decode(response.body));
    } else {
      // If that response was not OK, throw an error.
      throw Exception('Failed to load post');
    }
  }
}

class Ticket {
  final int date;
  final String sellerId;
  final String concertId;

  Ticket({this.date, this.sellerId, this.concertId});

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
        date: json['date'],
        sellerId: json['sellerId'],
        concertId: json['concertId']);
  }
}
