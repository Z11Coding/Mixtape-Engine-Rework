package backend.pokemon;

import cpp.Lib;
import backend.Paths;

enum CharacterType
{
	NPC;
	Player;
	Opponent;
}

class PokeSprite
{
    public var spritePath:String;
    public var moe:Bool;
    public var shiny:Bool;

    public function new(pokemon:String, moe:Bool = false, shiny:Bool = false)
    {
        var basePath:String = "assets/shared/pokemon/";
        var spriteType:String = "";

        if (moe) spriteType += "-moe";
        if (shiny) spriteType += "-shiny";

        this.spritePath = basePath + pokemon  + "/" + spriteType + "/";

        this.moe = moe;
        this.shiny = shiny;
    }

    public function loadFrontSprite():FlxSprite
    {
        var frontSpritePath:String = spritePath + "front.png";
        return new FlxSprite(0, 0, frontSpritePath);
    }

    public function loadBackSprite():FlxSprite
    {
        var backSpritePath:String = spritePath + "back.png";
        return new FlxSprite(0, 0, backSpritePath);
    }
}

class CharacterSprite
{
	public var overworld:String;
	public var front:String;
	public var back:String;

	public function new(character:String, type:CharacterType)
	{
		var basePath:String = "assets/shared/images/";
		var spritePath:String;

		switch type
		{
			case NPC:
				spritePath = basePath + "npcs/" + character + "/overworld.png";
				if (!FileSystem.exists(spritePath))
					throw "Overworld sprite not found for NPC: " + character;
				this.overworld = spritePath;
			case Player, Opponent:
				spritePath = basePath + (type == Player ? "players/" : "opponents/") + character;
				this.overworld = loadSprite(spritePath + "/overworld.png", "Overworld");
				this.front = loadSprite(spritePath + "/front.png", "Front battle");
				this.back = loadSprite(spritePath + "/back.png", "Back battle");
		}
	}

	private function loadSprite(path:String, spriteType:String):String
	{
		if (!FileSystem.exists(path))
			throw spriteType + " sprite not found at path: " + path;
		return path;
	}

	public function loadOverworldSprite():FlxSprite
	{
		return new FlxSprite(0, 0, overworld);
	}

	public function loadFrontSprite():FlxSprite
	{
		if (front == null)
			throw "Front sprite not available";
		return new FlxSprite(0, 0, front);
	}

	public function loadBackSprite():FlxSprite
	{
		if (back == null)
			throw "Back sprite not available";
		return new FlxSprite(0, 0, back);
	}
}

enum PokeType
{
	Normal;
	Fire;
	Water;
	Grass;
	Electric;
	Ice;
	Fighting;
	Poison;
	Ground;
	Flying;
	Psychic;
	Bug;
	Rock;
	Ghost;
	Dragon;
	Dark;
	Steel;
	Fairy;
}

class PokeTypePair
{
	public var types:Array<PokeType>;

	public function new(type1:PokeType, type2:PokeType = null)
	{
		types = [type1];
		if (type2 != null)
		{
			types.push(type2);
		}
	}
}

typedef PokeMove =
{
	var name:String;
	var damage:Int;
	var type:PokeType;
	var animation:String;
	var statusEffect:String;
	var levelRequirement:Null<Int>; // Level requirement for the move
	var pokemonRequirement:Null<PokeSpecies>; // Pokemon requirement for the move
	var additionalRules:Array<Rule>; // Additional rules for move eligibility
}

typedef Rule =
{
	var ruleType:RuleType;
	var value:Dynamic;
}

enum RuleType
{
	LevelGreaterThan; // Level of the Pokemon must be greater than the specified value
	LevelLessThan; // Level of the Pokemon must be less than the specified value
	HasType; // Pokemon must have the specified type
	HasAbility; // Pokemon must have the specified ability
	HasItem; // Pokemon must have the specified item
	HasStatusEffect; // Pokemon must have the specified status effect
}

typedef PokeMoves = Array<PokeMove>;

typedef PokeSpecies =
{
	var name:String;
	var type:PokeTypePair;
	var baseStats:{
		attack:Int,
		defense:Int,
		speed:Int,
		specialAttack:Int,
		specialDefense:Int
	};
	var moves:PokeMoves;
	var sprite:PokeSprite;
	var moe:Bool;
	var abilities:Array<String>;
	var items:Array<PokeItems>;
}

enum PokeGender
{
	Male;
	Female;
	Genderless;
}

enum PokeNature
{
	Hardy;
	Lonely;
	Brave;
	Adamant;
	Naughty;
	Bold;
	Docile;
	Relaxed;
	Impish;
	Lax;
	Timid;
	Hasty;
	Serious;
	Jolly;
	Naive;
	Modest;
	Mild;
	Quiet;
	Bashful;
	Rash;
	Calm;
	Gentle;
	Sassy;
	Careful;
	Quirky;
}

enum PlayerAction
{
	Move;
	Switch;
	UseItem;
	Run;
}

enum BattleState
{
	PlayerTurn;
	OpponentTurn;
	PlayerWin;
	OpponentWin;
	Draw;
}

enum BattleMode
{
	Wild;
	Trainer;
	Double;
	Multi;
}

enum BattleWeather
{
	Clear;
	Rain;
	Sandstorm;
	Hail;
	Sun;
	Fog;
	Wind;
	Thunderstorm;
	Custom(name:String);
	Special(name:String, func:Void->Void);
}

enum BattleTerrain
{
	None;
	Grassy;
	Electric;
	Misty;
	Psychic;
	Custom(name:String);
	Special(name:String, func:Void->Void);
}

enum PlayerGender
{
	Male;
	Female;
}

typedef Pokemon =
{
	var id:Int;
	var species:PokeSpecies;
	var nickName:String;
	var gender:PokeGender;
    var shiny:Bool;
    var nature:PokeNature;
	var stats:{
		attack:Int,
		defense:Int,
		speed:Int,
		specialAttack:Int,
		specialDefense:Int
	};
	var hp:Int;
	var type:PokeTypePair;
	var moves:PokeMoves;
	var sprite:PokeSprite;
	var moe:Bool;
	var ability:String;
	var heldItem:PokeItems;
	var status:Array<StatusEffect>;
}

class PokeDex
{
	private static var instance:PokeDex;

	private var speciesMap:Map<Int, PokeSpecies>;

	private function new()
	{
		if (instance != null)
		{
			throw "PokeDex instance already exists";
		}
		speciesMap = new Map<Int, PokeSpecies>();
	}

	public static function getInstance():PokeDex
	{
		if (instance == null)
		{
			instance = new PokeDex();
		}
		return instance;
	}

	public function addSpecies(id:Null<Int>, species:PokeSpecies):Void
	{
		if (id != null && speciesMap.exists(id))
		{
			// Simulate a dialogue box asking the user what to do
			var userChoice:String = showDialogueBox("An entry with the same ID already exists. It will be overriden if you press OK, or moved if you press Cancel. Proceed?");

			switch userChoice
			{
				case "yes":
					// Replace the existing species
					speciesMap.set(id, species);
				case "no":
					// Find the next available ID and add the species there
					var nextID:Int = findNextAvailableID();
					speciesMap.set(nextID, species);
				case null:
					// Handle null (user made no decision)
					throw "Unable to comply: Error adding Pokemon to PokeDex with ID " + id + " and Species name " + species.name;
				default:
					// Optionally handle unexpected input
			}
		}
		else
		{
			// Your existing logic for adding a species with a new or null ID
			var nextID:Int = id == null ? findNextAvailableID() : id;
			speciesMap.set(nextID, species);
		}
	}

	private function findNextAvailableID():Int
	{
		var nextID:Int = 0;
		while (speciesMap.exists(nextID))
		{
			nextID++;
		}
		return nextID;
	}

	private function showDialogueBox(message:String):String
	{
		// Load the user32.dll library where MessageBox is located
		var user32 = cpp.Lib.load("user32", "MessageBox", 4);

		// Define the MessageBox parameters
		var hwnd:Dynamic = null; // Handle to the owner window; null for no owner
		var lpText:String = message; // The message to be displayed
		var lpCaption:String = "Decision Required"; // The dialog box title
		var uType:Int = 0x00000001 | 0x00000030; // MB_OKCANCEL | MB_ICONWARNING to show "OK" and "Cancel" buttons with a warning icon

		// Call MessageBox
		// 1 = IDOK, 2 = IDCANCEL, according to the Windows API
		var result:Int = user32(hwnd, lpText, lpCaption, uType);

		// Convert the result to a Haxe-readable format
		switch result
		{
			case 1:
				return "yes";
			case 2:
				return "no";
			default:
				return null;
		}
	}

	public function createSpecies(species:PokeSpecies):Void
	{
		PokeDex.getInstance().addSpecies(null, species);
	}

	public function getSpeciesByID(id:Int):Null<PokeSpecies>
	{
		return speciesMap.get(id);
	}

	public function getIDBySpecies(species:PokeSpecies):Null<Int>
	{
		for (key in speciesMap.keys())
		{
			if (speciesMap.get(key) == species)
			{
				return key;
			}
		}
		return null;
	}
}

enum StatusEffect
{
	None; // Null equivalent
	Paralyze(time:Int);
	Sleep(time:Int);
	Poison(time:Int);
	Burn(time:Int);
	Freeze(time:Int);
	Confusion(time:Int);
	Infatuation(time:Int);
	Curse(time:Int);
	BadlyPoison(time:Int);
	Faint;
}

typedef PokeItems =
{
	var name:String;
	var effect:String;
	var category:PokemonItemCategory;
}

enum PokemonItemCategory
{
	Health;
	Battle;
	Evolution;
	Status;
	Misc;
}

typedef PokeTrainer =
{
	var name:String;
	var team:Team;
	var items:Array<PokeItems>;
}

class PokePlayer
{
	public var trainer:PokeTrainer;
	public var items:Array<PokeItems>;
	public var saveData:SaveData;

	public function new(trainer:PokeTrainer, items:Array<PokeItems>, saveData:SaveData)
	{
		this.trainer = trainer;
		this.items = items;
		this.saveData = saveData;
	}
}

class SaveData
{
	// Define the properties of the save data here
}

class SaveManager
{
	public var saveData:SaveData;

	public function new()
	{
		saveData = new SaveData();
	}

	public function saveGame(player:PokePlayer):Void
	{
		// Save the game using the player's data and the save data
	}

	public function loadGame():PokePlayer
	{
		// Load the game and return a PokePlayer object with the loaded data
		return new PokePlayer(/* loaded trainer */, /* loaded items */, saveData);
	}
}

typedef Team =
{
	var pokemon:Array<Pokemon>;

	public function new(pokemon:Array<Pokemon>)
	{
		if (pokemon.length > 6)
		{
			throw "Team can only have 6 Pokemon";
		}
		this.pokemon = pokemon;
	}
}

class PokemonManager
{
	public var trainers:Array<PokeTrainer>;
	public var allMoves:PokeMoves;
	public var allItems:Array<PokeItems>;

	public function new()
	{
		trainers = [];
		allMoves = [];
		allItems = [];
	}

	public function addPokeMove(move:PokeMove):Void
	{
		allMoves.push(move);
	}

	public function addPokeItem(item:PokeItems):Void
	{
		allItems.push(item);
	}

	public function addTrainer(trainer:PokeTrainer):Void
	{
		trainers.push(trainer);
	}

	public static function createPokeSprite(spriteName:String, moe:Bool = false):PokeSprite
	{
		return new PokeSprite(spriteName, moe);
	}

	public extern inline overload function addPokemonToTrainer(trainer:PokeTrainer, id:Int):Void
	{
		var species = PokeDex.getInstance().getSpeciesByID(id);
		if (species == null)
			throw "Species not found for ID: " + id;
		var pokemon = createPokemonFromSpecies(species);
		addPokemonToTeam(trainer, pokemon);
	}

	public extern inline overload function addPokemonToTrainer(trainer:PokeTrainer, species:PokeSpecies):Void
	{
		var pokemon = createPokemonFromSpecies(species);
		addPokemonToTeam(trainer, pokemon);
	}

	public extern inline overload function addPokemonToTrainer(trainer:PokeTrainer, pokemon:Pokemon):Void
	{
		addPokemonToTeam(trainer, pokemon);
	}

	private function addPokemonToTeam(trainer:PokeTrainer, pokemon:Pokemon):Void
	{
		if (trainer.team.pokemon.length >= 6)
		{
			throw "Team can only have 6 Pokemon";
		}
		trainer.team.pokemon.push(pokemon);
	}

	private function createPokemonFromSpecies(species:PokeSpecies):Pokemon
	{
		// Simplified example of creating a Pokemon instance from a PokeSpecies
		return {
			id: 0, // Generate or assign an ID
			species: species,
			nickName: species.name,
			stats: species.baseStats,
			hp: 100, // Example HP value
			type: species.type,
			moves: species.moves,
			sprite: species.sprite,
			moe: species.moe,
			ability: "", // Assign an ability
			heldItem: null, // Assign an item if any
			status: [] // Initialize status effects
		};
	}

	public static function updateStatusEffects(pokemon:Pokemon):Void
	{
		for (i in 0...pokemon.status.length)
		{
			var effect = pokemon.status[i];
			switch (effect)
			{
				case StatusEffect.Paralyze(time):
					if (time > 0)
					{
						pokemon.status[i] = StatusEffect.Paralyze(time - 1);
					}
					else
					{
						removeStatusEffect(pokemon, effect);
					}
					break;
				case StatusEffect.Sleep(time):
					if (time > 0)
					{
						pokemon.status[i] = StatusEffect.Sleep(time - 1);
					}
					else
					{
						removeStatusEffect(pokemon, effect);
					}
					break;
				case StatusEffect.Poison(time):
					if (time > 0)
					{
						pokemon.status[i] = StatusEffect.Poison(time - 1);
					}
					else
					{
						removeStatusEffect(pokemon, effect);
					}
					break;
				case StatusEffect.Burn(time):
					if (time > 0)
					{
						pokemon.status[i] = StatusEffect.Burn(time - 1);
					}
					else
					{
						removeStatusEffect(pokemon, effect);
					}
					break;
				case StatusEffect.Freeze(time):
					if (time > 0)
					{
						pokemon.status[i] = StatusEffect.Freeze(time - 1);
					}
					else
					{
						removeStatusEffect(pokemon, effect);
					}
					break;
				case StatusEffect.Confusion(time):
					if (time > 0)
					{
						pokemon.status[i] = StatusEffect.Confusion(time - 1);
					}
					else
					{
						removeStatusEffect(pokemon, effect);
					}
					break;
				case StatusEffect.Infatuation(time):
					if (time > 0)
					{
						pokemon.status[i] = StatusEffect.Infatuation(time - 1);
					}
					else
					{
						removeStatusEffect(pokemon, effect);
					}
					break;
				case StatusEffect.Curse(time):
					if (time > 0)
					{
						pokemon.status[i] = StatusEffect.Curse(time - 1);
					}
					else
					{
						removeStatusEffect(pokemon, effect);
					}
					break;
				case StatusEffect.BadlyPoison(time):
					if (time > 0)
					{
						pokemon.status[i] = StatusEffect.BadlyPoison(time - 1);
					}
					else
					{
						removeStatusEffect(pokemon, effect);
					}
					break;
				case StatusEffect.Faint:
					// Faint effect does not have a time, so no need to update or remove it
					break;
				default:
					// No effect, do nothing
					break;
			}
		}
	}

	public static function applyStatusEffect(pokemon:Pokemon, effect:StatusEffect, ?time:Null<Int>):Void
	{
		switch (effect)
		{
			case StatusEffect.Paralyze:
				pokemon.status.push(StatusEffect.Paralyze(time != null ? time : 3)); // Example duration of 3 turns
				break;
			case StatusEffect.Sleep:
				pokemon.status.push(StatusEffect.Sleep(time != null ? time : 5)); // Example duration of 5 turns
				break;
			case StatusEffect.Poison:
				pokemon.status.push(StatusEffect.Poison(time != null ? time : 4)); // Example duration of 4 turns
				break;
			case StatusEffect.Burn:
				pokemon.status.push(StatusEffect.Burn(time != null ? time : 3)); // Example duration of 3 turns
				break;
			case StatusEffect.Freeze:
				pokemon.status.push(StatusEffect.Freeze(time != null ? time : 2)); // Example duration of 2 turns
				break;
			case StatusEffect.Confusion:
				pokemon.status.push(StatusEffect.Confusion(time != null ? time : 4)); // Example duration of 4 turns
				break;
			case StatusEffect.Infatuation:
				pokemon.status.push(StatusEffect.Infatuation(time != null ? time : 3)); // Example duration of 3 turns
				break;
			case StatusEffect.Curse:
				pokemon.status.push(StatusEffect.Curse(time != null ? time : 5)); // Example duration of 5 turns
				break;
			case StatusEffect.BadlyPoison:
				pokemon.status.push(StatusEffect.BadlyPoison(time != null ? time : 6)); // Example duration of 6 turns
				break;
			case StatusEffect.Faint:
				pokemon.status.push(StatusEffect.Faint); // Faint effect does not have a duration
				break;
			default:
				// No effect, do nothing
				break;
		}
	}

	public static function removeStatusEffect(pokemon:Pokemon, effect:StatusEffect):Void
	{
		switch (effect)
		{
			case StatusEffect.Paralyze:
				// Remove paralysis effect from the pokemon
				break;
			case StatusEffect.Sleep:
				// Remove sleep effect from the pokemon
				break;
			case StatusEffect.Poison:
				// Remove poison effect from the pokemon
				break;
			case StatusEffect.Burn:
				// Remove burn effect from the pokemon
				break;
			case StatusEffect.Freeze:
				// Remove freeze effect from the pokemon
				break;
			case StatusEffect.Confusion:
				// Remove confusion effect from the pokemon
				break;
			case StatusEffect.Infatuation:
				// Remove infatuation effect from the pokemon
				break;
			case StatusEffect.Curse:
				// Remove curse effect from the pokemon
				break;
			case StatusEffect.BadlyPoison:
				// Remove badly poison effect from the pokemon
				break;
			case StatusEffect.Faint:
				// Remove faint effect from the pokemon
				break;
			default:
				// No effect, do nothing
				break;
		}
	}

	public static function initializePokedex():Void
	{
		var pokedex:PokeDex = new PokeDex();
		// Add Pokemon species to the Pokedex
		pokedex.createSpecies("Bulbasaur");
		pokedex.createSpecies("Charmander");
		pokedex.createSpecies("Squirtle");
		// Add more Pokemon species here
	}

	public static function calculateDamage(attacker:Pokemon, defender:Pokemon, move:PokeMove):Int
	{
		// Calculate the damage dealt by the move from the attacker to the defender
		return 0;
	}
}

class TypeWeaknessManager
{
	static var weaknesses:Map<PokeType, Array<{type:PokeType, percentage:Float}>> = new Map();
	static var immunities:Map<PokeType, Array<PokeType>> = new Map();
	static var resistances:Map<PokeType, Array<{type:PokeType, percentage:Float}>> = new Map();

	static function __init__()
	{
		weaknesses.set(PokeType.Normal, [{type: PokeType.Fighting, percentage: 1.0}]);
		weaknesses.set(PokeType.Fire, [
			{type: PokeType.Water, percentage: 2.0},
			{type: PokeType.Ground, percentage: 1.5},
			{type: PokeType.Rock, percentage: 1.5}
		]);
		weaknesses.set(PokeType.Water, [
			{type: PokeType.Electric, percentage: 1.5},
			{type: PokeType.Grass, percentage: 0.5}
		]);
		weaknesses.set(PokeType.Electric, [{type: PokeType.Ground, percentage: 0.0}]);
		weaknesses.set(PokeType.Grass, [
			{type: PokeType.Fire, percentage: 2.0},
			{type: PokeType.Ice, percentage: 2.0},
			{type: PokeType.Poison, percentage: 1.5},
			{type: PokeType.Flying, percentage: 1.5},
			{type: PokeType.Bug, percentage: 1.5}
		]);
		weaknesses.set(PokeType.Ice, [
			{type: PokeType.Fire, percentage: 2.0},
			{type: PokeType.Fighting, percentage: 2.0},
			{type: PokeType.Rock, percentage: 1.5},
			{type: PokeType.Steel, percentage: 1.5}
		]);
		weaknesses.set(PokeType.Fighting, [
			{type: PokeType.Flying, percentage: 1.5},
			{type: PokeType.Psychic, percentage: 1.5},
			{type: PokeType.Fairy, percentage: 1.5}
		]);
		weaknesses.set(PokeType.Poison, [
			{type: PokeType.Ground, percentage: 1.5},
			{type: PokeType.Psychic, percentage: 1.5}
		]);
		weaknesses.set(PokeType.Ground, [
			{type: PokeType.Water, percentage: 2.0},
			{type: PokeType.Grass, percentage: 2.0},
			{type: PokeType.Ice, percentage: 1.5}
		]);
		weaknesses.set(PokeType.Flying, [
			{type: PokeType.Electric, percentage: 2.0},
			{type: PokeType.Ice, percentage: 2.0},
			{type: PokeType.Rock, percentage: 1.5}
		]);
		weaknesses.set(PokeType.Psychic, [
			{type: PokeType.Bug, percentage: 1.5},
			{type: PokeType.Ghost, percentage: 1.5},
			{type: PokeType.Dark, percentage: 1.5}
		]);
		weaknesses.set(PokeType.Bug, [
			{type: PokeType.Fire, percentage: 2.0},
			{type: PokeType.Flying, percentage: 2.0},
			{type: PokeType.Rock, percentage: 1.5}
		]);
		weaknesses.set(PokeType.Rock, [
			{type: PokeType.Water, percentage: 2.0},
			{type: PokeType.Grass, percentage: 2.0},
			{type: PokeType.Fighting, percentage: 2.0},
			{type: PokeType.Ground, percentage: 2.0},
			{type: PokeType.Steel, percentage: 1.5}
		]);
		weaknesses.set(PokeType.Ghost, [{type: PokeType.Ghost, percentage: 1.5}, {type: PokeType.Dark, percentage: 1.5}]);
		weaknesses.set(PokeType.Dragon, [
			{type: PokeType.Ice, percentage: 2.0},
			{type: PokeType.Dragon, percentage: 2.0},
			{type: PokeType.Fairy, percentage: 2.0}
		]);
		weaknesses.set(PokeType.Dark, [
			{type: PokeType.Fighting, percentage: 1.5},
			{type: PokeType.Bug, percentage: 1.5},
			{type: PokeType.Fairy, percentage: 1.5}
		]);
		weaknesses.set(PokeType.Steel, [
			{type: PokeType.Fire, percentage: 2.0},
			{type: PokeType.Fighting, percentage: 2.0},
			{type: PokeType.Ground, percentage: 2.0}
		]);
		weaknesses.set(PokeType.Fairy, [
			{type: PokeType.Poison, percentage: 2.0},
			{type: PokeType.Steel, percentage: 2.0}
		]);

		immunities.set(PokeType.Ghost, [PokeType.Normal, PokeType.Fighting]);
		immunities.set(PokeType.Normal, [PokeType.Ghost]);

		resistances.set(PokeType.Fire, [
			{type: PokeType.Grass, percentage: 0.5},
			{type: PokeType.Ice, percentage: 0.5},
			{type: PokeType.Bug, percentage: 0.5},
			{type: PokeType.Steel, percentage: 0.5},
			{type: PokeType.Fairy, percentage: 0.5}
		]);
		resistances.set(PokeType.Water, [
			{type: PokeType.Fire, percentage: 0.5},
			{type: PokeType.Steel, percentage: 0.5},
			{type: PokeType.Water, percentage: 0.5},
			{type: PokeType.Ice, percentage: 0.5}
		]);
		// Add more resistances as needed
	}

	public static function isWeakAgainst(type:PokeType, againstType:PokeType):Bool
	{
		return weaknesses.exists(type) && weaknesses.get(type).some(function(weakness) return weakness.type == againstType);
	}

	public static function isImmuneTo(type:PokeType, againstType:PokeType):Bool
	{
		return immunities.exists(type) && immunities.get(type).indexOf(againstType) != -1;
	}

	public static function isResistantTo(type:PokeType, againstType:PokeType):Bool
	{
		return resistances.exists(type) && resistances.get(type).some(function(resistance) return resistance.type == againstType);
	}

	public static function calculateEffectiveness(moveType:PokeType, pokemonTypes:Array<PokeType>):Float
	{
		var effectivenessMultiplier:Float = 1.0;

		for (pokemonType in pokemonTypes)
		{
			if (isImmuneTo(pokemonType, moveType))
			{
				return 0; // Immediate immunity
			}
			else if (isWeakAgainst(pokemonType, moveType))
			{
				effectivenessMultiplier *= 2.0; // Weakness doubles effectiveness
			}
			else if (isResistantTo(pokemonType, moveType))
			{
				effectivenessMultiplier *= 0.5; // Resistance halves effectiveness
			}
			// No change for neutral effectiveness
		}

		return effectivenessMultiplier;
	}

	public static function getWeaknesses(type:PokeType):Array<{type:PokeType, percentage:Float}>
	{
		return weaknesses.get(type);
	}

	public static function getImmunities(type:PokeType):Array<PokeType>
	{
		return immunities.get(type);
	}

	public static function getResistances(type:PokeType):Array<{type:PokeType, percentage:Float}>
	{
		return resistances.get(type);
	}
}
