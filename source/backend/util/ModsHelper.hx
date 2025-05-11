package backend.util;

import openfl.filters.BitmapFilter;
import flixel.util.FlxSort;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import haxe.io.Path;

using backend.util.ArrayTools;

class ModsHelper {
	public static function getModsWithPlayersRegistry():Array<String> {
		#if MODS_ALLOWED
		return Mods.parseList().enabled.filter(s ->Paths.exists(Paths.mods(s)+'/registry/players'));
		#else
		return [];
		#end
	}
	public inline static function loadabsoluteGraphic(path:String):FlxGraphic {
		if(!Paths.currentTrackedAssets.exists(path)) {
			Paths.cacheBitmap(path,null,BitmapData.fromFile(path));
		}
		return Paths.currentTrackedAssets.get(path);
	}
	public inline static function getSoundChannel(sound:FlxSound){
		@:privateAccess
		return sound._channel.__audioSource;
	}
	public inline static function setFiltersOnCam(camera:FlxCamera,value:Array<BitmapFilter>){
		camera.filters = value;
		camera.filtersEnabled = true;
	}
	#if sys
	public inline static function collectVideos():String{
		var dirsToList = new Array<String>();
		dirsToList.push('assets/videos/commercials/');
		if(Paths.exists('mods/videos/commercials'))dirsToList.push('mods/videos/commercials/');
		Mods.loadTopMod();
		var modsToSearch = Mods.getGlobalMods();
		modsToSearch.pushUnique(Mods.currentModDirectory);
		modsToSearch = modsToSearch.filter(s -> Paths.exists('mods/$s/videos/commercials')).map(s -> 'mods/$s/videos/commercials');
		
		dirsToList = dirsToList.concat(modsToSearch);
		var commercialsToSelect = new Array<String>();
		for(potencialComercials in dirsToList){
		  for (file in Paths.readDirectory(potencialComercials).filter(s -> s.endsWith(".mp4"))) {
			commercialsToSelect.push(potencialComercials + '/'+file);
		  }
		}
		return FlxG.random.getObject(commercialsToSelect);
	  }
	#end
}