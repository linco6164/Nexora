import 'package:flutter/material.dart';

import 'api_service.dart';
import 'models/listing.dart';
import 'listing_detail_page.dart';

class PublicProfilePage extends StatefulWidget {
  final String userId;

  const PublicProfilePage({
    super.key,
    required this.userId,
  });

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  late Future<Map<String, dynamic>> _profileFuture;

  Map<String, dynamic>? _reviewSummary;
  List<dynamic> _reviews = [];
  bool _loadingReviews = true;

  @override
  void initState() {
    super.initState();

    _profileFuture = _loadProfile();
    _loadReviews();
  }

  Future<Map<String, dynamic>> _loadProfile() async {
    return await ApiService.getPublicProfile(widget.userId);
  }

  Future<void> _loadReviews() async {
    try {
      final summary =
          await ApiService.getReviewSummary(widget.userId);

      final reviews =
          await ApiService.getSellerReviews(widget.userId);

      if (!mounted) return;

      setState(() {
        _reviewSummary = summary;
        _reviews = reviews;
        _loadingReviews = false;
      });
    } catch (e, stackTrace) {
      debugPrint('REVIEWS ERROR: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _loadingReviews = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _profileFuture = _loadProfile();
      _loadingReviews = true;
    });

    await Future.wait([
      _profileFuture,
      _loadReviews(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading(context);
          }

          if (snapshot.hasError) {
            return _buildError(context);
          }

          if (!snapshot.hasData) {
            return _buildError(context);
          }

          final profile = snapshot.data!;

          final user = Map<String, dynamic>.from(
            profile['user'] ?? {},
          );

          final stats = Map<String, dynamic>.from(
            profile['stats'] ?? {},
          );

          final rawListings = profile['listings'];

          final listings = <Listing>[];

          if (rawListings is List) {
            for (final item in rawListings) {
              if (item is Map) {
                try {
                  listings.add(
                    Listing.fromJson(
                      Map<String, dynamic>.from(item),
                    ),
                  );
                } catch (e) {
                  debugPrint(
                    'LISTING PARSE ERROR: $e',
                  );
                }
              }
            }
          }

          return RefreshIndicator(
            color: colors.primary,
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildAppBar(context, user),

                SliverToBoxAdapter(
                  child: _buildProfileHeader(
                    context,
                    user,
                    stats,
                  ),
                ),

                SliverToBoxAdapter(
                  child: _buildAbout(
                    context,
                    user,
                  ),
                ),

                SliverToBoxAdapter(
                  child: _buildStats(
                    context,
                    stats,
                  ),
                ),

                // REVIEWS
                SliverToBoxAdapter(
                  child: _buildReviewsSection(context),
                ),

                SliverToBoxAdapter(
                  child: _buildListingsHeader(
                    context,
                    listings.length,
                  ),
                ),

                if (listings.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildEmptyListings(context),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      40,
                    ),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _ListingCard(
                            listing: listings[index],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ListingDetailPage(
                                    listingId:
                                        listings[index].id,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        childCount: listings.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.70,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  Widget _buildAppBar(
    BuildContext context,
    Map<String, dynamic> user,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final username =
        user['username']?.toString().trim() ?? '';

    return SliverAppBar(
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: Text(
        username.isEmpty ? 'Profil' : username,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: _refresh,
          icon: Icon(
            Icons.refresh_rounded,
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _buildProfileHeader(
    BuildContext context,
    Map<String, dynamic> user,
    Map<String, dynamic> stats,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final username =
        user['username']?.toString().trim() ?? '';

    final fullName =
        user['fullName']?.toString().trim() ?? '';

    final avatar =
        user['avatar']?.toString().trim() ?? '';

    final city =
        user['city']?.toString().trim() ?? '';

    final country =
        user['country']?.toString().trim() ?? '';

    final bio =
        user['bio']?.toString().trim() ?? '';

    final listingsCount =
        _toInt(stats['listings']);

    final soldCount =
        _toInt(stats['sold']);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        0,
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor:
                colors.surfaceContainerHighest,
            backgroundImage: avatar.isNotEmpty
                ? NetworkImage(avatar)
                : null,
            child: avatar.isEmpty
                ? Icon(
                    Icons.person_rounded,
                    size: 48,
                    color: colors.onSurfaceVariant,
                  )
                : null,
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  username.isEmpty
                      ? 'Utilizator'
                      : username,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          if (fullName.isNotEmpty &&
              fullName != username) ...[
            const SizedBox(height: 4),
            Text(
              fullName,
              textAlign: TextAlign.center,
              style:
                  theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],

          if (city.isNotEmpty ||
              country.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 17,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    [
                      if (city.isNotEmpty) city,
                      if (country.isNotEmpty) country,
                    ].join(', '),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (bio.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              bio,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style:
                  theme.textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // RATING
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _ProfileMetric(
                  value: listingsCount.toString(),
                  label: 'Anunțuri',
                  icon: Icons.grid_view_rounded,
                ),
              ),
              Expanded(
                child: _ProfileMetric(
                  value: soldCount.toString(),
                  label: 'Vândute',
                  icon:
                      Icons.check_circle_outline_rounded,
                ),
              ),
              Expanded(
                child: _ProfileMetric(
                  value:
                      _reviewCount.toString(),
                  label: 'Evaluări',
                  icon: Icons.star_outline_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RATING SUMMARY
  // ============================================================

  double get _averageRating {
    final value =
        _reviewSummary?['averageRating'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  int get _reviewCount {
    final value =
        _reviewSummary?['count'];

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        _reviews.length;
  }

  // ============================================================
  // ABOUT
  // ============================================================

  Widget _buildAbout(
    BuildContext context,
    Map<String, dynamic> user,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final createdAt =
        user['createdAt']?.toString();

    if (createdAt == null ||
        createdAt.isEmpty) {
      return const SizedBox(height: 20);
    }

    DateTime? date;

    try {
      date = DateTime.parse(createdAt).toLocal();
    } catch (_) {}

    if (date == null) {
      return const SizedBox(height: 20);
    }

    final month =
        _monthName(date.month);

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        22,
        20,
        0,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest
              .withValues(alpha: 0.45),
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Membru Nexora din $month ${date.year}',
                style:
                    theme.textTheme.bodyMedium
                        ?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EXTRA STATS
  // ============================================================

  Widget _buildStats(
    BuildContext context,
    Map<String, dynamic> stats,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final favorites =
        _toInt(stats['favorites']);

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        0,
      ),
      child: Row(
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 18,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: 7),
          Text(
            '$favorites favorite',
            style:
                theme.textTheme.bodySmall
                    ?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REVIEWS
  // ============================================================

  Widget _buildReviewsSection(
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_loadingReviews) {
      return const Padding(
        padding: EdgeInsets.all(28),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final rating = _averageRating;
    final count = _reviewCount;

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        28,
        20,
        8,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Evaluări',
                  style:
                      theme.textTheme.titleLarge
                          ?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$count',
                style:
                    theme.textTheme.titleMedium
                        ?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors
                  .surfaceContainerHighest
                  .withValues(alpha: 0.45),
              borderRadius:
                  BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(width: 14),

                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _buildStars(
                      rating,
                      size: 21,
                    ),

                    const SizedBox(height: 4),

                    Text(
                      count == 1
                          ? '1 evaluare'
                          : '$count evaluări',
                      style: theme
                          .textTheme.bodySmall
                          ?.copyWith(
                        color:
                            colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          if (_reviews.isEmpty)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors
                    .surfaceContainerHighest
                    .withValues(alpha: 0.30),
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.star_border_rounded,
                    size: 38,
                    color:
                        colors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nu există încă evaluări',
                    style: theme
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._reviews.map(
              (review) {
                if (review is Map) {
                  return _buildReviewCard(
                    context,
                    Map<String, dynamic>.from(
                      review,
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStars(
    double rating, {
    double size = 18,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) {
          final position = index + 1;

          IconData icon;

          if (rating >= position) {
            icon = Icons.star_rounded;
          } else if (rating >= position - 0.5) {
            icon = Icons.star_half_rounded;
          } else {
            icon = Icons.star_outline_rounded;
          }

          return Icon(
            icon,
            color: Colors.amber,
            size: size,
          );
        },
      ),
    );
  }

  Widget _buildReviewCard(
    BuildContext context,
    Map<String, dynamic> review,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final reviewer = review['reviewer'];

    String username = 'Utilizator';
    String avatar = '';

    if (reviewer is Map) {
      username =
          reviewer['username']?.toString() ??
              'Utilizator';

      avatar =
          reviewer['avatar']?.toString() ?? '';
    }

    final rating =
        _toInt(review['rating']);

    final comment =
        review['comment']?.toString().trim() ?? '';

    final createdAt =
        review['createdAt']?.toString();

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant
              .withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor:
                    colors.surfaceContainerHighest,
                backgroundImage:
                    avatar.isNotEmpty
                        ? NetworkImage(avatar)
                        : null,
                child: avatar.isEmpty
                    ? Icon(
                        Icons.person_rounded,
                        color:
                            colors.onSurfaceVariant,
                      )
                    : null,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: theme
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        _buildStars(
                          rating.toDouble(),
                          size: 16,
                        ),

                        if (createdAt != null &&
                            createdAt.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            _formatReviewDate(
                              createdAt,
                            ),
                            style: theme
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                              color: colors
                                  .onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (comment.isNotEmpty) ...[
            const SizedBox(height: 13),
            Text(
              comment,
              style: theme
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatReviewDate(
    String value,
  ) {
    final date = DateTime.tryParse(value);

    if (date == null) {
      return '';
    }

    final localDate = date.toLocal();

    final difference =
        DateTime.now().difference(localDate);

    if (difference.inMinutes < 1) {
      return 'acum';
    }

    if (difference.inHours < 1) {
      return '${difference.inMinutes} min';
    }

    if (difference.inDays < 1) {
      return '${difference.inHours} h';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} zile';
    }

    return '${localDate.day.toString().padLeft(2, '0')}.'
        '${localDate.month.toString().padLeft(2, '0')}.'
        '${localDate.year}';
  }

  // ============================================================
  // LISTINGS
  // ============================================================

  Widget _buildListingsHeader(
    BuildContext context,
    int count,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        28,
        20,
        14,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Anunțurile lui',
              style:
                  theme.textTheme.titleLarge
                      ?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '$count',
            style:
                theme.textTheme.titleMedium
                    ?.copyWith(
              fontWeight: FontWeight.w700,
              color:
                  theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyListings(
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        30,
        20,
        80,
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color:
                  colors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 32,
              color:
                  colors.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Nu are anunțuri active',
            style:
                theme.textTheme.titleMedium
                    ?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Acest utilizator nu are momentan produse disponibile.',
            textAlign: TextAlign.center,
            style:
                theme.textTheme.bodyMedium
                    ?.copyWith(
              color:
                  colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING / ERROR
  // ============================================================

  Widget _buildLoading(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Profil'),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Profil'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 56,
                color:
                    colors.onSurfaceVariant,
              ),

              const SizedBox(height: 16),

              Text(
                'Profilul nu a putut fi încărcat.',
                textAlign: TextAlign.center,
                style: theme
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 16),

              FilledButton.icon(
                onPressed: _refresh,
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
                label: const Text(
                  'Încearcă din nou',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  int _toInt(dynamic value) {
    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String _monthName(int month) {
    const months = [
      'ianuarie',
      'februarie',
      'martie',
      'aprilie',
      'mai',
      'iunie',
      'iulie',
      'august',
      'septembrie',
      'octombrie',
      'noiembrie',
      'decembrie',
    ];

    if (month < 1 || month > 12) {
      return '';
    }

    return months[month - 1];
  }
}

// ============================================================
// PROFILE METRIC
// ============================================================

class _ProfileMetric extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _ProfileMetric({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: colors.primary,
        ),

        const SizedBox(height: 6),

        Text(
          value,
          style: theme.textTheme.titleMedium
              ?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          label,
          style: theme.textTheme.bodySmall
              ?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// LISTING CARD
// ============================================================

class _ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;

  const _ListingCard({
    required this.listing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final image = listing.images.isNotEmpty
        ? listing.images.first
        : null;

    return Material(
      color: colors.surface,
      borderRadius:
          BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (image != null)
                    Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) {
                        return Container(
                          color: colors
                              .surfaceContainerHighest,
                          child: Icon(
                            Icons
                                .image_not_supported_outlined,
                            color: colors
                                .onSurfaceVariant,
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      color: colors
                          .surfaceContainerHighest,
                      child: Icon(
                        Icons.image_outlined,
                        size: 34,
                        color: colors
                            .onSurfaceVariant,
                      ),
                    ),

                  if (listing.negotiable)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration:
                            BoxDecoration(
                          color: colors.surface
                              .withValues(alpha: 0.92),
                          borderRadius:
                              BorderRadius.circular(
                            8,
                          ),
                        ),
                        child: Text(
                          'Negociabil',
                          style: theme
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              flex: 3,
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  10,
                  9,
                  10,
                  8,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: theme
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const Spacer(),

                    Text(
                      '${listing.price.toStringAsFixed(2)} ${listing.currency}',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: theme
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w800,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}