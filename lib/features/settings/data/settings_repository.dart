import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:craftbloom/core/theme/seasonal_theme.dart';
import 'package:craftbloom/core/utils/firebase_logger.dart';
import 'package:craftbloom/shared/providers/firebase_providers.dart';

class SettingsRepository {
  final FirebaseFirestore _db;
  SettingsRepository(this._db);

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('settings').doc('app_settings');

  Stream<SeasonalTheme> watchSeasonalTheme() {
    return _doc.snapshots().map((snap) {
      return SeasonalTheme.fromString(snap.data()?['seasonalTheme'] as String?);
    }).handleError(
      (e, st) => logFirebaseError('watchSeasonalTheme', e, st as StackTrace),
    );
  }

  Future<void> setSeasonalTheme(SeasonalTheme theme) async {
    await _doc.set({'seasonalTheme': theme.name}, SetOptions(merge: true));
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(firestoreProvider));
});

final seasonalThemeProvider = StreamProvider<SeasonalTheme>((ref) {
  return ref.watch(settingsRepositoryProvider).watchSeasonalTheme();
});
