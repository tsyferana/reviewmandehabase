import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.size = 20,
    this.onRatingChanged,
    this.interactive = false,
  });

  final double rating;
  final double size;
  final ValueChanged<double>? onRatingChanged;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starRating = index + 1;
        final isFilled = starRating <= rating;
        final isHalf = starRating - 0.5 == rating;

        return GestureDetector(
          onTap: interactive
              ? () => onRatingChanged?.call(starRating.toDouble())
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              isHalf
                  ? Icons.star_half_rounded
                  : isFilled
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              size: size,
              color: Colors.amber,
            ),
          ),
        );
      }),
    );
  }
}
