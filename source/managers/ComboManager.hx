package managers;

import backend.Rating;
#if LUA_ALLOWED
import psychlua.*;

using psychlua.IntegratedScript;
#else
import psychlua.HScript;
import psychlua.LuaUtils;
#end

/*
    The very fun combo manager because yes!!!

    as of right now it only handles the actual stats of a song
    but i plan on also making handle the visual aspect as well
*/

class ComboManager {
    public static var instance:ComboManager;

    // Wife3 Accuracy System STANDARD (StepMania)
	public var wife3Scores:Array<Float> = []; // Save the score of each individual note
	public var wife3_maxms:Float = 180.0; // Maximum timing window in milliseconds (boo window)

	// Psych Engine/Mixtape Engine Accuracy System (Original)
	// Use totalNotesHit (Mod rating summary) and totalPlayed
    public var ratingsData:Array<Rating> = Rating.loadDefault();
    public var combo:Int = 0;
    public var maxCombo:Int = 0;
	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
    public var comboBreaks:Int = 0; // Combo breaks counter (includes misses + bad/shit if activated)
    public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
    public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	// Simple Accuracy System
	public var notesHitSimple:Int = 0; // Simple struck note counter

	// osu!mania Accuracy System
	public var osuMania_n300:Int = 0;  // Epic/Sick hits
	public var osuMania_n200:Int = 0;  // Good hits
	public var osuMania_n100:Int = 0;  // Bad hits
	public var osuMania_n50:Int = 0;   // Shit hits
	public var osuMania_nMiss:Int = 0; // Misses

	// DJMAX Accuracy System
	public var djmax_maxPerfect:Int = 0;
	public var djmax_perfect:Int = 0;
	public var djmax_great:Int = 0;
	public var djmax_good:Int = 0;
	public var djmax_bad:Int = 0;
	public var djmax_miss:Int = 0;
	public var djmax_combo:Int = 0;
	public var djmax_maxCombo:Int = 0;

	// ITG (Dance Points) System
	public var itg_FantasticPlus:Int = 0; // W0 - Epic (±15ms)
	public var itg_Fantastic:Int = 0;     // W1 - Sick (±22.5ms)
	public var itg_Excellent:Int = 0;     // W2 - Good (±45ms)
	public var itg_Great:Int = 0;         // W3 - Bad (±90ms)
	public var itg_Decent:Int = 0;        // W4 - Shit (±135ms)
	public var itg_WayOff:Int = 0;        // W5 - Boo (±180ms)
	public var itg_Miss:Int = 0;
	public var itg_DP:Float = 0.0;        // Dance Points acumulativo

    public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], //From 0% to 19%
		['Shit', 0.4], //From 20% to 39%
		['Bad', 0.5], //From 40% to 49%
		['Bruh', 0.6], //From 50% to 59%
		['Meh', 0.69], //From 60% to 68%
		['Nice', 0.7], //69%
		['Good', 0.8], //From 70% to 79%
		['Great', 0.9], //From 80% to 89%
		['Sick!', 1], //From 90% to 99%
		['Perfect!!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];

    public static function getRatingStuff():Array<Dynamic> {
		return [
			// Normal Ratings (0% - 100%) - Wife3 standard does not allow negative ratings
			[Language.getPhrase('rating_terrible', 'please hit the notes.'), 0], // 0% a 20%

			// Normal Ratings (0% - 100%)
			[Language.getPhrase('rating_you_suck', 'You Suck!'), 0.2],
			[Language.getPhrase('rating_shit', 'Shit'), 0.4],
			[Language.getPhrase('rating_bad', 'Bad'), 0.5],
			[Language.getPhrase('rating_bruh', 'Bruh'), 0.6],
			[Language.getPhrase('rating_meh', 'Meh'), 0.69],
			[Language.getPhrase('rating_nice', 'Nice'), 0.7],
			[Language.getPhrase('rating_good', 'Good'), 0.8],
			[Language.getPhrase('rating_great', 'Great'), 0.9],
			[Language.getPhrase('rating_sick', 'Sick!'), 0.95],
			[Language.getPhrase('rating_marv', 'Marvelous!!'), 1],

			// Superior Ratings (>100%) - Achievable with bonus system
			[Language.getPhrase('rating_perfect', 'Perfect!!!'), 1.05], // 100% - 105%
			[Language.getPhrase('rating_fantastic', 'FANTASTIC!!!!'), 1.10], // 105% - 110%
			[Language.getPhrase('rating_phenominal', '★ PHENOMINAL ★'), 1.15] // >110% (theoretical maximum ~115%)
		];
	}

    //AI Stuff
    public var AIScore:Int = 0;
    public var AIMisses:Int = 0;
    public var AITotalNotesHit:Float = 0;
    public var AITotalPlayed:Int = 0;
    public var ratingNameAI:String = '?';
	public var ratingPercentAI:Float;
	public var ratingFCAI:String;
    public var comboOpp:Int = 0;

    public function new() {
        instance = this;
    }

    public dynamic function fullComboFunctionAI()
    {
        ratingFCAI = "";

        var marvs:Int = ratingsData[0].hits;
        var sicks:Int = ratingsData[1].hits;
        var goods:Int = ratingsData[2].hits;
        var bads:Int = ratingsData[3].hits;
        var shits:Int = ratingsData[4].hits;

        if (AIMisses == 0)
        {
            if (bads > 0 || shits > 0)
                ratingFCAI = '[Full Combo]';
            else if (goods > 0)
                ratingFCAI = '[Good Full Combo]';
            else if (sicks > 0)
                ratingFCAI = '[Sick Full Combo]';
            else if (marvs > 0)
                ratingFCAI = '[Marvelous Full Combo]';
        }
        else
        {
            if (AIMisses < 10)
                ratingFCAI = '[Single Digit Combo Break]';
            else
                ratingFCAI = '[Ok I guess...]';
        }
    }

    public dynamic function fullComboFunction()
    {
        ratingFC = "";

        var marvs:Int = ratingsData[0].hits;
        var sicks:Int = ratingsData[1].hits;
        var goods:Int = ratingsData[2].hits;
        var bads:Int = ratingsData[3].hits;
        var shits:Int = ratingsData[4].hits;

        if (songMisses == 0)
        {
            if (shits > 0)
                ratingFC = '[Full Combo]';
            else if (bads > 0)
                ratingFC = '[Bad Full Combo]';
            else if (goods > 1)
                ratingFC = '[Accurate Full Combo]';
            else if (goods > 0)
                ratingFC = '[Good Full Combo]';
            else if (sicks > 0)
                ratingFC = '[Sick Full Combo]';
            else if (marvs > 0)
                ratingFC = '[Marvioulus Full Combo]';
        }
        else
        {
            if (songMisses < 2) ratingFC = '[Single Miss Clear]';
			else if (songMisses < 5) ratingFC = '[Low Miss Clear]';
            else if (songMisses < 10)
                ratingFC = '[Medium Miss Clear]';
            else if (songMisses < 20)
                ratingFC = '[High Miss Clear]';
            else if (songMisses < 50)
                ratingFC = '[Ok I guess...]';
            else
                ratingFC = '[at least you\'re still alive?]';
        }
    }

    public function RecalculateRating(badHit:Bool = false, scoreBop:Bool = true) {
		PlayState.instance?.setOnScripts('score', songScore);
		PlayState.instance?.setOnScripts('misses', songMisses);
		PlayState.instance?.setOnScripts('hits', songHits);
		PlayState.instance?.setOnScripts('combo', combo);

		var ret:Dynamic = PlayState.instance?.callOnScripts('onRecalculateRating', null, true);
		if(ret != LuaUtils.Function_Stop)
		{
			ratingName = '?';
            ratingPercent = 0.0;

            // Select accuracy system according to user preference
			var selectedSystem:String = ClientPrefs.data.accuracySystem;

			if(totalPlayed != 0) //Prevent divide by 0
			{
				if(selectedSystem == 'Wife3')
                {
                    // === WIFE3 ACCURACY SYSTEM (STEPMANIA) ===
                    if(wife3Scores.length > 0)
                    {
                        var totalPoints:Float = 0.0;
                        for(score in wife3Scores)
                        {
                            totalPoints += score;
                        }

                        var maxPossiblePoints:Float = wife3Scores.length * 2.0;

                        // Calculate base percentage
                        var rawPercent:Float = totalPoints / maxPossiblePoints;

                        // CLAMP between 0% and 100% (Wife3 standard)
                        ratingPercent = Math.max(0.0, Math.min(1.0, rawPercent));
                    }
                }
                else if(selectedSystem == 'Psych')
                {
                    // === PSYCH ACCURACY SYSTEM (ORIGINAL) ===
                    if(totalPlayed != 0)
                    {
                        ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
                    }
                }
                else if(selectedSystem == 'Mixtape')
                {
                    // === MIXTAPE ACCURACY SYSTEM (Here just in case I decide to get fancy with this for some reason) ===
                    if(totalPlayed != 0)
                    {
                        ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
                    }
                }
                else if(selectedSystem == 'Simple')
                {
                    // === SIMPLE ACCURACY SYSTEM ===
                    if(totalPlayed != 0)
                    {
                        // Simple percentage: notes hit well /total notes
                        ratingPercent = Math.min(1, Math.max(0, notesHitSimple / totalPlayed));
                    }
                }
                else if(selectedSystem == 'osu!mania')
                {
                    // === OSU!MANIA ACCURACY SYSTEM ===
                    var totalHits:Int = osuMania_n300 + osuMania_n200 + osuMania_n100 + osuMania_n50 + osuMania_nMiss;
                    if(totalHits > 0)
                    {
                        // osu!mania Formula: (300×n300 + 200×n200 + 100×n100 + 50×n50) /(300×totalNotes)
                        var weightedScore:Float = (300.0 * osuMania_n300) + (200.0 * osuMania_n200) + (100.0 * osuMania_n100) + (50.0 * osuMania_n50);
                        var maxPossibleScore:Float = 300.0 * totalHits;
                        ratingPercent = weightedScore / maxPossibleScore;
                        ratingPercent = Math.min(1, Math.max(0, ratingPercent));
                    }
                }
                else if(selectedSystem == 'DJMAX')
                {
                    // === DJMAX RESPECT ACCURACY SYSTEM ===
                    var totalNotes:Int = djmax_maxPerfect + djmax_perfect + djmax_great + djmax_good + djmax_bad + djmax_miss;
                    if(totalNotes > 0)
                    {
                        // Score based on grade
                        var baseScorePerNote:Float = 1000000.0 / totalNotes;

                        // Calculate score total
                        var totalScore:Float = 0.0;
                        totalScore += djmax_maxPerfect * baseScorePerNote * 1.0;  // 100%
                        totalScore += djmax_perfect * baseScorePerNote * 0.95;    // 95%
                        totalScore += djmax_great * baseScorePerNote * 0.80;      // 80%
                        totalScore += djmax_good * baseScorePerNote * 0.40;       // 40%
                        totalScore += djmax_bad * baseScorePerNote * 0.10;        // 10%
                        // djmax_miss adds nothing

                        // Bonus por combo (up to 10% additional)
                        var comboBonus:Float = 0.0;
                        if(totalNotes > 0) {
                            var comboRatio:Float = djmax_maxCombo / totalNotes;
                            comboBonus = comboRatio * 0.10 * 1000000.0;
                        }

                        ratingPercent = (totalScore + comboBonus) / 1100000.0; // 1M base + 100k combo
                        ratingPercent = Math.min(1, Math.max(0, ratingPercent));
                    }
                }
                else if(selectedSystem == 'ITG')
                {
                    // === ITG (DANCE POINTS) SYSTEM ===
                    var totalNotes:Int = itg_FantasticPlus + itg_Fantastic + itg_Excellent + itg_Great + itg_Decent + itg_WayOff + itg_Miss;
                    if(totalNotes > 0)
                    {
                        // Calculate maximum possible DP (all Fantastic+)
                        var maxDP:Float = totalNotes * 10.0;

                        // Current DP (it is already calculated in popUpScore and noteMissCommon)
                        // Ensure it is not negative
                        var currentDP:Float = Math.max(0, itg_DP);

                        // Percentage
                        ratingPercent = currentDP / maxDP;
                        ratingPercent = Math.min(1, Math.max(0, ratingPercent));
                    }
                }

				// Rating Name
				ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				var translatedRatingStuff = getRatingStuff();
                if(ratingPercent >= 0 && totalPlayed > 0)
                {
                    ratingName = translatedRatingStuff[translatedRatingStuff.length-1][0]; //Uses last string
                    if(ratingPercent < 1)
                        for (i in 0...translatedRatingStuff.length-1)
                            if(ratingPercent < translatedRatingStuff[i][1])
                            {
                                ratingName = translatedRatingStuff[i][0];
                                break;
                            }
                }
			}
			fullComboFunction();
		}
		PlayState.instance?.setOnScripts('rating', ratingPercent);
		PlayState.instance?.setOnScripts('ratingName', ratingName);
		PlayState.instance?.setOnScripts('ratingFC', ratingFC);
		PlayState.instance?.setOnScripts('totalPlayed', totalPlayed);
		PlayState.instance?.setOnScripts('totalNotesHit', totalNotesHit);
        PlayState.instance?.setOnScripts('accuracySystem', ClientPrefs.data.accuracySystem);

        // Calcular porcentajes individuales para cada sistema
		var wife3Percent:Float = 0.0;
		var psychPercent:Float = 0.0;
        var mixtapePercent:Float = 0.0;
		var simplePercent:Float = 0.0;
		var osuPercent:Float = 0.0;
		var djmaxPercent:Float = 0.0;
		var itgPercent:Float = 0.0;

		// Wife3 Percent
		if(wife3Scores.length > 0) {
			var totalPoints:Float = 0.0;
			for(score in wife3Scores) totalPoints += score;
			var maxPossiblePoints:Float = wife3Scores.length * 2.0;
			wife3Percent = Math.max(0.0, Math.min(1.0, totalPoints / maxPossiblePoints));
		}

		// Psych Engine Percent
		if(totalPlayed > 0) {
			psychPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
		}

        // Mixtape Engine Percent
		if(totalPlayed > 0) {
			mixtapePercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
		}

		// Simple Percent
		if(totalPlayed > 0) {
			simplePercent = Math.min(1, Math.max(0, notesHitSimple / totalPlayed));
		}

		// osu!mania Percent
		var totalHitsOsu:Int = osuMania_n300 + osuMania_n200 + osuMania_n100 + osuMania_n50 + osuMania_nMiss;
		if(totalHitsOsu > 0) {
			var weightedScore:Float = (300.0 * osuMania_n300) + (200.0 * osuMania_n200) + (100.0 * osuMania_n100) + (50.0 * osuMania_n50);
			var maxPossibleScore:Float = 300.0 * totalHitsOsu;
			osuPercent = Math.min(1, Math.max(0, weightedScore / maxPossibleScore));
		}

		// DJMAX Percent
		var totalNotesDJ:Int = djmax_maxPerfect + djmax_perfect + djmax_great + djmax_good + djmax_bad + djmax_miss;
		if(totalNotesDJ > 0) {
			var baseScorePerNote:Float = 1000000.0 / totalNotesDJ;
			var totalScore:Float = 0.0;
			totalScore += djmax_maxPerfect * baseScorePerNote * 1.0;
			totalScore += djmax_perfect * baseScorePerNote * 0.95;
			totalScore += djmax_great * baseScorePerNote * 0.80;
			totalScore += djmax_good * baseScorePerNote * 0.40;
			totalScore += djmax_bad * baseScorePerNote * 0.10;
			var comboBonus:Float = 0.0;
			if(totalNotesDJ > 0) {
				var comboRatio:Float = djmax_maxCombo / totalNotesDJ;
				comboBonus = comboRatio * 0.10 * 1000000.0;
			}
			djmaxPercent = Math.min(1, Math.max(0, (totalScore + comboBonus) / 1100000.0));
		}

		// ITG Percent
		var totalNotesITG:Int = itg_FantasticPlus + itg_Fantastic + itg_Excellent + itg_Great + itg_Decent + itg_WayOff + itg_Miss;
		if(totalNotesITG > 0) {
			var maxDP:Float = totalNotesITG * 10.0;
			var currentDP:Float = Math.max(0, itg_DP);
			itgPercent = Math.min(1, Math.max(0, currentDP / maxDP));
		}

		// Wife3 (StepMania) System
		PlayState.instance?.setOnScripts('ratingWife3', wife3Percent);
		PlayState.instance?.setOnScripts('wife3Scores', wife3Scores);

		// Psych Engine System
		PlayState.instance?.setOnScripts('ratingPsych', psychPercent);
		PlayState.instance?.setOnScripts('ratingPsychTotal', totalPlayed);

        // Mixtape Engine System
		PlayState.instance?.setOnScripts('ratingMixtape', mixtapePercent);
		PlayState.instance?.setOnScripts('ratingMixtapeTotal', totalPlayed);

		// Simple System
		PlayState.instance?.setOnScripts('ratingSimple', simplePercent);
		PlayState.instance?.setOnScripts('ratingSimpleTotal', totalPlayed);

		// osu!mania System
		PlayState.instance?.setOnScripts('ratingOsu', osuPercent);
		PlayState.instance?.setOnScripts('osuMania_n300', osuMania_n300);
		PlayState.instance?.setOnScripts('osuMania_n200', osuMania_n200);
		PlayState.instance?.setOnScripts('osuMania_n100', osuMania_n100);
		PlayState.instance?.setOnScripts('osuMania_n50', osuMania_n50);
		PlayState.instance?.setOnScripts('osuMania_nMiss', osuMania_nMiss);

		// DJMAX System
		PlayState.instance?.setOnScripts('ratingDJMAX', djmaxPercent);
		PlayState.instance?.setOnScripts('djmax_maxPerfect', djmax_maxPerfect);
		PlayState.instance?.setOnScripts('djmax_perfect', djmax_perfect);
		PlayState.instance?.setOnScripts('djmax_great', djmax_great);
		PlayState.instance?.setOnScripts('djmax_good', djmax_good);
		PlayState.instance?.setOnScripts('djmax_bad', djmax_bad);
		PlayState.instance?.setOnScripts('djmax_miss', djmax_miss);
		PlayState.instance?.setOnScripts('djmax_combo', djmax_combo);
		PlayState.instance?.setOnScripts('djmax_maxCombo', djmax_maxCombo);

		// ITG (Dance Points) System
		PlayState.instance?.setOnScripts('ratingITG', itgPercent);
		PlayState.instance?.setOnScripts('itg_FantasticPlus', itg_FantasticPlus);
		PlayState.instance?.setOnScripts('itg_Fantastic', itg_Fantastic);
		PlayState.instance?.setOnScripts('itg_Excellent', itg_Excellent);
		PlayState.instance?.setOnScripts('itg_Great', itg_Great);
		PlayState.instance?.setOnScripts('itg_Decent', itg_Decent);
		PlayState.instance?.setOnScripts('itg_WayOff', itg_WayOff);
		PlayState.instance?.setOnScripts('itg_Miss', itg_Miss);
		PlayState.instance?.setOnScripts('itg_DP', itg_DP);

		PlayState.instance?.updateScore(badHit, scoreBop); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce
	}

    // The AI doesn't get to be cool lol
	public function RecalculateRatingAI(badHit:Bool = false)
	{
		if (AITotalPlayed != 0) // Prevent divide by 0
        {
            // Rating Percent
            ratingPercentAI = Math.min(1, Math.max(0, AITotalNotesHit / AITotalPlayed));
            // trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

            // Rating Name
            ratingNameAI = ratingStuff[ratingStuff.length - 1][0]; // Uses last string
            if (ratingPercentAI < 1)
                for (i in 0...ratingStuff.length - 1)
                    if (ratingPercentAI < ratingStuff[i][1])
                    {
                        ratingNameAI = ratingStuff[i][0];
                        break;
                    }
        }
        fullComboFunctionAI();
		PlayState.instance.updateScoreAI(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce -Ghost
	}
}
