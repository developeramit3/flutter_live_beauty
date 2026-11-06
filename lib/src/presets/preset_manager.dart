import 'dart:convert';
import 'dart:io';
import 'beauty_preset.dart';

/// Manages built-in and local persistent custom beauty presets.
class PresetManager {
  PresetManager({this.storageDirectory});

  /// Custom storage directory (optional, defaults to local app data directory).
  final Directory? storageDirectory;

  final Map<String, BeautyPreset> _customPresets = {};
  bool _isLoaded = false;

  static const String _presetFileName = 'beauty_presets_v1.json';

  /// Returns combined list of built-in presets followed by user custom presets.
  List<BeautyPreset> getAllPresets() {
    return [
      ...BeautyPreset.builtInPresets,
      ..._customPresets.values,
    ];
  }

  /// Get preset by its unique ID.
  BeautyPreset? getPreset(String id) {
    for (final p in BeautyPreset.builtInPresets) {
      if (p.id == id) return p;
    }
    return _customPresets[id];
  }

  /// Load custom presets from local JSON file.
  Future<void> loadCustomPresets() async {
    if (_isLoaded) return;
    try {
      final file = await _getStorageFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> decoded = jsonDecode(content) as List<dynamic>;
        _customPresets.clear();
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final preset = BeautyPreset.fromMap(item);
            _customPresets[preset.id] = preset;
          }
        }
      }
    } catch (_) {
      // Gracefully handle file read error
    } finally {
      _isLoaded = true;
    }
  }

  /// Save or update a custom preset locally.
  Future<BeautyPreset> saveCustomPreset(BeautyPreset preset) async {
    final customPreset = preset.copyWith(isBuiltIn: false);
    _customPresets[customPreset.id] = customPreset;
    await _persist();
    return customPreset;
  }

  /// Rename an existing custom preset.
  Future<bool> renameCustomPreset(String id, String newName) async {
    final existing = _customPresets[id];
    if (existing == null) return false;
    _customPresets[id] = existing.copyWith(name: newName);
    await _persist();
    return true;
  }

  /// Delete a custom preset.
  Future<bool> deleteCustomPreset(String id) async {
    if (_customPresets.remove(id) != null) {
      await _persist();
      return true;
    }
    return false;
  }

  /// Clear all custom presets and revert back to built-ins.
  Future<void> restoreDefaults() async {
    _customPresets.clear();
    final file = await _getStorageFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> _persist() async {
    try {
      final file = await _getStorageFile();
      final list = _customPresets.values.map((p) => p.toMap()).toList();
      await file.writeAsString(jsonEncode(list));
    } catch (_) {
      // Failed to write file
    }
  }

  Future<File> _getStorageFile() async {
    final dir = storageDirectory ?? Directory.systemTemp;
    return File('${dir.path}/$_presetFileName');
  }
}
