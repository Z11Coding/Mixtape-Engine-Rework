package managers;

import backend.Rating;
#if LUA_ALLOWED
import psychlua.*;
using psychlua.IntegratedScript;
#else
import psychlua.LuaUtils;
import psychlua.HScript;
#end

/*
    The very fun combo manager because yes!!!

    as of right now it only handles the actual stats of a song
    but i plan on also making handle the visual aspect as well 
*/

class ComboManager {
    public static var instance:ComboManager;

    public var ratingsData:Array<Rating> = Rating.loadDefault();    
    public var combo:Int = 0;
	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
    public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
    public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

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
                ratingFCAI = '[Marvioulus Full Combo]';
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
            if (bads > 0 || shits > 0)
                ratingFC = '[Full Combo]';
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
            if (songMisses < 10)
                ratingFC = '[Single Digit Combo Break]';
            else
                ratingFC = '[Ok I guess...]';
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
			if(totalPlayed != 0) //Prevent divide by 0
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				if(ratingPercent < 1)
					for (i in 0...ratingStuff.length-1)
						if(ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
			}
			fullComboFunction();
		}
		PlayState.instance?.setOnScripts('rating', ratingPercent);
		PlayState.instance?.setOnScripts('ratingName', ratingName);
		PlayState.instance?.setOnScripts('ratingFC', ratingFC);
		PlayState.instance?.setOnScripts('totalPlayed', totalPlayed);
		PlayState.instance?.setOnScripts('totalNotesHit', totalNotesHit);
		PlayState.instance?.updateScore(badHit, scoreBop); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce
	}

    
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