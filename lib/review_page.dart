import 'package:flutter/material.dart';
import 'api_service.dart';

class ReviewPage extends StatefulWidget {
  final String orderId;
  final String sellerName;

  const ReviewPage({
    super.key,
    required this.orderId,
    required this.sellerName,
  });

  @override
  State<ReviewPage> createState() =>
      _ReviewPageState();
}

class _ReviewPageState
    extends State<ReviewPage> {
  int _rating = 0;

  final TextEditingController _commentController =
      TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating < 1 || _rating > 5) {
      _showMessage(
        'Selectează un rating de la 1 la 5.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ApiService.createReview(
        orderId: widget.orderId,
        rating: _rating,
        comment: _commentController.text,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'Evaluare trimisă',
            ),
            content: const Text(
              'Mulțumim! Evaluarea ta a fost adăugată.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Închide'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Evaluează vânzătorul',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      child: const Icon(
                        Icons.person_outline_rounded,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.sellerName,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Cum a fost experiența ta?',
                      style: TextStyle(
                        color:
                            colorScheme
                                .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Rating',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) {
                      final value = index + 1;

                      return IconButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                setState(() {
                                  _rating = value;
                                });
                              },
                        iconSize: 42,
                        icon: Icon(
                          value <= _rating
                              ? Icons.star_rounded
                              : Icons
                                  .star_border_rounded,
                          color: value <= _rating
                              ? Colors.amber
                              : colorScheme
                                  .onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: Text(
                  _rating == 0
                      ? 'Selectează un rating'
                      : _ratingLabel(_rating),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color:
                        colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Comentariu',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _commentController,
                enabled: !_isSubmitting,
                maxLines: 6,
                maxLength: 1000,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText:
                      'Scrie câteva cuvinte despre experiența ta...',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color:
                          colorScheme.outlineVariant,
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color:
                          colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : _submitReview,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                        ),
                  label: Text(
                    _isSubmitting
                        ? 'Se trimite...'
                        : 'Trimite evaluarea',
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: Text(
                  'Evaluarea poate fi trimisă doar pentru o comandă finalizată.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        colorScheme
                            .onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Foarte slab';
      case 2:
        return 'Slab';
      case 3:
        return 'Acceptabil';
      case 4:
        return 'Bun';
      case 5:
        return 'Excelent';
      default:
        return '';
    }
  }
}