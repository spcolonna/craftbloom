import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SocialService {
  final FirebaseFunctions _functions;
  SocialService(this._functions);

  Future<void> postToInstagram({
    required String imageUrl,
    required String caption,
  }) async {
    final callable = _functions.httpsCallable('postToInstagram');
    await callable.call<Map<String, dynamic>>({
      'imageUrl': imageUrl,
      'caption': caption,
    });
  }
}

final socialServiceProvider = Provider<SocialService>(
  (ref) => SocialService(FirebaseFunctions.instance),
);
