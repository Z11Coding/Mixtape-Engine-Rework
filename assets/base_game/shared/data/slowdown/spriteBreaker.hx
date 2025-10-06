var spriteBreaker:ProxyField;
var spriteBreaker2:ProxyField;
function onCreatePost()
{
    game.dadField.noteField.scrollFactor.set(1, 1);
    game.playerField.noteField.scrollFactor.set(1, 1);

    game.dadField.cameras = [game.camGame];
    game.dadField.noteField.cameras = [game.camGame];

    game.playerField.cameras = [game.camOther];
    game.playerField.noteField.cameras = [game.camOther];
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
