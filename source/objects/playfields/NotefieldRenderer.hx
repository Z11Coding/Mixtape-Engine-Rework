package objects.playfields;

import flixel.util.FlxDestroyUtil;
import flixel.math.FlxPoint;
import openfl.geom.ColorTransform;
import flixel.util.FlxColor;
import objects.playfields.NoteField;
import objects.playfields.FieldBase;
import objects.proxies.ProxyField;
import flixel.util.FlxSort;
import flixel.FlxBasic;
@:structInit
class FinalRenderObject extends RenderObject {
	public var sourceField:FieldBase;
	public var glowColour:FlxColor;
	public var cameras:Array<FlxCamera>;

}

class NotefieldRenderer extends FlxBasic {
	public var members:Array<FieldBase> = [];

	public function add(field:FieldBase){
		if(members.contains(field))return;
		members.push(field);
	}
	public function remove(field:FieldBase){
		if (members.contains(field))
			members.remove(field);
	}
	
	static function drawQueueSort(Obj1:FinalRenderObject, Obj2:FinalRenderObject) 
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.zIndex, Obj2.zIndex);
	
	var point:FlxPoint = FlxPoint.get(0, 0);
	
	override function draw(){
		var finalDrawQueue:Array<FinalRenderObject> = [];

		// Get all the drawing stuff from the fields
		for(field in members){
			if (!field.active || !field.exists || !field.visible)
				continue; // Ignore it

			field.preDraw(); // Collects all the drawing information
		}
		
		// Now that the main draw queues should have been populated, it's time to push them into the final draw queue for sorting
		
		
		for (field in members){
			field.draw(); // Just incase they want to do something before gathering happens (i.e ProxyFields grabbing their host's draw queue) 

			if(!field.visible || !field.active || !field.exists)
				continue;
			
			var realField:NoteField = cast field.isProxy ? cast(field, ProxyField).proxiedField : field;

			var glowColour = realField.modManager == null ? FlxColor.WHITE : FlxColor.fromRGBFloat(realField.modManager.getValue("flashR",
				realField.modNumber), realField.modManager.getValue("flashG", realField.modNumber),
				realField.modManager.getValue("flashB", realField.modNumber));

			var queue:Array<RenderObject> = field.drawQueue;
			for (object in queue){
				finalDrawQueue.push({
					graphic: object.graphic,
					shader: object.shader,
					alphas: object.alphas,
					glows: object.glows,
					uvData: object.uvData,
					vertices: object.vertices,
					indices: object.indices,
					zIndex: object.zIndex,
					colorSwap: object.colorSwap,
					antialiasing: object.antialiasing,
					sourceField: field,
					glowColour: glowColour,  // Maybe this should be part of the regular RenderObject?
					cameras: field.cameras
				});
			}
		}

		finalDrawQueue.sort(drawQueueSort); // TODO: Sort the *individual vertices* for better looking z-sorting

		// Now that it's all sorted, it's rendering time!

		// TODO: Put a callback here to allow us to use scripts to fuck w/ the final draw queue

		for (object in finalDrawQueue) {
			if (object == null)
				continue;
			var shader = object.shader;
			var graphic = object.graphic;
			var alphas = object.alphas;
			var glows = object.glows;
			var vertices = object.vertices;
			var uvData = object.uvData;
			var indices = object.indices;
			var colorSwap = object.colorSwap;
			var transforms:Array<ColorTransform> = []; // todo use fastvector
			var multAlpha = object.sourceField.alpha * 1;
			for (n in 0...Std.int(vertices.length / 2)) {
				var glow = glows[n];
				var transfarm:ColorTransform = new ColorTransform();
				transfarm.redMultiplier = 1 - glow;
				transfarm.greenMultiplier = 1 - glow;
				transfarm.blueMultiplier = 1 - glow;
				transfarm.redOffset = object.glowColour.red * glow;
				transfarm.greenOffset = object.glowColour.green * glow;
				transfarm.blueOffset = object.glowColour.blue * glow;
				transfarm.alphaMultiplier = alphas[n] * multAlpha;
				transforms.push(transfarm);
			}
			for (camera in object.cameras) {
				if (camera != null && camera.canvas != null && camera.canvas.graphics != null) {
					if (camera.alpha == 0 || !camera.visible)
						continue;
					for (shit in transforms)
						shit.alphaMultiplier *= camera.alpha;
					
					object.sourceField.getScreenPosition(point, camera);
					var drawItem = camera.startTrianglesBatch(graphic, object.antialiasing, true, null, true, shader);
					@:privateAccess
					{
						drawItem.addTrianglesColorArray(vertices, indices, uvData, null, point, camera._bounds, transforms, colorSwap);
					}
					for (n in 0...transforms.length)
						transforms[n].alphaMultiplier = alphas[n] * multAlpha;
				}
			}
		}

	}

	override function update(elapsed:Float){
		super.update(elapsed);
		
		for(field in members)
			field.update(elapsed);
	}
	override function destroy()
	{
		point = FlxDestroyUtil.put(point);
		super.destroy();

		try {
			while (members.length > 0)
				members.pop().destroy(); 
		}
		catch(e) {trace('No Members to Pop!');}
		
		members = null;
	}
}