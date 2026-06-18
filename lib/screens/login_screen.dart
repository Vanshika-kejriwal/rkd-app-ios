// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:business_app/screens/dashboard.dart';
import 'package:business_app/widgets/background.dart';
import 'package:business_app/widgets/input_field.dart';
import 'package:business_app/widgets/userregheader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// Removed go_router import
import 'package:http/http.dart' as http;
import "package:business_app/constants.dart";
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usrnamecontroller = TextEditingController();
  final _otpcontroller = TextEditingController();
  // final _pwdcontroller = TextEditingController();
  bool _isLoading = false;

  Future<void> _requestOTP() async {
    setState(() {
      _isLoading = true;
    });

    final phonenumber = _usrnamecontroller.text;
    try {
      final response = await http.post(Uri.parse('$baseuri/api/login/'),
          body: {'phone_num': phonenumber});
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text("OTP successfully sent on Whatsapp."),
            backgroundColor: Colors.green[400]));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Something went wrong. Please try again."),
            backgroundColor: Colors.red));
      }
    } catch (e) {
      debugPrint(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Something went wrong. Please try again."),
          backgroundColor: Colors.red));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _validateOTP() async {
    final usr;
    setState(() {
      _isLoading = true;
    });

    final phonenumber = _usrnamecontroller.text;
    final otp = _otpcontroller.text;

    try {
      final response = await http.post(Uri.parse('$baseuri/api/validate_otp/'),
          body: {'phone_num': phonenumber, 'otp': otp});
      if (response.statusCode == 200) {
        usr = json.decode(response.body);
        if (kDebugMode) {
          print(usr);
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text("OTP verified successfully"),
            backgroundColor: Colors.green[400]));
        var sharedpref = await SharedPreferences.getInstance();
        sharedpref.setBool("Login", true);
        sharedpref.setString("Mobile", phonenumber);
        if (usr.isEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserRegHeader(fromLogin: true),
            ),
          );
        } else {
          sharedpref.setString("UT", usr[0]['UT']);
          sharedpref.setString("NAME", usr[0]['NAME']);
          sharedpref.setString("UC", usr[0]['UC']);
          var userType = usr[0]['UT'];
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Dashboard(ut: userType),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Incorrect OTP. Please try again."),
            backgroundColor: Colors.red));
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Something went wrong. Please try again."),
          backgroundColor: Colors.red));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double swidth = MediaQuery.of(context).size.width;
    double sheight = MediaQuery.of(context).size.height;
    return Background(
      appbartitle: const Text(""),
      appbaractions: const [],
      childs: Center(
        child: SizedBox(
          width: swidth * 0.6,
          height: sheight * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_isLoading)
                const Center(
                    child: CircularProgressIndicator(color: Colors.brown)),
              Text(
                'LOGIN',
                style: TextStyle(
                    color: Colors.brown[900],
                    fontSize: 40,
                    fontWeight: FontWeight.w500),
              ),
              Form(
                  child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: InputField(
                        label: "Phone Number",
                        controller: _usrnamecontroller,
                        suff: TextButton(
                            onPressed: _requestOTP,
                            child: const Text("Verify")),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: InputField(
                        label: "OTP",
                        controller: _otpcontroller,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: ElevatedButton(
                        onPressed: _validateOTP,
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromRGBO(252, 101, 8, 1),
                            foregroundColor: Colors.white),
                        child: const Text("Login"),
                      ),
                    )
                  ],
                ),
              ))
            ],
          ),
        ),
      ),
    );
  }
}
