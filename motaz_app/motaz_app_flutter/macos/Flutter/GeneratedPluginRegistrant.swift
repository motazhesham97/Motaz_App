//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import connectivity_plus
import file_picker
import file_selector_macos
import flutter_secure_storage_darwin
import shared_preferences_foundation
import sqflite_darwin
import sqlite3_flutter_libs

/// Registers the generated Flutter macOS plugins with the given plugin registry.
/// - Parameters:
/// Registers the generated Flutter macOS plugins with the provided plugin registry.
/// - Parameter registry: The `FlutterPluginRegistry` used to obtain registrars for each plugin so they can be registered with the Flutter engine.
func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  ConnectivityPlusPlugin.register(with: registry.registrar(forPlugin: "ConnectivityPlusPlugin"))
  FilePickerPlugin.register(with: registry.registrar(forPlugin: "FilePickerPlugin"))
  FileSelectorPlugin.register(with: registry.registrar(forPlugin: "FileSelectorPlugin"))
  FlutterSecureStorageDarwinPlugin.register(with: registry.registrar(forPlugin: "FlutterSecureStorageDarwinPlugin"))
  SharedPreferencesPlugin.register(with: registry.registrar(forPlugin: "SharedPreferencesPlugin"))
  SqflitePlugin.register(with: registry.registrar(forPlugin: "SqflitePlugin"))
  Sqlite3FlutterLibsPlugin.register(with: registry.registrar(forPlugin: "Sqlite3FlutterLibsPlugin"))
}
