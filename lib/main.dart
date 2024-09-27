import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'QRScannerPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _teamNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // For form validation

  Future<void> _checkOrCreateParticipantDocument(String teamName) async {
    try {
      // Check if the document already exists
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance.collection('participants').doc(teamName).get();

      if (documentSnapshot.exists) {
        // If the team already exists, navigate to the QRScannerPage with the existing data
        Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;
        int points = data['points'];
        List<dynamic> attempted = data['attempted'];

        // Navigate to QRScannerPage, passing the existing points and scannedQuestions
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QRScannerPage(
              teamName: teamName,
              points: points,
              scannedQuestions: List<String>.from(attempted), // Convert dynamic list to a List<String>
            ),
          ),
        );
      } else {
        // Create a new document if the team doesn't exist
        await FirebaseFirestore.instance.collection('participants').doc(teamName).set({
          'points': 0,
          'attempted': [],
        });

        // Navigate to QRScannerPage with initial points and scannedQuestions
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QRScannerPage(
              teamName: teamName,
              points: 0,
              scannedQuestions: [],
            ),
          ),
        );
      }
    } catch (e) {
      print('Error checking/creating document: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Sets the background color of the screen to black
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height, // Set container height to screen height
            alignment: Alignment.center, // Center the container content
            child: Form(
              key: _formKey, // Associate the form key
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Centers vertically
                crossAxisAlignment: CrossAxisAlignment.center, // Centers horizontally
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60.0),
                    child: Image.asset(
                      "images/depLogos.png",
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60.0),
                    child: Image.asset(
                      "images/bytecode.png",
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'in collaboration with',
                    style: TextStyle(color: Colors.white),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 120.0, vertical: 10),
                    child: Image.asset(
                      "images/dects.png",
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 50),
                    child: TextFormField(
                      controller: _teamNameController, // Controller for team name input
                      style: const TextStyle(
                        color: Colors.white, // Sets the text color to white
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter your Team Name',
                        hintStyle: const TextStyle(
                          color: Colors.white70, // Sets the hint text color to a slightly lighter white
                        ),
                        filled: true, // Fills the background color
                        fillColor: Colors.grey[850], // Dark grey background to contrast with black
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10), // Rounded corners
                          borderSide: const BorderSide(
                            color: Colors.grey, // Border color when not focused
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Colors.white, // Border color when focused
                            width: 2.0,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your team name'; // Validation message
                        }
                        return null;
                      },
                    ),
                  ),
                  // Button wrapped in a Container for consistent width
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50.0), // Add padding for consistent width
                    child: Container(
                      width: double.infinity, // Makes the button take the full width of the container
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // Rounded corners
                          ),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            String teamName = _teamNameController.text.trim();
                            await _checkOrCreateParticipantDocument(teamName); // Check or create the document
                          }
                        },
                        child: const Text(
                          'START',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}