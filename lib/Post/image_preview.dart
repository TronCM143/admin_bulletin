import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

void showImagePreview(BuildContext context, String imageUrl) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        child: FractionallySizedBox(
          alignment: Alignment.center,
          widthFactor: 0.6,
          heightFactor: 0.6,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) =>
                const Center(child: Icon(Icons.error)),
          ),
        ),
      );
    },
  );
}
