package funkin.modding;

#if sys
import haxe.Json;
import haxe.io.Path;
import funkin.data.character.CharacterRegistry;
import funkin.data.song.SongRegistry;
import funkin.data.stage.StageRegistry;
import funkin.util.Constants;
import sys.FileSystem;
import sys.io.File;

using StringTools;

/**
 * Presents common Psych Engine data files in the native registry layout.
 */
class PsychModContentAdapter
{
  static final indexes:Map<String, PsychModContentIndex> = new Map<String, PsychModContentIndex>();

  public static function clearCache():Void
  {
    indexes.clear();
  }

  public static function listFiles(modId:String):Array<String>
  {
    return getIndex(modId).files.copy();
  }

  public static function exists(modId:String, assetPath:String):Bool
  {
    final path = normalizeAssetPath(assetPath);
    final index = getIndex(modId);
    return index.texts.exists(path) || index.sources.exists(path);
  }

  public static function isDirectory(modId:String, assetPath:String):Bool
  {
    final prefix = normalizeAssetPath(assetPath);
    final folderPrefix = prefix == '' ? '' : '$prefix/';
    return getIndex(modId).files.exists((file) -> file.startsWith('assets/$folderPrefix'));
  }

  public static function readDirectory(modId:String, assetPath:String):Array<String>
  {
    final prefix = normalizeAssetPath(assetPath);
    final folderPrefix = prefix == '' ? 'assets/' : 'assets/$prefix/';
    final result:Array<String> = [];

    for (file in getIndex(modId).files)
    {
      if (!file.startsWith(folderPrefix)) continue;
      final remainder = file.substring(folderPrefix.length);
      if (remainder == '') continue;
      final child = remainder.split('/')[0];
      if (!result.contains(child)) result.push(child);
    }

    result.sort(Reflect.compare);
    return result;
  }

  public static function readDirectoryRecursive(modId:String, assetPath:String):Array<String>
  {
    final prefix = normalizeAssetPath(assetPath);
    final folderPrefix = prefix == '' ? 'assets/' : 'assets/$prefix/';
    return getIndex(modId).files
      .filter((file) -> file.startsWith(folderPrefix))
      .map((file) -> file.substring(folderPrefix.length));
  }

  public static function getContent(modId:String, assetPath:String):Null<String>
  {
    return getIndex(modId).texts.get(normalizeAssetPath(assetPath));
  }

  public static function getBytes(modId:String, assetPath:String):Null<haxe.io.Bytes>
  {
    final path = normalizeAssetPath(assetPath);
    final index = getIndex(modId);

    if (index.texts.exists(path)) return haxe.io.Bytes.ofString(index.texts.get(path));

    final source = index.sources.get(path);
    return source != null ? File.getBytes(source) : null;
  }

  static function getIndex(modId:String):PsychModContentIndex
  {
    final cached = indexes.get(modId);
    if (cached != null) return cached;

    final index:PsychModContentIndex = {
      files: [],
      texts: new Map<String, String>(),
      sources: new Map<String, String>()
    };
    indexes.set(modId, index);

    if (modId.length == 0 || modId == '.' || modId == '..' || modId.contains('/') || modId.contains('\\')) return index;

    final modRoot = Path.join([PolymodHandler.MOD_FOLDER, modId]);
    if (!FileSystem.isDirectory(modRoot)) return index;

    indexCharacters(index, modRoot);
    indexStages(index, modRoot);
    indexSongs(index, modRoot);

    index.files.sort(Reflect.compare);
    return index;
  }

  static function indexCharacters(index:PsychModContentIndex, modRoot:String):Void
  {
    final charactersRoot = Path.join([modRoot, 'characters']);
    if (!FileSystem.isDirectory(charactersRoot)) return;

    for (file in sortedEntries(charactersRoot))
    {
      if (Path.extension(file).toLowerCase() != 'json') continue;
      final sourcePath = Path.join([charactersRoot, file]);
      if (FileSystem.isDirectory(sourcePath)) continue;

      final id = Path.withoutExtension(file);
      final source = parseJson(sourcePath);
      if (source == null) continue;

      final image = readString(source, ['image']);
      if (image == null) continue;

      final imagePath = findImage(modRoot, image);
      if (imagePath == null) continue;

      final assetBase = 'gameplay/characters/$id/${id}';
      addText(index, '$assetBase-data.json', Json.stringify(convertCharacter(id, source, assetBase)));
      addImageAliases(index, assetBase, imagePath);
    }
  }

  static function convertCharacter(id:String, source:Dynamic, assetBase:String):Dynamic
  {
    final position = numberArray(Reflect.field(source, 'position'), [0, 0]);
    final cameraPosition = numberArray(Reflect.field(source, 'camera_position'), [0, 0]);
    final rawAnimations = arrayValue(Reflect.field(source, 'animations'));
    final animations:Array<Dynamic> = [];

    for (animation in rawAnimations)
    {
      final name = readString(animation, ['anim']);
      final prefix = readString(animation, ['name']);
      if (name == null || prefix == null) continue;

      final item:Dynamic = {
        name: name,
        prefix: prefix,
        frameRate: intValue(Reflect.field(animation, 'fps'), 24),
        looped: boolValue(Reflect.field(animation, 'loop'), false),
        offsets: numberArray(Reflect.field(animation, 'offsets'), [0, 0])
      };

      final indices = arrayValue(Reflect.field(animation, 'indices'));
      if (indices.length > 0) item.frameIndices = indices.map((value) -> intValue(value, 0));
      animations.push(item);
    }

    final healthIconId = readString(source, ['healthicon']) ?? id;
    final result:Dynamic = {
      version: CharacterRegistry.CHARACTER_DATA_VERSION,
      name: readString(source, ['name']) ?? id,
      assetPath: assetBase,
      renderType: 'sparrow',
      scale: numberValue(Reflect.field(source, 'scale'), 1),
      healthIcon: {
        id: healthIconId,
        shouldBop: true,
        scale: 1,
        flipX: false,
        isPixel: boolValue(Reflect.field(source, 'no_antialiasing'), false),
        offsets: [0, 25]
      },
      offsets: position,
      cameraOffsets: cameraPosition,
      isPixel: boolValue(Reflect.field(source, 'no_antialiasing'), false),
      danceEvery: 1,
      singTime: numberValue(Reflect.field(source, 'sing_duration'), 4),
      animations: animations,
      startingAnimation: animations.length > 0 ? animations[0].name : 'idle',
      flipX: boolValue(Reflect.field(source, 'flip_x'), false)
    };

    return result;
  }

  static function indexStages(index:PsychModContentIndex, modRoot:String):Void
  {
    final stagesRoot = Path.join([modRoot, 'stages']);
    if (!FileSystem.isDirectory(stagesRoot)) return;

    for (file in sortedEntries(stagesRoot))
    {
      if (Path.extension(file).toLowerCase() != 'json') continue;
      final sourcePath = Path.join([stagesRoot, file]);
      if (FileSystem.isDirectory(sourcePath)) continue;

      final id = Path.withoutExtension(file);
      final source = parseJson(sourcePath);
      if (source == null) continue;

      final nativePath = 'gameplay/stages/$id/$id-data.json';
      addText(index, nativePath, Json.stringify(convertStage(id, source, modRoot, index)));
    }
  }

  static function convertStage(id:String, source:Dynamic, modRoot:String, index:PsychModContentIndex):Dynamic
  {
    final props:Array<Dynamic> = [];
    final sourceProps = arrayValue(Reflect.field(source, 'objects') ?? Reflect.field(source, 'sprites') ?? Reflect.field(source, 'props'));
    final isPixelStage = boolValue(Reflect.field(source, 'isPixelStage'), false);
    var propIndex = 0;

    for (sourceProp in sourceProps)
    {
      final image = readString(sourceProp, ['image', 'path', 'asset']);
      if (image == null) continue;

      final imagePath = findImage(modRoot, image);
      if (imagePath == null) continue;

      final assetPath = 'gameplay/stages/$id/psych-prop-$propIndex';
      addImageAliases(index, assetPath, imagePath);

      final position = numberArray(Reflect.field(sourceProp, 'position'), [0, 0]);
      final scroll = numberArray(Reflect.field(sourceProp, 'scrollFactor'), [1, 1]);
      final prop:Dynamic = {
        name: readString(sourceProp, ['name']) ?? 'psych-prop-$propIndex',
        assetPath: assetPath,
        position: position,
        zIndex: intValue(Reflect.field(sourceProp, 'zIndex'), propIndex),
        isPixel: isPixelStage || !boolValue(Reflect.field(sourceProp, 'antialiasing'), true),
        flipX: boolValue(Reflect.field(sourceProp, 'flipX'), false),
        flipY: boolValue(Reflect.field(sourceProp, 'flipY'), false),
        scale: Reflect.field(sourceProp, 'scale') ?? 1,
        alpha: numberValue(Reflect.field(sourceProp, 'alpha'), 1),
        scroll: scroll,
        angle: numberValue(Reflect.field(sourceProp, 'angle'), 0),
        blend: '',
        color: '#FFFFFF',
        animType: 'sparrow',
        animations: convertAnimations(Reflect.field(sourceProp, 'animations'))
      };
      props.push(prop);
      propIndex++;
    }

    final boyfriend = numberArray(Reflect.field(source, 'boyfriend'), [770, 100]);
    final opponent = numberArray(Reflect.field(source, 'opponent'), [100, 100]);
    final hideGirlfriend = boolValue(Reflect.field(source, 'hide_girlfriend'), false);
    final girlfriend = hideGirlfriend ? [-10000.0, 0.0] : numberArray(Reflect.field(source, 'girlfriend'), [400, 130]);
    final result:Dynamic = {
      version: StageRegistry.STAGE_DATA_VERSION,
      name: readString(source, ['name']) ?? id,
      props: props,
      characters: {
        bf: {
          zIndex: 0,
          scale: 1,
          position: boyfriend,
          cameraOffsets: numberArray(Reflect.field(source, 'camera_boyfriend'), [-100, -100])
        },
        dad: {
          zIndex: 0,
          scale: 1,
          position: opponent,
          cameraOffsets: numberArray(Reflect.field(source, 'camera_opponent'), [100, -100])
        },
        gf: {
          zIndex: 0,
          scale: 1,
          position: girlfriend,
          cameraOffsets: numberArray(Reflect.field(source, 'camera_girlfriend'), [0, 0])
        }
      },
      cameraZoom: numberValue(Reflect.field(source, 'defaultZoom'), 1),
      directory: 'shared'
    };

    return result;
  }

  static function convertAnimations(value:Dynamic):Array<Dynamic>
  {
    final result:Array<Dynamic> = [];
    for (animation in arrayValue(value))
    {
      final name = readString(animation, ['anim', 'name']);
      final prefix = readString(animation, ['name', 'anim', 'prefix']);
      if (name == null || prefix == null) continue;
      result.push({
        name: name,
        prefix: prefix,
        frameRate: intValue(Reflect.field(animation, 'fps'), 24),
        looped: boolValue(Reflect.field(animation, 'loop'), false),
        offsets: numberArray(Reflect.field(animation, 'offsets'), [0, 0])
      });
    }
    return result;
  }

  static function indexSongs(index:PsychModContentIndex, modRoot:String):Void
  {
    final dataRoot = Path.join([modRoot, 'data']);
    if (!FileSystem.isDirectory(dataRoot)) return;

    for (songId in sortedEntries(dataRoot))
    {
      final songRoot = Path.join([dataRoot, songId]);
      if (!FileSystem.isDirectory(songRoot)) continue;

      final charts:Array<PsychChartFile> = [];
      for (file in sortedEntries(songRoot))
      {
        if (Path.extension(file).toLowerCase() != 'json') continue;
        final sourcePath = Path.join([songRoot, file]);
        if (FileSystem.isDirectory(sourcePath)) continue;

        final document = parseJson(sourcePath);
        if (document == null) continue;
        final songData:Dynamic = chartSongData(document);
        if (songData == null || !Std.isOfType(Reflect.field(songData, 'notes'), Array)) continue;

        charts.push({
          difficulty: difficultyFromFilename(songId, file),
          song: songData,
          document: document
        });
      }

      if (charts.length == 0) continue;
      charts.sort((a, b) -> Reflect.compare(a.difficulty, b.difficulty));
      indexSong(index, modRoot, songId, charts);
    }
  }

  static function indexSong(index:PsychModContentIndex, modRoot:String, id:String, charts:Array<PsychChartFile>):Void
  {
    final firstSong = charts[0].song;
    final difficulties:Array<String> = [];
    final chartNotes:Dynamic = {};
    final scrollSpeed:Dynamic = {};
    final timeChanges = convertTimeChanges(firstSong);
    var stageId = readString(firstSong, ['stage']) ?? 'mainStage';
    if (!FileSystem.exists(Path.join([modRoot, 'stages', '$stageId.json']))) stageId = 'mainStage';

    for (chart in charts)
    {
      final difficulty = chart.difficulty;
      if (!difficulties.contains(difficulty)) difficulties.push(difficulty);
      Reflect.setField(chartNotes, difficulty, convertNotes(chart.song));
      Reflect.setField(scrollSpeed, difficulty, numberValue(Reflect.field(chart.song, 'speed'), 1));
    }

    final player = readString(firstSong, ['player1']) ?? 'bf';
    final opponent = readString(firstSong, ['player2']) ?? 'dad';
    final girlfriend = readString(firstSong, ['gfVersion']) ?? 'gf';
    final title = readString(firstSong, ['song']) ?? id;

    final metadata:Dynamic = {
      version: SongRegistry.SONG_METADATA_VERSION,
      songName: title,
      artist: readString(firstSong, ['artist']) ?? 'Unknown',
      charter: readString(firstSong, ['charter']) ?? 'Unknown',
      generatedBy: SongRegistry.DEFAULT_GENERATEDBY,
      timeFormat: 'ms',
      timeChanges: timeChanges,
      playData: {
        difficulties: difficulties,
        characters: {
          player: player,
          girlfriend: girlfriend,
          opponent: opponent
        },
        stage: stageId,
        noteStyle: Constants.DEFAULT_NOTE_STYLE,
        ratings: {}
      }
    };

    final chart:Dynamic = {
      version: SongRegistry.SONG_CHART_DATA_VERSION,
      generatedBy: SongRegistry.DEFAULT_GENERATEDBY,
      scrollSpeed: scrollSpeed,
      events: convertEvents(firstSong),
      notes: chartNotes
    };

    final nativeRoot = 'gameplay/songs/$id/$id';
    addText(index, '$nativeRoot-metadata.json', Json.stringify(metadata));
    addText(index, '$nativeRoot-chart.json', Json.stringify(chart));
    indexSongAudio(index, modRoot, id, boolValue(Reflect.field(firstSong, 'needsVoices'), true));
  }

  static function convertNotes(song:Dynamic):Array<Dynamic>
  {
    final result:Array<Dynamic> = [];

    for (section in arrayValue(Reflect.field(song, 'notes')))
    {
      final mustHit = boolValue(Reflect.field(section, 'mustHitSection'), false);

      for (note in arrayValue(Reflect.field(section, 'sectionNotes')))
      {
        final values = arrayValue(note);
        if (values.length < 2) continue;

        final time = numberValue(values[0], 0);
        final psychLane = intValue(values[1], 0);
        final playerSide = psychLane > 3 ? !mustHit : mustHit;
        final lane = psychLane % 4;
        final length = values.length > 2 ? Math.max(0, numberValue(values[2], 0)) : 0;
        final kind = values.length > 3 ? Std.string(values[3]) : '';

        result.push({
          t: time,
          d: lane + (playerSide ? 0 : 4),
          l: length,
          k: kind == '' ? null : kind
        });
      }
    }

    return result;
  }

  static function convertTimeChanges(song:Dynamic):Array<Dynamic>
  {
    var bpm = numberValue(Reflect.field(song, 'bpm'), 100);
    var currentBpm = bpm;
    var sectionStart = 0.0;
    final result:Array<Dynamic> = [{t: 0, bpm: bpm}];

    for (section in arrayValue(Reflect.field(song, 'notes')))
    {
      final sectionBpm = numberValue(Reflect.field(section, 'bpm'), currentBpm);
      if (boolValue(Reflect.field(section, 'changeBPM'), false) && sectionBpm != currentBpm)
      {
        currentBpm = sectionBpm;
        result.push({t: sectionStart, bpm: currentBpm});
      }
      sectionStart += numberValue(Reflect.field(section, 'sectionBeats'), 4) * 60000 / Math.max(1, currentBpm);
    }

    return result;
  }

  static function convertEvents(song:Dynamic):Array<Dynamic>
  {
    final result:Array<Dynamic> = [];
    for (event in arrayValue(Reflect.field(song, 'events')))
    {
      final outer = arrayValue(event);
      if (outer.length < 2) continue;

      final time = numberValue(outer[0], 0);
      for (psychEvent in arrayValue(outer[1]))
      {
        final values = arrayValue(psychEvent);
        if (values.length == 0) continue;
        result.push({
          t: time,
          e: 'PsychEvent',
          v: {
            name: Std.string(values[0]),
            value1: values.length > 1 ? values[1] : '',
            value2: values.length > 2 ? values[2] : ''
          }
        });
      }
    }
    return result;
  }

  static function indexSongAudio(index:PsychModContentIndex, modRoot:String, id:String, needsVoices:Bool):Void
  {
    final sourceDir = Path.join([modRoot, 'songs', id]);
    if (!FileSystem.isDirectory(sourceDir)) return;

    final targetPrefix = 'gameplay/songs/$id';
    for (file in sortedEntries(sourceDir))
    {
      final source = Path.join([sourceDir, file]);
      if (FileSystem.isDirectory(source)) continue;
      final extension = Path.extension(file).toLowerCase();
      if (extension == 'ogg' || extension == 'mp3' || extension == 'wav')
      {
        if (!needsVoices && file.toLowerCase().startsWith('voices')) continue;
        addSource(index, '$targetPrefix/$file', source);
      }
    }
  }

  static function findImage(modRoot:String, image:String):Null<String>
  {
    var stem = image.trim().replace('\\', '/');
    while (stem.startsWith('/')) stem = stem.substring(1);
    if (stem.startsWith('assets/')) stem = stem.substring('assets/'.length);
    if (stem.startsWith('images/')) stem = stem.substring('images/'.length);
    stem = Path.withoutExtension(stem);

    final candidates = [
      Path.join([modRoot, 'images', '$stem.png']),
      Path.join([modRoot, '$stem.png'])
    ];
    for (candidate in candidates)
    {
      if (FileSystem.exists(candidate) && !FileSystem.isDirectory(candidate)) return candidate;
    }
    return null;
  }

  static function addImageAliases(index:PsychModContentIndex, assetBase:String, sourcePng:String):Void
  {
    addSource(index, '$assetBase.png', sourcePng);
    final sourceXml = Path.withoutExtension(sourcePng) + '.xml';
    if (FileSystem.exists(sourceXml)) addSource(index, '$assetBase.xml', sourceXml);
  }

  static function addText(index:PsychModContentIndex, assetPath:String, text:String):Void
  {
    final path = normalizeAssetPath(assetPath);
    final file = 'assets/$path';
    if (!index.files.contains(file)) index.files.push(file);
    index.texts.set(path, text);
  }

  static function addSource(index:PsychModContentIndex, assetPath:String, source:String):Void
  {
    final path = normalizeAssetPath(assetPath);
    final file = 'assets/$path';
    if (!index.files.contains(file)) index.files.push(file);
    index.sources.set(path, source);
  }

  static function chartSongData(document:Dynamic):Null<Dynamic>
  {
    final nested:Dynamic = Reflect.field(document, 'song');
    if (nested != null && !Std.isOfType(nested, String)) return nested;
    return document;
  }

  static function difficultyFromFilename(songId:String, filename:String):String
  {
    final base = Path.withoutExtension(filename).toLowerCase();
    final id = songId.toLowerCase();
    if (base == id || base == 'song') return 'normal';
    if (base.startsWith('$id-')) return base.substring(id.length + 1);
    return 'normal';
  }

  static function parseJson(path:String):Null<Dynamic>
  {
    try
    {
      return Json.parse(File.getContent(path));
    }
    catch (e:Dynamic)
    {
      trace('Failed to parse Psych mod data "$path": ${Std.string(e)}');
      return null;
    }
  }

  static function sortedEntries(path:String):Array<String>
  {
    final result = FileSystem.readDirectory(path);
    result.sort(Reflect.compare);
    return result;
  }

  static function readString(source:Dynamic, fields:Array<String>):Null<String>
  {
    if (source == null) return null;
    for (field in fields)
    {
      final value:Dynamic = Reflect.field(source, field);
      if (value != null && Std.string(value).trim() != '') return Std.string(value).trim();
    }
    return null;
  }

  static function arrayValue(value:Dynamic):Array<Dynamic>
  {
    return Std.isOfType(value, Array) ? cast value : [];
  }

  static function numberArray(value:Dynamic, fallback:Array<Float>):Array<Float>
  {
    final values = arrayValue(value);
    if (values.length < 2) return fallback.copy();
    return [numberValue(values[0], fallback[0]), numberValue(values[1], fallback[1])];
  }

  static function numberValue(value:Dynamic, fallback:Float):Float
  {
    if (value == null) return fallback;
    final parsed = Std.parseFloat(Std.string(value));
    return Math.isNaN(parsed) ? fallback : parsed;
  }

  static function intValue(value:Dynamic, fallback:Int):Int
  {
    if (value == null) return fallback;
    final parsed = Std.parseInt(Std.string(value));
    return parsed == null ? fallback : parsed;
  }

  static function boolValue(value:Dynamic, fallback:Bool):Bool
  {
    return value == null ? fallback : value == true;
  }

  static function normalizeAssetPath(path:String):String
  {
    var result = Path.normalize(path).replace('\\', '/');
    while (result.startsWith('/')) result = result.substring(1);
    if (result.startsWith('assets/')) result = result.substring('assets/'.length);
    return result;
  }
}

private typedef PsychChartFile =
{
  var difficulty:String;
  var song:Dynamic;
  var document:Dynamic;
}

private typedef PsychModContentIndex =
{
  var files:Array<String>;
  var texts:Map<String, String>;
  var sources:Map<String, String>;
}
#end
