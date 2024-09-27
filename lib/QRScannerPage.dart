import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRScannerPage extends StatefulWidget {
  final String teamName;
  final int points;
  final List<String> scannedQuestions;

  const QRScannerPage({
    super.key,
    required this.teamName,
    required this.points,
    required this.scannedQuestions,
  });

  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  // Initialize points and scannedQuestions from the widget
  late int points = widget.points;
  late List<String> scannedQuestions = widget.scannedQuestions;

  // Mapping QR code results to questions and correct answers
  final Map<String, Map<String, String>> questions = {
    "1": {"question": "Which function in Python is used to read input from the user?", "answer": "input"},
    "2": {"question": "Which keyword is used to stop a loop in Python?", "answer": "break"},
    "3": {"question": "What keyword is used to inherit a class in Java?", "answer": "extends"},
    "4": {"question": "Which loop is typically used for iterating over arrays in C?", "answer": "for"},
    "5": {"question": "What is the data structure that follows FIFO order?", "answer": "queue"},
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BYTECode QR Scanner'),
      ),
      body: Container(
        color: Colors.black,
        child: Column(
          children: <Widget>[
            SizedBox(height: 30),
            Image.asset(
              "images/bytecode.png",
              width: 120,
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: QRView(
                    key: qrKey,
                    onQRViewCreated: _onQRViewCreated,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  'Total Points: $points',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
      controller.pauseCamera();  // Pause camera after scan
      if (result != null && questions.containsKey(result!.code)) {
        _showAlertWithInput(result!.code!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No question found for this QR code!')),
        );
        controller.resumeCamera(); // Resume camera if no valid question is found
      }
    });
  }

  // After the user answers a question correctly, update Firebase
  Future<void> _updateParticipantData() async {
    try {
      await FirebaseFirestore.instance.collection('participants').doc(widget.teamName).update({
        'points': points,
        'attempted': scannedQuestions,
      });
    } catch (e) {
      print('Error updating participant data: $e');
    }
  }

  Future<void> _showAlertWithInput(String code) async {
    if (scannedQuestions.contains(code)) {
      return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("QR Code already scanned"), // Title text
            content: Text("Can't scan a QR twice"),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  controller?.resumeCamera(); // Resume the camera
                },
              ),
            ],
          );
        },
      );
    } else {
      TextEditingController answerController = TextEditingController();
      String question = questions[code]?["question"] ?? "No question available";
      String correctAnswer = questions[code]?["answer"] ?? "";

      return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title:
                Text('Question: $question'),
            content: TextField(
              controller: answerController,
              decoration: InputDecoration(hintText: 'Enter your answer'),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  controller?.resumeCamera(); // Resume the camera
                },
              ),
              TextButton(
                child: Text('Submit'),
                onPressed: () {
                  String enteredAnswer = answerController.text.trim();
                  if (enteredAnswer.toLowerCase() == correctAnswer.toLowerCase()) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Correct answer!')),
                    );
                    setState(() {
                      points += 1;
                      scannedQuestions.add(code);
                    });
                    _updateParticipantData(); // Update points and scanned questions in Firebase
                    controller?.resumeCamera();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Incorrect answer, try again!')),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}