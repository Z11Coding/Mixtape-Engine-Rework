package games.brun;

import flixel.FlxState;
import undertale.UnderTextParser;

class BRunMainMenu extends FlxState {
  // First Launch stuff
  var blackScreen:FlxSprite;
  var daText:UnderDialManager;

  var introDial:Array<String> = [
    "[set:0.8]...",
    "[set:0.8]..!",
    "[set:0.4]Oh, [pause:1]a guest...",
    "...[set:0.2]OH SHI-[instant]",
    "[sfx:brun/dialsfx/cartoonmayhem][instant]",
  ];

  var introDial2:Array<String> = [
    "[set:0.4]Hey There, [pause:1]Bozo!",
    "[next]Looks Like We've Got Ourselves A New Touture-",
    "[next]I Mean...[pause:3]",
    "New Runner!",
    "[sfx:brun/dialsfx/crowdclap]*Clap Sounds*",
    "Welcome to...[pause:1](Drumroll Please!)",
    "[sfx:brun/dialsfx/drumroll]*Drumroll*",
    "[sfx:brun/dialsfx/tada]BOYFRIEND RUNNER!!",
    "[playS:brun/music/mainmenu]Now, I Won't Keep Ya Too Long, [pause:1]So I'll Skip Right To The Chace.",
    "TL;DR, [pause:1]Press \"Start Running\" To Start The Game!",
    "Got Questions? [pause:1]Feel free to stop by the Q&A Station!\n[pause:1](The \"I\" Icon)",
    "Wanna Run Away? [pause:1]Fine, [pause:1]Whatever, [pause:1]Press \"ESC\" to ESCAPE![sfx:brun/dialsfx/badumtis]",
    "Alright, [pause:1]Enough Yapping! [pause:1]START RUNNING!"
  ];

  override function new() {
    super();

    daText = new UnderDialManager({
      sound: "uifont",
      color: FlxColor.WHITE,
      music: "",
      addStatic: true,
      addChroma: true,
      font: "fnf1",
      speed: 0.2
    }).loadDialogue(introDial);


  }

}
