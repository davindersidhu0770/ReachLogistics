import 'package:flutter/material.dart';

class ScanOptionScreen extends StatelessWidget {
  const ScanOptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2ECE9),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAD7CF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF4D2D),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  size: 60,
                  color: Color(0xFFFF4D2D),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Scan QR code",
                style: TextStyle(fontSize: 18),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigator.push(
                      // context,
                      // MaterialPageRoute(
                      //   builder: (_) => const QRScannerScreen(),
                      // ),
                    // );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4D2D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Start scanning",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                "or enter asset ID manually.",
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  color: Color(0xFFFF4D2D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}