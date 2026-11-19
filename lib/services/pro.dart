import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../app/config.dart';
import '../data/pro.dart';
import 'analytics.dart';
import 'customer.dart';
import 'home_files.dart';
import 'showcase.dart';

/// The provider's side: signing up, their profile, and their jobs.
abstract final class Pro {
  static SupabaseClient get _db => Supabase.instance.client;

  static Future<T> _call<T>(String fn, [Map<String, dynamic>? params]) async {
    if (!await Customer.instance.ensureSignedIn()) throw const NotSignedIn();
    return await _db.rpc(fn, params: params).timeout(AppConfig.requestTimeout) as T;
  }

  /// Null when this phone has no provider profile.
  static Future<MyProfile?> me() async {
    if (!AppConfig.hasBackend) return null;
    final json = await _call<Map<String, dynamic>?>('my_provider');
    return json == null ? null : MyProfile.fromJson(json, Showcase.publicUrl);
  }

  static Future<String> apply({
    required String kind,
    required String name,
    required String phone,
    required List<String> services,
    String? specialty,
    String? area,
    int? years,
    String? bio,
    String? syndicateNo,
  }) async => await _call<String>('apply_as_provider', {
    'p_device_id': await Analytics.instance.ensureDeviceId(),
    'p_kind': kind,
    'p_name': name,
    'p_phone': phone,
    'p_services': services,
    'p_specialty': specialty,
    'p_area': area,
    'p_years': years,
    'p_bio': bio,
    'p_syndicate_no': syndicateNo,
  });

  static Future<void> uploadPhoto(String providerId, XFile photo) async {
    final path = 'providers/$providerId/profile-${const Uuid().v4()}.jpg';
    await _db.storage.from('public-media').uploadBinary(
      path,
      await photo.readAsBytes(),
      fileOptions: const FileOptions(contentType: 'image/jpeg'),
    );
    await _call<void>('set_provider_files', {'p_photo_path': path});
  }

  static Future<void> uploadCertificate(String providerId, XFile file) async {
    final path = '$providerId/certificate-${const Uuid().v4()}.jpg';
    await _db.storage.from('provider-docs').uploadBinary(
      path,
      await file.readAsBytes(),
      fileOptions: const FileOptions(contentType: 'image/jpeg'),
    );
    await _call<void>('set_provider_files', {'p_certificate_path': path});
  }

  /// A new phone: the code the team gave from the dashboard.
  static Future<void> claimLink(String code) => _call<void>('claim_provider_link', {
    'p_code': code.trim(),
    'p_device_id': Analytics.instance.deviceId,
  });

  static Future<List<JobSummary>> jobs() async {
    final rows = await _call<List>('my_jobs');
    return [for (final r in rows.cast<Map<String, dynamic>>()) JobSummary.fromJson(r)];
  }

  static Future<JobFile> job(int number) async {
    final json = await _call<Map<String, dynamic>>('my_job_file', {'p_request_no': number});
    final paths = [for (final m in (json['media'] as List).cast<Map<String, dynamic>>()) m['path'] as String];
    final urls = <String, String>{};
    if (paths.isNotEmpty) {
      try {
        final signed = await _db.storage.from('home-files').createSignedUrlsResult(paths, 3600);
        for (final s in signed.whereType<SignedUrlSuccess>()) {
          urls[s.path] = s.signedUrl;
        }
      } catch (_) {
        // The job still shows; photos say they could not load.
      }
    }
    return JobFile.fromJson(json, urls);
  }

  static Future<void> addStages(int number, [List<String>? titles]) =>
      _call<void>('provider_add_stages', {'p_request_no': number, 'p_titles': titles});

  static Future<void> setStage(String stageId, String status, {num? payment}) =>
      _call<void>('provider_set_stage', {'p_stage_id': stageId, 'p_status': status, 'p_payment': payment});

  /// Uploads photos into one group of the job (stage, wiring, materials, handover).
  static Future<int> addPhotos({
    required String requestId,
    required int number,
    required String category,
    required List<XFile> photos,
    String? stageId,
    String? caption,
    String? room,
  }) async {
    var done = 0;
    for (final photo in photos) {
      final path = '$requestId/$category/${const Uuid().v4()}.jpg';
      try {
        await _db.storage
            .from('home-files')
            .uploadBinary(path, await photo.readAsBytes(), fileOptions: const FileOptions(contentType: 'image/jpeg'))
            .timeout(const Duration(seconds: 60));
        await _db.rpc(
          'provider_add_media',
          params: {
            'p_request_no': number,
            'p_path': path,
            'p_category': category,
            'p_stage_id': stageId,
            'p_caption': caption,
            'p_room': room,
          },
        );
        done++;
      } catch (_) {
        // Skipped; the others still go.
      }
    }
    return done;
  }

  static Future<void> updateClaim(String claimId, String status, {DateTime? visitAt, String? note}) =>
      _call<void>('provider_update_claim', {
        'p_claim_id': claimId,
        'p_status': status,
        'p_visit_at': visitAt?.toUtc().toIso8601String(),
        'p_note': note,
      });
}
