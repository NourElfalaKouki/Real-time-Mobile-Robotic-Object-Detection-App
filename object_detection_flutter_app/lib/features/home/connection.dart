import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:object_detection_flutter_app/features/home/object_detection_socket_service.dart';

class ConnectionStatusWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SocketService>(
      builder: (context, socketService, child) {
        return Container(
          padding: EdgeInsets.all(8.0),
          margin: EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: socketService.isConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            border: Border.all(
              color: socketService.isConnected ? Colors.green : Colors.red,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    socketService.isConnected ? Icons.wifi : Icons.wifi_off,
                    color: socketService.isConnected ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Socket Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: socketService.isConnected ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                socketService.connectionStatus,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}