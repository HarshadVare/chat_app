import 'dart:core';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/widgets/user_image_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();

  var _isLogin = true;
  var _enteredEmail = '';
  var _enteredPassword = '';
  var _enteredUsername = '';
  File? _selecteImage;
  var _isAuthenticating = false;

  void _submit() async {
    // DateTime dateTime = DateTime.now();
    // String formattedDate = "${dateTime.year}-${dateTime.month}-${dateTime.day}";
    // String formattedTime =
    //     "${dateTime.hour}:${dateTime.minute}:${dateTime.second}";
    // FirebaseFirestore.instance
    //     .collection("Insurance_test")
    //     .doc(dateTime.year.toString())
    //     .collection(dateTime.month.toString())
    //     .doc(formattedDate)
    //     .collection("151542")
    //     .doc("health")
    //     .set({
    //   'plans': {
    //     'counts': FieldValue.arrayUnion([formattedTime]),
    //     'id': 'hdfc_3465',
    //     'name': 'Bajaj'
    //   },
    //   'user_details': {'id': '123524126', 'name': 'Kunal'}
    // }, SetOptions(merge: true));

    // await FirebaseFirestore.instance
    //     .collection('Insurance')
    //     .doc(currentDate.year.toString()).collection(collectionPath)

    final isValid = _form.currentState!.validate();

    if (!isValid || !_isLogin && _selecteImage == null) {
      //show error message
      print('invalid Data');
      return;
    }
    _form.currentState!.save();
    try {
      setState(() {
        _isAuthenticating = true;
      });
      if (_isLogin) {
        //for login user
        final userCredential = await _firebase.signInWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);
      } else {
        //for sign up user
        final userCredential = await _firebase.createUserWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);

        //for storage images
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCredential.user!.uid}.jpg');
        await storageRef.putFile(_selecteImage!);
        final imageUrl = await storageRef.getDownloadURL();

        //for store user data on firestore collections
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'username': _enteredUsername,
          'email': _enteredEmail,
          'image_url': imageUrl
        });
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        // ...
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Authentication Failed')));
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
            margin:
                const EdgeInsets.only(top: 30, bottom: 20, left: 20, right: 20),
            width: 200,
            child: Image.asset('assets/images/chat.png'),
          ),
          Card(
            margin: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_isLogin)
                        UserImagePicker(
                          onPickImage: (pickedImage) {
                            _selecteImage = pickedImage;
                          },
                        ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.none,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty ||
                              !value.contains('@')) {
                            return 'Please enter a valid email address.';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _enteredEmail = value!;
                        },
                      ),
                      if (!_isLogin)
                        TextFormField(
                          decoration:
                              const InputDecoration(label: Text('Username')),
                          enableSuggestions: false,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty ||
                                value.trim().length < 4) {
                              return 'Please enter atleast 4 characters';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _enteredUsername = value!;
                          },
                        ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.trim().length < 8) {
                            return 'Passwords must be atleast 8 characters long.';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _enteredPassword = value!;
                        },
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      if (_isAuthenticating) const CircularProgressIndicator(),
                      if (!_isAuthenticating)
                        ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer),
                          child: Text(_isLogin ? 'Login' : 'Signup'),
                        ),
                      if (!_isAuthenticating)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                            });
                          },
                          child: Text(_isLogin
                              ? 'Create an account'
                              : 'I already have an account'),
                        )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ]),
      )),
    );
  }
}
