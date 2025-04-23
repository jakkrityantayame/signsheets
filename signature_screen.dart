import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignatureScreen extends StatefulWidget {
  @override
  _SignatureScreenState createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("วาดลายเซ็น"),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () async {
              if (_controller.isNotEmpty) {
                final signature = await _controller.toPngBytes();
                if (signature != null) {
                  final base64Signature = base64Encode(signature);
                  Navigator.pop(context, base64Signature);
                }
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _controller.clear();
              });
            },
          ),
        ],
      ),
      body: Signature(
        controller: _controller,
        height: 300,
        backgroundColor: Colors.white,
      ),
    );
  }
}