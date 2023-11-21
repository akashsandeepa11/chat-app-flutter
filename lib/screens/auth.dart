// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_chat_app/widgets/user_image_picker.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  var _isLogin = true;
  var _enteredEmail = "";
  var _enteredPassword = "";
  var _enteredUsername = "";
  var _isAuthenticating = false;
  File? pickedImage;

  // void _submit() {
  //   final isValid = _formKey.currentState!.validate();

  //   if (!isValid) {
  //     return;
  //   }
  //   _formKey.currentState!.save();

  //   try {
  //     if (_isLogin) {
  //       final userCredential = _firebase.signInWithEmailAndPassword(
  //           email: _enteredEmail, password: _enteredPassword);

  //       print("userCredential :  $userCredential");
  //     } else {
  //       final userCredential = _firebase.createUserWithEmailAndPassword(
  //           email: _enteredEmail, password: _enteredPassword);

  //       print("userCredential :  $userCredential");
  //     }
  //   } on FirebaseAuthException catch (error) {
  //     if (error.code == "email-already-in-use") {
  //       ScaffoldMessenger.of(context).clearSnackBars();
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(error.message ?? "Authentication faild."),
  //         ),
  //       );
  //     }

  //     print("Error message : ${error.message}");
  //   }
  // }

  void _submit() async {
    final isValid = _formKey.currentState!.validate();

    if (!isValid || !_isLogin && pickedImage == null) {
      return;
    }
    _formKey.currentState!.save();

    try {
      setState(() {
        _isAuthenticating = true;
      });
      if (_isLogin) {
        await _firebase.signInWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);
      } else {
        final userCredential = await _firebase.createUserWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);

        final storageRef = FirebaseStorage.instance
            .ref()
            .child("user_images")
            .child("${userCredential.user!.uid}.jpg");

        await storageRef.putFile(pickedImage!);

        final imageUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection("users")
            .doc(userCredential.user!.uid)
            .set({
          'username': _enteredUsername,
          'email': _enteredEmail,
          'image_url': imageUrl,
        });
      }
    } on FirebaseAuthException catch (error) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? "Authentication failed."),
        ),
      );

      setState(() {
        _isAuthenticating = false;
      });
    } catch (error) {
      // Catch any other type of error
      // print("Unexpected error:..................................... $error");

      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
          child: SingleChildScrollView(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            margin: const EdgeInsets.only(
              top: 30,
              bottom: 20,
              left: 20,
              right: 0,
            ),
            width: 200,
            child: Image.asset("assets/images/chat.png"),
          ),
          Card(
            margin: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_isLogin)
                          UserImagePicker(onPickImage: (image) {
                            pickedImage = image;
                          }),
                        TextFormField(
                          decoration:
                              const InputDecoration(labelText: "Email Address"),
                          autocorrect: false,
                          keyboardType: TextInputType.emailAddress,
                          textCapitalization: TextCapitalization.none,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty ||
                                !value.contains("@gmail")) {
                              return "Please enter a valid Email address.";
                            }
                            return null;
                          },
                          onSaved: (newValue) {
                            _enteredEmail = newValue!;
                          },
                        ),
                        if (!_isLogin)
                          TextFormField(
                            decoration:
                                const InputDecoration(labelText: "User name"),
                            enableSuggestions: false,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  value.length < 4) {
                                return "Please enter at least 4 characters.";
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              _enteredUsername = newValue!;
                            },
                          ),
                        TextFormField(
                          decoration:
                              const InputDecoration(labelText: "Password"),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.trim().length < 6) {
                              return "Password must be 6 characters long.";
                            }
                            return null;
                          },
                          onSaved: (newValue) {
                            _enteredPassword = newValue!;
                          },
                        ),
                        const SizedBox(height: 12),
                        if (_isAuthenticating)
                          const CircularProgressIndicator(),
                        if (!_isAuthenticating)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer),
                            onPressed: _submit,
                            child: Text(_isLogin ? "Login" : "SignUp",
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer)),
                          ),
                        if (!_isAuthenticating)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                              });
                            },
                            child: Text(_isLogin
                                ? "Create an Account"
                                : "I already have an account"),
                          ),
                      ],
                    )),
              ),
            ),
          )
        ]),
      )),
    );
  }
}
