package objects.proxies;

import objects.playfields.FieldBase;
import objects.playfields.NoteField;
import states.PlayState;
import flixel.math.FlxPoint;
import flixel.graphics.FlxGraphic;
import flixel.graphics.tile.FlxDrawTrianglesItem;
import flixel.util.FlxColor;
import openfl.Vector;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;

/* 
	ProxyField - A lightweight copy of a NoteField that shares only the draw data
	
	This is designed to be performance-optimized for creating multiple visual copies
	of the same notefield without the computational overhead of recalculating positions.
	
	Key principles:
	- Only copies the drawQueue (rendering data) from the source field
	- All other properties (position, alpha, color, etc.) are completely independent
	- Can be used for mirror effects, trails, multiple camera views, etc.
*/

class ProxyField extends FieldBase {
	@:allow(objects.playfields.NotefieldRenderer)
	var proxiedField:NoteField;
	
	// Track if we've been added to the renderer to avoid duplicate rendering
	private var addedToRenderer:Bool = false;

	public function new(field:NoteField, ?autoAdd:Bool = true) {
		super(0, 0);
		
		if (field == null) {
			throw "ProxyField requires a valid NoteField to proxy";
		}
		
		proxiedField = field;
		this.field = proxiedField.field;
		isProxy = true;
		
		// Initialize as a visible, active object
		exists = true;
		visible = true;
		alpha = 1.0;
		
		// Initialize empty draw queue
		drawQueue = [];
		
		trace('ProxyField created successfully, proxying: ${Type.getClassName(Type.getClass(field))}');
		trace('Auto-add to renderer: $autoAdd');
		
		// Auto-add to renderer if requested
		if (autoAdd) {
			autoAddToRenderer();
		}
	}

	override public function getNotefield():NoteField {
		return proxiedField;
	}

	override function preDraw():Void {
		// ProxyField doesn't do its own pre-draw calculations
		// We rely on the NotefieldRenderer to call preDraw on the source field first
		// Since the renderer processes all fields in order, the source should be ready by now
		
		// Just ensure we have a valid state
		if (proxiedField == null) {
			drawQueue = [];
		}
	}
	
	override function update(elapsed:Float):Void {
		// Keep field reference in sync
		if (proxiedField != null) {
			field = proxiedField.field;
		}
		
		super.update(elapsed);
	}
	
	override public function destroy():Void {
		proxiedField = null;
		drawQueue = null;
		super.destroy();
	}
	
	/**
	 * Get debug information about this ProxyField
	 */
	public function getDebugInfo():String {
		var info = "=== ProxyField Debug Info ===\n";
		info += 'Exists: $exists, Visible: $visible, Alpha: $alpha\n';
		info += 'Position: ($x, $y)\n';
		info += 'Cameras: ${cameras != null ? cameras.length : 0}\n';
		info += 'ProxiedField: ${proxiedField != null ? "Valid" : "NULL"}\n';
		
		if (proxiedField != null) {
			info += 'Source exists: ${proxiedField.exists}, visible: ${proxiedField.visible}\n';
			info += 'Source drawQueue: ${proxiedField.drawQueue != null ? proxiedField.drawQueue.length : 0} objects\n';
		}
		
		info += 'My drawQueue: ${drawQueue != null ? drawQueue.length : 0} objects\n';
		info += 'IsProxy: $isProxy\n';
		info += "========================\n";
		
		return info;
	}
	
	/**
	 * Helper method to properly add this ProxyField to the rendering system
	 * This ensures the source field is processed before this proxy
	 */
	public static function addToRenderer(renderer:objects.playfields.NotefieldRenderer, proxy:ProxyField):Void {
		if (renderer == null || proxy == null) {
			trace("ERROR: Cannot add ProxyField - renderer or proxy is null");
			return;
		}
		
		// Make sure the source field is already in the renderer
		var sourceInRenderer = false;
		for (field in renderer.members) {
			if (field == proxy.proxiedField) {
				sourceInRenderer = true;
				break;
			}
		}
		
		if (!sourceInRenderer) {
			trace("WARNING: Source field not found in renderer. Adding source field first...");
			renderer.add(proxy.proxiedField);
		}
		
		// Now add the proxy field
		renderer.add(proxy);
		proxy.addedToRenderer = true;
		trace("ProxyField added to renderer successfully");
	}
	
	/**
	 * Override the default draw to integrate with FlxObject rendering pipeline
	 * This allows ProxyField to work with PlayState's addBehindGF/BF/Dad functions
	 */
	override public function draw():Void {
		// If we haven't been added to a renderer yet, try to auto-add
		if (!addedToRenderer) {
			trace("ProxyField.draw() called but not added to renderer yet. Auto-adding...");
			autoAddToRenderer();
		}
		
		// Ensure the source field has been processed by the NotefieldRenderer
		ensureSourceFieldProcessed();
		
		// Call our custom draw logic to copy from proxied field
		drawProxyField();
		
		// If we're being rendered by PlayState (not NotefieldRenderer), 
		// we need to actually render the triangles
		if (isInPlayStateMembers() && drawQueue != null && drawQueue.length > 0) {
			renderTrianglesToCameras();
		}
	}
	
	/**
	 * Renders the draw queue as triangles to all active cameras
	 * This is needed when ProxyField is in PlayState's members list
	 */
	private function renderTrianglesToCameras():Void {
		if (cameras == null || cameras.length == 0) return;
		
		var point = FlxPoint.get(0, 0);
		
		for (camera in cameras) {
			if (camera == null || !camera.visible || !camera.exists) continue;
			
			// Process each render object in our draw queue
			for (object in drawQueue) {
				if (object == null || object.graphic == null) continue;
				
				var vertices = object.vertices;
				var indices = object.indices;
				var uvData = object.uvData;
				
				if (vertices != null && indices != null && uvData != null) {
					// Use the same positioning logic as NotefieldRenderer
					// This properly accounts for camera scrolling and transforms
					this.getScreenPosition(point, camera);
					
					// Draw the triangles using the camera's method
					camera.drawTriangles(
						object.graphic,
						vertices,
						indices,
						uvData,
						null, // colors
						point,
						null, // blend
						false, // repeat
						object.antialiasing,
						null, // transform
						object.shader,
						object.colorSwap
					);
				}
			}
		}
		
		point.put(); // Return the point to the pool
	}
	
	/**
	 * Ensures that the source field has been processed by the NotefieldRenderer
	 * This is critical when ProxyField is rendered through PlayState's system
	 */
	private function ensureSourceFieldProcessed():Void {
		if (proxiedField == null) return;
		
		// Get the NotefieldRenderer from PlayState
		var playState = PlayState.instance;
		if (playState != null && playState.notefields != null) {
			var renderer = playState.notefields;
			
			// Check if the source field is in the renderer
			var sourceInRenderer = false;
			for (field in renderer.members) {
				if (field == proxiedField) {
					sourceInRenderer = true;
					break;
				}
			}
			
			// If source is in renderer, manually call preDraw on it to ensure it's ready
			if (sourceInRenderer) {
				if (proxiedField.exists || proxiedField.forcePreDraw) {
					proxiedField.preDraw();
				}
			} else {
				trace("WARNING: ProxyField source not found in renderer during draw");
			}
		}
	}
	
	/**
	 * Custom draw logic that copies the draw queue from the proxied field
	 */
	private function drawProxyField():Void {
		// Copy the draw queue from the proxied field
		if (proxiedField != null && proxiedField.drawQueue != null) {
			// Create a shallow copy to avoid reference issues
			drawQueue = proxiedField.drawQueue.copy();
		} else {
			drawQueue = [];
		}
	}
	
	/**
	 * Automatically add this ProxyField to the notefields renderer if possible
	 */
	private function autoAddToRenderer():Void {
		// Try to get the notefields renderer from PlayState
		var playState = PlayState.instance;
		if (playState != null && playState.notefields != null) {
			trace("Auto-adding ProxyField to renderer...");
			addToRenderer(playState.notefields, this);
		} else {
			trace("Cannot auto-add ProxyField: PlayState.instance = " + playState + 
				  ", notefields = " + (playState != null ? Std.string(playState.notefields) : "N/A"));
		}
	}
	
	/**
	 * Check if this ProxyField is in PlayState's members list
	 */
	private function isInPlayStateMembers():Bool {
		var playState = PlayState.instance;
		if (playState != null && playState.members != null) {
			return playState.members.contains(this);
		}
		return false;
	}
}
