//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import connectivity_plus
import file_picker
import file_selector_macos
import shared_preferences_foundation
import sqflite_darwin
import sqlite3_flutter_libs

/// Registers all generated macOS Flutter plugins with the given plugin registry.
/// 
/// This function registers the connectivity, file picker/selector, shared preferences,
/// and SQLite-related plugins so they become available to the Flutter engine on macOS.
/// - Parameters:
///   - registry: The `FlutterPluginRegistry` that will receive the plugin registrations.
func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  ConnectivityPlusPlugin.register(with: registry.registrar(forPlugin: "ConnectivityPlusPlugin"))
  FilePickerPlugin.register(with: registry.registrar(forPlugin: "FilePickerPlugin"))
  FileSelectorPlugin.register(with: registry.registrar(forPlugin: "FileSelectorPlugin"))
  SharedPreferencesPlugin.register(with: registry.registrar(forPlugin: "SharedPreferencesPlugin"))
  SqflitePlugin.register(with: registry.registrar(forPlugin: "SqflitePlugin"))
  Sqlite3FlutterLibsPlugin.register(with: registry.registrar(forPlugin: "Sqlite3FlutterLibsPlugin"))
}
