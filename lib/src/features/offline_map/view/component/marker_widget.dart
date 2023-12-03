import 'package:flutter/material.dart';
import 'package:flutter_map_offline_poc/src/services/marker_service/marker_service.dart';

class MarkerWidget extends StatelessWidget {
  final CustomMarker marker;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MarkerWidget({
    super.key,
    required this.marker,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showMarkerDetailsDialog(context, marker);
      },
      child: const Icon(Icons.location_on),
    );
  }

  Future<void> _showMarkerDetailsDialog(BuildContext context, CustomMarker marker) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Marker Details'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Notes: ${marker.notes}'),
              Text('Latitude: ${marker.position.latitude}'),
              Text('Longitude: ${marker.position.longitude}'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
            ),
          ],
        );
      },
    );
  }
}
