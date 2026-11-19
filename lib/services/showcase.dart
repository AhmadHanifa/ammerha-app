import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/config.dart';
import '../data/article.dart';
import '../data/providers.dart';
import '../data/showcase.dart';

/// Published gallery projects and ready designs, kept for the session.
class Showcase {
  Showcase._();
  static final instance = Showcase._();

  Future<List<GalleryProject>>? _gallery;
  Future<List<ReadyDesign>>? _designs;
  Future<List<Provider>>? _providers;
  Future<List<Article>>? _articles;

  Future<List<Article>> articles({bool refresh = false}) {
    if (refresh) _articles = null;
    return _articles ??= _loadArticles().catchError((Object e) {
      _articles = null;
      throw e;
    });
  }

  Future<List<Article>> _loadArticles() async {
    if (!AppConfig.hasBackend) return const [];
    final rows = await Supabase.instance.client
        .from('articles')
        .select('id, title, summary, category, service, body, checklist, cover_path')
        .order('sort')
        .order('created_at', ascending: false)
        .timeout(AppConfig.requestTimeout);
    return [
      for (final r in rows)
        Article(
          id: r['id'] as String,
          title: r['title'] as String,
          category: r['category'] as String,
          body: r['body'] as String? ?? '',
          checklist: ((r['checklist'] as List?) ?? const []).cast<String>(),
          summary: r['summary'] as String?,
          service: r['service'] as String?,
          coverUrl: r['cover_path'] == null ? null : _url(r['cover_path'] as String),
        ),
    ];
  }

  Future<List<Provider>> providers({bool refresh = false}) {
    if (refresh) _providers = null;
    return _providers ??= _loadProviders().catchError((Object e) {
      _providers = null;
      throw e;
    });
  }

  Future<List<ProviderReview>> reviews(String providerId) async {
    if (!AppConfig.hasBackend) return const [];
    final rows = await Supabase.instance.client
        .rpc('provider_reviews', params: {'p_provider_id': providerId})
        .timeout(AppConfig.requestTimeout) as List;
    return [for (final r in rows.cast<Map<String, dynamic>>()) ProviderReview.fromJson(r)];
  }

  Future<List<Provider>> _loadProviders() async {
    if (!AppConfig.hasBackend) return const [];
    final rows = await Supabase.instance.client.rpc('provider_directory').timeout(AppConfig.requestTimeout) as List;
    return [
      for (final r in rows.cast<Map<String, dynamic>>())
        Provider(
          id: r['id'] as String,
          kind: r['kind'] as String,
          name: r['name'] as String,
          services: ((r['services'] as List?) ?? const []).cast<String>(),
          photos: [
            for (final p in ((r['photos'] as List?) ?? const []).cast<Map<String, dynamic>>())
              ShowcasePhoto(url: _url(p['path'] as String), caption: p['caption'] as String?),
          ],
          jobs: (r['jobs'] as num? ?? 0).toInt(),
          reviews: (r['reviews'] as num? ?? 0).toInt(),
          claims: (r['claims'] as num? ?? 0).toInt(),
          claimsFixed: (r['claims_fixed'] as num? ?? 0).toInt(),
          specialty: r['specialty'] as String?,
          area: r['area'] as String?,
          bio: r['bio'] as String?,
          photoUrl: r['photo_path'] == null ? null : _url(r['photo_path'] as String),
          years: (r['years'] as num?)?.toInt(),
          verified: r['is_verified'] == true,
          rating: r['rating'] as num?,
        ),
    ];
  }

  Future<List<GalleryProject>> gallery({bool refresh = false}) {
    if (refresh) _gallery = null;
    return _gallery ??= _loadGallery().catchError((Object e) {
      _gallery = null;
      throw e;
    });
  }

  Future<List<ReadyDesign>> designs({bool refresh = false}) {
    if (refresh) _designs = null;
    return _designs ??= _loadDesigns().catchError((Object e) {
      _designs = null;
      throw e;
    });
  }

  static String publicUrl(String path) => _url(path);

  static String _url(String path) => Supabase.instance.client.storage.from('public-media').getPublicUrl(path);

  static List<ShowcasePhoto> _photos(Object? rows) {
    final list = [...((rows as List?) ?? const []).cast<Map<String, dynamic>>()]
      ..sort((a, b) => (a['sort'] as num? ?? 0).compareTo(b['sort'] as num? ?? 0));
    return [
      for (final p in list)
        ShowcasePhoto(url: _url(p['path'] as String), stage: p['stage'] as String?, caption: p['caption'] as String?),
    ];
  }

  Future<List<GalleryProject>> _loadGallery() async {
    if (!AppConfig.hasBackend) return const [];
    final rows = await Supabase.instance.client
        .from('gallery_projects')
        .select('*, gallery_photos(path, stage, caption, sort)')
        .order('sort')
        .order('created_at', ascending: false)
        .timeout(AppConfig.requestTimeout);
    return [
      for (final r in rows)
        GalleryProject(
          id: r['id'] as String,
          title: r['title'] as String,
          kind: r['kind'] as String? ?? 'full',
          services: ((r['services'] as List?) ?? const []).cast<String>(),
          photos: _photos(r['gallery_photos']),
          area: r['area_m2'] as num?,
          level: levelFromKey(r['level']),
          location: r['location'] as String?,
          durationWeeks: (r['duration_weeks'] as num?)?.toInt(),
          costUsd: r['cost_usd'] as num?,
          story: r['story'] as String?,
        ),
    ];
  }

  Future<List<ReadyDesign>> _loadDesigns() async {
    if (!AppConfig.hasBackend) return const [];
    final rows = await Supabase.instance.client
        .from('designs')
        .select('*, design_photos(path, caption, sort)')
        .order('sort')
        .order('created_at', ascending: false)
        .timeout(AppConfig.requestTimeout);
    return [
      for (final r in rows)
        ReadyDesign(
          id: r['id'] as String,
          title: r['title'] as String,
          room: r['room'] as String,
          style: r['style'] as String,
          photos: _photos(r['design_photos']),
          level: levelFromKey(r['level']),
          description: r['description'] as String?,
        ),
    ];
  }
}
