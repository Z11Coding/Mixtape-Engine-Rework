package states.playbits;

import backend.Rating;

class ComboManager {
    public static var instance:ComboManager;

    public var ratingsData:Array<Rating> = Rating.loadDefault();    
    public var combo:Int = 0;
	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;

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

        if (ClientPrefs.data.useMarvs)
        {
            marvs = ratingsData[0].hits;
            sicks = ratingsData[1].hits;
            goods = ratingsData[2].hits;
            bads = ratingsData[3].hits;
            shits = ratingsData[4].hits;

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
        else
        {
            sicks = ratingsData[0].hits;
            goods = ratingsData[1].hits;
            bads = ratingsData[2].hits;
            shits = ratingsData[3].hits;
            if (AIMisses == 0)
            {
                if (bads > 0 || shits > 0)
                    ratingFCAI = '[Full Combo]';
                else if (goods > 0)
                    ratingFCAI = '[Good Full Combo]';
                else if (sicks > 0)
                    ratingFCAI = '[Sick Full Combo]';
            }
            else
            {
                if (AIMisses < 10)
                    ratingFCAI = '[Single Digit Combo Break]';
                else
                    ratingFCAI = '[Ok I guess...]';
            }
        }
        #if sys
        ArtemisIntegration.setComboType(ratingFCAI);
        ArtemisIntegration.setRating(ratingPercent * 100);
        #end
    }
}