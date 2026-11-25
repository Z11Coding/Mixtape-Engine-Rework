package funkin.modding;

import haxe.Json;
import haxe.io.Path;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

@:nullSafety
class ModManager
{
  public static inline final ENGINE_VSLICE:String = 'VSlice';
  public static inline final ENGINE_PSYCH:String = 'Psych';
  public static inline final ENGINE_UNKNOWN:String = 'Unknown';

  public static var mods:Map<String, Map<String, Dynamic>> = [];
  public static var instance:Null<ModManager> = null;

  static final PSYCH_METADATA_FILE:String = '_polymod_meta.json';
  static final PSYCH_PACK_FILE:String = 'pack.json';
  static final SEMVER_PATTERN:EReg = ~/^\d+\.\d+\.\d+([+-][0-9A-Za-z.-]+)?$/;

  public static function getModEngine(folder:String):String
  {
    #if sys
    if (!isValidModFolder(folder)) return ENGINE_UNKNOWN;

    final modPath = getModPath(folder);
    if (FileSystem.exists(Path.join([modPath, PSYCH_METADATA_FILE]))) return ENGINE_VSLICE;
    if (!FileSystem.isDirectory(modPath) || !FileSystem.exists(Path.join([modPath, PSYCH_PACK_FILE]))) return ENGINE_UNKNOWN;

    final pack = getPack(folder);
    final declaredEngine = readString(pack, ['engine', 'modEngine', 'format']);
    if (declaredEngine != null)
    {
      return normalizeEngine(declaredEngine);
    }

    return ENGINE_PSYCH;
    #else
    return ENGINE_UNKNOWN;
    #end
  }

  public static function getEngineNickname(engine:String):String
  {
    return switch (normalizeEngine(engine))
    {
      case ENGINE_VSLICE: 'V-Slice';
      case ENGINE_PSYCH: 'Psych Engine';
      default: 'Unknown';
    }
  }

  public static function getPack(folder:String):Null<Dynamic>
  {
    #if sys
    if (!isValidModFolder(folder)) return null;

    final packPath = Path.join([getModPath(folder), PSYCH_PACK_FILE]);
    if (!FileSystem.exists(packPath)) return null;

    try
    {
      return Json.parse(File.getContent(packPath));
    }
    catch (e:Dynamic)
    {
      trace('Failed to parse Psych mod pack file "$packPath": ${Std.string(e)}');
      return null;
    }
    #else
    return null;
    #end
  }

  public static function getPsychModDirectories():Array<String>
  {
    #if sys
    if (!FileSystem.exists(PolymodHandler.MOD_FOLDER)) return [];

    return FileSystem.readDirectory(PolymodHandler.MOD_FOLDER).filter((folder) -> getModEngine(folder) == ENGINE_PSYCH);
    #else
    return [];
    #end
  }

  public static function getEnabledPsychModDirectories():Array<String>
  {
    return PolymodHandler.enabledModIds.filter((modId) -> getModEngine(modId) == ENGINE_PSYCH);
  }

  public static function getPsychMetadataForPath(path:String):Null<String>
  {
    #if sys
    final normalizedPath = normalizePath(path);
    final normalizedRoot = normalizePath(PolymodHandler.MOD_FOLDER);
    final prefix = normalizedRoot.endsWith('/') ? normalizedRoot : '$normalizedRoot/';
    if (!normalizedPath.startsWith(prefix)) return null;

    final relativePath = normalizedPath.substring(prefix.length);
    final parts = relativePath.split('/');
    if (parts.length != 2 || parts[1] != PSYCH_METADATA_FILE) return null;

    return getPsychMetadata(parts[0]);
    #else
    return null;
    #end
  }

  static function getPsychMetadata(folder:String):Null<String>
  {
    if (getModEngine(folder) != ENGINE_PSYCH) return null;

    final pack = getPack(folder);
    if (pack == null) return null;

    final modVersion = readString(pack, ['mod_version', 'modVersion', 'version']);
    final title = readString(pack, ['title', 'name', 'modName']) ?? folder;
    final description = readString(pack, ['description', 'modDescription']) ?? 'Psych Engine mod';
    final author = readString(pack, ['author', 'creator']);
    final contributors:Array<Dynamic> = author != null ? [{name: author}] : [];

    return Json.stringify({
      title: title,
      description: description,
      contributors: contributors,
      homepage: readString(pack, ['homepage', 'url']) ?? '',
      api_version: PolymodHandler.API_VERSION,
      mod_version: normalizeVersion(modVersion),
      license: readString(pack, ['license']) ?? '',
      metadata: {
        engine: ENGINE_PSYCH,
        format: 'Psych Engine'
      }
    });
  }

  static function normalizeVersion(version:Null<String>):String
  {
    if (version == null || !SEMVER_PATTERN.match(version)) return '1.0.0';
    return version;
  }

  static function normalizeEngine(engine:String):String
  {
    return switch (engine.trim().toLowerCase())
    {
      case 'vslice' | 'v-slice' | 'v slice': ENGINE_VSLICE;
      case 'psych' | 'psych engine' | 'mixtape' | 'pe': ENGINE_PSYCH;
      default: ENGINE_UNKNOWN;
    }
  }

  static function readString(source:Null<Dynamic>, fields:Array<String>):Null<String>
  {
    if (source == null) return null;

    for (field in fields)
    {
      final value:Dynamic = Reflect.field(source, field);
      if (value != null && Std.string(value).trim().length > 0) return Std.string(value).trim();
    }

    return null;
  }

  static function getModPath(folder:String):String
  {
    return Path.join([PolymodHandler.MOD_FOLDER, folder]);
  }

  static function isValidModFolder(folder:String):Bool
  {
    return folder.length > 0 && folder != '.' && folder != '..' && !folder.contains('/') && !folder.contains('\\');
  }

  static function normalizePath(path:String):String
  {
    var normalizedPath = Path.normalize(path).replace('\\', '/');
    while (normalizedPath.endsWith('/'))
    {
      normalizedPath = normalizedPath.substr(0, normalizedPath.length - 1);
    }
    return normalizedPath;
  }
}
