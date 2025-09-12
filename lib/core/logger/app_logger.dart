import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// A simple logger class for the application
class AppLogger {
  final String name;
  static bool _isDebugMode = false;

  AppLogger(this.name);

  static void setDebugMode(bool enabled) {
    _isDebugMode = enabled;
  }

  /// Log a message at level [Level.verbose]
  void v(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _log(Level.verbose, message, error, stackTrace);
  }

  /// Log a message at level [Level.debug]
  void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _log(Level.debug, message, error, stackTrace);
  }

  /// Log a message at level [Level.info]
  void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _log(Level.info, message, error, stackTrace);
  }

  /// Log a message at level [Level.warning]
  void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _log(Level.warning, message, error, stackTrace);
  }

  /// Log a message at level [Level.error]
  void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _log(Level.error, message, error, stackTrace);
  }

  void _log(Level level, dynamic message, [dynamic error, StackTrace? stackTrace]) {
    // Only log in debug mode or for errors
    if (!_isDebugMode && level.index < Level.warning.index) {
      return;
    }

    final buffer = StringBuffer();
    buffer.write('[$name] ${level.emoji} ${level.name.toUpperCase()}: $message');
    
    if (error != null) {
      buffer.write('\nError: $error');
    }
    
    if (stackTrace != null) {
      buffer.write('\n$stackTrace');
    }

    final logMessage = buffer.toString();
    
    if (level == Level.error) {
      developer.log(logMessage, name: name, level: 1000, error: error, stackTrace: stackTrace);
    } else if (kDebugMode) {
      // In debug mode, print to console with color
      final coloredMessage = '${level.ansiColor}$logMessage\x1B[0m';
      developer.log(coloredMessage, name: name);
    }
  }
}

/// Logging levels
enum Level {
  verbose('🔍', '\x1B[90m'),    // Gray
  debug('🐛', '\x1B[36m'),     // Cyan
  info('ℹ️', '\x1B[32m'),     // Green
  warning('⚠️', '\x1B[33m'),  // Yellow
  error('❌', '\x1B[31m');   // Red

  final String emoji;
  final String ansiColor;
  
  const Level(this.emoji, this.ansiColor);
}

/// Extension methods for logging
extension LogExtension on Object {
  /// Get a logger for this object's runtime type
  AppLogger get logger => AppLogger(runtimeType.toString());
}
