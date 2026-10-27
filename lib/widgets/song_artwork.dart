import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../core/state/artwork.dart';

/// Embedded artwork for a song or album, loaded through [ArtworkCache] and
/// decoded at the size it is drawn at.
///
/// [size] is the drawn size in logical pixels; leave it null to fill the
/// parent (e.g. a grid card). [requestSize] is the pixel size asked of the
/// media library.
class SongArtwork extends ConsumerStatefulWidget {
  const SongArtwork({
    super.key,
    required this.id,
    required this.placeholder,
    this.type = ArtworkType.AUDIO,
    this.size,
    this.requestSize = 200,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  final int id;
  final ArtworkType type;
  final double? size;
  final int requestSize;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final Widget placeholder;

  @override
  ConsumerState<SongArtwork> createState() => _SongArtworkState();
}

class _SongArtworkState extends ConsumerState<SongArtwork> {
  late Future<Uint8List?> _future;
  Uint8List? _initial;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(SongArtwork old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id ||
        old.type != widget.type ||
        old.requestSize != widget.requestSize) {
      _resolve();
    }
  }

  void _resolve() {
    final cache = ref.read(artworkCacheProvider);
    _initial = cache.peek(widget.id, widget.type, widget.requestSize);
    _future = cache.load(widget.id, widget.type, widget.requestSize);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final decodeWidth = size != null
        ? (size * dpr).round().clamp(1, widget.requestSize)
        : widget.requestSize;

    Widget child = FutureBuilder<Uint8List?>(
      future: _future,
      initialData: _initial,
      builder: (context, snap) {
        final bytes = snap.data;
        if (bytes == null) return widget.placeholder;
        return Image.memory(
          bytes,
          width: size,
          height: size,
          fit: widget.fit,
          gaplessPlayback: true,
          cacheWidth: decodeWidth,
          errorBuilder: (_, _, _) => widget.placeholder,
        );
      },
    );

    final radius = widget.borderRadius;
    if (radius != null) child = ClipRRect(borderRadius: radius, child: child);
    if (size != null) {
      child = SizedBox(width: size, height: size, child: child);
    }
    return child;
  }
}

/// Artwork from the web (Discover tracks), cached on disk between launches
/// and decoded at the size it is drawn at.
class RemoteArtwork extends StatelessWidget {
  const RemoteArtwork({
    super.key,
    required this.url,
    required this.size,
    required this.placeholder,
  });

  final String url;
  final double size;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    final px = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      memCacheWidth: px,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
    );
  }
}
