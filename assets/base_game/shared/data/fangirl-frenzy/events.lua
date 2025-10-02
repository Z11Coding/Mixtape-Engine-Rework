orchHit = false
bopCam = false
function onSongStart()
    triggerEvent("Add Camera Zoom", 0.05, 0.05)
end

function onBeatHit()
    if bopCam then
        triggerEvent("Add Camera Zoom", 0.05, 0.05)
    end
    if bopCamLite then
        triggerEvent("Add Camera Zoom", 0.02, 0.02)
    end
    if bopCamLiteH then
        if curBeat % 4 == 2 then
            triggerEvent("Add Camera Zoom", 0.02, 0.02)
        end
    end
end

function onStepHit()
    if curStep == 1 then
        orchHit = true
    end
    if curStep == 255 then
        orchHit = false
    end
    if curStep == 383 then
        orchHit2 = true
    end
    if curStep == 512 then
        orchHit2 = false
        orchHit3 = true
    end
    if curStep == 1024 then
        orchHit3 = false
        bopCam = true
    end
    if curStep == 1520 then
        setProperty('cameraSpeed', 999999999999999999999999999999)
    end
    if curStep == 1528 then
        setProperty('defaultCamZoom', 1.4)
        setProperty('camGame.zoom', 1.4)
        triggerEvent("Camera Follow Pos", getMidpointX("dad")+150, getMidpointY("dad")-100)
    end
    if curStep == 1536 then
        if flashingLights then
            cameraFlash('hud', 0xFFFFFFFF, 1)
        end
        bopCam = false
        bopCamLite = true
        setProperty('defaultCamZoom', 1.2)
    end
    if curStep == 1664 then
        triggerEvent("Camera Follow Pos", getMidpointX("boyfriend")-100, getMidpointY("boyfriend")-100)
        if flashingLights then
            cameraFlash('hud', 0xFFFFFFFF, 1)
        end
        bopCam = false
        bopCamLite = true
        setProperty('defaultCamZoom', 1.2)
    end
    if curStep == 1792 then
        triggerEvent("Camera Follow Pos", nil, nil)
        if flashingLights then
            cameraFlash('hud', 0xFFFFFFFF, 1)
        end
        bopCamLite = false
        bopCamLiteH = true
        setProperty('defaultCamZoom', 1)
        setProperty('cameraSpeed', 1)
    end
    if curStep == 2048 then
        bopCamLite = true
        bopCamLiteH = false
    end
    if curStep == 2560 then
        bopCamLite = false
        orchHit = true
    end
    if curStep == 3071 then
        orchHit = false
        bopCam = true
    end
    if curStep == 3584 then
        bopCam = false
        orchHit3B = true
    end
    if curStep == 3840 then
        orchHit3B = false
    end

    if orchHit then
        if curStep % 64 == 0 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
        if curStep % 64 == 24 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
        if curStep % 64 == 28 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
        if curStep % 64 == 32 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
        if curStep % 64 == 48 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
        if curStep % 64 == 54 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
        if curStep % 64 == 60 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
    end

    if orchHit2 then
        if curStep % 64 == 0 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
        if curStep % 64 == 16 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
        if curStep % 64 == 32 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
        if curStep % 64 == 48 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
        if curStep % 64 == 54 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
        if curStep % 64 == 60 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
    end

    if orchHit3 then
        if curStep % 64 == 0 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
        if curStep % 64 == 6 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
        if curStep % 64 == 12 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
        if curStep % 64 == 16 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
        if curStep % 64 == 22 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
        if curStep % 64 == 28 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
        if curStep % 64 == 32 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
        if curStep % 64 == 38 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
        if curStep % 64 == 44 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
        if curStep % 64 == 48 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
        if curStep % 64 == 54 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
        if curStep % 64 == 60 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
    end

    if orchHit3B then
        if curStep % 64 == 0 then
            triggerEvent("Add Camera Zoom", 0.08, 0.05)
        end
        if curStep % 64 == 6 then
            triggerEvent("Add Camera Zoom", 0.08, 0.05)
        end
        if curStep % 64 == 12 then
            triggerEvent("Add Camera Zoom", 0.08, 0.05)
        end
        if curStep % 64 == 16 then
            triggerEvent("Add Camera Zoom", 0.08, 0.05)
        end
        if curStep % 64 == 22 then
            triggerEvent("Add Camera Zoom", 0.08, 0.05)
        end
        if curStep % 64 == 28 then
            triggerEvent("Add Camera Zoom", 0.08, 0.05)
        end
        if curStep % 64 == 32 then
            triggerEvent("Add Camera Zoom", 0.08, 0.05)
        end
        if curStep % 64 == 38 then
            triggerEvent("Add Camera Zoom", 0.08, 0.05)
        end
        if curStep % 64 == 44 then
            triggerEvent("Add Camera Zoom", 0.08, 0.05)
        end
        if curStep % 64 == 48 then
            triggerEvent("Add Camera Zoom", 0.08, 0.05)
        end
        if curStep % 64 == 54 then
            triggerEvent("Add Camera Zoom", 0.08, 0.05)
        end
        if curStep % 64 == 60 then
            triggerEvent("Add Camera Zoom", 0.08, 0.05)
        end
    end
end