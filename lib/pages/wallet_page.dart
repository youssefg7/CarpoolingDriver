import 'package:flutter/material.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  var walletBalance = 0.0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet Page'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Card(
            color: Colors.green[100],
            shadowColor: Colors.green,
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Icon(Icons.account_balance_wallet),
                Text(
                  'Wallet Balance',
                  style: TextStyle(
                      fontSize: 20,
                      // fontWeight: FontWeight.bold,
                      color: Colors.green[900],

                  ),),
                Expanded(
                  // margin: const EdgeInsets.all(10),
                  child: Text('EGP ${walletBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],

                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      )
    );
  }
}
