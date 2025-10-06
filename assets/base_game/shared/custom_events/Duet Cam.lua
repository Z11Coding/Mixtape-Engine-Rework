--works fine to get the middle
--buggy on pixel stages

--Made by Held_der_Zeit


isBoth = false --if the CAM shows at both

function onCreatePost()
    zeroBfOffX = getMidpointX("boyfriend")-100
    zeroBfOffY = getMidpointY("boyfriend")-100
    zeroDadOffX = getMidpointX("dad") +150
    zeroDadOffY = getMidpointY("dad") -100

    stageZoom = getProperty("defaultCamZoom")
end

function onEvent(name, value1, value2)
    if name == 'Duet Cam' then
        zeroBfOffX = getMidpointX("boyfriend")-100
        zeroBfOffY = getMidpointY("boyfriend")-100
        zeroDadOffX = getMidpointX("dad") +150
        zeroDadOffY = getMidpointY("dad") -100

        stageZoom = getProperty("defaultCamZoom")
        -- debugPrint("'"..value2.."'")
        -- debugPrint("CHANGE")
        
        --keep cam (but let zoom change) if value2 is ANYTHING
        if isBoth and (value2 ~= "") then --or (value2 ~= nil) then
            isBoth = not isBoth
            -- debugPrint(isBoth)
            -- setProperty("isCameraOnForcedPos", isBoth)
            -- debugPrint(getProperty("isCameraOnForcedPos"))
        end

        isBoth = not isBoth

        setProperty("isCameraOnForcedPos", isBoth)

        if isBoth then
            setProperty("camFollow.x",(zeroBfOffX<zeroDadOffX and zeroBfOffX or zeroDadOffX) + math.abs(zeroBfOffX - zeroDadOffX)/2)
            setProperty("camFollow.y",(zeroBfOffY<zeroDadOffY and zeroBfOffY or zeroDadOffY) + math.abs(zeroBfOffY - zeroDadOffY)/2)

            --custom camzoom (for when chars are further away)
            if tonumber(value1) ~= nil then
                setProperty("defaultCamZoom", value1)
            else
                setProperty("defaultCamZoom", stageZoom)

            end
        else
            setProperty("defaultCamZoom", stageZoom)

            cameraSetTarget(mustHitSection and "boyfriend" or "dad")
            -- if mustHitSection then
            --     cameraSetTarget("boyfriend")
            -- else
            --     cameraSetTarget("dad")
            -- end
        end
    end
end