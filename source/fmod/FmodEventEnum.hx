package fmod;
// Generated haxefmod constants - do not edit (regenerate from FMOD Studio or via haxelib run haxefmod generate)

enum FmodEventEnum {
	MusicLevel1;
	MusicLevel2;
	MusicLevel3;
	MusicLevel4;
	MusicMainMenu;
	SfxCoin;
	SfxJump;
}

// Static extension: `using FmodEventEnum.FmodEventTools;` enables
// FmodEventEnum.MusicMainLevel.path() and .guid()
class FmodEventTools {
	public static inline function path(event:FmodEventEnum):String {
		return switch (event) {
			case MusicLevel1: "event:/Music/Level1";
			case MusicLevel2: "event:/Music/Level2";
			case MusicLevel3: "event:/Music/Level3";
			case MusicLevel4: "event:/Music/Level4";
			case MusicMainMenu: "event:/Music/MainMenu";
			case SfxCoin: "event:/sfx/Coin";
			case SfxJump: "event:/sfx/Jump";
		};
	}

	public static inline function guid(event:FmodEventEnum):String {
		return switch (event) {
			case MusicLevel1: "{86994bb3-3afd-4b68-a7e8-ad64a471943c}";
			case MusicLevel2: "{a5a14ac0-7469-47b7-9682-4cb1206bb495}";
			case MusicLevel3: "{0e0213cb-4a67-41b0-aed5-d5e4a0a15894}";
			case MusicLevel4: "{09426d80-3cab-49ee-8e70-651640918cbf}";
			case MusicMainMenu: "{55f91bc3-62b4-4907-927f-153d3b190ef7}";
			case SfxCoin: "{79a002ed-6985-45b7-9c7e-f5ed19b06592}";
			case SfxJump: "{6ba339eb-58d0-4636-b96d-18f56f242172}";
		};
	}
}
