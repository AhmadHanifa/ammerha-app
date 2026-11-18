import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/theme.dart';

/// A photo from the network, with a calm placeholder while it loads.
class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.radius = AppRadius.card, this.fit = BoxFit.cover});

  final String? url;
  final double radius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: AppColors.primarySoft,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: AppColors.inkSoft),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url == null
          ? placeholder
          : Image.network(
              url!,
              fit: fit,
              loadingBuilder: (context, child, progress) => progress == null ? child : placeholder,
              errorBuilder: (context, error, stack) => placeholder,
            ),
    );
  }
}

/// Full screen photos, swiped sideways and pinched to zoom.
Future<void> showPhotos(BuildContext context, List<String?> urls, {int initial = 0, List<String?>? captions}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (context, animation, _) => FadeTransition(
        opacity: animation,
        child: _PhotoViewer(urls: urls, initial: initial, captions: captions),
      ),
    ),
  );
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.urls, required this.initial, this.captions});

  final List<String?> urls;
  final int initial;
  final List<String?>? captions;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late var _index = widget.initial;
  late final _pages = PageController(initialPage: widget.initial);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caption = widget.captions?[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pages,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => InteractiveViewer(
                maxScale: 4,
                child: Center(child: NetImage(widget.urls[i], radius: 0, fit: BoxFit.contain)),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                tooltip: 'سكّر',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Text(
                [if (caption != null && caption.isNotEmpty) caption, '${_index + 1} من ${widget.urls.length}'].join(' · '),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A row of square thumbnails that open full screen.
class PhotoStrip extends StatelessWidget {
  const PhotoStrip({super.key, required this.urls, this.captions, this.size = 84});

  final List<String?> urls;
  final List<String?>? captions;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (context, i) => const SizedBox(width: 8),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => showPhotos(context, urls, initial: i, captions: captions),
          child: SizedBox.square(dimension: size, child: NetImage(urls[i], radius: 12)),
        ),
      ),
    );
  }
}

/// Photos the customer adds from the camera or the gallery, before sending.
class PhotoPickerField extends StatelessWidget {
  const PhotoPickerField({super.key, required this.photos, required this.onChanged, this.max = 6, this.hint});

  final List<XFile> photos;
  final ValueChanged<List<XFile>> onChanged;
  final int max;
  final String? hint;

  Future<void> _add(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('صوّر هلق'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('من الصور'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picker = ImagePicker();
    try {
      final picked = source == ImageSource.camera
          ? [?await picker.pickImage(source: source, maxWidth: 1600, imageQuality: 80)]
          : await picker.pickMultiImage(maxWidth: 1600, imageQuality: 80, limit: max - photos.length);
      if (picked.isEmpty) return;
      onChanged([...photos, ...picked].take(max).toList());
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ما قدرنا نفتح الصور')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hint != null) ...[Text(hint!, style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: 8)],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (i, photo) in photos.indexed)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _PickedThumb(photo),
                  ),
                  Positioned(
                    top: 2,
                    left: 2,
                    child: InkWell(
                      onTap: () => onChanged([...photos]..removeAt(i)),
                      child: const CircleAvatar(
                        radius: 11,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            if (photos.length < max)
              Material(
                color: AppColors.primarySoft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.line),
                ),
                child: InkWell(
                  onTap: () => _add(context),
                  borderRadius: BorderRadius.circular(12),
                  child: const SizedBox.square(
                    dimension: 72,
                    child: Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// A picked photo before it is uploaded; its bytes are read once.
class _PickedThumb extends StatefulWidget {
  const _PickedThumb(this.file);

  final XFile file;

  @override
  State<_PickedThumb> createState() => _PickedThumbState();
}

class _PickedThumbState extends State<_PickedThumb> {
  late final _bytes = widget.file.readAsBytes();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _bytes,
      builder: (context, snap) => snap.hasData
          ? Image.memory(snap.data!, width: 72, height: 72, fit: BoxFit.cover)
          : const SizedBox.square(dimension: 72, child: ColoredBox(color: AppColors.primarySoft)),
    );
  }
}
