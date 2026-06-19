import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/business_model.dart';
import '../../models/review_model.dart';
import '../../repositories/review_repository.dart';
import '../../services/maps_sim_service.dart';
import '../../services/supabase_data_service.dart';

class BusinessDetailScreen extends StatefulWidget {
  const BusinessDetailScreen({super.key, this.businessId = 'biz-001'});

  static const routeName = '/business/:id';

  final String businessId;

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  final _dataService = SupabaseDataService();
  final _mapsService = MapsSimService();

  BusinessModel? _business;
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDetail());
  }

  Future<void> _loadDetail() async {
    final business = await _dataService.getBusinessById(widget.businessId);
    final reviews = await _dataService.getReviewsForBusiness(
      widget.businessId,
    );

    if (!mounted) return;

    setState(() {
      _business = business;
      _reviews = reviews;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final business = _business;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (business == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Entreprise introuvable.')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _BusinessCoverAppBar(business: business),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BusinessHeader(business: business),
                  const SizedBox(height: 18),
                  _ActionButtons(
                    isFavorite: _isFavorite,
                    onFavoriteToggle: () {
                      setState(() => _isFavorite = !_isFavorite);
                    },
                  ),
                  const SizedBox(height: 26),
                  _PhotoGallery(
                    imageUrls: [business.imageUrl, ...business.galleryUrls],
                  ),
                  const SizedBox(height: 28),
                  _AboutSection(business: business),
                  const SizedBox(height: 28),
                  _ServicesSection(services: business.services),
                  const SizedBox(height: 28),
                  _ReviewsSection(businessId: business.id, reviews: _reviews),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/home/reviews/${business.id}'),
        icon: const Icon(Icons.rate_review_rounded),
        label: const Text('Laisser un avis'),
      ),
    );
  }
}

class _BusinessCoverAppBar extends StatelessWidget {
  const _BusinessCoverAppBar({required this.business});

  final BusinessModel business;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      actions: [
        IconButton.filledTonal(
          tooltip: 'Partager',
          onPressed: () {},
          icon: const Icon(Icons.ios_share_rounded),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'business-cover-${business.id}',
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                business.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return ColoredBox(
                    color: colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.storefront_rounded, size: 54),
                  );
                },
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusinessHeader extends StatelessWidget {
  const _BusinessHeader({required this.business});

  final BusinessModel business;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          business.name,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          business.categoryName,
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _RatingStars(rating: business.rating),
            Text(
              '${business.rating.toStringAsFixed(1)} (${business.reviewCount} avis)',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            _OpenStatusPill(isOpen: business.isOpen),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.place_outlined, color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                business.address,
                style: textTheme.bodyMedium?.copyWith(height: 1.35),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.call_rounded,
            label: 'Appeler',
            onPressed: () {},
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            icon: Icons.directions_rounded,
            label: 'Itineraire',
            onPressed: () {},
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            icon: isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            label: 'Favoris',
            onPressed: onFavoriteToggle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            icon: Icons.ios_share_rounded,
            label: 'Partager',
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _PhotoGallery extends StatelessWidget {
  const _PhotoGallery({required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Galerie photos'),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: imageUrls.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final imageUrl = imageUrls[index];
              return GestureDetector(
                onTap: () => _openPhotoViewer(context, imageUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 148,
                    height: 106,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openPhotoViewer(BuildContext context, String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog.fullscreen(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(imageUrl, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.business});

  final BusinessModel business;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'A propos'),
        const SizedBox(height: 8),
        Text(
          business.description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 10),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          title: const Text('Horaires'),
          children: business.openingHours.entries.map((entry) {
            String displayValue;
            final val = entry.value;
            if (val is String) {
              displayValue = val;
            } else if (val is Map) {
              if (val['isOpen'] == true) {
                displayValue = '${val['open']} - ${val['close']}';
              } else {
                displayValue = 'Fermé';
              }
            } else {
              displayValue = val.toString();
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(child: Text(entry.key)),
                  Text(
                    displayValue,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ServicesSection extends StatelessWidget {
  const _ServicesSection({required this.services});

  final List<Map<String, String>> services;

  @override
  Widget build(BuildContext context) {
    final fallbackServices = services.isEmpty
        ? [
            {'name': 'Consultation', 'price': '25 000 Ar'},
            {'name': 'Service standard', 'price': '45 000 Ar'},
            {'name': 'Service premium', 'price': 'Sur devis'},
          ]
        : services;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Services'),
        const SizedBox(height: 10),
        ...fallbackServices.map((service) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.check_circle_outline_rounded),
            title: Text(service['name'] ?? ''),
            trailing: Text(
              service['price'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          );
        }),
      ],
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.businessId, required this.reviews});

  final String businessId;
  final List<ReviewModel> reviews;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionTitle(title: 'Derniers avis')),
            TextButton(
              onPressed: () => context.go('/home/reviews/$businessId'),
              child: const Text('Voir tous les avis'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (reviews.isEmpty)
          const Text('Aucun avis pour le moment.')
        else
          ...reviews.map((review) => _ReviewTile(review: review)),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final date = DateFormat('d MMM yyyy', 'fr_FR').format(review.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: NetworkImage(review.userPhotoUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        review.userName,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      date,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _RatingStars(rating: review.rating, size: 17),
                const SizedBox(height: 6),
                Text(
                  review.comment,
                  style: textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
                if (review.photoUrls.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: review.photoUrls.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            review.photoUrls[index],
                            width: 100,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                ],
                if (review.replies.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...review.replies.map((reply) {
                    final isOwner = reply.senderRole == 'owner';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isOwner
                              ? colorScheme.surfaceContainerHighest.withOpacity(0.5)
                              : colorScheme.secondaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isOwner
                                ? colorScheme.primary.withOpacity(0.2)
                                : colorScheme.secondary.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isOwner ? Icons.reply_rounded : Icons.person_rounded, 
                                  size: 16, 
                                  color: isOwner ? colorScheme.primary : colorScheme.secondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isOwner ? 'Réponse de l\'entreprise' : 'Votre réponse',
                                  style: textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isOwner ? colorScheme.primary : colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              reply.message,
                              style: textTheme.bodyMedium?.copyWith(
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
                // Add reply button if last message is from owner and currentUser is the author
                if (review.isCurrentUser && (review.replies.isEmpty || review.replies.last.senderRole == 'owner')) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _showReplyDialog(context),
                      icon: const Icon(Icons.reply_rounded, size: 16),
                      label: const Text('Répondre'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReplyDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Répondre'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Votre réponse...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final msg = controller.text.trim();
              Navigator.pop(context);
              
              try {
                final repo = ReviewRepository();
                final newReply = ReviewReplyModel(
                  senderRole: 'client',
                  message: msg,
                  createdAt: DateTime.now(),
                );
                await repo.updateReplies(review.id, [...review.replies, newReply]);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Réponse envoyée. Actualisez la page.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  const _RatingStars({required this.rating, this.size = 20});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final icon = rating >= starValue
            ? Icons.star_rounded
            : rating >= starValue - 0.5
            ? Icons.star_half_rounded
            : Icons.star_border_rounded;

        return Icon(icon, color: colorScheme.tertiary, size: size);
      }),
    );
  }
}

class _OpenStatusPill extends StatelessWidget {
  const _OpenStatusPill({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOpen
            ? colorScheme.primaryContainer
            : colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isOpen ? 'Ouvert' : 'Ferme',
        style: TextStyle(
          color: isOpen
              ? colorScheme.onPrimaryContainer
              : colorScheme.onErrorContainer,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}
