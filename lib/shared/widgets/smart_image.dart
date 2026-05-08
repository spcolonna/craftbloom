import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:craftbloom/core/constants/app_colors.dart';
import 'package:shimmer/shimmer.dart';

/// Renderiza automáticamente un asset local (si la URL empieza con "assets/")
/// o una imagen de red (CachedNetworkImage). Úsalo en cualquier lugar donde
/// el origen de la imagen puede ser cualquiera de los dos.
class SmartImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;

  const SmartImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
  });

  bool get _isAsset => url.startsWith('assets/');

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder();

    if (_isAsset) {
      return Image.asset(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, e, s) => _placeholder(),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, u) => Shimmer.fromColors(
        baseColor: AppColors.surfaceVariant,
        highlightColor: AppColors.surface,
        child: Container(color: AppColors.surfaceVariant, width: width, height: height),
      ),
      errorWidget: (_, u, e) => errorWidget ?? _placeholder(),
    );
  }

  Widget _placeholder() => Container(
    width: width,
    height: height,
    color: AppColors.primaryLight.withValues(alpha: 0.2),
    child: const Center(child: Icon(Icons.image_outlined, color: AppColors.primary, size: 32)),
  );
}
