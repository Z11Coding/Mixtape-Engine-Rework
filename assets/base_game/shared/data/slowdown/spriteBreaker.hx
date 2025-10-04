var spriteBreaker:ProxyField;
var spriteBreaker2:ProxyField;
function onCreatePost()
{
    game.dadField.noteField.alpha = 0;
	game.dadField.noteField.scrollFactor.set(1, 1);
    game.playerField.noteField.scrollFactor.set(1, 1);
    
    spriteBreaker = new ProxyField(game.dadField.noteField);
	spriteBreaker.cameras = [game.camGame];
	spriteBreaker.scrollFactor.set(1,1);
    addBehindDad(spriteBreaker);

    spriteBreaker2 = new ProxyField(game.playerField.noteField);
	spriteBreaker2.cameras = [game.camOther];
	spriteBreaker2.scrollFactor.set(1,1);
    spriteBreaker2.alpha = 0;
    add(spriteBreaker2);
}

function onStepHit() {
    if (curStep == 2544) 
    {
        game.playerField.noteField.alpha = 0;
        game.playerField.noteField.scrollFactor.set(1, 1);
        spriteBreaker2.alpha = 1;
    }
}

function onUpdate() {
    spriteBreaker.x = game.dad.x - 130;
    spriteBreaker.y = game.dad.y - 100;
}