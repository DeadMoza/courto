import 'package:flutter/material.dart';

/// Full-screen photo browser, used for gym galleries and field carousels.
///
/// Swipe between photos, pinch or double-tap to zoom, drag a zoomed photo
/// around, and swipe down to dismiss.
class ImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final bool isEnglish;

  const ImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.isEnglish = false,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late int _index;

  // Only the visible page can be interacted with, so one controller that
  // resets on page change is enough - no need to hold one per photo.
  final TransformationController _transform = TransformationController();
  late final AnimationController _zoomAnim;
  Animation<Matrix4>? _zoomTween;

  // Panning a zoomed photo must not also flip the page, so the PageView is
  // locked while the current photo is scaled up.
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.images.length - 1);
    _pageController = PageController(initialPage: _index);

    _zoomAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        final tween = _zoomTween;
        if (tween != null) _transform.value = tween.value;
      });

    _transform.addListener(_onTransformChanged);
  }

  void _onTransformChanged() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _isZoomed && mounted) {
      setState(() => _isZoomed = zoomed);
    }
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransformChanged);
    _pageController.dispose();
    _transform.dispose();
    _zoomAnim.dispose();
    super.dispose();
  }

  void _animateTo(Matrix4 target) {
    _zoomTween = Matrix4Tween(begin: _transform.value, end: target)
        .animate(CurvedAnimation(parent: _zoomAnim, curve: Curves.easeOut));
    _zoomAnim.forward(from: 0);
  }

  void _handleDoubleTap(TapDownDetails details) {
    if (_isZoomed) {
      _animateTo(Matrix4.identity());
      return;
    }

    // Zoom toward the point that was tapped rather than the centre.
    const scale = 2.5;
    final pos = details.localPosition;
    _animateTo(
      Matrix4.identity()
        ..translateByDouble(
            -pos.dx * (scale - 1), -pos.dy * (scale - 1), 0, 1)
        ..scaleByDouble(scale, scale, scale, 1),
    );
  }

  void _resetZoom() {
    if (_transform.value != Matrix4.identity()) {
      _transform.value = Matrix4.identity();
    }
  }

  Widget _overlayPill({required Widget child, bool circle = false}) {
    return Container(
      padding: circle
          ? const EdgeInsets.all(8)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(20),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final en = widget.isEnglish;
    final hint = en
        ? 'Double-tap or pinch to zoom'
        : 'انقر مرتين أو باعد بأصبعيك للتكبير';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Swipe down to dismiss, but only when not zoomed - otherwise it
          // fights with panning a zoomed photo.
          GestureDetector(
            onVerticalDragEnd: (d) {
              if (!_isZoomed && (d.primaryVelocity ?? 0) > 300) {
                Navigator.of(context).pop();
              }
            },
            child: PageView.builder(
              controller: _pageController,
              physics: _isZoomed
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              itemCount: widget.images.length,
              onPageChanged: (i) {
                _resetZoom();
                setState(() => _index = i);
              },
              itemBuilder: (_, i) {
                final photo = InteractiveViewer(
                  transformationController: i == _index ? _transform : null,
                  minScale: 1,
                  maxScale: 5,
                  child: Center(
                    child: Image.network(
                      widget.images[i],
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child:
                              CircularProgressIndicator(color: Colors.white54),
                        );
                      },
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image,
                            color: Colors.white38, size: 56),
                      ),
                    ),
                  ),
                );

                if (i != _index) return photo;

                return GestureDetector(
                  onDoubleTapDown: _handleDoubleTap,
                  // onDoubleTap has to be present for onDoubleTapDown to fire.
                  onDoubleTap: () {},
                  child: photo,
                );
              },
            ),
          ),

          // Close button and position counter
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: _overlayPill(
                        circle: true,
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                    const Spacer(),
                    if (widget.images.length > 1)
                      _overlayPill(
                        child: Text(
                          '${_index + 1} / ${widget.images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Hint, dropped once the user has actually zoomed.
          if (!_isZoomed)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Center(
                    child: Text(
                      hint,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
