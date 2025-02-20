package backend;

import flixel.FlxG;
import flixel.math.FlxMath;

class AIPlayer
{
	public static var BadNoteTypes:Array<String> = ['Hurt Note'];
	public static var active:Bool = false;
	public static var diff:Int = 1;

	/*
	 * make a humidity system type of shit by calculating how many notes there are
	 * the closer the humidity is to the best humidity, this benefits the AI best
	 * although higher humidity will guarantee higher accuracy
	 * 
	 * 
	 * 
	 * the fps will always be locked to 80 fps for the ai
	 */
	public static function GeneratePlayMap(map:Song.SwagSong, diff:Int):Array<Array<Float>>
	{
		var strumList:Array<Array<Float>> = [];

		switch (diff)
		{
            case 0: //First Time Playing FNF
				{
					var ratingChance:Array<Float> = [0, 0, 0, 70, 95];
					var isolatedHits:Array<Array<Float>> = isolateHits(map);

					for (section in isolatedHits)
					{
						strumList[isolatedHits.indexOf(section)] = [];

						for (note in section)
						{
							if (FlxG.random.bool(6.5))
							{
								strumList[isolatedHits.indexOf(section)][section.indexOf(note)] = -FlxMath.MAX_VALUE_FLOAT;
							}
							else
							{
								var timingWindows:Array<Null<Float>> = [
									ClientPrefs.data.marvWindow,
                                    ClientPrefs.data.sickWindow,
									ClientPrefs.data.goodWindow,
									ClientPrefs.data.badWindow,
									Conductor.safeZoneOffset
								];

								var selectedRating:Int = FlxG.random.weightedPick(ratingChance);

								if (selectedRating == 0)
									strumList[isolatedHits.indexOf(section)][section.indexOf(note)] = FlxG.random.float(-(ClientPrefs.data.marvWindow / FlxG.random.float(1.5)),
								(ClientPrefs.data.marvWindow / 1.5));
								else
								{
									if (timingWindows[Std.int(selectedRating + 1)] != null)
										strumList[isolatedHits.indexOf(section)][section.indexOf(note)] = FlxG.random.float(timingWindows[selectedRating],
											timingWindows[Std.int(selectedRating + 1)]);
									else
									{
										strumList[isolatedHits.indexOf(section)][section.indexOf(note)] = FlxG.random.float(timingWindows[selectedRating - 1],
											timingWindows[selectedRating]);
									}
									strumList[isolatedHits.indexOf(section)][section.indexOf(note)] *= FlxG.random.sign();
								}
							}

							//trace('section: ${isolatedHits.indexOf(section)}, id: ${section.indexOf(note)}, strum: ${strumList[isolatedHits.indexOf(section)][section.indexOf(note)]}ms');
						}
					}
				}
			case 1: //I Play Occasonally
				{
					var ratingChance:Array<Float> = [5, 10, 30, 60, 90];
					var isolatedHits:Array<Array<Float>> = isolateHits(map);

					for (section in isolatedHits)
					{
						strumList[isolatedHits.indexOf(section)] = [];

						for (note in section)
						{
							if (FlxG.random.bool(6.5))
							{
								strumList[isolatedHits.indexOf(section)][section.indexOf(note)] = -FlxMath.MAX_VALUE_FLOAT;
							}
							else
							{
								var timingWindows:Array<Null<Float>> = [
									ClientPrefs.data.marvWindow,
                                    ClientPrefs.data.sickWindow,
									ClientPrefs.data.goodWindow,
									ClientPrefs.data.badWindow,
									Conductor.safeZoneOffset
								];

								var selectedRating:Int = FlxG.random.weightedPick(ratingChance);

								if (selectedRating == 0)
									strumList[isolatedHits.indexOf(section)][section.indexOf(note)] = FlxG.random.float(-(ClientPrefs.data.marvWindow / FlxG.random.float(1.5)),
								(ClientPrefs.data.marvWindow / 1.5));
								else
								{
									if (timingWindows[Std.int(selectedRating + 1)] != null)
										strumList[isolatedHits.indexOf(section)][section.indexOf(note)] = FlxG.random.float(timingWindows[selectedRating],
											timingWindows[Std.int(selectedRating + 1)]);
									else
									{
										strumList[isolatedHits.indexOf(section)][section.indexOf(note)] = FlxG.random.float(timingWindows[selectedRating - 1],
											timingWindows[selectedRating]);
									}
									strumList[isolatedHits.indexOf(section)][section.indexOf(note)] *= FlxG.random.sign();
								}
							}

							//trace('section: ${isolatedHits.indexOf(section)}, id: ${section.indexOf(note)}, strum: ${strumList[isolatedHits.indexOf(section)][section.indexOf(note)]}ms');
						}
					}
				}
			case 2: //I play all the time
				{
					var ratingChance:Array<Float> = [50, 20, 10, 1.3, 0.1];
					var isolatedHits:Array<Array<Float>> = isolateHits(map);

					for (section in isolatedHits)
					{
						strumList[isolatedHits.indexOf(section)] = [];

						for (note in section)
						{
							if (FlxG.random.bool(3.5))
							{
								strumList[isolatedHits.indexOf(section)][section.indexOf(note)] = -FlxMath.MAX_VALUE_FLOAT;
							}
							else
							{
								var timingWindows:Array<Null<Float>> = [
									ClientPrefs.data.marvWindow,
                                    ClientPrefs.data.sickWindow,
									ClientPrefs.data.goodWindow,
									ClientPrefs.data.badWindow,
									Conductor.safeZoneOffset
								];

								var selectedRating:Int = FlxG.random.weightedPick(ratingChance);

								if (selectedRating == 0)
									strumList[isolatedHits.indexOf(section)][section.indexOf(note)] = FlxG.random.float(-ClientPrefs.data.marvWindow,
										ClientPrefs.data.marvWindow);
								else
								{
									if (timingWindows[Std.int(selectedRating + 1)] != null)
										strumList[isolatedHits.indexOf(section)][section.indexOf(note)] = FlxG.random.float(timingWindows[selectedRating] / 1.35,
											timingWindows[Std.int(selectedRating
											+ 1)] / 1.35);
									else
									{
										strumList[isolatedHits.indexOf(section)][section.indexOf(note)] = FlxG.random.float(timingWindows[selectedRating - 1] / 1.35,
											timingWindows[selectedRating] / 1.35);
									}
									strumList[isolatedHits.indexOf(section)][section.indexOf(note)] *= FlxG.random.sign();
								}
							}

							//trace('section: ${isolatedHits.indexOf(section)}, id: ${section.indexOf(note)}, strum: ${strumList[isolatedHits.indexOf(section)][section.indexOf(note)]}ms');
						}
					}
				}
			case 3: //FNF is my life, my religion, and everything I breath for
				{
					var ratingChance:Array<Float> = [70, 50, 20, 0.5, 0.0];
					var isolatedHits:Array<Array<Float>> = isolateHits(map);

					for (section in isolatedHits)
					{
						strumList[isolatedHits.indexOf(section)] = [];

						for (note in section)
						{
							var timingWindows:Array<Null<Float>> = [
                                ClientPrefs.data.marvWindow,
                                ClientPrefs.data.sickWindow,
                                ClientPrefs.data.goodWindow,
                                ClientPrefs.data.badWindow,
                                Conductor.safeZoneOffset
                            ];

							var selectedRating:Int = FlxG.random.weightedPick(ratingChance);

							if (selectedRating == 0)
								strumList[isolatedHits.indexOf(section)][section.indexOf(note)] = FlxG.random.float(-ClientPrefs.data.marvWindow,
									ClientPrefs.data.marvWindow);
							else
							{
								if (timingWindows[Std.int(selectedRating + 1)] != null)
									strumList[isolatedHits.indexOf(section)][section.indexOf(note)] = FlxG.random.float(timingWindows[selectedRating] / 1.35,
										timingWindows[Std.int(selectedRating + 1)] / 1.35);
								else
								{
									strumList[isolatedHits.indexOf(section)][section.indexOf(note)] = FlxG.random.float(timingWindows[selectedRating - 1] / 1.35,
										timingWindows[selectedRating] / 1.35);
								}
								strumList[isolatedHits.indexOf(section)][section.indexOf(note)] *= FlxG.random.sign();
							}

							//trace('section: ${isolatedHits.indexOf(section)}, id: ${section.indexOf(note)}, strum: ${strumList[isolatedHits.indexOf(section)][section.indexOf(note)]}ms');
						}
					}
				}
            case 4: //Hi, my name is SillyFangirlosu
				{
					var ratingChance:Array<Float> = [90, 70, 0.5, 0.1, 0.01];
					var isolatedHits:Array<Array<Float>> = isolateHits(map);

					for (section in isolatedHits)
					{
						strumList[isolatedHits.indexOf(section)] = [];

						for (note in section)
						{
							var timingWindows:Array<Null<Float>> = [
                                ClientPrefs.data.marvWindow,
                                ClientPrefs.data.sickWindow,
                                ClientPrefs.data.goodWindow,
                                ClientPrefs.data.badWindow,
                                Conductor.safeZoneOffset
                            ];

							var selectedRating:Int = FlxG.random.weightedPick(ratingChance);

							if (selectedRating == 0)
								strumList[isolatedHits.indexOf(section)][section.indexOf(note)] = FlxG.random.float(-ClientPrefs.data.marvWindow,
									ClientPrefs.data.marvWindow);
							else
							{
								if (timingWindows[Std.int(selectedRating + 1)] != null)
									strumList[isolatedHits.indexOf(section)][section.indexOf(note)] = FlxG.random.float(timingWindows[selectedRating] / 1.35,
										timingWindows[Std.int(selectedRating + 1)] / 1.35);
								else
								{
									strumList[isolatedHits.indexOf(section)][section.indexOf(note)] = FlxG.random.float(timingWindows[selectedRating - 1] / 1.35,
										timingWindows[selectedRating] / 1.35);
								}
								strumList[isolatedHits.indexOf(section)][section.indexOf(note)] *= FlxG.random.sign();
							}

							//trace('section: ${isolatedHits.indexOf(section)}, id: ${section.indexOf(note)}, strum: ${strumList[isolatedHits.indexOf(section)][section.indexOf(note)]}ms');
						}
					}
				}
			case 5: //Average "Thanos if she didnt have a sucky computer" player:
				{
					var ratingChance:Array<Float> = [90, 10, 0.1, 0.01, 0.001];
					var isolatedHits:Array<Array<Float>> = isolateHits(map);

					for (section in isolatedHits)
					{
						strumList[isolatedHits.indexOf(section)] = [];

						for (note in section)
						{
							var timingWindows:Array<Null<Float>> = [
                                ClientPrefs.data.marvWindow,
                                ClientPrefs.data.sickWindow,
                                ClientPrefs.data.goodWindow,
                                ClientPrefs.data.badWindow,
                                Conductor.safeZoneOffset
                            ];

							var selectedRating:Int = FlxG.random.weightedPick(ratingChance);

							if (selectedRating == 0)
								strumList[isolatedHits.indexOf(section)][section.indexOf(note)] = FlxG.random.float(ClientPrefs.data.sickWindow,
									ClientPrefs.data.marvWindow);
							else
							{
								if (timingWindows[Std.int(selectedRating + 1)] != null)
									strumList[isolatedHits.indexOf(section)][section.indexOf(note)] = FlxG.random.float(timingWindows[selectedRating] / 1.35,
										timingWindows[Std.int(selectedRating + 1)] / 1.35);
								else
								{
									strumList[isolatedHits.indexOf(section)][section.indexOf(note)] = FlxG.random.float(timingWindows[selectedRating - 1] / 1.35,
										timingWindows[selectedRating] / 1.35);
								}
								strumList[isolatedHits.indexOf(section)][section.indexOf(note)] *= FlxG.random.sign();
							}

							//trace('section: ${isolatedHits.indexOf(section)}, id: ${section.indexOf(note)}, strum: ${strumList[isolatedHits.indexOf(section)][section.indexOf(note)]}ms');
						}
					}
				}
            case 6: //Boyfriend getting freaky on a friday night:
				{
					var ratingChance:Array<Float> = [100, 0, 0, 0, 0];
					var isolatedHits:Array<Array<Float>> = isolateHits(map);

					for (section in isolatedHits)
					{
						strumList[isolatedHits.indexOf(section)] = [];

						for (note in section)
						{
							var timingWindows:Array<Null<Float>> = [
                                ClientPrefs.data.marvWindow,
                                ClientPrefs.data.sickWindow,
                                ClientPrefs.data.goodWindow,
                                ClientPrefs.data.badWindow,
                                Conductor.safeZoneOffset
                            ];

							var selectedRating:Int = FlxG.random.weightedPick(ratingChance);

							if (selectedRating == 0)
								strumList[isolatedHits.indexOf(section)][section.indexOf(note)] = ClientPrefs.data.marvWindow;
							else
							{
								if (timingWindows[Std.int(selectedRating + 1)] != null)
									strumList[isolatedHits.indexOf(section)][section.indexOf(note)] = FlxG.random.float(timingWindows[selectedRating] / 1.35,
										timingWindows[Std.int(selectedRating + 1)] / 1.35);
								else
								{
									strumList[isolatedHits.indexOf(section)][section.indexOf(note)] = FlxG.random.float(timingWindows[selectedRating - 1] / 1.35,
										timingWindows[selectedRating] / 1.35);
								}
								strumList[isolatedHits.indexOf(section)][section.indexOf(note)] *= FlxG.random.sign();
							}

							//trace('section: ${isolatedHits.indexOf(section)}, id: ${section.indexOf(note)}, strum: ${strumList[isolatedHits.indexOf(section)][section.indexOf(note)]}ms');
						}
					}
				}
		}

		return strumList;
	}

	private static function isolateHits(map:Song.SwagSong):Array<Array<Float>>
	{
		var opponentNotes:Array<Array<Float>> = [];
		for (sect in map.notes)
		{
			opponentNotes[map.notes.indexOf(sect)] = [];
			for (note in sect.sectionNotes)
			{
				var gottaHitNote:Bool = sect.mustHitSection;

				if (note[1] > 3)
				{
					gottaHitNote = !sect.mustHitSection;
				}

				if (!gottaHitNote)
					opponentNotes[map.notes.indexOf(sect)][sect.sectionNotes.indexOf(note)] = note[0];
			}
		}
		return opponentNotes;
	}
}

typedef Hand =
{
	var Finger1:Finger;
	var Finger2:Finger;
}

class Finger
{
	public var noteDirection:Int;
	public var tiredness:Float = 1.0;

	public function new(noteDirection:Int)
	{
		this.noteDirection = noteDirection;
	}
}