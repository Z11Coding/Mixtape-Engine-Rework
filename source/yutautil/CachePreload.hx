import haxe.macro.Context;
import haxe.macro.Expr;
import states.CacheState;

class CachePreload {
	public static macro function preloadImages():Expr {
		// Generate code to preload images and add them to ImageCache
		var code:Expr = macro {
			var images:Array<String> = [];
			Paths.crawlDirectory("assets", ".png", images);
			for (image in images) {
				ImageCache.add(image);
			}
		};
		return code;
	}
}