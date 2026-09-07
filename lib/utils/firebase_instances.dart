import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Overridable seams for the Firebase singletons this app's customer-facing
/// auth/booking flow (and the mechanic module's own screens) use —
/// production code sees the real SDK instances (the defaults below); tests
/// reassign these to a MockFirebaseAuth/FakeFirebaseFirestore before
/// pumping any widget tree, instead of threading an instance through every
/// call site individually. firebaseStorageInstance follows the same
/// pattern for MechanicProfileRepository.uploadCoverPhoto — there is no
/// equivalent fake/mock Storage package in this project's test
/// dependencies yet, so tests that need a real photo URL present seed it
/// directly on the fake Firestore document instead of exercising an actual
/// upload (see mechanic_profile_screen_test.dart).
FirebaseAuth firebaseAuthInstance = FirebaseAuth.instance;
FirebaseFirestore firestoreInstance = FirebaseFirestore.instance;
FirebaseStorage firebaseStorageInstance = FirebaseStorage.instance;
