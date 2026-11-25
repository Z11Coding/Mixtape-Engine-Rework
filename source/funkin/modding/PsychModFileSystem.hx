package funkin.modding;

#if sys
import haxe.io.Path;
import polymod.fs.SysZipFileSystem;
import sys.FileSystem;

@:nullSafety
class PsychModFileSystem extends SysZipFileSystem
{
  static final ASSET_ROOTS:Array<String> = [
    'achievements',
    'characters',
    'custom_events',
    'custom_notetypes',
    'data',
    'fonts',
    'images',
    'music',
    'scripts',
    'shaders',
    'songs',
    'sounds',
    'stages',
    'videos',
    'weeks'
  ];

  override public function exists(path:String):Bool
  {
    return ModManager.getPsychMetadataForPath(path) != null
      || getPsychVirtualAsset(path) != null
      || getPsychAssetPath(path) != null
      || super.exists(path);
  }

  override public function isDirectory(path:String):Bool
  {
    final virtualAsset = getPsychVirtualAsset(path);
    if (virtualAsset != null && PsychModContentAdapter.isDirectory(virtualAsset.modId, virtualAsset.assetPath))
    {
      return true;
    }

    final assetPath = getPsychAssetPath(path);
    return assetPath != null ? FileSystem.isDirectory(assetPath) : super.isDirectory(path);
  }

  override public function readDirectory(path:String):Array<String>
  {
    final virtualAsset = getPsychVirtualAsset(path);
    if (virtualAsset != null && PsychModContentAdapter.isDirectory(virtualAsset.modId, virtualAsset.assetPath))
    {
      return PsychModContentAdapter.readDirectory(virtualAsset.modId, virtualAsset.assetPath);
    }

    final assetPath = getPsychAssetPath(path);
    return super.readDirectory(assetPath ?? path);
  }

  override public function readDirectoryRecursive(path:String):Array<String>
  {
    final virtualAsset = getPsychVirtualAsset(path);
    if (virtualAsset != null && PsychModContentAdapter.isDirectory(virtualAsset.modId, virtualAsset.assetPath))
    {
      return PsychModContentAdapter.readDirectoryRecursive(virtualAsset.modId, virtualAsset.assetPath);
    }

    final assetPath = getPsychAssetPath(path);
    return super.readDirectoryRecursive(assetPath ?? path);
  }

  override public function readModDirectory(modDir:String, recursive:Bool = true):Array<String>
  {
    final files = super.readModDirectory(modDir, recursive);
    if (ModManager.getModEngine(modDir) != ModManager.ENGINE_PSYCH) return files;

    final result = files.copy();
    if (!result.contains('_polymod_meta.json')) result.push('_polymod_meta.json');

    for (file in files)
    {
      if (isPsychAssetPath(file))
      {
        final alias = 'assets/$file';
        if (!result.contains(alias)) result.push(alias);
      }
    }

    for (file in PsychModContentAdapter.listFiles(modDir))
    {
      if (!result.contains(file)) result.push(file);
    }

    return result;
  }

  override public function getFileContent(path:String):Null<String>
  {
    final metadata = ModManager.getPsychMetadataForPath(path);
    if (metadata != null) return metadata;

    final virtualAsset = getPsychVirtualAsset(path);
    if (virtualAsset != null)
    {
      final text = PsychModContentAdapter.getContent(virtualAsset.modId, virtualAsset.assetPath);
      if (text != null) return text;
    }

    final assetPath = getPsychAssetPath(path);
    return super.getFileContent(assetPath ?? path);
  }

  override public function getFileBytes(path:String):Null<haxe.io.Bytes>
  {
    final metadata = ModManager.getPsychMetadataForPath(path);
    if (metadata != null) return haxe.io.Bytes.ofString(metadata);

    final virtualAsset = getPsychVirtualAsset(path);
    if (virtualAsset != null)
    {
      final bytes = PsychModContentAdapter.getBytes(virtualAsset.modId, virtualAsset.assetPath);
      if (bytes != null) return bytes;
    }

    final assetPath = getPsychAssetPath(path);
    return super.getFileBytes(assetPath ?? path);
  }

  function getPsychVirtualAsset(path:String):Null<{modId:String, assetPath:String}>
  {
    final normalizedPath = normalizePath(path);
    final normalizedRoot = normalizePath(modRoot);
    final prefix = normalizedRoot.endsWith('/') ? normalizedRoot : '$normalizedRoot/';
    if (!normalizedPath.startsWith(prefix)) return null;

    final relativePath = normalizedPath.substring(prefix.length);
    final parts = relativePath.split('/');
    if (parts.length < 3 || parts[1] != 'assets') return null;

    final modId = parts[0];
    if (ModManager.getModEngine(modId) != ModManager.ENGINE_PSYCH) return null;

    final assetPath = parts.slice(2).join('/');
    if (!PsychModContentAdapter.exists(modId, assetPath) && !PsychModContentAdapter.isDirectory(modId, assetPath)) return null;
    return {modId: modId, assetPath: assetPath};
  }

  override public function onLoadMod(modId:String):Void
  {
    if (ModManager.getModEngine(modId) == ModManager.ENGINE_PSYCH) return;
    super.onLoadMod(modId);
  }

  override public function onUnloadMod(modId:String):Void
  {
    if (ModManager.getModEngine(modId) == ModManager.ENGINE_PSYCH) return;
    super.onUnloadMod(modId);
  }

  function getPsychAssetPath(path:String):Null<String>
  {
    final normalizedPath = normalizePath(path);
    final normalizedRoot = normalizePath(modRoot);
    final prefix = normalizedRoot.endsWith('/') ? normalizedRoot : '$normalizedRoot/';
    if (!normalizedPath.startsWith(prefix)) return null;

    final relativePath = normalizedPath.substring(prefix.length);
    final separator = relativePath.indexOf('/');
    if (separator <= 0) return null;

    final modDir = relativePath.substring(0, separator);
    if (ModManager.getModEngine(modDir) != ModManager.ENGINE_PSYCH) return null;

    var filePath = relativePath.substring(separator + 1);
    if (!filePath.startsWith('assets/')) return null;
    filePath = filePath.substring('assets/'.length);
    if (!isPsychAssetPath(filePath)) return null;

    final targetPath = Path.join([modRoot, modDir, filePath]);
    return FileSystem.exists(targetPath) ? targetPath : null;
  }

  function isPsychAssetPath(path:String):Bool
  {
    final root = path.replace('\\', '/').split('/')[0];
    return ASSET_ROOTS.contains(root);
  }

  function normalizePath(path:String):String
  {
    return Path.normalize(path).replace('\\', '/');
  }
}
#else
typedef PsychModFileSystem = polymod.fs.MemoryZipFileSystem;
#end
