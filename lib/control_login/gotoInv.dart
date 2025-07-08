import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:habibuios/control_login/invoice_search.dart';


class InvoicesHomePage extends StatefulWidget {
   final int user_id;
  const InvoicesHomePage({Key? key, required this.user_id}) : super(key: key);

  @override
  State<InvoicesHomePage> createState() => _InvoicesHomePageState();
}

class _InvoicesHomePageState extends State<InvoicesHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices App'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // رسالة الترحيب
              const Text(
                'Welcome to the Invoices Section',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // زر الانتقال
              ElevatedButton.icon(
                onPressed: () {
                  // يمكنك استبدال InvoicesSection() بالصفحة التي تريد التنقل إليها
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InvoicesSection(user_id:widget.user_id),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Go to Invoices'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}