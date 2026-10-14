package backend.funkin.util;

import objects.notes.Note;
import objects.notes.Strumline;

/**
 * A structure to hold the hit window values.
 * @param start The start time of the hit window.
 * @param center The center time of the hit window.
 * @param end The end time of the hit window.
 */
typedef HitWindow =
{
  public var start:Float;
  public var center:Float;
  public var end:Float;
}

/**
 * A structure to hold the result of a hit window check for botplay.
 * @param botplayHit True if the note was hit by botplay.
 * @param cont True if the game should continue after the hit.
 */
typedef HitWindowRes =
{
  public var botplayHit:Bool;
  public var cont:Bool;
}

/**
 * GRhythmUtil
 * A utility class for processing hit windows, and calculating the y-position of notes.
 */
class GRhythmUtil
{
  /**
   * Mirror the note direction.
   * @param noteData The original note direction.
   * @return The mirrored note direction.
   */
  public static function mirrorNoteDirection(noteData:Int):Int
  {
    final MAX_KEY_VALUE:Int = (noteData < (ExtraKeys.mania+1) ? (ExtraKeys.mania+1) : (ExtraKeys.mania+1) * 2);

    return (MAX_KEY_VALUE - 1) - (noteData % (ExtraKeys.mania+1));
  }

  /**
   * Get the current hit window for a note.
   * @param note The note to get the hit window for.
   * @return A HitWindow object containing the start, center, and end times of the hit window.
   */
  public static function getHitWindow(note:Note):HitWindow
  {
    return {
      start: note.strumTime - (Constants.HIT_WINDOW_MS #if FEATURE_WITF_INPUTS * note.hitWindowMultiplier #end),
      center: note.strumTime,
      end: note.strumTime + (Constants.HIT_WINDOW_MS #if FEATURE_WITF_INPUTS * note.hitWindowMultiplier #end)
    };
  }

  /**
   * Get the y-position of a note based on its strum time.
   * @param strumTime The strum time of the note.
   * @param scrollSpeed The scroll speed of the strumline.
   * @param downscroll Whether the strumline is in downscroll mode.
   * @param conductorInUse The conductor to use for calculating the y-position.
   * @return The y-position of the note.
   */
  public static function getNoteY(strumTime:Float, scrollSpeed:Float, downscroll:Bool = false, ?conductorInUse:RConductor):Float
  {
    if (conductorInUse == null) conductorInUse = MegaManager.conductor;
    return Constants.PIXELS_PER_MS * (conductorInUse.getTimeWithDelta() - strumTime) * scrollSpeed * (downscroll ? 1 : -1);
  }
}
