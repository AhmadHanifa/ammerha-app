import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../app/config.dart';
import '../data/home_file.dart';
import 'customer.dart';

/// The customer's side of the home file: their requests, stage approvals,
/// material confirmations, photos and certificate.
abstract final class HomeFiles {
  static SupabaseClient get _db => Supabase.instance.client;

  static Future<T> _call<T>(String fn, [Map<String, dynamic>? params]) async {
    if (!await Customer.instance.ensureSignedIn()) throw const NotSignedIn();
    return await _db.rpc(fn, params: params).timeout(AppConfig.requestTimeout) as T;
  }

  static Future<List<RequestSummary>> myRequests() async {
    final rows = await _call<List>('my_requests');
    return [for (final r in rows.cast<Map<String, dynamic>>()) RequestSummary.fromJson(r)];
  }

  static Future<RequestFile> load(int number) async {
    final json = await _call<Map<String, dynamic>>('my_request_file', {'p_request_no': number});
    final paths = [for (final m in (json['media'] as List).cast<Map<String, dynamic>>()) m['path'] as String];
    final urls = <String, String>{};
    if (paths.isNotEmpty) {
      try {
        final signed = await _db.storage
            .from('home-files')
            .createSignedUrlsResult(paths, 3600)
            .timeout(AppConfig.requestTimeout);
        for (final s in signed.whereType<SignedUrlSuccess>()) {
          urls[s.path] = s.signedUrl;
        }
      } catch (_) {
        // The file still shows; the photos say they could not load.
      }
    }
    return RequestFile.fromJson(json, urls);
  }

  static Future<void> decideStage(String stageId, {required bool approve, String? note}) =>
      _call<void>('decide_stage', {'p_stage_id': stageId, 'p_approve': approve, 'p_note': note});

  static Future<void> confirmMaterial(String mediaId) => _call<void>('confirm_material', {'p_media_id': mediaId});

  static Future<void> setCertificatePublic(int number, bool public) =>
      _call<void>('set_certificate_public', {'p_request_no': number, 'p_public': public});

  /// Uploads the photos picked with a request; returns how many made it.
  static Future<int> uploadIntake({required String requestId, required int number, required List<XFile> photos}) async {
    if (photos.isEmpty || !await Customer.instance.ensureSignedIn()) return 0;
    var done = 0;
    for (final photo in photos) {
      final path = '$requestId/intake/${const Uuid().v4()}.jpg';
      try {
        await _db.storage
            .from('home-files')
            .uploadBinary(path, await photo.readAsBytes(), fileOptions: const FileOptions(contentType: 'image/jpeg'))
            .timeout(const Duration(seconds: 60));
        await _db.rpc('add_intake_photo', params: {'p_request_no': number, 'p_path': path});
        done++;
      } catch (_) {
        // A photo that fails is skipped; the request itself is already sent.
      }
    }
    return done;
  }

  /// A public certificate by its code, or null.
  static Future<Map<String, dynamic>?> verify(String code) async {
    final json = await _db.rpc('verify_certificate', params: {'p_code': code}).timeout(AppConfig.requestTimeout);
    return json as Map<String, dynamic>?;
  }
}

class NotSignedIn implements Exception {
  const NotSignedIn();
}
