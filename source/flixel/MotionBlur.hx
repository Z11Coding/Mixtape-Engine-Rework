package flixel;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSpriteUtil;
import openfl.display.BitmapData;
import openfl.filters.BlurFilter;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.events.Event;
import openfl.Lib;

class MotionBlur extends FlxSprite {
    public static var maxMilisecond:Int = 20;
    public static var listeMotionBlur:Array<MotionBlur> = [];

    public var reference:FlxSprite;
    public var lux:ColorTransform;
    public var quality:MotionBlurQuality;
    public var refresh:Bool;

    public function new(reference:FlxSprite, ?quality:MotionBlurQuality, ?lumiere:Float = 1) {
        super();
        this.quality = quality != null ? quality : MotionBlurQuality.HIGH;
        this.reference = reference;
        lux = new ColorTransform();
        source_lumiere(lumiere);
        pp = new Point(reference.x, reference.y);
        vp = new Point(0, 0);
        MotionBlur.listeMotionBlur.push(this);
    }

    public static function activer() {
        Lib.current.stage.addEventListener(Event.RENDER, actualise, false, -10);
        Lib.current.stage.addEventListener(Event.ENTER_FRAME, call_invalidate);
    }

    public static function desactiver() {
        Lib.current.stage.removeEventListener(Event.RENDER, actualise);
        Lib.current.stage.removeEventListener(Event.ENTER_FRAME, call_invalidate);
    }

    static function actualise(e:Event) {
        for (blur in listeMotionBlur) {
            blur.prepar();
            if (blur.changements()) {
                blur.drawBlur();
            }
        }
        Lib.current.stage.invalidate();
    }

    static function call_invalidate(e:Event) {
        Lib.current.stage.invalidate();
    }

    public function source_lumiere(intensite:Float) {
        lux.alphaMultiplier = intensite;
    }

    public function teleport() {
        pp = new Point(reference.x, reference.y);
    }

    public function delete() {
        if (pixels != null) pixels.dispose();
        MotionBlur.listeMotionBlur.remove(this);
    }

    var w:Int;
    var h:Int;
    var pp:Point; // previous position of the reference
    var vp:Point; // drawn speed of the blur in the coincident reference frame of the object
    var vit:Point; // real speed of the object in the coincident reference frame of the object
    var longueur:Int;

    function prepar() {
        var pos:Point = new Point(reference.x, reference.y);
        vit = pos.subtract(pp);
        pp = pos;
        var cos = vit.x / vit.length;
        var sin = vit.y / vit.length;

        var matDim:Matrix = new Matrix();
        matDim.scale(quality.scaleX, quality.scaleY); // scale to the desired real resolution
        matDim.concat(new Matrix(cos, sin, -sin, cos)); // rotate in the direction of movement
        transform.matrix = matDim;

        var rect = reference.getGraphicMidpoint();
        var p = matDim.transformPoint(rect); // coordinates of the top left corner of reference relative to the parent
        x = p.x - vit.x;
        y = p.y - vit.y; // this is placed at the last real position of reference relative to the parent

        longueur = Std.int(vit.length / quality.scaleX);
        w = Std.int(reference.width + longueur);
        h = Std.int(reference.height);
    }

    function changements() {
        if (!refresh && vit.length < quality.minSpeed) {
            reference.visible = true;
            visible = false;
            return false;
        } else {
            reference.visible = quality.objectVisible;
            visible = true;
            if (refresh || vit.subtract(vp).length / vit.length > quality.tolerance) {
                refresh = false;
                vp = vit;
                return true;
            } else return false;
        }
    }

    function drawBlur() {
        if (pixels != null) pixels.dispose();
        pixels = new BitmapData(w, h, true, 0);

        var tempFilters = reference.filters;
        var tempQuality = FlxG.stage.quality;
        FlxG.stage.quality = quality.stageQuality;
        tempFilters.push(new BlurFilter(longueur, 0, 1));
        reference.filters = tempFilters;

        var inv_bmp = transform.matrix.clone();
        inv_bmp.invert();
        inv_bmp.translate(-longueur / 2, 0);
        var location_in_bmp = reference.transform.matrix.clone();
        location_in_bmp.concat(inv_bmp);

        pixels.draw(reference, location_in_bmp, lux, null, null, quality.smooth);

        tempFilters.pop();
        reference.filters = tempFilters;
        FlxG.stage.quality = tempQuality;
    }
}

class MotionBlurQuality {
    public var scaleX:Int;
    public var scaleY:Int;
    public var stageQuality:StageQuality;
    public var minSpeed:Float;
    public var tolerance:Float;
    public var smooth:Bool;
    public var objectVisible:Bool;
    public var maxMilisecond:Int;

    public function new(scaleX = 2,
                        scaleY = 1,
                        stageQuality = StageQuality.LOW,
                        minSpeed = 30,
                        tolerance = 0.1,
                        smooth = false,
                        objectVisible = false,
                        maxMilisecond = 0xffffffff) {
        this.scaleY = scaleY;
        this.scaleX = scaleX;
        this.stageQuality = stageQuality;
        this.minSpeed = minSpeed;
        this.tolerance = tolerance;
        this.smooth = smooth;
        this.objectVisible = objectVisible;
        this.maxMilisecond = maxMilisecond;
    }

    public static var LOW = new MotionBlurQuality(3, 6, StageQuality.LOW, 50, 0.3, false);
    public static var MEDIUM = new MotionBlurQuality(2, 4, StageQuality.LOW, 20, 0.2, false);
    public static var HIGH = new MotionBlurQuality(1, 2, StageQuality.LOW, 10, 0.1, false);
    public static var MAX = new MotionBlurQuality(1, 1, StageQuality.HIGH, 2, 0.01, true);
}