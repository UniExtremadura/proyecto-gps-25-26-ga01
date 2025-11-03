import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme.dart';
import '../../../core/models/album.dart';

class AlbumCard extends StatelessWidget {
  final Album album;

  const AlbumCard({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/album', arguments: album.id);
      },
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: AppTheme.cardBlack,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: album.coverImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: album.coverImageUrl!,
                      width: 180,
                      height: 140,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 180,
                        height: 140,
                        color: AppTheme.surfaceBlack,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 180,
                        height: 140,
                        color: AppTheme.surfaceBlack,
                        child: const Icon(Icons.album, size: 48),
                      ),
                    )
                  : Container(
                      width: 180,
                      height: 140,
                      color: AppTheme.surfaceBlack,
                      child: const Icon(Icons.album, size: 48),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${album.price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppTheme.textGrey,
                              decoration: TextDecoration.lineThrough,
                            ),
                      ),
                      Text(
                        '\$${album.discountedPrice.toStringAsFixed(2)}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.primaryBlue,
                                ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
