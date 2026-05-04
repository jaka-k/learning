// NOT RUNNABLE STANDALONE — Flutter learning reference file.
// Requires a Flutter project. Covers slivers and composable scroll primitives.

// ============================================================
// WHAT IS A SLIVER?
// ============================================================
//
// A "sliver" is a portion of a scrollable area that knows its scroll offset
// and can paint itself lazily as it becomes visible.
//
// Regular Box widgets (Column, ListView built with children:[...]) must
// build ALL their children during layout, even off-screen ones. This is
// fine for small lists but catastrophic for 10,000-item feeds.
//
// Slivers solve this with a different layout protocol:
//   • Box protocol:   parent gives constraints → child returns size.
//   • Sliver protocol: parent gives SliverConstraints (scroll offset,
//     remaining paint extent, viewport size...) → child returns
//     SliverGeometry (scroll extent, paint extent, layout extent...).
//
// Because each sliver knows exactly how much of it is visible, it can
// build only the visible children (lazy building).
//
// MENTAL MODEL: Slivers are the "paragraphs" of a scrollable document.
// CustomScrollView is the "page" that holds them all.

import 'package:flutter/material.dart';

// ============================================================
// CUSTOMSCROLLVIEW — the container for slivers
// ============================================================
//
// CustomScrollView is to slivers what Column is to box widgets.
// It coordinates the slivers, manages the ScrollController,
// and clips/paints the visible area.
//
// Every direct child MUST be a sliver widget. Mixing regular Box
// widgets directly causes a type error. Use SliverToBoxAdapter to
// embed box widgets.

class BasicSliverExample extends StatelessWidget {
  const BasicSliverExample({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      // physics: controls scroll feel (BouncingScrollPhysics,
      //          ClampingScrollPhysics, NeverScrollableScrollPhysics...).
      physics: const BouncingScrollPhysics(),
      slivers: [
        // SliverAppBar — the collapsible header (covered in detail below)
        const SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(title: Text('My Feed')),
        ),

        // SliverPadding — adds EdgeInsets around a child sliver.
        // Use instead of wrapping in Padding (which is a Box widget).
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => ListTile(title: Text('Item $index')),
              childCount: 50,
            ),
          ),
        ),

        // A regular Box widget embedded in the sliver list.
        const SliverToBoxAdapter(
          child: Divider(thickness: 2),
        ),

        // SliverGrid follows the SliverList section.
        SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Card(
              child: Center(child: Text('Grid $index')),
            ),
            childCount: 20,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
        ),

        // SliverFillRemaining — takes up all remaining space in the viewport.
        // Useful for a "load more" spinner or an empty-state illustration
        // pinned at the bottom.
        const SliverFillRemaining(
          hasScrollBody: false, // child is centered, not scrollable itself
          child: Center(child: Text('End of list')),
        ),
      ],
    );
  }
}

// ============================================================
// SLIVERLIST — lazy vertical list
// ============================================================
//
// SliverList.builder is the most common pattern. The delegate is called
// only for items that are visible (or about to become visible).
//
// SliverChildBuilderDelegate vs SliverChildListDelegate:
//   • Builder  — lazy; pass childCount for accurate scroll extent calculation.
//                Without childCount, Flutter cannot determine the total
//                scroll extent until the user scrolls to the end.
//   • List     — eager; like children:[] in ListView. Fine for short lists.

Widget sliverListExamples() {
  return CustomScrollView(
    slivers: [
      // ---- Builder delegate (preferred for long lists) ----
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            return ListTile(
              leading: CircleAvatar(child: Text('$index')),
              title: Text('Item $index'),
            );
          },
          childCount: 1000, // IMPORTANT: provide this for accurate scrollbar
          // addAutomaticKeepAlives: false — disable KeepAlive for items not
          //   currently visible (default: true). Set to false for very long
          //   lists to save memory.
          addAutomaticKeepAlives: false,
          // addRepaintBoundaries: true (default) wraps each item in
          //   RepaintBoundary for cheaper repaints.
        ),
      ),

      // ---- List delegate (for short, static lists) ----
      SliverList(
        delegate: SliverChildListDelegate([
          const ListTile(title: Text('Static item A')),
          const ListTile(title: Text('Static item B')),
        ]),
      ),

      // ---- SliverList.separated — adds separators between items ----
      SliverList.separated(
        itemBuilder: (context, index) => ListTile(title: Text('Sep $index')),
        separatorBuilder: (context, index) => const Divider(),
        itemCount: 10,
      ),
    ],
  );
}

// ============================================================
// SLIVERGRID — lazy grid
// ============================================================
//
// Two common grid delegates:
//
// SliverGridDelegateWithFixedCrossAxisCount
//   — Fixed number of columns. Item width = viewport / crossAxisCount.
//
// SliverGridDelegateWithMaxCrossAxisExtent
//   — Items have a max width; Flutter auto-calculates the column count.
//   — Great for responsive grids: on a phone you get 2 cols, on tablet 4 cols.

Widget sliverGridExamples(List<String> imageUrls) {
  return CustomScrollView(
    slivers: [
      // Fixed column count
      SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Image.network(imageUrls[index], fit: BoxFit.cover),
          childCount: imageUrls.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1.0, // width / height ratio of each cell
        ),
      ),

      // Max-extent grid (responsive)
      SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Card(child: Center(child: Text('$index'))),
          childCount: 30,
        ),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180, // each item is at most 180px wide
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          mainAxisExtent: 200, // fixed height for each item (optional)
        ),
      ),
    ],
  );
}

// ============================================================
// SLIVERAPPBAR — collapsing header
// ============================================================
//
// SliverAppBar is the most visually dramatic sliver. It must be inside a
// CustomScrollView; it cannot stand alone.
//
// Key parameters:
//
//   expandedHeight  — total height when fully expanded.
//   collapsedHeight — height when fully collapsed (defaults to toolbarHeight,
//                     which is kToolbarHeight = 56).
//   flexibleSpace   — the widget shown in the expanded region.
//                     FlexibleSpaceBar is the standard choice.
//
//   pinned:  true  — app bar stays visible at the top when collapsed.
//   floating: true — app bar reappears as soon as you scroll UP (even a little).
//   snap:    true  — requires floating:true. The bar snaps to fully
//                    expanded/collapsed rather than stopping mid-way.
//                    Nice UX for search bars.
//
// Combinations:
//   pinned:true,  floating:false → sticky header, collapses but never leaves
//   pinned:false, floating:false → scrolls away entirely
//   pinned:false, floating:true  → reappears on scroll-up, scrolls away on down
//   pinned:true,  floating:true  → always visible, but re-expands on scroll-up
//   pinned:true,  floating:true, snap:true → snaps to full/collapsed on scroll-up

Widget sliverAppBarExample() {
  return CustomScrollView(
    slivers: [
      SliverAppBar(
        expandedHeight: 250.0,
        pinned: true,
        floating: false,
        snap: false,
        // stretch: true — the expanded area stretches (overdraw) when the user
        // pulls past the top (iOS rubber-band effect). Pair with onStretchTrigger.
        stretch: true,
        onStretchTrigger: () async {
          // Called when the user stretches past the threshold (e.g., refresh).
        },
        flexibleSpace: FlexibleSpaceBar(
          title: const Text('My App'),
          // titlePadding controls where the title sits in the collapsed state.
          titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
          // centerTitle: collapseMode decides behavior of background and title.
          // CollapseMode.parallax — background scrolls slower than foreground.
          // CollapseMode.pin      — background stays fixed.
          // CollapseMode.none     — background scrolls with content.
          collapseMode: CollapseMode.parallax,
          background: Image.network(
            'https://picsum.photos/800/250',
            fit: BoxFit.cover,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),

      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => ListTile(title: Text('Item $index')),
          childCount: 40,
        ),
      ),
    ],
  );
}

// ============================================================
// SLIVERPERSISTENTHEADER — custom persistent/floating header
// ============================================================
//
// Use when you need a custom header that:
//   • Has a variable height (expands/collapses).
//   • Is not the app bar (e.g., a sticky section header in a chat app).
//
// You must provide a SliverPersistentHeaderDelegate.

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final double height;

  const _SectionHeaderDelegate({required this.title, this.height = 48});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // shrinkOffset: how many pixels the header has shrunk from maxExtent.
    // overlapsContent: true if the header is floating over content.
    //
    // Use shrinkOffset to animate between expanded and collapsed states.
    final progress = shrinkOffset / (maxExtent - minExtent);
    return Container(
      color: Color.lerp(Colors.blue, Colors.blueGrey, progress),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(title,
          style: const TextStyle(color: Colors.white, fontSize: 18)),
    );
  }

  // maxExtent — the header's fully expanded height.
  @override
  double get maxExtent => height;

  // minExtent — the collapsed height. Set equal to maxExtent for a
  // non-collapsing sticky header (like a section title).
  // Set smaller for a collapsing header.
  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(_SectionHeaderDelegate old) {
    return old.title != title || old.height != height;
  }

  // floating: true — the header re-appears as soon as the user scrolls up,
  // even if it was scrolled off screen.
  // pinned: true  — the header stays at the top even when scrolled past.
  // (These are set on SliverPersistentHeader, not on the delegate.)
}

Widget sliverPersistentHeaderExample() {
  return CustomScrollView(
    slivers: [
      SliverPersistentHeader(
        pinned: true,  // stays at top when scrolled past
        floating: false,
        delegate: const _SectionHeaderDelegate(title: 'Section A'),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => ListTile(title: Text('A-$i')),
          childCount: 10,
        ),
      ),
      SliverPersistentHeader(
        pinned: true,
        delegate: const _SectionHeaderDelegate(title: 'Section B'),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => ListTile(title: Text('B-$i')),
          childCount: 10,
        ),
      ),
    ],
  );
}

// ============================================================
// SLIVERTOBOXADAPTER — embed a Box widget in a sliver list
// ============================================================
//
// SliverToBoxAdapter is the bridge from Box → Sliver world.
// It wraps a single Box widget and adapts it to the sliver layout protocol.
//
// GOTCHA: Do NOT put scrollable Box widgets (ListView, GridView, SingleChildScrollView)
// inside SliverToBoxAdapter without explicit sizing. Nested scrollables with
// unbounded height cause layout errors. Instead:
//   • Use SliverList / SliverGrid for lists within the same scroll view.
//   • If you must nest a scrollable, give it an explicit SizedBox height or
//     use shrinkWrap: true (but shrinkWrap is slow for long lists).

Widget sliverToBoxAdapterExample() {
  return CustomScrollView(
    slivers: [
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Welcome banner', style: TextStyle(fontSize: 24)),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 120,
          child: ListView.builder(
            // Give this nested ListView an explicit height (via SizedBox)
            // and scrollDirection: horizontal to avoid the unbounded-height trap.
            scrollDirection: Axis.horizontal,
            itemCount: 10,
            itemBuilder: (ctx, i) => Card(
              child: SizedBox(
                width: 100,
                child: Center(child: Text('Card $i')),
              ),
            ),
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => ListTile(title: Text('Item $index')),
          childCount: 20,
        ),
      ),
    ],
  );
}

// ============================================================
// SLIVERFILLREMAINING and SLIVERFILLVIEWPORT
// ============================================================
//
// SliverFillRemaining — occupies all remaining space in the viewport
//   after other slivers have been laid out.
//   • hasScrollBody: false — child is non-scrollable, centered.
//   • hasScrollBody: true  — child is scrollable (default).
//   Common use: empty state illustration, loading spinner at the bottom.
//
// SliverFillViewport — each child occupies a full viewport height.
//   Like a vertical page view within a CustomScrollView.
//   • viewportFraction: 0.8 — each child is 80% of viewport (peek effect).

Widget fillSliverExamples() {
  return CustomScrollView(
    slivers: [
      SliverFillViewport(
        viewportFraction: 1.0, // each page fills the full viewport
        delegate: SliverChildBuilderDelegate(
          (context, index) => Container(
            color: index.isEven ? Colors.orange : Colors.purple,
            child: Center(child: Text('Page $index',
                style: const TextStyle(color: Colors.white, fontSize: 32))),
          ),
          childCount: 5,
        ),
      ),
    ],
  );
}

// ============================================================
// NESTEDSCROLLVIEW — collapsing app bar with tab views
// ============================================================
//
// NestedScrollView is the go-to solution for the common pattern:
//   • A SliverAppBar that collapses as you scroll.
//   • A TabBar pinned below the app bar.
//   • Each tab has its own scrollable list.
//
// The "outer" scroll view drives the app bar collapse.
// Each "inner" scroll view drives its own tab content.
// NestedScrollView coordinates them so the app bar collapses before
// the inner list starts scrolling, and re-expands correctly.
//
// GOTCHA: The inner scroll views must set:
//   physics: const ClampingScrollPhysics()
// on iOS, or the rubber-band physics fights with NestedScrollView.

class NestedScrollExample extends StatefulWidget {
  const NestedScrollExample({super.key});
  @override
  State<NestedScrollExample> createState() => _NestedScrollExampleState();
}

class _NestedScrollExampleState extends State<NestedScrollExample>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      // headerSliverBuilder builds the outer scroll area's header slivers.
      // `innerBoxIsScrolled` is true when the inner scroll view has content
      // above the visible area (useful for styling the pinned app bar).
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return [
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            floating: true,
            snap: true,
            // forceElevated: shows elevation shadow when innerBoxIsScrolled.
            // Without this, the app bar looks flat even when content is under it.
            forceElevated: innerBoxIsScrolled,
            flexibleSpace: const FlexibleSpaceBar(
              title: Text('Profile'),
              background: Placeholder(),
            ),
          ),
          // The TabBar is pinned below the collapsing header.
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Posts'),
                  Tab(text: 'Photos'),
                  Tab(text: 'Likes'),
                ],
              ),
            ),
          ),
        ];
      },

      // body is the inner scrollable content — here a TabBarView.
      body: TabBarView(
        controller: _tabController,
        children: List.generate(3, (tabIndex) {
          return ListView.builder(
            // IMPORTANT: Tell the inner scroll view to use its own scroll
            // position and to pass overflow scrolling to the outer view.
            // This is handled automatically by NestedScrollView, but you
            // must NOT override the physics unless you know what you're doing.
            itemCount: 30,
            itemBuilder: (context, index) {
              return ListTile(title: Text('Tab $tabIndex — Item $index'));
            },
          );
        }),
      ),
    );
  }
}

// Helper delegate to pin a TabBar as a SliverPersistentHeader.
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(_TabBarDelegate old) => old.tabBar != tabBar;
}

// ============================================================
// PERFORMANCE: WHY SLIVERS ARE FASTER THAN LISTVIEW FOR COMPLEX LAYOUTS
// ============================================================
//
// 1. Lazy build — only items in or near the viewport are built.
//    A SliverList with 10,000 items creates ~10 item widgets, not 10,000.
//
// 2. Composability — mixing a pinned header, grid, list, and footer in one
//    CustomScrollView shares a single scroll position and a single
//    ScrollPhysics instance. There is no nested scroll fighting.
//
// 3. No shrinkWrap overhead — ListView(shrinkWrap: true) inside a Column
//    must lay out ALL children to know its own height. SliverList never
//    needs to do this; it reports an estimate and refines lazily.
//
// 4. RepaintBoundaries — SliverChildBuilderDelegate wraps each item in a
//    RepaintBoundary by default (addRepaintBoundaries: true), so scrolling
//    does not force repaints of off-screen items.
//
// When to use ListView directly (instead of CustomScrollView + SliverList):
//   • Simple, single-section list with no custom app bar.
//   • Prototype / small list where the extra composability is not needed.
//   • You want pull-to-refresh via RefreshIndicator (wrap the ListView).
//     (RefreshIndicator does work with CustomScrollView too, but requires more setup.)
