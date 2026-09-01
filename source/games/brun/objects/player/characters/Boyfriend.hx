package games.brun.objects.player.characters;

class Boyfriend extends BaseChar {
  override public function new() {
    super("boyfriend", {
      charName: "Boyfriend",
      charPortrait: "bf",
      charPronouns: "He/Him",
      charSpeed: 100,
      charVelocity: 4,
      charGravity: 600
    }); // Default Character
  }
}

//TODO: Add mechanics to BF
