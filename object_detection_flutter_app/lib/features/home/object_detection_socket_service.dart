import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'package:object_detection_flutter_app/features/home/object_detected.dart';
import 'dart:convert';

class SocketService with ChangeNotifier {
  final ObjectDetected objectDetected;
  SocketService(this.objectDetected);

  late IO.Socket _socket;
  bool _isConnected = false;
  String _connectionStatus = 'Disconnected';

  IO.Socket get socket => _socket;
  bool get isConnected => _isConnected;
  String get connectionStatus => _connectionStatus;

  void initSocket() {
    print('🔄 [SocketService] Initializing socket connection...');

    _socket = IO.io(
      'http://192.168.0.7:5000',
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling']) 
          .enableReconnection()
          .enableForceNew()
          .build(),
    );
    _socket.onAny((event, data) {
      debugPrint('📡 Received [$event]: $data');
    });

    _socket.onConnect((_) {
      debugPrint('✅ [SocketService] Socket connected successfully');
      _isConnected = true;
      _connectionStatus = 'Connected';
      notifyListeners();
    });

    _socket.onConnectError((error) {
      debugPrint('❌ [SocketService] Connection error: $error');
      _isConnected = false;
      _connectionStatus = 'Connection Error: $error';
      notifyListeners();
    });

    _socket.onError((error) {
      debugPrint('❌ [SocketService] Socket error: $error');
      _connectionStatus = 'Socket Error: $error';
      notifyListeners();
    });

    _socket.onDisconnect((reason) {
      debugPrint('🔌 [SocketService] Socket disconnected: $reason');
      _isConnected = false;
      _connectionStatus = 'Disconnected: $reason';
      notifyListeners();
    });

    _socket.on('object-detected', (data) {
      debugPrint('📦 [SocketService] Received object-detected event');
      debugPrint('📦 [SocketService] Data type: ${data.runtimeType}');
      debugPrint('📦 [SocketService] Data: $data');

      try {
        Map<String, dynamic> decodedData;
        
        if (data is String) {
          // Handle JSON string
          debugPrint('🔄 [SocketService] Decoding JSON string...');
          decodedData = json.decode(data);
        } else if (data is Map) {
          // Handle already parsed JSON object
          debugPrint('🔄 [SocketService] Using Map directly...');
          decodedData = Map<String, dynamic>.from(data);
        } else {
          debugPrint('❌ [SocketService] Unsupported data type: ${data.runtimeType}');
          return;
        }

        debugPrint('🔄 [SocketService] Calling objectDetected.updateFromGeoJson...');
        objectDetected.updateFromGeoJson(decodedData);

        debugPrint('✅ [SocketService] Successfully updated ObjectDetected');
        debugPrint('📊 [SocketService] Markers count: ${objectDetected.markersData.length}');
        debugPrint('📊 [SocketService] Labels: ${objectDetected.labels}');
        notifyListeners();
      } catch (e) {
        debugPrint('❌ [SocketService] Error updating ObjectDetected: $e');
        debugPrint('❌ [SocketService] Stack trace: ${StackTrace.current}');
      }
    });

    debugPrint('🔄 [SocketService] Attempting to connect...');
    _socket.connect();
  }

  void sendMessage(String event, dynamic data) {
    if (_isConnected) {
      debugPrint('📤 [SocketService] Sending message: $event with data: $data');
      _socket.emit(event, data);
    } else {
      debugPrint('❌ [SocketService] Cannot send message - socket not connected');
    }
  }

  void disposeSocket() {
    debugPrint('🔄 [SocketService] Disposing socket...');
    _socket.dispose();
  }
}