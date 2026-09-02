import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Overridable seams for the two Firebase singletons this app's
/// customer-facing auth/booking flow uses — production code sees the real
/// SDK instances (the defaults below); tests reassign these to a
/// MockFirebaseAuth/FakeFirebaseFirestore before pumping any widget tree,
/// instead of threading an instance through every call site individually.
FirebaseAuth firebaseAuthInstance = FirebaseAuth.instance;
FirebaseFirestore firestoreInstance = FirebaseFirestore.instance;
