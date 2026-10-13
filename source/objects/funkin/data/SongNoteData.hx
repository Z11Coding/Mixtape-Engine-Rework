package objects.funkin.data;

/**
 * The underlying data for a single note.
 */
class SongNoteDataRaw implements ICloneable<SongNoteDataRaw>
{
  /**
   * The timestamp of the note. The timestamp is in the format of the song's time format.
   */
  @:alias("t")
  public var time(default, set):Float;

  function set_time(value:Float):Float
  {
    _stepTime = null;
    return time = value;
  }

  /**
   * Data for the note. Represents the index on the strumline.
   * 0 = left, 1 = down, 2 = up, 3 = right
   * `floor(direction / strumlineSize)` specifies which strumline the note is on.
   * 0 = player, 1 = opponent, etc.
   */
  @:alias("d")
  public var data:Int;

  /**
   * Length of the note, if applicable.
   * Defaults to 0 for single notes.
   */
  @:alias("l") @:default(0) @:optional
  public var length(default, set):Float;

  function set_length(value:Float):Float
  {
    _stepLength = null;
    return length = value;
  }

  /**
   * The kind of the note.
   * This can allow the note to include information used for custom behavior.
   * Defaults to `null` for no kind.
   */
  @:alias("k") @:optional @:isVar
  public var kind(get, set):Null<String> = null;

  function get_kind():Null<String>
  {
    if (this.kind == null || this.kind == '') return null;

    return this.kind;
  }

  function set_kind(value:Null<String>):Null<String>
  {
    if (value == '') value = null;
    return this.kind = value;
  }

  /**
   * The parameters for the note.
   * Used for custom behavior on custom note kinds. Defaults to an empty array.
   */
  @:alias("p") @:default([]) @:optional
  public var params:Array<NoteParamData>;

  public function new(time:Float, data:Int, length:Float = 0, kind:String = '', ?params:Array<NoteParamData>)
  {
    this.time = time;
    this.data = data;
    this.length = length;
    this.kind = kind;
    this.params = params ?? [];
  }

  /**
   * The direction of the note, if applicable.
   * Strips the strumline index from the data.
   *
   * 0 = left, 1 = down, 2 = up, 3 = right
   *
   * @param strumlineSize The size of the strumline for the current song. Defaults to 4.
   * @return The direction of the note as an index.
   */
  public inline function getDirection(strumlineSize:Int = 4):Int
  {
    return this.data % strumlineSize;
  }

  /**
   * The name of the direction of the note, if applicable.
   * Strips the strumline index from the data.
   *
   * @param strumlineSize The size of the strumline for the current song. Defaults to 4.
   * @return The direction of the note as a name.
   */
  public function getDirectionName(strumlineSize:Int = 4):String
  {
    return SongNoteData.buildDirectionName(this.data, strumlineSize);
  }

  /**
   * The strumline index of the note, if applicable.
   * Strips the direction from the data.
   *
   * 0 = player, 1 = opponent, etc.
   *
   * @param strumlineSize The size of the strumline for the current song. Defaults to 4.
   * @return The strumline index of the note.
   */
  public function getStrumlineIndex(strumlineSize:Int = 4):Int
  {
    return Math.floor(this.data / strumlineSize);
  }

  /**
   * Returns true if the note is one that Boyfriend should try to hit (i.e. it's on his side).
   * TODO: The name of this function is a little misleading; what about mines?
   * @param strumlineSize Defaults to 4.
   * @return True if it's Boyfriend's note.
   */
  public function getMustHitNote(strumlineSize:Int = 4):Bool
  {
    return getStrumlineIndex(strumlineSize) == 0;
  }

  /**
   * The position of the note in the song, in steps.
   * Calculated from the time and the BPM.
   * Cached for performance. Set to `null` to recalculate.
   */
  @:jignored
  var _stepTime:Null<Float> = null;

  /**
   * @param force Set to `true` to force recalculation (good after BPM changes)
   * @return The position of the note in the song, in steps.
   */
  public function getStepTime(force:Bool = false):Float
  {
    if (_stepTime != null && !force) return _stepTime;

    return _stepTime = Conductor.instance.getTimeInSteps(this.time);
  }

  /**
   * The length of the note, if applicable, in steps.
   * Calculated from the length and the BPM.
   * Cached for performance. Set to `null` to recalculate.
   */
  @:jignored
  var _stepLength:Null<Float> = null;

  /**
   * @param force Set to `true` to force recalculation (good after BPM changes)
   * @return The length of the hold note in steps, or `0` if this is not a hold note.
   */
  public function getStepLength(force = false):Float
  {
    if (this.length <= 0) return 0.0;

    if (_stepLength != null && !force) return _stepLength;

    return _stepLength = Conductor.instance.getTimeInSteps(this.time + this.length) - getStepTime();
  }

  /**
   * Set the length of the hold note, in steps.
   * @param value The desired length of the hold note, in steps. Use `0` to make this a tap note.
   */
  public function setStepLength(value:Float):Void
  {
    if (value <= 0)
    {
      this.length = 0.0;
    }
    else
    {
      var endStep:Float = getStepTime() + value;
      var endMs:Float = Conductor.instance.getStepTimeInMs(endStep);
      var lengthMs:Float = endMs - this.time;

      this.length = lengthMs;
    }

    // Recalculate the step length next time it's requested.
    _stepLength = null;
  }

  /**
   * Clone the `params` data for this node, creating a new independent instance.
   * @return A new array of cloned `NoteParamData` instances.
   */
  public function cloneParams():Array<NoteParamData>
  {
    var newParams:Array<NoteParamData> = [];
    for (param in this.params)
    {
      newParams.push(param.clone());
    }
    return newParams;
  }

   /**
   * Clone this song note data, creating a new independent instance with identical data.
   * @return The newly created song note data.
   */
  public function clone():SongNoteDataRaw
  {
    return new SongNoteDataRaw(this.time, this.data, this.length, this.kind, cloneParams());
  }

  public function toString():String
  {
    return 'SongNoteData(${this.time}ms, ' + (this.length > 0 ? '[${this.length}ms hold]' : '') + ' ${this.data}'
      + (this.kind != '' ? ' [kind: ${this.kind}])' : ')');
  }

  /**
   * Build a tooltip string for this note, as seen when hovering in the Chart Editor.
   * @return The tooltip string to display.
   */
  public function buildTooltip():String
  {
    if ((this.kind?.length ?? 0) == 0) return '';

    var noteKind:Null<NoteKind> = NoteKindManager.getNoteKind(this.kind);
    var noteKindDesc:String = noteKind?.description ?? this.kind;

    var result:String = 'Kind: $noteKindDesc';
    if (this.params.length == 0) return result;

    result += '\nParams:';

    for (param in params)
    {
      result += '\n- ${param.name}: ${param.value}';
    }

    return result;
  }
}

/**
 * Wrap SongNoteData in an abstract so we can overload operators.
 * Don't want to have to use this, but for the sake of just getting it working, it'll have to do.
 */
@:forward
abstract SongNoteData(SongNoteDataRaw) from SongNoteDataRaw to SongNoteDataRaw
{
  public function new(time:Float, data:Int, length:Float = 0, ?params:Array<NoteParamData>)
  {
    this = new SongNoteDataRaw(time, data, length, params);
  }

  public static function buildDirectionName(data:Int, strumlineSize:Int = 4):String
  {
    switch (data % strumlineSize)
    {
      case 0:
        return 'Left';
      case 1:
        return 'Down';
      case 2:
        return 'Up';
      case 3:
        return 'Right';
      case 4:
        return 'Center';
      default:
        return 'Unknown';
    }
  }

  /**
   * Whether this note is a hold note.
   */
  @:jignored
  public var isHoldNote(get, never):Bool;

  function get_isHoldNote():Bool
  {
    return this.length > 0;
  }

  /**
   * Determine if two notes are equal.
   * Ex. `note1 == note2`
   *
   * @param other The other note to compare.
   * @return Whether the two notes have equal data.
   */
  @:op(A == B)
  public function op_equals(other:SongNoteData):Bool
  {
    // Handle the case where one value is null.
    if (this == null) return other == null;
    if (other == null) return false;

    if (this.kind == null || this.kind == '')
    {
      if (other.kind != '' && this.kind != null) return false;
    }
    else
    {
      if (other.kind == '' || this.kind == null) return false;
    }

    return this.time == other.time && this.data == other.data && this.length == other.length && this.params == other.params;
  }

  @:op(A != B)
  public function op_notEquals(other:SongNoteData):Bool
  {
    // Handle the case where one value is null.
    if (this == null) return other == null;
    if (other == null) return false;

    if (this.kind == '')
    {
      if (other.kind != '') return true;
    }
    else
    {
      if (other.kind == '') return true;
    }

    return this.time != other.time || this.data != other.data || this.length != other.length || this.params != other.params;
  }

  @:op(A > B)
  public function op_greaterThan(other:SongNoteData):Bool
  {
    if (other == null) return false;

    return this.time > other.time;
  }

  @:op(A < B)
  public function op_lessThan(other:SongNoteData):Bool
  {
    if (other == null) return false;

    return this.time < other.time;
  }

  @:op(A >= B)
  public function op_greaterThanOrEquals(other:SongNoteData):Bool
  {
    if (other == null) return false;

    return this.time >= other.time;
  }

  @:op(A <= B)
  public function op_lessThanOrEquals(other:SongNoteData):Bool
  {
    if (other == null) return false;

    return this.time <= other.time;
  }

  public function clone():SongNoteData
  {
    return new SongNoteData(this.time, this.data, this.length, this.kind, this.params);
  }

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongNoteData(${this.time}ms, ' + (this.length > 0 ? '[${this.length}ms hold]' : '') + ' ${this.data}'
      + (this.kind != '' ? ' [kind: ${this.kind}])' : ')');
  }
}

class NoteParamData implements ICloneable<NoteParamData>
{
  @:alias("n")
  public var name:String;
  @:alias("v")
  public var value:Dynamic;

  public function new(name:String, value:Dynamic)
  {
    this.name = name;
    this.value = value;
  }

  public function clone():NoteParamData
  {
    return new NoteParamData(this.name, this.value);
  }

  public function toString():String
  {
    return 'NoteParamData(${this.name}, ${this.value})';
  }
}
