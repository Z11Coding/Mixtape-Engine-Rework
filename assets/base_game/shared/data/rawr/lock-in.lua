lastFocus = ''
function onCreatePost()
    setProperty("cameraSpeed", 9999999999)
    setVar("enableLockInCam", true)
end
function onMoveCamera(focus)
    if getVar("enableLockInCam") then
        if focus ~= lastFocus then
            lastFocus = focus
            setProperty("camGame.zoom", getProperty("camGame.zoom")+0.1)
            doTweenZoom('camGameZoomBack', 'camGame', getProperty("camGame.zoom")-0.1, stepCrochet*0.001*2, 'sineOut')
            if focus == "dad" then
                triggerEvent('Camera Follow Pos', getProperty("dad.getMidpoint().x"), getProperty("dad.getMidpoint().y"))
            elseif focus == "boyfriend" then
                triggerEvent('Camera Follow Pos', getProperty("boyfriend.getMidpoint().x"), getProperty("boyfriend.getMidpoint().y"))
            elseif focus == "gf" then
                triggerEvent('Camera Follow Pos', getProperty("gf.getMidpoint().x"), getProperty("gf.getMidpoint().y"))
            end
        end
    end
end