import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Configs/Dbpaths.dart';
import '../homepage/homepage.dart';

class RechargeScreen extends StatefulWidget {
  final String contactno;
  final DocumentSnapshot<Map<String, dynamic>> doc;
  final SharedPreferences prefs;
  const RechargeScreen(
      {super.key,
      required this.contactno,
      required this.doc,
      required this.prefs});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  late Razorpay _razorpay;
  String key = '';
  int amount = 0;
  String number = '';

  @override
  void initState() {
    super.initState();
    _fetchAmount();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Handle payment success
    await FirebaseFirestore.instance
        .collection(DbPaths.collectionusers)
        .doc(widget.contactno)
        .update({
      'rechargeDate': DateTime.now().add(Duration(days: 30)),
    });
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (context) => Homepage(
              currentUserNo: widget.contactno,
              prefs: widget.prefs,
              doc: widget.doc)),
      (route) => false,
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    // Handle payment failure
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet
  }

  void _openCheckout(String key, int amount) {
    var options = {
      'key': key,
      'amount': amount * 100, // amount in paise (e.g., 2000 paise = Rs 20)
      'name': 'Load App',
      'description': 'Recharge',
      'prefill': {'contact': widget.contactno, 'email': 'loadapp@gmail.com'},
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: ${e.toString()}');
    }
  }

  _fetchAmount() async {
    await FirebaseFirestore.instance
        .collection('razorpay')
        .doc('data')
        .get()
        .then((value) {
      setState(() {
        key = value.data()!['key'];
        amount = value.data()!['amount'];
        number = value.data()!['number'];
      });
    });
  }

  _fetchRazorpayDataFromDB() async {
    showLoaderDialog(context);
    await FirebaseFirestore.instance
        .collection('razorpay')
        .doc('data')
        .get()
        .then((value) {
      Navigator.pop(context);
      _openCheckout(value.data()!['key'], value.data()!['amount']);
    });
  }

  showLoaderDialog(BuildContext context) {
    AlertDialog alert = AlertDialog(
      content: Row(
        children: const [
          const CircularProgressIndicator(),
          const SizedBox(
            width: 20,
          ),
          const Text("Loading..."),
        ],
      ),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Text(
                'Recharge Screen',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * .2,
            ),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/applogo.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.fill,
                ),
              ),
            ),
            SizedBox(
              height: 40,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  Text(
                    "Amount : ₹$amount",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  InkWell(
                    onTap: () async {
                      String url = 'https://wa.me/$number';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      } else {
                        throw 'Could not launch WhatsApp.';
                      }
                    },
                    child: Image.asset(
                      'assets/images/whatsapp.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.fill,
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),
            InkWell(
              onTap: () {
                if (key == '') {
                  _fetchRazorpayDataFromDB();
                } else {
                  _openCheckout(key, amount);
                }
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Color(0xFF7b00cc),
                ),
                child: Center(
                  child: Text(
                    'Recharge',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 40,
            ),
          ],
        ),
      )),
    );
  }
}
