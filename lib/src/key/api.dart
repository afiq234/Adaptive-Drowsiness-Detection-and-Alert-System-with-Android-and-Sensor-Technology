import 'package:googleapis_auth/auth_io.dart' as auth;
import 'dart:typed_data';
import 'package:gcloud/storage.dart';
import 'package:mime/mime.dart';

class CloudApi {
  final auth.ServiceAccountCredentials _credentials;
  late auth.AutoRefreshingAuthClient _client;

  CloudApi(String json)
      : _credentials = auth.ServiceAccountCredentials.fromJson(json);

  Future<ObjectInfo> save(String name, Uint8List imgBytes) async {
    try {
      _client =
          await auth.clientViaServiceAccount(_credentials, Storage.SCOPES);

      var storage = Storage(_client, 'flaskfyp2detection');
      var bucket = storage.bucket('facial_status');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final type = lookupMimeType(name);
      return await bucket.writeBytes(
        name,
        imgBytes,
        metadata: ObjectMetadata(
          contentType: type,
          custom: <String, String>{'timestamp': '$timestamp'},
        ),
      );
    } catch (e) {
      print('Error uploading to Cloud Storage: $e');
      rethrow;
    }
  }
}
