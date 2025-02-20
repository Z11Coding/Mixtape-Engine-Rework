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
    addBehindGF(spriteBreaker);
}

function onStepHit()
{
    if (curStep == 1)
    {
        game.camGame.setFilters([new ShaderFilter(game.getLuaObject("oldtimer").shader)]);
        game.camHUD.setFilters([new ShaderFilter(game.getLuaObject("oldtimer").shader)]);
    }
    if (curStep == 284)
    {
        game.camGame.setFilters([]);
        game.camHUD.setFilters([]);
    }
    if (curStep == 732)
    {
        game.camGame.setFilters([new ShaderFilter(game.getLuaObject("oldtimer").shader)]);
        game.camHUD.setFilters([new ShaderFilter(game.getLuaObject("oldtimer").shader)]);
    }
    if (curStep == 864)
    {
        game.camGame.setFilters([]);
        game.camHUD.setFilters([]);
    }
    if (curStep == 1120)
    {
        game.camGame.setFilters([new ShaderFilter(game.getLuaObject("oldtimer").shader)]);
        game.camHUD.setFilters([new ShaderFilter(game.getLuaObject("oldtimer").shader)]);
    }
    if (curStep == 1184)
    {
        game.camGame.setFilters([]);
        game.camHUD.setFilters([]);
    }
}