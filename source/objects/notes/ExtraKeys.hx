package objects.notes;

class ExtraKeys {
  // Start of Extra Keys
	public static final gfxLetter:Array<String> = [
		'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I',
		'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R'
	];

	//EK Data
	public static final ammo:Array<Int> = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18];
	public static final scales:Array<Float> = [0.9, 0.85, 0.8, 0.7, 0.66, 0.6, 0.55, 0.50, 0.46, 0.39, 0.36, 0.32, 0.31, 0.31, 0.3, 0.26, 0.26, 0.22];
	public static final lessX:Array<Int> = [0, 0, 0, 0, 0, 8, 7, 8, 8, 7, 6, 6, 8, 7, 6, 7, 6, 6];
	public static final separator:Array<Int> = [-50, 99, 99, 1, 1, 1, 2, 3, 3, 3, 4, 5, 6, 6, 7, 6, 5, 4];
	public static final xtra:Array<Int> = [1, 89, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
	public static final posRest:Array<Int> = [0, 0, 0, 0, 25, 32,46, 52, 60, 40, 45, 30, 30, 29,72, 37, 61, 80];
	public static final gridSizes:Array<Int> = [40, 40, 40, 40, 40, 40, 40, 40, 40, 35, 30, 25, 25, 20, 20, 20, 20, 15];
	public static final xPosButBetter:Array<Float> = [2, 2, 2, 2, 1.5, 1.1, 1.1, 1, 1, 2, 2, 2, 2, 1.2, 2, 2, 2, 2];
	public static final xPosButBetter2:Array<Float> = [1, 1, 1, 1, 1.1, 1.2, 1.3, 1.5, 1.7, 1, 1, 1, 1, 2.9, 1, 1, 1, 1];
	public static final xPosButBetterOff:Array<Float> = [100, 100, 100, 100, 130, 250, 300, 300, 300, 100, 100, 100, 100, 250, 100, 100, 100, 100];
	public static final offsets:Array<Dynamic> = [[20, 10], [10, 10], [10, 10], [10, 10], [10, 10], [10, 10], [10, 10], [10, 10], [10, 10], [10, 20], [10, 10], [10, 10], [10, 10], [10, 10], [10, 10],[10, 10],[10, 10], [10, 10]];
	public static final noteSplashScales:Array<Float> = [1.3, 1.2, 1.1, 1, 1, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.3, 0.3, 0.2, 0.18, 0.18, 0.15];
	public static final noteSplashOffsets:Map<Int, Array<Int>> = [0 => [20, 10], 9 => [10, 20]];

	public static final minMania:Int = 0;
	public static final maxMania:Int = 17;
	public static final defaultMania:Int = 3;
	public static final pixelNotesDivisionValue:Array<Int> = [4, 18];

  public static final minManiaUI_integer:Int = minMania + 1;
	public static final maxManiaUI_integer:Int = maxMania + 1;

	public static final splashMax:Int = 17; // This specifies the max of the splashes can go

	public static final keysShit:Map<Int, Map<String, Dynamic>> = [
		0 => [
			"letters" => ["E"],
			"anims" => ["UP"],
			"singAnims" => ["singUP"],
			"strumAnims" => ["SPACE"],
			"pixelAnimIndex" => [4],
			"colArray" => [2]
		],
		1 => [
				"letters" => ["A", "D"],
				"anims" => ["LEFT", "RIGHT"],
				"singAnims" => ["singLEFT", "singRIGHT"],
				"strumAnims" => ["LEFT", "RIGHT"],
				"pixelAnimIndex" => [0, 3],
				"colArray" => [0, 3]
			],
		2 => [
				"letters" => ["A", "E", "D"],
				"anims" => ["LEFT", "UP", "RIGHT"],
				"singAnims" => ["singLEFT", "singUP", "singRIGHT"],
				"strumAnims" => ["LEFT", "SPACE", "RIGHT"],
				"pixelAnimIndex" => [0, 4, 3],
				"colArray" => [0, 2, 3]
			],
		3 => [
				"letters" => ["A", "B", "C", "D"],
				"anims" => ["LEFT", "DOWN", "UP", "RIGHT"],
				"singAnims" => ["singLEFT", "singDOWN", "singUP", "singRIGHT"],
				"strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT"],
				"pixelAnimIndex" => [0, 1, 2, 3],
				"colArray" => [0, 1, 2, 3]
			],

		4 => [
				"letters" => ["A", "B", "E", "C", "D"],
				"anims" => ["LEFT", "DOWN", "UP", "UP", "RIGHT"],
				"singAnims" => ["singLEFT", "singDOWN", "singUP", "singUP", "singRIGHT"],
				"strumAnims" => ["LEFT", "DOWN", "SPACE", "UP", "RIGHT"],
				"pixelAnimIndex" => [0, 1, 4, 2, 3],
				"colArray" => [0, 1, 2, 2, 3]
			],
		5 => [
				"letters" => ["A", "C", "D", "F", "B", "I"],
				"anims" => ["LEFT", "UP", "RIGHT", "LEFT", "DOWN", "RIGHT"],
				"singAnims" => ["singLEFT", "singUP", "singRIGHT", "singLEFT", "singDOWN", "singRIGHT"],
				"strumAnims" => ["LEFT", "UP", "RIGHT", "LEFT", "DOWN", "RIGHT"],
				"pixelAnimIndex" => [0, 2, 3, 5, 1, 8],
				"colArray" => [0, 2, 3, 0, 1, 3]
			],
		6 => [
				"letters" => ["A", "C", "D", "E", "F", "B", "I"],
				"anims" => ["LEFT", "UP", "RIGHT", "UP", "LEFT", "DOWN", "RIGHT"],
				"singAnims" => ["singLEFT", "singUP", "singRIGHT", "singUP", "singLEFT", "singDOWN", "singRIGHT"],
				"strumAnims" => ["LEFT", "UP", "RIGHT", "SPACE", "LEFT", "DOWN", "RIGHT"],
				"pixelAnimIndex" => [0, 2, 3, 4, 5, 1, 8],
				"colArray" => [0, 2, 3, 2, 0, 1, 3]
			],
		7 => [
				"letters" => ["A", "B", "C", "D", "F", "G", "H", "I"],
				"anims" => ["LEFT", "DOWN", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT"],
				"singAnims" => ["singLEFT", "singDOWN", "singUP", "singRIGHT", "singLEFT", "singDOWN", "singUP", "singRIGHT"],
				"strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT"],
				"pixelAnimIndex" => [0, 1, 2, 3, 5, 6, 7, 8],
				"colArray" => [0, 1, 2, 3, 0, 1, 2, 3]
			],
		8 => [
				"letters" => ["A", "B", "C", "D", "E", "F", "G", "H", "I"],
				"anims" => ["LEFT", "DOWN", "UP", "RIGHT", "UP", "LEFT", "DOWN", "UP", "RIGHT"],
				"singAnims" => ["singLEFT", "singDOWN", "singUP", "singRIGHT", "singUP", "singLEFT", "singDOWN", "singUP", "singRIGHT"],
				"strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "SPACE", "LEFT", "DOWN", "UP", "RIGHT"],
				"pixelAnimIndex" => [0, 1, 2, 3, 4, 5, 6, 7, 8],
				"colArray" => [0, 1, 2, 3, 2, 0, 1, 2, 3]
			],
		9 => [
				"letters" => ["A", "B", "C", "D", "E", "N", "F", "G", "H", "I"],
				"anims" => ["LEFT", "DOWN", "UP", "RIGHT", "UP", "UP", "LEFT", "DOWN", "UP", "RIGHT"],
				"singAnims" => ["singLEFT", "singDOWN", "singUP", "singRIGHT", "singUP", "singUP", "singLEFT", "singDOWN", "singUP", "singRIGHT"],
				"strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "SPACE", "CIRCLE", "LEFT", "DOWN", "UP", "RIGHT"],
				"pixelAnimIndex" => [0, 1, 2, 3, 4, 13, 5, 6, 7, 8],
				"colArray" => [0, 1, 2, 3, 2, 2, 0, 1, 2, 3]
			],
		10 => [
				"letters" => ["A", "B", "C", "D", "J", "E", "M", "F", "G", "H", "I"],
				"anims" => ["LEFT", "DOWN", "UP", "RIGHT", "LEFT", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT"],
				"singAnims" => ["singLEFT", "singDOWN", "singUP", "singRIGHT", "singLEFT", "singUP", "singRIGHT", "singLEFT", "singDOWN", "singUP", "singRIGHT"],
				"strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "CIRCLE", "SPACE", "CIRCLE", "LEFT", "DOWN", "UP", "RIGHT"],
				"pixelAnimIndex" => [0, 1, 2, 3, 9, 4, 12, 5, 6, 7, 8],
				"colArray" => [0, 1, 2, 3, 0, 2, 3, 0, 1, 2, 3]
			],
		11 => [
				"letters" => ["A", "B", "C", "D", "J", "K", "L", "M", "F", "G", "H", "I"],
				"anims" => ["LEFT", "DOWN", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT"],
				"singAnims" => ["singLEFT", "singDOWN", "singUP", "singRIGHT", "singLEFT", "singDOWN", "singUP", "singRIGHT", "singLEFT", "singDOWN", "singUP", "singRIGHT"],
				"strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "CIRCLE", "CIRCLE", "CIRCLE", "CIRCLE", "LEFT", "DOWN", "UP", "RIGHT"],
				"pixelAnimIndex" => [0, 1, 2, 3, 9, 10, 11, 12, 5, 6, 7, 8],
				"colArray" => [0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3]
			],
		12 => [
				"letters" => ["A", "B", "C", "D", "J", "K", "N", "L", "M", "F", "G", "H", "I"],
				"anims" => ["LEFT", "DOWN", "UP", "RIGHT", "LEFT", "DOWN", "UP", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT"],
				"singAnims" => ["singLEFT", "singDOWN", "singUP", "singRIGHT", "singLEFT", "singDOWN", "singUP", "singUP", "singRIGHT", "singLEFT", "singDOWN", "singUP", "singRIGHT"],
				"strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "CIRCLE", "CIRCLE", "CIRCLE", "CIRCLE", "CIRCLE", "LEFT", "DOWN", "UP", "RIGHT"],
				"pixelAnimIndex" => [0, 1, 2, 3, 9, 10, 13, 11, 12, 5, 6, 7, 8],
				"colArray" => [0, 1, 2, 3, 0, 1, 2, 2, 3, 0, 1, 2, 3]
			],
		13 => [
				"letters" => ["A", "B", "C", "D", "J", "K", "E", "N", "L", "M", "F", "G", "H", "I"],
				"anims" => ["LEFT", "DOWN", "UP", "RIGHT", "LEFT", "DOWN", "UP", "UP", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT"],
				"singAnims" => ["singLEFT", "singDOWN", "singUP", "singRIGHT", "singLEFT", "singDOWN", "singUP", "singUP", "singUP", "singRIGHT", "singLEFT", "singDOWN", "singUP", "singRIGHT"],
				"strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "CIRCLE", "CIRCLE", "SPACE", "CIRCLE", "CIRCLE", "CIRCLE", "LEFT", "DOWN", "UP", "RIGHT"],
				"pixelAnimIndex" => [0, 1, 2, 3, 9, 10, 4, 13, 11, 12, 5, 6, 7, 8],
				"colArray" => [0, 1, 2, 3, 0, 1, 2, 2, 2, 3, 0, 1, 2, 3]
			],
		14 => [
				"letters" => ["A", "B", "C", "D", "J", "K", "E", "N", "E", "L", "M", "F", "G", "H", "I"],
				"anims" => ["LEFT", "DOWN", "UP", "RIGHT", "LEFT", "DOWN", "UP", "UP", "UP", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT"],
				"singAnims" => ["singLEFT", "singDOWN", "singUP", "singRIGHT", "singLEFT", "singDOWN", "singUP", "singUP", "singUP", "singUP", "singRIGHT", "singLEFT", "singDOWN", "singUP", "singRIGHT"],
				"strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "CIRCLE", "CIRCLE", "SPACE", "CIRCLE", "SPACE", "CIRCLE", "CIRCLE", "LEFT", "DOWN", "UP", "RIGHT"],
				"pixelAnimIndex" => [0, 1, 2, 3, 9, 10, 4, 13, 4, 11, 12, 5, 6, 7, 8],
				"colArray" => [0, 1, 2, 3, 0, 1, 2, 2, 2, 2, 3, 0, 1, 2, 3]
			],
		15 => [
				"letters" => ["A", "B", "C", "D", "J", "K", "L", "M", "O", "P", "Q", "R", "F", "G", "H", "I"],
				"anims" => ["LEFT", "DOWN", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT"],
				"singAnims" => ["singLEFT", "singDOWN", "singUP", "singRIGHT", "singLEFT", "singDOWN", "singUP", "singRIGHT", "singLEFT", "singDOWN", "singUP", "singRIGHT", "singLEFT", "singDOWN", "singUP", "singRIGHT"],
				"strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "CIRCLE", "CIRCLE", "CIRCLE", "CIRCLE", "CIRCLE", "CIRCLE", "CIRCLE", "CIRCLE", "LEFT", "DOWN", "UP", "RIGHT"],
				"pixelAnimIndex" => [0, 1, 2, 3, 9, 10, 11, 12, 14, 15, 16, 17, 5, 6, 7, 8],
				"colArray" => [0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3]
			],
		16 => [
				"letters" => ["A", "B", "C", "D", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "F", "G", "H", "I"],
				"anims" => ["LEFT", "DOWN", "UP", "RIGHT", "LEFT", "DOWN", "UP", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT"],
				"singAnims" => ["singLEFT", "singDOWN", "singUP", "singRIGHT", "singLEFT", "singDOWN", "singUP", "singUP", "singRIGHT", "singLEFT", "singDOWN", "singUP", "singRIGHT", "singLEFT", "singDOWN", "singUP", "singRIGHT"],
				"strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "CIRCLE", "CIRCLE", "CIRCLE", "CIRCLE", "CIRCLE", "CIRCLE", "CIRCLE", "CIRCLE", "CIRCLE", "LEFT", "DOWN", "UP", "RIGHT"],
				"pixelAnimIndex" => [0, 1, 2, 3, 9, 10, 11, 12, 13, 14, 15, 16, 17, 5, 6, 7, 8],
				"colArray" => [0, 1, 2, 3, 0, 1, 2, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3]
		],
		17 => [
				"letters" => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I',
				'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R'],
				"anims" => ["LEFT", "DOWN", "UP", "RIGHT", "UP", "LEFT", "DOWN", "UP", "RIGHT",
				"LEFT", "DOWN", "UP", "RIGHT", "UP", "LEFT", "DOWN", "UP", "RIGHT"],
				"singAnims" => ["singLEFT", "singDOWN", "singUP", "singRIGHT", "singUP", "singLEFT", "singDOWN", "singUP", "singRIGHT",
				"singLEFT", "singDOWN", "singUP", "singRIGHT", "singUP", "singLEFT", "singDOWN", "singUP", "singRIGHT"],
				"strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "SPACE", "LEFT", "DOWN", "UP", "RIGHT",
				"LEFT", "DOWN", "UP", "RIGHT", "CIRCLE", "LEFT", "DOWN", "UP", "RIGHT"],
				"pixelAnimIndex" => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
				"colArray" => [0, 1, 2, 3, 2, 0, 1, 2, 3, 0, 1, 2, 3, 2, 0, 1, 2, 3]
		],
	];

  public static final pixelScales:Array<Float> = [
    1.2, //1k
    1.15, //2k
    1.1, //3k
    1, //4k
    0.9, //5k
    0.83, //6k
    0.8, //7k
    0.74, //8k
    0.7, //9k
    0.6, //10k
    0.55,//11k
    0.5, //12k
    0.48, //13k
    0.48, //14k
    0.42, //15k
    0.38, //16k
    0.38, //17k
    0.32 //18k
  ];

  public static var mania:Int = 3;

	// End of Extra Keys
}
