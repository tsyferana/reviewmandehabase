import 'dart:async';
import 'package:flutter/material.dart';
import '../repositories/favorite_repository.dart';

class FavoriteButton extends StatefulWidget {
  const FavoriteButton({super.key, required this.businessId});
  final String businessId;

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool _isFavorite = false;
  final _favoriteRepo = FavoriteRepository();

  @override
  void initState() {
    super.initState();
    unawaited(_checkFavorite());
  }

  Future<void> _checkFavorite() async {
    final isFav = await _favoriteRepo.isFavorite(widget.businessId);
    if (mounted) setState(() => _isFavorite = isFav);
  }

  Future<void> _toggle() async {
    final newValue = !_isFavorite;
    setState(() => _isFavorite = newValue);
    
    try {
      if (newValue) {
        await _favoriteRepo.addFavorite(widget.businessId);
      } else {
        await _favoriteRepo.removeFavorite(widget.businessId);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFavorite = !newValue); // Revert UI on error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggle,
        customBorder: const CircleBorder(),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: _isFavorite ? Colors.red : Colors.grey[700],
            size: 18,
          ),
        ),
      ),
    );
  }
}
