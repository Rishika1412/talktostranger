import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Terms extends StatefulWidget {
  const Terms({Key? key}) : super(key: key);

  @override
  State<Terms> createState() => _TermsState();
}

class _TermsState extends State<Terms> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 0.0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context); // This will navigate back to the previous screen
          },
        ),
        title: Text("Terms and Conditions"),
      ),
      body: FutureBuilder(
        future: _getTermsAndConditions(),
        builder: (context, AsyncSnapshot<String> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(snapshot.data ?? 'No terms found.'),
            );
          }
        },
      ),
    );
  }

  Future<String> _getTermsAndConditions() async {
    try {
      // Replace 'your_collection' with the actual collection name in your Firestore
      var document = await _firestore.collection('appinfo').doc('terms').get();

      if (document.exists) {
        return document['terms_text'];
      } else {
        return 'No terms found.';
      }
    } catch (e) {
      return 'Error fetching terms: $e';
    }
  }
}


