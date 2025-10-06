local fs, mx = false, false
local ffi = require("ffi")

local runners = {}
local winSave = {
    x = 0,
    y = 0,
    fullscreen = false,
    maximized = false,
    width = 1280,
    height = 720,
    fullWidth = 0,
    fullHeight = 0
}
local enableShaderMask = false;

function onCreate()

    addHaxeLibrary('Lib', 'openfl')
    winSave.fullscreen = getPropertyFromClass('openfl.Lib', 'application.window.fullscreen')
    winSave.maximized = getPropertyFromClass('openfl.Lib', 'application.window.maximized')
    winSave.x = getPropertyFromClass('openfl.Lib', 'application.window.x')
    winSave.y = getPropertyFromClass('openfl.Lib', 'application.window.y')
    winSave.width = getPropertyFromClass('openfl.Lib', 'application.window.width')
    winSave.height = getPropertyFromClass('openfl.Lib', 'application.window.height')
    winSave.fullWidth = getPropertyFromClass("openfl.Lib", "application.window.display.bounds.width")
    winSave.fullHeight = getPropertyFromClass("openfl.Lib", "application.window.display.bounds.height")

    setVar('winX', winSave.x)
    setVar('winY', winSave.y)
    setVar('winW', winSave.width)
    setVar('winH', winSave.height)
    setVar('winSX', winSave.fullWidth)
    setVar('winSY', winSave.fullHeight)

    makeLuaSprite("arrowInit", "effects/mask/arrow2", 0, 0)
    setObjectCamera("arrowInit", "game")
    setProperty("arrowInit.alpha", 0)
    setSpriteShader("arrowInit", "ActualMaskShader")
    setShaderSampler2D("arrowInit", "iChannel1", "white")
    addLuaSprite("arrowInit", true)

    precacheImage('effects/mask/arrow0')
    precacheImage('effects/mask/arrow1')
    precacheImage('effects/mask/arrow2')
    precacheImage('effects/mask/arrow3')
    precacheImage('effects/mask/arrowtransition001')
    precacheImage('effects/mask/arrowtransition002')
    precacheImage('effects/mask/arrowtransition003')
    precacheImage('effects/mask/arrowtransition004')
    precacheImage('effects/mask/arrowtransition005')
    precacheImage('effects/mask/arrowtransition006')
    precacheImage('effects/mask/arrowtransition007')
    precacheImage('effects/mask/arrowtransition008')
    precacheImage('effects/mask/arrowtransition009')
    precacheImage('effects/mask/arrowtransition010')
    precacheImage('effects/mask/arrowtransition011')
    precacheImage('effects/mask/arrowtransition012')
    precacheImage('effects/mask/arrowtransition013')
    precacheImage('effects/mask/arrowtransition014')
    precacheImage('effects/mask/arrowtransition015')
    precacheImage('effects/mask/arrowtransition016')
end

function onEvent(name,v1,v2)
    if name == 'Arrow Mask Shader' then
        if v1 == 'on' then
            enableMaskShader()
        end

        if v1 == 'off' then
            disableMaskShader()
        end
    end
end


function enableMaskShader()
    fadeHUD(true)
    runTimer("arrowUpdate", 0.0216, 16)
end

function disableMaskShader()
    runTimer("arrowDelete", 0.02166, 16)
    fadeHUD(false)
    normalizeWindow();
    enableShaderMask = false;
end

function onTimerCompleted(t, l, ll)
    if t == "arrowUpdate" then
        local number = 16 - ll
        local text = string.format("%02d", number)
            
        setShaderSampler2D("arrowInit", "iChannel1", "effects/mask/arrowtransition0"..text)
        
        runHaxeCode(
            [[
                game.camGame.setFilters([new ShaderFilter(game.modchartSprites.get('arrowInit').shader)]);
            ]]
        )

        if number == 16 then
            setShaderSampler2D("arrowInit", "iChannel1", "effects/mask/arrow2")
    
        
            runHaxeCode(
                [[
                    game.camGame.setFilters([new ShaderFilter(game.modchartSprites.get('arrowInit').shader)]);
                ]]
            )
        
            enableShaderMask = true;
        end
    end

    if t == 'arrowDelete' then
        local number = ll + 1
        local text = string.format("%02d", number)
            
        setShaderSampler2D("arrowInit", "iChannel1", "effects/mask/arrowtransition0"..text)
        
        runHaxeCode(
            [[
                game.camGame.setFilters([new ShaderFilter(game.modchartSprites.get('arrowInit').shader)]);
            ]]
        )

        if number == 1 then

            runHaxeCode(
                [[
                    game.camGame.setFilters([]);
                ]]
            )
        end

        cancelTween('winMoveX')
        cancelTween('winMoveY')
        runHaxeCode([[
            var tag = 'winMove';
            var tag2 = 'winMoveY';
    
            var changex = getVar('winX');
            var changey = getVar('winY');
            if(game.modchartTweens.exists(tag)) {
                game.modchartTweens.get(tag).cancel();
                game.modchartTweens.get(tag).destroy();
                game.modchartTweens.remove(tag);
            }
            if(game.modchartTweens.exists(tag2)) {
                game.modchartTweens.get(tag2).cancel();
                game.modchartTweens.get(tag2).destroy();
                game.modchartTweens.remove(tag2);
            }
        ]]);
    end
end

function fadeHUD(fade)
    if fade then
        doTweenAlpha('fadeOutHUD','camHUD',0.001,stepCrochet*0.001*4,'quadInOut')
    else
        doTweenAlpha('fadeInHUD','camHUD',1,stepCrochet*0.001*4,'quadInOut')
    end
end

function opponentNoteHit(id,data,type,isSustain)
    if enableShaderMask then
        if not mustHitSection then
            setShaderSampler2D("arrowInit", "iChannel1", "effects/mask/arrow".. data)
            
            runHaxeCode(
                [[
                    game.camGame.setFilters([new ShaderFilter(game.modchartSprites.get('arrowInit').shader)]);
                ]]
            )
    
            if not isSustain then
                movementWindow(data)
            end
        end
    end
end

function goodNoteHit(id,data,type,isSustain)
    if enableShaderMask then
        if mustHitSection then
            setShaderSampler2D("arrowInit", "iChannel1", "effects/mask/arrow".. data)
            
            runHaxeCode(
                [[
                    game.camGame.setFilters([new ShaderFilter(game.modchartSprites.get('arrowInit').shader)]);
                ]]
            )
    
            if not isSustain then
                movementWindow(data)
            end
        end
    end
end

function movementWindow(data)
    cancelTween('winMoveX')
    cancelTween('winMoveY')
    runHaxeCode([[
        var tag = 'winMove';
        var tag2 = 'winMoveY';

        var changex = getVar('winX');
        var changey = getVar('winY');
        if(game.modchartTweens.exists(tag)) {
            game.modchartTweens.get(tag).cancel();
            game.modchartTweens.get(tag).destroy();
            game.modchartTweens.remove(tag);
        }
        if(game.modchartTweens.exists(tag2)) {
            game.modchartTweens.get(tag2).cancel();
            game.modchartTweens.get(tag2).destroy();
            game.modchartTweens.remove(tag2);
        }
        
        if (]] .. data .. [[ == 0) {
            game.modchartTweens.set(tag, FlxTween.tween(Lib.application.window, {x: changex - 100, y: changey}, 0.1, {ease: FlxEase.expoOut}));
        }

        if (]] .. data .. [[ == 1) {
            game.modchartTweens.set(tag2, FlxTween.tween(Lib.application.window, {x: changex, y: changey + 100}, 0.1, {ease: FlxEase.expoOut}));
        }

        if (]] .. data .. [[ == 2) {
            game.modchartTweens.set(tag2, FlxTween.tween(Lib.application.window, {x: changex, y: changey - 100}, 0.1, {ease: FlxEase.expoOut}));
        }

        if (]] .. data .. [[ == 3) {
            game.modchartTweens.set(tag, FlxTween.tween(Lib.application.window, {x: changex + 100, y: changey}, 0.1, {ease: FlxEase.expoOut}));
        }
    ]])
end

function onStepHit()
	if enableShaderMask then
        if buildTarget ~= 'windows' then
            onDestroy = function () end
            ffi, fs, mx = nil, nil, nil
            return
        end

    ffi.cdef([[
        typedef void* HWND;
        typedef int BOOL;
        typedef unsigned char BYTE;
        typedef unsigned long DWORD;
        HWND GetActiveWindow();
        long SetWindowLongA(HWND hWnd, int nIndex, long dwNewLong);
        BOOL SetLayeredWindowAttributes(HWND hwnd, DWORD crKey, BYTE bAlpha, DWORD dwFlags);
    ]])

    local hwnd = ffi.C.GetActiveWindow()
    ffi.C.SetWindowLongA(hwnd, -20, 0x00080000)
    ffi.C.SetLayeredWindowAttributes(hwnd, 0x000000, 0, 0x00000001)

    addHaxeLibrary('Lib', 'openfl')
    fs = getPropertyFromClass('openfl.Lib', 'application.window.fullscreen')
    mx = getPropertyFromClass('openfl.Lib', 'application.window.maximized')
    runHaxeCode([[
            Lib.application.window.borderless = true;
            Lib.application.window.maximized = false;
            Lib.application.window.fullscreen = false;
        ]])
	end
end

function onDestroy()
    normalizeWindow()
end

function normalizeWindow()
    ffi.C.SetWindowLongA(ffi.C.GetActiveWindow(), -20, 0x00000000)
    setPropertyFromClass('openfl.Lib', 'application.window.borderless', false)
    setPropertyFromClass('openfl.Lib', 'application.window.fullscreen', fs)
    setPropertyFromClass('openfl.Lib', 'application.window.maximized', mx)
end