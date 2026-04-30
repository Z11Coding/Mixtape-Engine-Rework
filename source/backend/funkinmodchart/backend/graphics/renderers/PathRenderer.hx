package backend.funkinmodchart.backend.graphics.renderers;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxDestroyUtil;
import openfl.geom.ColorTransform;

using flixel.util.FlxColorTransformUtil;

var pathVector = new Vector3();

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
final class PathRenderer extends BaseRenderer<FlxSprite> {
	var __lineGraphic:FlxGraphic;
	var __lastDivisions:Int = -1;

	var uvt:NativeVector<Float>;
	var indices:NativeVector<Int>;

	public function updateTris(divisions:Int) {
		if (divisions != __lastDivisions) {
			uvt = new NativeVector<Float>(divisions * 12);
			indices = new NativeVector<Int>(divisions * 6);
			var ui = 0, ii = 0, vertCount = 0;
			for (div in 0...divisions) {
				for (_ in 0...4) {
					uvt.set(ui++, 0);
					uvt.set(ui++, 0);
					uvt.set(ui++, 1);
				}

				// indices
				indices.set(ii++, vertCount);
				indices.set(ii++, vertCount + 1);
				indices.set(ii++, vertCount + 2);
				indices.set(ii++, vertCount + 1);
				indices.set(ii++, vertCount + 3);
				indices.set(ii++, vertCount + 2);

				vertCount += 4;
			}
		}

		__lastDivisions = divisions;
	}

	public function new(parent:PlayField) {
		super(parent);

		__lineGraphic = FlxG.bitmap.create(1, 1, 0xFFFFFFFF, true);
		__lineGraphic.destroyOnNoUse = false;
		__lineGraphic.persist = true;
	}

	var __lastPlayer:Int = -1;
	var __lastAlpha:Float = 0;
	var __lastThickness:Float = 0;

	// the entry sprite should be A RECEPTOR / STRUM !!
	override public function prepare(item:FlxSprite):Null<DrawCommand> {
		final lane = Adapter.instance.getLaneFromArrow(item);
		final fn = Adapter.instance.getPlayerFromArrow(item);

		final canUseLast = fn == __lastPlayer;

		final pathAlpha = canUseLast ? __lastAlpha : parent.getPercent('arrowPathAlpha', fn);
		final pathThickness = canUseLast ? __lastThickness : parent.getPercent('arrowPathThickness', fn);

		if (pathAlpha <= 0 || pathThickness <= 0)
			return null;

		__lastAlpha = pathAlpha;
		__lastThickness = pathThickness;
		__lastPlayer = fn;

		final divisions = Std.int(15 * Config.ARROW_PATHS_CONFIG.RESOLUTION);
		final limit = 1800 + Config.ARROW_PATHS_CONFIG.LENGTH;
		final interval = limit / divisions;
		final songPos = Adapter.instance.getSongPosition();

		final segs = divisions - 1;
		final vertices = new NativeVector<Float>(segs * 8);

		var vi = 0, vertCount = 0;

		var lastOutput:ModifierOutput = null;
		pathVector.setTo(Adapter.instance.getDefaultReceptorX(lane, fn), Adapter.instance.getDefaultReceptorY(lane, fn), 0);
		pathVector.incrementBy(ModchartUtil.getHalfPos());

		final colored = Config.ARROW_PATHS_CONFIG.APPLY_COLOR;
		final applyAlpha = Config.ARROW_PATHS_CONFIG.APPLY_ALPHA;

		final transforms = new NativeVector<ColorTransform>(segs);
		var tID:Int = 0;

		var hasC = false;
		var hasCOff = false;

		for (index in 0...divisions) {
			var hitTime = -500 + interval * index;

			var vec = pathVector.clone();
			var param:ArrowData = {
				hitTime: songPos + hitTime,
				distance: hitTime,
				lane: lane,
				player: fn,
				isTapArrow: true
			};

			var output = parent.modifiers.getPath(vec, param);

			if (lastOutput != null) {
				final p0 = lastOutput;
				final p1 = output;

				final pos0 = p0.pos;
				final pos1 = p1.pos;

				final dx = pos1.x - pos0.x;
				final dy = pos1.y - pos0.y;
				final len = Math.sqrt(dx * dx + dy * dy);
				final nx = -dy / len;
				final ny = dx / len;

				final t0 = (pathThickness * (Config.ARROW_PATHS_CONFIG.APPLY_SCALE ? p1.visuals.scaleX : 1) * (Config.ARROW_PATHS_CONFIG.APPLY_DEPTH ? 1 / pos0.z : 1)) * 0.5;
				final t1 = (pathThickness * (Config.ARROW_PATHS_CONFIG.APPLY_SCALE ? p1.visuals.scaleX : 1) * (Config.ARROW_PATHS_CONFIG.APPLY_DEPTH ? 1 / pos1.z : 1)) * 0.5;

				final a1x = pos0.x + nx * t0;
				final a1y = pos0.y + ny * t0;
				final a2x = pos0.x - nx * t0;
				final a2y = pos0.y - ny * t0;

				final b1x = pos1.x + nx * t1;
				final b1y = pos1.y + ny * t1;
				final b2x = pos1.x - nx * t1;
				final b2y = pos1.y - ny * t1;

				// vertices
				vertices.set(vi++, a1x);
				vertices.set(vi++, a1y);
				vertices.set(vi++, a2x);
				vertices.set(vi++, a2y);
				vertices.set(vi++, b1x);
				vertices.set(vi++, b1y);
				vertices.set(vi++, b2x);
				vertices.set(vi++, b2y);

				final glow = (colored ? p0.visuals.glow : 0);
				final fAlpha = (applyAlpha ? p0.visuals.alpha : 1);
				final negGlow = 1 - glow;
				final absGlow = glow * 255;

				var ctr:ColorTransform;

				transforms[tID++] = ctr = new ColorTransform(negGlow, negGlow, negGlow, fAlpha * pathAlpha, Math.round(p0.visuals.glowR * absGlow),
					Math.round(p0.visuals.glowG * absGlow), Math.round(p0.visuals.glowB * absGlow));

				if (ctr.hasRGBMultipliers() || ctr.alphaMultiplier != 1)
					hasC = true;
				if (ctr.hasRGBAOffsets())
					hasCOff = true;

				vertCount += 4;
			}

			lastOutput = output;
		}

		updateTris(divisions);

		var dc:DrawCommand = {
			parent: item,
			graphic: __lineGraphic,
			antialiasing: false,
			blend: NORMAL,
			cameras: ModchartUtil.resolveCameras(parent, item),
			shader: null,

			vertices: vertices,
			uvs: uvt,
			indices: indices,
			colors: transforms,
			isColored: hasC,
			hasColorOffsets: hasCOff
		};
		return dc;
	}

	override function dispose() {
		__lineGraphic.destroy();

		__lineGraphic = null;
	}
}
