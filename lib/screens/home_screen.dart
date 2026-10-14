import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/brand.dart';
import '../widgets/form_widgets.dart';

// ------------------------------------------------------------------- helpers

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts[1][0]).toUpperCase();
}

Map<String, dynamic> prefsOf(Map<String, dynamic>? data) =>
    (data?['preferences'] as Map<String, dynamic>?) ?? <String, dynamic>{};

int profilePercent(String name, String email, Map<String, dynamic>? data) {
  final prefs = prefsOf(data);
  String p(String k) => ((prefs[k] as String?) ?? '').trim();
  final filled = [name, email, p('studyLevel'), p('funding'), p('countries'), p('subject')]
      .where((s) => s.trim().isNotEmpty)
      .length;
  return (filled / 6 * 100).round();
}

// ------------------------------------------------------------- sample data

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

class _Scholarship {
  _Scholarship({
    required this.id,
    required this.code,
    required this.country,
    required this.title,
    required this.level,
    required this.funding,
    required this.date,
    required this.tileBg,
    required this.tileFg,
  });

  final String id;
  final String code;
  final String country;
  final String title;
  final String level;
  final String funding;
  final DateTime date;
  final Color tileBg;
  final Color tileFg;

  String get deadline =>
      '${date.day.toString().padLeft(2, '0')} ${_months[date.month - 1]}';
}

// Sample data for now. Later this will come from Firestore.
final _scholarships = <_Scholarship>[
  _Scholarship(
    id: 'bologna',
    code: 'IT',
    country: 'Italy',
    title: 'University of Bologna Scholarship',
    level: "Master's",
    funding: 'Fully Funded',
    date: DateTime(2026, 12, 20),
    tileBg: const Color(0xFFFDE8E6),
    tileFg: const Color(0xFFC0504A),
  ),
  _Scholarship(
    id: 'chevening',
    code: 'GB',
    country: 'United Kingdom',
    title: 'Chevening Scholarship',
    level: "Master's",
    funding: 'Fully Funded',
    date: DateTime(2026, 11, 5),
    tileBg: const Color(0xFFE6EEFB),
    tileFg: const Color(0xFF2F5DA8),
  ),
  _Scholarship(
    id: 'daad',
    code: 'DE',
    country: 'Germany',
    title: 'DAAD Scholarship',
    level: "Master's",
    funding: 'Fully Funded',
    date: DateTime(2026, 11, 15),
    tileBg: const Color(0xFFFFF3D6),
    tileFg: const Color(0xFF9A6A00),
  ),
  _Scholarship(
    id: 'pm-award',
    code: 'BD',
    country: 'Bangladesh',
    title: 'Prime Minister Education Award',
    level: 'Undergraduate',
    funding: 'Partial Funding',
    date: DateTime(2026, 12, 20),
    tileBg: const Color(0xFFE3F4EC),
    tileFg: AppColors.forest,
  ),
];

// --------------------------------------------------------------- HomeScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _tab = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocus.requestFocus());
  }

  Future<void> _toggleSave(String uid, String id, bool isSaved) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'saved': isSaved ? FieldValue.arrayRemove([id]) : FieldValue.arrayUnion([id]),
      }, SetOptions(merge: true));
    } catch (_) {
      if (mounted) showMessage(context, 'Could not update saved list.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data();
        final name = (data?['name'] as String?) ?? user.displayName ?? 'Student';
        final email = user.email ?? '';
        final saved = ((data?['saved'] as List?) ?? const <dynamic>[])
            .map((e) => e.toString())
            .toSet();
        void toggleSave(String id) => _toggleSave(user.uid, id, saved.contains(id));

        final pages = <Widget>[
          _HomeTab(
            name: name,
            percent: profilePercent(name, email, data),
            onComplete: () => _showEditProfile(
              context,
              uid: user.uid,
              name: name,
              prefs: prefsOf(data),
            ),
            onSearch: _openSearch,
            saved: saved,
            onToggleSave: toggleSave,
          ),
          _SearchTab(
            focusNode: _searchFocus,
            saved: saved,
            onToggleSave: toggleSave,
          ),
          const _PlaceholderTab(icon: Icons.bookmark_border_rounded, title: 'Saved'),
          _ProfileTab(
            uid: user.uid,
            data: data,
            name: name,
            email: email,
            onLogout: () => FirebaseAuth.instance.signOut(),
          ),
        ];

        return Scaffold(
          body: SafeArea(child: IndexedStack(index: _tab, children: pages)),
          bottomNavigationBar: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: Colors.white,
              indicatorColor: AppColors.mint,
              elevation: 0,
              labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: s.contains(WidgetState.selected)
                        ? AppColors.forest
                        : AppColors.muted,
                  )),
              iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
                    color: s.contains(WidgetState.selected)
                        ? AppColors.forest
                        : AppColors.muted,
                  )),
            ),
            child: NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Home'),
                NavigationDestination(
                    icon: Icon(Icons.search_rounded),
                    selectedIcon: Icon(Icons.search_rounded),
                    label: 'Search'),
                NavigationDestination(
                    icon: Icon(Icons.bookmark_border_rounded),
                    selectedIcon: Icon(Icons.bookmark_rounded),
                    label: 'Saved'),
                NavigationDestination(
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: 'Profile'),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- small parts

class _Avatar extends StatelessWidget {
  const _Avatar(this.text, {this.size = 44, this.fill = AppColors.forest});
  final String text;
  final double size;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFBFE6D4), width: 3),
      ),
      child: Text(text,
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.34)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.overline, this.title, {this.action, this.onAction});
  final String overline;
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(overline,
                  style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted)),
              const SizedBox(height: 4),
              Text(title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            ],
          ),
        ),
        if (action != null)
          InkWell(
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Text(action!,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.forest)),
            ),
          ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard(this.icon, this.label, this.count);
  final IconData icon;
  final String label;
  final String count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: AppColors.mint, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.forest, size: 20),
          ),
          const SizedBox(height: 14),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(count,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, {required this.bg, required this.fg});
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: AppColors.mint, borderRadius: BorderRadius.circular(8)),
      child: const Text('✓ VERIFIED',
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.forest)),
    );
  }
}

class _BookmarkButton extends StatelessWidget {
  const _BookmarkButton({required this.saved, required this.onTap});
  final bool saved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
            color: AppColors.mint, borderRadius: BorderRadius.circular(14)),
        child: Icon(
          saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          color: AppColors.forest,
          size: 22,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(this.label, {required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.forest : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.forest : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? Colors.white : AppColors.ink)),
      ),
    );
  }
}

// ------------------------------------------------------- featured scholarships

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard(this.s, {required this.saved, required this.onToggle});
  final _Scholarship s;
  final bool saved;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: s.tileBg, borderRadius: BorderRadius.circular(14)),
                child: Text(s.code,
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800, color: s.tileFg)),
              ),
              const Spacer(),
              _BookmarkButton(saved: saved, onTap: onToggle),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Flexible(
                child: Text(s.country.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest)),
              ),
              const SizedBox(width: 8),
              const _VerifiedBadge(),
            ],
          ),
          const SizedBox(height: 8),
          Text(s.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, height: 1.25)),
          const Spacer(),
          Row(
            children: [
              _Chip(s.level, bg: const Color(0xFFF0F2F1), fg: AppColors.muted),
              const SizedBox(width: 8),
              Flexible(child: _Chip(s.funding, bg: AppColors.mint, fg: AppColors.forest)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 16, color: AppColors.muted),
              const SizedBox(width: 6),
              const Text('Deadline',
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
              const Spacer(),
              Text(s.deadline,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------- upcoming deadlines

class _DeadlineRow extends StatelessWidget {
  const _DeadlineRow(this.s);
  final _Scholarship s;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 52,
            decoration: BoxDecoration(
                color: AppColors.mint, borderRadius: BorderRadius.circular(14)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(s.date.day.toString().padLeft(2, '0'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.forest)),
                Text(_months[s.date.month - 1].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.forest)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text('${s.country} · ${s.level}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}

// ------------------------------------------------------- complete profile card

class _CompleteProfileCard extends StatelessWidget {
  const _CompleteProfileCard({required this.percent, required this.onTap});
  final int percent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF083D2D),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_outline_rounded,
                    color: Colors.white, size: 21),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Complete your profile',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: 2),
                    Text('Get scholarship matches made for you.',
                        style: TextStyle(color: Color(0xFFBFE6D4), fontSize: 12)),
                  ],
                ),
              ),
              Text('$percent%',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF5FD4A0)),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.forest,
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Complete profile'),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ Home tab

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.name,
    required this.percent,
    required this.onComplete,
    required this.onSearch,
    required this.saved,
    required this.onToggleSave,
  });

  final String name;
  final int percent;
  final VoidCallback onComplete;
  final VoidCallback onSearch;
  final Set<String> saved;
  final void Function(String id) onToggleSave;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'GOOD MORNING,';
    if (h < 17) return 'GOOD AFTERNOON,';
    return 'GOOD EVENING,';
  }

  @override
  Widget build(BuildContext context) {
    const pad = EdgeInsets.symmetric(horizontal: 20);
    final featured = _scholarships.take(3).toList();
    final byDate = [..._scholarships]..sort((a, b) => a.date.compareTo(b.date));
    final upcoming = byDate.take(3).toList();

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.mint, Colors.white],
          stops: [0, 0.4],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        children: [
          // Top bar: logo + bell
          Padding(
            padding: pad,
            child: Row(
              children: [
                const BrandMark(size: 40),
                const SizedBox(width: 10),
                const BrandName(size: 22),
                const Spacer(),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.notifications_none_rounded, size: 22),
                    ),
                    Positioned(
                      top: 9,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: Color(0xFFE5484D), shape: BoxShape.circle),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),

          // Greeting + avatar
          Padding(
            padding: pad,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting,
                    style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5)),
                    ),
                    _Avatar(initialsOf(name)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Search bar (tap = go to Search tab)
          Padding(
            padding: pad,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSearch,
              child: Container(
                height: 54,
                padding: const EdgeInsets.only(left: 16, right: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColors.muted),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Search scholarships, countries...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppColors.muted, fontSize: 14)),
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                          color: AppColors.forest,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Categories
          const Padding(
            padding: pad,
            child: _SectionTitle('EXPLORE OPPORTUNITIES', 'Scholarship categories'),
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: pad,
            child: Row(
              children: [
                Expanded(
                    child: _CategoryCard(
                        Icons.verified_user_outlined, 'Fully Funded', '184 scholarships')),
                SizedBox(width: 10),
                Expanded(
                    child: _CategoryCard(
                        Icons.description_outlined, "Master's", '243 scholarships')),
                SizedBox(width: 10),
                Expanded(
                    child: _CategoryCard(
                        Icons.public_rounded, 'International', '42 countries')),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Featured scholarships (scrolls sideways)
          Padding(
            padding: pad,
            child: _SectionTitle('SELECTED FOR YOU', 'Featured scholarships',
                action: 'See all', onAction: onSearch),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 262,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: pad,
              itemCount: featured.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _FeaturedCard(
                featured[i],
                saved: saved.contains(featured[i].id),
                onToggle: () => onToggleSave(featured[i].id),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Upcoming deadlines
          Padding(
            padding: pad,
            child: _SectionTitle("DON'T MISS OUT", 'Upcoming deadlines',
                action: 'View all', onAction: onSearch),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: pad,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < upcoming.length; i++) ...[
                    if (i > 0) const Divider(height: 1, color: AppColors.border),
                    _DeadlineRow(upcoming[i]),
                  ],
                ],
              ),
            ),
          ),

          // Complete profile card
          if (percent < 100) ...[
            const SizedBox(height: 24),
            Padding(
              padding: pad,
              child: _CompleteProfileCard(percent: percent, onTap: onComplete),
            ),
          ],
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- Search tab

class _SearchCard extends StatelessWidget {
  const _SearchCard(this.s, {required this.saved, required this.onToggle});
  final _Scholarship s;
  final bool saved;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: s.tileBg, borderRadius: BorderRadius.circular(14)),
            child: Text(s.code,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800, color: s.tileFg)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(s.country.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11,
                              letterSpacing: 0.6,
                              fontWeight: FontWeight.w800,
                              color: AppColors.forest)),
                    ),
                    const SizedBox(width: 8),
                    const _VerifiedBadge(),
                    const Spacer(),
                    _BookmarkButton(saved: saved, onTap: onToggle),
                  ],
                ),
                Text(s.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, height: 1.25)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _Chip(s.level, bg: const Color(0xFFF0F2F1), fg: AppColors.muted),
                    _Chip(s.funding, bg: AppColors.mint, fg: AppColors.forest),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 16, color: AppColors.muted),
                    const SizedBox(width: 6),
                    const Text('Deadline',
                        style: TextStyle(fontSize: 12, color: AppColors.muted)),
                    const Spacer(),
                    Text(s.deadline,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchTab extends StatefulWidget {
  const _SearchTab({
    required this.focusNode,
    required this.saved,
    required this.onToggleSave,
  });

  final FocusNode focusNode;
  final Set<String> saved;
  final void Function(String id) onToggleSave;

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  final _controller = TextEditingController();
  String? _country;
  String? _level;
  String? _funding;
  bool _byDeadline = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _activeFilters => [_country, _level, _funding].where((e) => e != null).length;

  List<_Scholarship> get _results {
    final q = _controller.text.trim().toLowerCase();
    final list = _scholarships.where((s) {
      if (_country != null && s.country != _country) return false;
      if (_level != null && s.level != _level) return false;
      if (_funding != null && s.funding != _funding) return false;
      if (q.isEmpty) return true;
      return '${s.title} ${s.country} ${s.level} ${s.funding}'.toLowerCase().contains(q);
    }).toList();
    if (_byDeadline) list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  void _clearFilters() => setState(() {
        _country = null;
        _level = null;
        _funding = null;
      });

  Future<void> _openFilters() async {
    String? country = _country;
    String? level = _level;
    String? funding = _funding;
    final countries = _scholarships.map((s) => s.country).toSet().toList();
    final levels = _scholarships.map((s) => s.level).toSet().toList();
    final fundings = _scholarships.map((s) => s.funding).toSet().toList();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Widget group(
              String title, List<String> options, String? value, void Function(String?) pick) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final o in options)
                      _FilterChip(
                        o,
                        selected: value == o,
                        onTap: () => setSheet(() => pick(value == o ? null : o)),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            );
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
                24, 22, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Filters',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      ),
                      TextButton(
                        onPressed: () => setSheet(() {
                          country = null;
                          level = null;
                          funding = null;
                        }),
                        child: const Text('Clear all',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, color: AppColors.forest)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  group('Country', countries, country, (v) => country = v),
                  group('Study level', levels, level, (v) => level = v),
                  group('Funding', fundings, funding, (v) => funding = v),
                  PrimaryButton(
                    label: 'Show results',
                    onPressed: () {
                      setState(() {
                        _country = country;
                        _level = level;
                        _funding = funding;
                      });
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        // Top bar
        Row(
          children: [
            const BrandMark(size: 40),
            const Expanded(
              child: Center(
                child: Text('Find scholarships',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
        const SizedBox(height: 18),

        // Search field + filter button
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: widget.focusNode,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search scholarships...',
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: AppColors.muted, size: 22),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: AppColors.muted, size: 20),
                          onPressed: () => setState(_controller.clear),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _openFilters,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.forest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Colors.white, size: 24),
                  ),
                  if (_activeFilters > 0)
                    Positioned(
                      top: -5,
                      right: -5,
                      child: Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                            color: Color(0xFFE5484D), shape: BoxShape.circle),
                        child: Text('$_activeFilters',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Quick filters
        const Text('Quick filters',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip('All', selected: _activeFilters == 0, onTap: _clearFilters),
              const SizedBox(width: 8),
              _FilterChip('Italy',
                  selected: _country == 'Italy',
                  onTap: () => setState(
                      () => _country = _country == 'Italy' ? null : 'Italy')),
              const SizedBox(width: 8),
              _FilterChip("Master's",
                  selected: _level == "Master's",
                  onTap: () => setState(
                      () => _level = _level == "Master's" ? null : "Master's")),
              const SizedBox(width: 8),
              _FilterChip('Fully Funded',
                  selected: _funding == 'Fully Funded',
                  onTap: () => setState(() =>
                      _funding = _funding == 'Fully Funded' ? null : 'Fully Funded')),
            ],
          ),
        ),
        const SizedBox(height: 26),

        // Heading
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recommended for you',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                  const SizedBox(height: 4),
                  Text(
                    '${results.length} ${results.length == 1 ? 'scholarship' : 'scholarships'} found',
                    style: const TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() => _byDeadline = !_byDeadline);
                showMessage(
                    context,
                    _byDeadline
                        ? 'Sorted by nearest deadline.'
                        : 'Sorted by recommended order.');
              },
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.settings_outlined,
                    size: 22,
                    color: _byDeadline ? AppColors.forest : AppColors.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Results
        if (results.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                const Icon(Icons.search_off_rounded, size: 44, color: AppColors.forest),
                const SizedBox(height: 12),
                const Text('No scholarships found',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Try a different word or clear your filters.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13)),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () {
                    _controller.clear();
                    _clearFilters();
                  },
                  child: const Text('Clear search and filters',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, color: AppColors.forest)),
                ),
              ],
            ),
          )
        else
          for (final s in results)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _SearchCard(
                s,
                saved: widget.saved.contains(s.id),
                onToggle: () => widget.onToggleSave(s.id),
              ),
            ),
      ],
    );
  }
}

// ----------------------------------------------------------- other tabs

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: AppColors.forest),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Coming soon', style: TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Profile tab

Future<void> _showEditProfile(
  BuildContext context, {
  required String uid,
  required String name,
  required Map<String, dynamic> prefs,
}) async {
  String p(String k) => (prefs[k] as String?) ?? '';
  final nameC = TextEditingController(text: name);
  final levelC = TextEditingController(text: p('studyLevel'));
  final fundingC = TextEditingController(text: p('funding'));
  final countriesC = TextEditingController(text: p('countries'));
  final subjectC = TextEditingController(text: p('subject'));

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit profile',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Full name',
              hint: 'Enter your full name',
              controller: nameC,
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Study level',
              hint: "e.g. Master's",
              controller: levelC,
              icon: Icons.school_outlined,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Funding',
              hint: 'e.g. Fully Funded',
              controller: fundingC,
              icon: Icons.payments_outlined,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Countries',
              hint: 'e.g. Italy, Germany',
              controller: countriesC,
              icon: Icons.public_rounded,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Subject',
              hint: 'e.g. Computer Science',
              controller: subjectC,
              icon: Icons.menu_book_outlined,
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'Save',
              onPressed: () async {
                final newName = nameC.text.trim();
                if (newName.isEmpty) {
                  showMessage(ctx, 'Name cannot be empty.', error: true);
                  return;
                }
                try {
                  await FirebaseFirestore.instance.collection('users').doc(uid).set({
                    'name': newName,
                    'preferences': {
                      'studyLevel': levelC.text.trim(),
                      'funding': fundingC.text.trim(),
                      'countries': countriesC.text.trim(),
                      'subject': subjectC.text.trim(),
                    },
                  }, SetOptions(merge: true));
                  await FirebaseAuth.instance.currentUser?.updateDisplayName(newName);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                } catch (_) {
                  if (ctx.mounted) {
                    showMessage(ctx, 'Could not save. Please try again.', error: true);
                  }
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _PrefTile extends StatelessWidget {
  const _PrefTile(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final empty = value.isEmpty;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(empty ? 'Not set' : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: empty ? AppColors.muted : AppColors.ink)),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile(this.icon, this.title, this.subtitle, {required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: AppColors.mint, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.forest, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.uid,
    required this.data,
    required this.name,
    required this.email,
    required this.onLogout,
  });

  final String uid;
  final Map<String, dynamic>? data;
  final String name;
  final String email;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final prefs = prefsOf(data);
    String pref(String k) => ((prefs[k] as String?) ?? '').trim();
    final level = pref('studyLevel');
    final funding = pref('funding');
    final countries = pref('countries');
    final subject = pref('subject');
    final percent = profilePercent(name, email, data);
    final isAdmin = data?['role'] == 'admin';

    void edit() => _showEditProfile(context, uid: uid, name: name, prefs: prefs);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        // Top bar: logo, title, settings
        Row(
          children: [
            const BrandMark(size: 40),
            const Expanded(
              child: Center(
                child: Text('Profile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => showMessage(context, 'Settings coming soon.'),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.settings_outlined, size: 21),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Green profile card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF083D2D),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              _Avatar(initialsOf(name), size: 64, fill: const Color(0xFF2E8B6A)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFBFE6D4), fontSize: 13)),
                    const SizedBox(height: 6),
                    Text('✓  Profile $percent% complete',
                        style: const TextStyle(color: Color(0xFFBFE6D4), fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: edit,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Scholarship preferences
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('YOUR INTERESTS',
                            style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w700,
                                color: AppColors.muted)),
                        SizedBox(height: 4),
                        Text('Scholarship preferences',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3)),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: edit,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      child: Text('Edit',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.forest)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _PrefTile('Study level', level)),
                  const SizedBox(width: 10),
                  Expanded(child: _PrefTile('Funding', funding)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _PrefTile('Countries', countries)),
                  const SizedBox(width: 10),
                  Expanded(child: _PrefTile('Subject', subject)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Menu list
        Material(
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Column(
            children: [
              _MenuTile(Icons.person_outline_rounded, 'Personal information',
                  'Name, email and education',
                  onTap: edit),
              const Divider(height: 1, color: AppColors.border),
              _MenuTile(Icons.notifications_none_rounded, 'Notifications',
                  'Deadline reminders and updates',
                  onTap: () => showMessage(context, 'Notifications coming soon.')),
              if (isAdmin) ...[
                const Divider(height: 1, color: AppColors.border),
                _MenuTile(Icons.verified_user_outlined, 'Admin dashboard',
                    'Manage scholarships and deadlines',
                    onTap: () => showMessage(context, 'Admin dashboard coming soon.')),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Log out
        Material(
          color: const Color(0xFFFDEEEE),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onLogout,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF5D0D0)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: Color(0xFF9B2C2C), size: 20),
                  SizedBox(width: 8),
                  Text('Log out',
                      style: TextStyle(
                          color: Color(0xFF9B2C2C),
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Center(
          child: Text('ScholarKhoj v1.0 · Student project',
              style: TextStyle(fontSize: 11, color: AppColors.muted)),
        ),
      ],
    );
  }
}