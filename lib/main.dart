import 'package:flutter/material.dart';

void main() {
  runApp(const SanayiApp());
}

class SanayiApp extends StatelessWidget {
  const SanayiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sanayi App',
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('🚗 Sanayi App'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.car_repair,
                  size: 90,
                  color: Colors.red,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Sanayi App',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Aracınız için güvenilir servis ve fiyat karşılaştırma',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Giriş Yap'),
                  ),
                ),

                const SizedBox(height: 15),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Kayıt Ol'),
                  ),
                ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: () {},
                  child: const Text('Misafir olarak devam et'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}