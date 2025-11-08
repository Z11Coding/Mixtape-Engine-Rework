package states.freeplay.vslice.capsule;

import backend.ClientPrefs;
import backend.Paths;
import flixel.FlxSprite;
import openfl.display.BlendMode;
import states.freeplay.vslice.obj.SngCapsuleData.ScoringRank;

/**
 * Rank display component for freeplay capsules
 * Adapted from P-Slice for Mixtape Engine
 */
class FreeplayRank extends FlxSprite
{
	public var rank(default, set):Null<ScoringRank> = null;

	function set_rank(val:Null<ScoringRank>):Null<ScoringRank>
	{
		rank = val;

		if (rank == null || val == null)
		{
			this.visible = false;
		}
		else
		{
			this.visible = true;

			// Convert rank to animation name
			var animName = switch(val) {
				case SHIT: 'LOSS';
				case GOOD: 'GOOD';
				case GREAT: 'GREAT';
				case EXCELLENT: 'EXCELLENT';
				case PERFECT: 'PERFECT';
				case PERFECT_GOLD: 'PERFECTSICK';
			}

			animation.play(animName, true, false);
			centerOffsets(false);

			switch (val)
			{
				case SHIT:
					// offset.x -= 1;
				case GOOD:
					// offset.x -= 1;
					offset.y -= 8;
				case GREAT:
					// offset.x -= 1;
					offset.y -= 8;
				case EXCELLENT:
					// offset.y += 5;
				case PERFECT:
					// offset.y += 5;
				case PERFECT_GOLD:
					// offset.y += 5;
				default:
					centerOffsets(false);
					this.visible = false;
			}
			updateHitbox();
		}

		return rank = val;
	}

	public var baseX:Float = 0;
	public var baseY:Float = 0;

	public function new(x:Float, y:Float)
	{
		super(x, y);

		frames = Paths.getSparrowAtlas('freeplay/rankbadges', 'vslice');

		// Create fallback if frames don't exist
		if (frames == null) {
			makeGraphic(50, 50, 0xFF888888);
		} else {
			animation.addByPrefix('PERFECT', 'PERFECT rank0', 24, false);
			animation.addByPrefix('EXCELLENT', 'EXCELLENT rank0', 24, false);
			animation.addByPrefix('GOOD', 'GOOD rank0', 24, false);
			animation.addByPrefix('PERFECTSICK', 'PERFECT rank GOLD', 24, false);
			animation.addByPrefix('GREAT', 'GREAT rank0', 24, false);
			animation.addByPrefix('LOSS', 'LOSS rank0', 24, false);
		}

		blend = BlendMode.ADD;
		antialiasing = ClientPrefs.data.antialiasing;
		this.rank = null;

		scale.set(0.9, 0.9);
		updateHitbox();
	}
}


