// NOT RUNNABLE STANDALONE — Flutter learning reference file.
// Requires a Flutter project. Covers Hero animations comprehensively.

// ============================================================
// WHAT IS A HERO ANIMATION?
// ============================================================
//
// A Hero animation "flies" a widget from one route to another, creating the
// visual illusion of continuity. The user sees the widget smoothly travel
// from its position on route A to its position on route B.
//
// Classic use case: a thumbnail image in a grid taps to a full-screen detail
// view. The thumbnail "flies" to become the full-size image.
//
// HOW IT WORKS (simplified):
//   1. When a route transition starts, Flutter finds Hero widgets with the
//      same `tag` on both the source and destination routes.
//   2. It measures the source Hero's position/size on-screen.
//   3. It overlays an "in-flight" copy of the widget on top of both routes.
//   4. It animates the overlay widget from source rect → destination rect.
//   5. When the transition ends, the destination Hero becomes visible.
//
// The source and destination Hero children do NOT need to be the same widget
// type — Flutter interpolates between the two rects regardless.

import 'package:flutter/material.dart';

// ============================================================
// BASIC HERO — tag must match on both routes
// ============================================================
//
// TAG REQUIREMENT:
//   • The `tag` must be identical on both source and destination Heroes.
//   • It can be any Object (String, int, a model identifier, etc.).
//   • Tags are compared with == so use objects that implement equality.
//
// TAG UNIQUENESS REQUIREMENT:
//   • There must be at most ONE visible Hero per tag in the Navigator at
//     any given time. If two Heroes with the same tag are visible
//     simultaneously (e.g., two items in a grid with the same tag),
//     Flutter throws: "There are multiple heroes that share the same tag
//     within a subtree."
//   • Solution: use a unique value per item, e.g., 'photo-${item.id}'.

class PhotoGridPage extends StatelessWidget {
  const PhotoGridPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PhotoDetailPage(photoIndex: index),
                ),
              );
            },
            child: Hero(
              // Each item has a unique tag derived from its index.
              tag: 'photo-$index',
              // The widget INSIDE the Hero is what flies.
              // Keep it simple — avoid widgets that change structure during flight.
              child: Image.network(
                'https://picsum.photos/seed/$index/200/200',
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}

class PhotoDetailPage extends StatelessWidget {
  final int photoIndex;
  const PhotoDetailPage({super.key, required this.photoIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use a transparent/dark background for the overlay effect.
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: Hero(
            // Same tag as the source → triggers the Hero animation.
            tag: 'photo-$photoIndex',
            child: Image.network(
              'https://picsum.photos/seed/$photoIndex/800/600',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// createRectTween — customize the flight path
// ============================================================
//
// By default, Hero uses a MaterialRectArcTween for the flight path, which
// curves the widget along an arc (the Material Design motion spec).
//
// You can provide a custom RectTween to control the path:
//   • MaterialRectArcTween    — default; curves along an arc.
//   • MaterialRectCenterArcTween — arc based on center points.
//   • RectTween               — linear path from source to destination.
//   • Custom subclass         — for any other interpolation.

class LinearHero extends StatelessWidget {
  final String tag;
  final Widget child;
  const LinearHero({super.key, required this.tag, required this.child});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      // createRectTween receives the source and destination Rects.
      // Return any RectTween to control the interpolation.
      createRectTween: (begin, end) {
        // Linear path: straight line from source to destination.
        return RectTween(begin: begin, end: end);
      },
      child: child,
    );
  }
}

// ============================================================
// HeroFlightShuttleBuilder — customize the in-flight widget
// ============================================================
//
// By default, the in-flight "shuttle" is the destination Hero's child.
// HeroFlightShuttleBuilder lets you swap in a completely different widget
// during the flight — for example, to show a loading spinner or a blurred
// version while the full image downloads.
//
// Parameters:
//   flightContext    — BuildContext in the overlay (not source or dest)
//   animation        — 0.0 (source) → 1.0 (destination)
//   flightDirection  — HeroFlightDirection.push or .pop
//   fromHeroContext  — context of the source Hero
//   toHeroContext    — context of the destination Hero

class CustomShuttleHero extends StatelessWidget {
  final String tag;
  final Widget child;
  const CustomShuttleHero({super.key, required this.tag, required this.child});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        // Retrieve the destination Hero's child to display during flight.
        final toHero = toHeroContext.widget as Hero;
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            // Fade from the source widget to the destination widget.
            // At animation.value == 0.0, we are at the source.
            // At animation.value == 1.0, we are at the destination.
            return FadeTransition(
              opacity: animation,
              child: toHero.child,
            );
          },
        );
      },
      child: child,
    );
  }
}

// ============================================================
// placeholderBuilder — what to show at source while flying
// ============================================================
//
// While the Hero is in flight, the SOURCE position shows a placeholder
// (by default the original widget remains, becoming invisible once flight starts).
// Use placeholderBuilder to show something else in the source's space
// during the transition (e.g., a loading skeleton).

class HeroWithPlaceholder extends StatelessWidget {
  const HeroWithPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'hero-with-placeholder',
      // placeholderBuilder is called with the size the Hero occupied
      // on the source route, while the shuttle is flying.
      placeholderBuilder: (context, heroSize, child) {
        // Show a grey box as a placeholder while the Hero flies away.
        return Container(
          width: heroSize.width,
          height: heroSize.height,
          color: Colors.grey.shade300,
          child: const Center(child: CircularProgressIndicator()),
        );
      },
      child: Image.network('https://picsum.photos/200'),
    );
  }
}

// ============================================================
// HERO WITH IMAGES — ensure image is loaded before transition
// ============================================================
//
// If the destination image hasn't loaded yet when the Hero lands, the
// transition looks janky (the hero arrives as a broken or gray box).
//
// Solutions:
//   1. Use the same URL on both source and destination — the image is
//      already in Flutter's image cache from the thumbnail.
//   2. Precache the destination image with precacheImage().
//   3. Use a FadeInImage or CachedNetworkImage with a placeholder so
//      the transition still looks smooth even if the image loads late.

Future<void> precacheBeforeNavigating(BuildContext context, String imageUrl) async {
  // precacheImage loads the image into the image cache.
  // Await it before navigating to ensure a smooth Hero landing.
  await precacheImage(NetworkImage(imageUrl), context);
  if (!context.mounted) return;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Hero(
          tag: 'precached-image',
          child: Image.network(imageUrl),
        ),
      ),
    ),
  );
}

// ============================================================
// NESTED HEROES — NOT SUPPORTED
// ============================================================
//
// Flutter does not support nested Hero widgets (a Hero inside a Hero's child).
// Attempting to do so causes unexpected behavior or errors.
//
// WORKAROUND:
//   If you need Hero behavior on a child inside a larger Hero, split the
//   animation into two separate Heroes with different tags. Use a custom
//   flightShuttleBuilder on the outer Hero to compose both visuals manually.
//
// Alternatively, use a custom explicit animation that mimics Hero behavior
// by measuring positions with RenderBox.localToGlobal() and animating in
// an Overlay.

// ============================================================
// HERO WITH NON-MATERIAL ROUTES
// ============================================================
//
// Hero animations work out of the box with MaterialPageRoute and
// CupertinoPageRoute. For custom PageRoutes, you must ensure that:
//
//   1. The route's transitionDuration is non-zero (Hero uses this duration).
//   2. The route's barrierColor allows the Hero to be visible during flight.
//      (Fully opaque barriers block the overlay where the Hero flies.)
//   3. The route's maintainState is true if you want the source page to
//      remain alive (so the source Hero position is still measurable).
//
// If you use a raw Route (not PageRoute), Hero animations do NOT fire
// automatically. The Hero mechanism is built into the Navigator's
// _TransitionOverlay, which is triggered only for PageRoute transitions.

// ============================================================
// HERO WITH GO_ROUTER / NAVIGATOR 2.0
// ============================================================
//
// Hero works with go_router because go_router uses the same underlying
// Navigator widget. As long as the MaterialPageRoute / CupertinoPageRoute
// transition is active, Hero animations fire normally.
//
// GOTCHA: ShellRoute renders child routes inside a nested Navigator.
// Heroes must be on routes sharing the SAME Navigator to animate between
// them. Cross-navigator Hero animations (e.g., from a tab's inner Navigator
// to the outer Navigator) do not work automatically.
//
// Workaround for cross-navigator Heroes:
//   • Use the RootNavigator: Navigator.of(context, rootNavigator: true)
//     to push a route onto the root Navigator rather than the shell's inner one.
//   • Or use an explicit custom animation that uses Overlay + CompositedTransform.

// ============================================================
// PRACTICAL EXAMPLE — Image Gallery with Hero Transitions
// ============================================================

class GalleryApp extends StatelessWidget {
  const GalleryApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const GalleryGridPage(),
    );
  }
}

class Photo {
  final int id;
  final String thumbnail;
  final String fullSize;
  const Photo({required this.id, required this.thumbnail, required this.fullSize});
}

final _photos = List.generate(
  18,
  (i) => Photo(
    id: i,
    thumbnail: 'https://picsum.photos/seed/$i/200/200',
    fullSize: 'https://picsum.photos/seed/$i/800/600',
  ),
);

class GalleryGridPage extends StatelessWidget {
  const GalleryGridPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      body: GridView.builder(
        padding: const EdgeInsets.all(4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: _photos.length,
        itemBuilder: (context, index) {
          final photo = _photos[index];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  // pageBuilder provides the destination page.
                  pageBuilder: (ctx, animation, secondaryAnimation) {
                    return GalleryDetailPage(photo: photo, allPhotos: _photos);
                  },
                  // transitionsBuilder wraps the page in a fade transition.
                  transitionsBuilder: (ctx, animation, secondary, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            },
            child: Hero(
              // Unique tag per photo — using the photo's id is clean and safe.
              tag: 'photo-hero-${photo.id}',
              child: Image.network(photo.thumbnail, fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }
}

class GalleryDetailPage extends StatefulWidget {
  final Photo photo;
  final List<Photo> allPhotos;
  const GalleryDetailPage({
    super.key,
    required this.photo,
    required this.allPhotos,
  });
  @override
  State<GalleryDetailPage> createState() => _GalleryDetailPageState();
}

class _GalleryDetailPageState extends State<GalleryDetailPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.allPhotos.indexOf(widget.photo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Photo ${_currentIndex + 1} of ${widget.allPhotos.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: _currentIndex),
        itemCount: widget.allPhotos.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final photo = widget.allPhotos[index];
          return Center(
            child: Hero(
              // IMPORTANT: when using PageView inside the detail page, only the
              // initially-shown photo gets the Hero animation. Photos swiped to
              // in the PageView do NOT fly (they were not visible on the source
              // route). This is expected behavior.
              tag: 'photo-hero-${photo.id}',
              child: Image.network(
                photo.fullSize,
                fit: BoxFit.contain,
                // Show thumbnail while full image loads — avoids janky landing.
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child; // loaded
                  return Image.network(photo.thumbnail, fit: BoxFit.contain);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
