package yutautil;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;

/**
 * SizedSprite - An FlxSprite that maintains a defined size at all times
 *
 * This sprite scales textures to fit within the defined bounds, with smaller textures
 * being centered within the box. Useful for UI elements that need consistent sizing
 * regardless of the texture dimensions.
 */
class SizedSprite extends FlxSprite {
	/**
	 * The defined width for this sprite (independent of texture)
	 */
	public var definedWidth(default, set):Float = 0;

	/**
	 * The defined height for this sprite (independent of texture)
	 */
	public var definedHeight(default, set):Float = 0;

	/**
	 * How the texture should be fitted within the defined bounds
	 */
	public var fitMode(default, set):SizedSpriteFitMode = SCALE_TO_FIT;

	/**
	 * Whether to maintain aspect ratio when scaling
	 */
	public var maintainAspectRatio(default, set):Bool = true;

	/**
	 * The original texture width before any scaling
	 */
	public var originalWidth(get, never):Float;

	/**
	 * The original texture height before any scaling
	 */
	public var originalHeight(get, never):Float;

	private var _originalTextureWidth:Float = 0;
	private var _originalTextureHeight:Float = 0;
	private var _needsTextureUpdate:Bool = false;

	/**
	 * Create a new SizedSprite with defined dimensions
	 * @param x X position
	 * @param y Y position
	 * @param definedWidth The fixed width for this sprite
	 * @param definedHeight The fixed height for this sprite
	 * @param graphic Optional graphic to load initially
	 */
	public function new(x:Float = 0, y:Float = 0, definedWidth:Float = 100, definedHeight:Float = 100, graphic:FlxGraphicAsset = null) {
		super(x, y);

		this.definedWidth = definedWidth;
		this.definedHeight = definedHeight;

		if (graphic != null) {
			loadGraphic(graphic);
		} else {
			// Create a default colored rectangle if no graphic is provided
			makeGraphic(Std.int(definedWidth), Std.int(definedHeight), 0xFFFFFFFF);
		}

		updateTextureScale();
	}

	/**
	 * Create a SizedSprite based on another FlxSprite
	 * Copies the graphic, position, and other properties while applying size constraints
	 * @param sourceSprite The sprite to copy from
	 * @param definedWidth The fixed width for the new sprite
	 * @param definedHeight The fixed height for the new sprite
	 * @param copyPosition Whether to copy the position from the source sprite
	 * @param copyProperties Whether to copy other properties (alpha, color, etc.)
	 */
	public static function fromSprite(sourceSprite:FlxSprite, definedWidth:Float, definedHeight:Float,
		copyPosition:Bool = true, copyProperties:Bool = true):SizedSprite {

		var sizedSprite = new SizedSprite(0, 0, definedWidth, definedHeight);

		// Copy graphic
		if (sourceSprite.graphic != null) {
			sizedSprite.graphic = sourceSprite.graphic;
			sizedSprite._originalTextureWidth = sourceSprite.graphic.width;
			sizedSprite._originalTextureHeight = sourceSprite.graphic.height;
		}

		// Copy frame data if it's animated
		if (sourceSprite.frames != null) {
			sizedSprite.frames = sourceSprite.frames;
		}

		// Copy position
		if (copyPosition) {
			sizedSprite.x = sourceSprite.x;
			sizedSprite.y = sourceSprite.y;
		}

		// Copy other properties
		if (copyProperties) {
			sizedSprite.alpha = sourceSprite.alpha;
			sizedSprite.color = sourceSprite.color;
			sizedSprite.angle = sourceSprite.angle;
			sizedSprite.flipX = sourceSprite.flipX;
			sizedSprite.flipY = sourceSprite.flipY;
			sizedSprite.visible = sourceSprite.visible;
			sizedSprite.blend = sourceSprite.blend;
		}

		sizedSprite.updateTextureScale();
		return sizedSprite;
	}

	/**
	 * Create a SizedSprite based on an existing FlxGraphic
	 * @param graphic The FlxGraphic to use
	 * @param x X position
	 * @param y Y position
	 * @param definedWidth The fixed width for the sprite
	 * @param definedHeight The fixed height for the sprite
	 */
	public static function fromGraphic(graphic:FlxGraphic, x:Float = 0, y:Float = 0,
		definedWidth:Float = 100, definedHeight:Float = 100):SizedSprite {

		var sizedSprite = new SizedSprite(x, y, definedWidth, definedHeight);

		if (graphic != null) {
			sizedSprite.graphic = graphic;
			sizedSprite._originalTextureWidth = graphic.width;
			sizedSprite._originalTextureHeight = graphic.height;
			sizedSprite.updateTextureScale();
		}

		return sizedSprite;
	}

	/**
	 * Create a SizedSprite that matches another sprite's dimensions but with scaled content
	 * Useful for creating UI elements that should be the same size as existing sprites
	 * @param referenceSprite The sprite whose dimensions to match
	 * @param contentSprite The sprite whose graphic content to use
	 * @param copyPosition Whether to copy position from reference sprite
	 */
	public static function matchSizeWithContent(referenceSprite:FlxSprite, contentSprite:FlxSprite,
		copyPosition:Bool = true):SizedSprite {

		var definedWidth = referenceSprite.width;
		var definedHeight = referenceSprite.height;

		var sizedSprite = fromSprite(contentSprite, definedWidth, definedHeight, false, true);

		if (copyPosition) {
			sizedSprite.x = referenceSprite.x;
			sizedSprite.y = referenceSprite.y;
		}

		return sizedSprite;
	}

	/**
	 * Clone this SizedSprite with the same properties and constraints
	 * @param x New X position (optional, uses current position if not specified)
	 * @param y New Y position (optional, uses current position if not specified)
	 */
	public override function clone(?x:Float, ?y:Float):SizedSprite {
		var cloned = new SizedSprite(x != null ? x : this.x, y != null ? y : this.y,
			definedWidth, definedHeight);

		// Copy graphic
		if (this.graphic != null) {
			cloned.graphic = this.graphic;
			cloned._originalTextureWidth = this._originalTextureWidth;
			cloned._originalTextureHeight = this._originalTextureHeight;
		}

		// Copy frame data
		if (this.frames != null) {
			cloned.frames = this.frames;
		}

		// Copy properties
		cloned.alpha = this.alpha;
		cloned.color = this.color;
		cloned.angle = this.angle;
		cloned.flipX = this.flipX;
		cloned.flipY = this.flipY;
		cloned.visible = this.visible;
		cloned.blend = this.blend;
		cloned.fitMode = this.fitMode;
		cloned.maintainAspectRatio = this.maintainAspectRatio;

		cloned.updateTextureScale();
		return cloned;
	}

	/**
	 * Create a SizedSprite from another sprite while preserving its original dimensions as the defined size
	 * This is useful when you want to convert an existing sprite to a SizedSprite without changing its appearance
	 * @param sourceSprite The sprite to convert
	 * @param copyPosition Whether to copy the position from the source sprite
	 * @param copyProperties Whether to copy other properties (alpha, color, etc.)
	 */
	public static function preserveSize(sourceSprite:FlxSprite, copyPosition:Bool = true, copyProperties:Bool = true):SizedSprite {
		return fromSprite(sourceSprite, sourceSprite.width, sourceSprite.height, copyPosition, copyProperties);
	}

	/**
	 * Replace this SizedSprite's content with another sprite's graphic while keeping defined dimensions
	 * @param sourceSprite The sprite whose graphic to copy
	 * @param copyProperties Whether to copy other properties (alpha, color, etc.)
	 */
	public function replaceContent(sourceSprite:FlxSprite, copyProperties:Bool = false):Void {
		// Copy graphic
		if (sourceSprite.graphic != null) {
			this.graphic = sourceSprite.graphic;
			this._originalTextureWidth = sourceSprite.graphic.width;
			this._originalTextureHeight = sourceSprite.graphic.height;
		}

		// Copy frame data if it's animated
		if (sourceSprite.frames != null) {
			this.frames = sourceSprite.frames;
		}

		// Copy other properties if requested
		if (copyProperties) {
			this.alpha = sourceSprite.alpha;
			this.color = sourceSprite.color;
			this.angle = sourceSprite.angle;
			this.flipX = sourceSprite.flipX;
			this.flipY = sourceSprite.flipY;
			this.visible = sourceSprite.visible;
			this.blend = sourceSprite.blend;
		}

		updateTextureScale();
	}

	/**
	 * Load a graphic and apply size constraints
	 */
	override public function loadGraphic(graphic:FlxGraphicAsset, animated:Bool = false, width:Int = 0, height:Int = 0, unique:Bool = false, ?key:String):FlxSprite {
		var result = super.loadGraphic(graphic, animated, width, height, unique, key);

		// Store original texture dimensions
		if (this.graphic != null) {
			_originalTextureWidth = this.graphic.width;
			_originalTextureHeight = this.graphic.height;
		}

		updateTextureScale();
		return result;
	}

	/**
	 * Make a colored graphic with the defined dimensions
	 */
	override public function makeGraphic(width:Int, height:Int, color:Int = 0xFFFFFFFF, unique:Bool = false, ?key:String):FlxSprite {
		var result = super.makeGraphic(width, height, color, unique, key);

		_originalTextureWidth = width;
		_originalTextureHeight = height;

		updateTextureScale();
		return result;
	}

	/**
	 * Update the scale and positioning based on the current fit mode and defined size
	 */
	private function updateTextureScale():Void {
		if (_originalTextureWidth == 0 || _originalTextureHeight == 0) return;
		if (definedWidth == 0 || definedHeight == 0) return;

		var scaleX:Float = 1.0;
		var scaleY:Float = 1.0;

		switch (fitMode) {
			case SCALE_TO_FIT:
				if (maintainAspectRatio) {
					// Scale uniformly to fit within bounds
					var scaleRatio = Math.min(definedWidth / _originalTextureWidth, definedHeight / _originalTextureHeight);
					scaleX = scaleY = scaleRatio;
				} else {
					// Scale to fill exactly, ignoring aspect ratio
					scaleX = definedWidth / _originalTextureWidth;
					scaleY = definedHeight / _originalTextureHeight;
				}

			case SCALE_TO_FILL:
				if (maintainAspectRatio) {
					// Scale uniformly to fill bounds completely (may crop)
					var scaleRatio = Math.max(definedWidth / _originalTextureWidth, definedHeight / _originalTextureHeight);
					scaleX = scaleY = scaleRatio;
				} else {
					// Same as SCALE_TO_FIT without aspect ratio
					scaleX = definedWidth / _originalTextureWidth;
					scaleY = definedHeight / _originalTextureHeight;
				}

			case CENTER:
				// Keep original size, just center within bounds
				scaleX = scaleY = 1.0;
		}

		// Apply the calculated scale
		scale.set(scaleX, scaleY);

		// Center the sprite within the defined bounds
		centerInBounds();

		updateHitbox();
	}

	/**
	 * Center the scaled sprite within the defined bounds
	 */
	private function centerInBounds():Void {
		if (fitMode == CENTER) {
			// For center mode, position so the sprite is centered within the defined area
			var actualWidth = _originalTextureWidth * scale.x;
			var actualHeight = _originalTextureHeight * scale.y;

			offset.x = (definedWidth - actualWidth) * 0.5;
			offset.y = (definedHeight - actualHeight) * 0.5;
		} else {
			// For scaling modes, the sprite should fill the defined bounds
			var actualWidth = _originalTextureWidth * scale.x;
			var actualHeight = _originalTextureHeight * scale.y;

			offset.x = (definedWidth - actualWidth) * 0.5;
			offset.y = (definedHeight - actualHeight) * 0.5;
		}
	}

	/**
	 * Override updateHitbox to use defined dimensions
	 */
	override public function updateHitbox():Void {
		super.updateHitbox();

		// Always maintain the defined dimensions for collision/positioning
		width = definedWidth;
		height = definedHeight;
	}

	/**
	 * Get the bounds as a FlxPoint (width, height)
	 */
	public function getDefinedSize():FlxPoint {
		return FlxPoint.get(definedWidth, definedHeight);
	}

	/**
	 * Set both defined dimensions at once
	 */
	public function setDefinedSize(width:Float, height:Float):Void {
		definedWidth = width;
		definedHeight = height;
		updateTextureScale();
	}

	/**
	 * Get the scale factor applied to the texture
	 */
	public function getTextureScale():FlxPoint {
		return FlxPoint.get(scale.x, scale.y);
	}

	// Setters for properties that require texture updates
	private function set_definedWidth(value:Float):Float {
		if (definedWidth != value) {
			definedWidth = value;
			updateTextureScale();
		}
		return definedWidth;
	}

	private function set_definedHeight(value:Float):Float {
		if (definedHeight != value) {
			definedHeight = value;
			updateTextureScale();
		}
		return definedHeight;
	}

	private function set_fitMode(value:SizedSpriteFitMode):SizedSpriteFitMode {
		if (fitMode != value) {
			fitMode = value;
			updateTextureScale();
		}
		return fitMode;
	}

	private function set_maintainAspectRatio(value:Bool):Bool {
		if (maintainAspectRatio != value) {
			maintainAspectRatio = value;
			updateTextureScale();
		}
		return maintainAspectRatio;
	}

	private function get_originalWidth():Float {
		return _originalTextureWidth;
	}

	private function get_originalHeight():Float {
		return _originalTextureHeight;
	}

	override public function destroy():Void {
		super.destroy();
	}
}

/**
 * Enum defining how textures should be fitted within the defined sprite bounds
 */
enum SizedSpriteFitMode {
	/**
	 * Scale the texture to fit within the bounds (default)
	 * May leave empty space if aspect ratios don't match
	 */
	SCALE_TO_FIT;

	/**
	 * Scale the texture to fill the bounds completely
	 * May crop parts of the texture if aspect ratios don't match
	 */
	SCALE_TO_FILL;

	/**
	 * Keep original texture size and center it within bounds
	 * Useful for small textures that should stay crisp
	 */
	CENTER;
}
