import 'package:flutter/material.dart';

import 'api_service.dart';

class MyReviewsPage extends StatefulWidget {
  const MyReviewsPage({super.key});

  @override
  State<MyReviewsPage> createState() => _MyReviewsPageState();
}

class _MyReviewsPageState extends State<MyReviewsPage> {
  List<dynamic> _reviews = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final profile = await ApiService.getProfile();

      final user = profile['user'];

      final userId = user is Map ? user['_id']?.toString() : null;

      if (userId == null || userId.isEmpty) {
        throw Exception('Nu s-a putut identifica utilizatorul.');
      }

      final reviews = await ApiService.getSellerReviews(userId);

      if (!mounted) return;

      setState(() {
        _reviews = reviews;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evaluările mele')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }

    if (_reviews.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rate_review_outlined, size: 64),
            SizedBox(height: 16),
            Text(
              'Nu ai primit încă evaluări.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReviews,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _reviews.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final review = Map<String, dynamic>.from(_reviews[index]);

          final reviewer = review['reviewer'] is Map
              ? Map<String, dynamic>.from(review['reviewer'])
              : <String, dynamic>{};

          final rating = (review['rating'] ?? 0).toInt();

          final comment = review['comment']?.toString() ?? '';

          final username = reviewer['username']?.toString() ?? 'Utilizator';

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: reviewer['avatar'] != null
                            ? NetworkImage(reviewer['avatar'].toString())
                            : null,
                        child: reviewer['avatar'] == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          username,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      _buildStars(rating),
                    ],
                  ),
                  if (comment.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(comment),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 19,
          color: Colors.amber,
        ),
      ),
    );
  }
}
