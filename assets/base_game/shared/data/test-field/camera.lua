
--[[
    Camera Move Script
    by Shartize
]]

local Camdata = {
    {Character="bf",type="Auto",Posename="find",Ofs=20},
    {Character="dad",type="Auto",Posename="find",Ofs=20},
    {Character="monster",type="manual",Posename="find",
    Poselist={
        {name="LEFT",Ofs={x=100,y=0}},
        {name="DOWN",Ofs={x=0,y=100}},
        {name="UP",Ofs={x=0,y=-100}},
        {name="RIGHT",Ofs={x=-100,y=0}},
    }},
    {Character="monster-christmas",type="manual",Posename="find",
    Poselist={
        {name="LEFT",Ofs={x=100,y=0}},
        {name="DOWN",Ofs={x=0,y=100}},
        {name="UP",Ofs={x=0,y=-100}},
        {name="RIGHT",Ofs={x=-100,y=0}},
    }},
}
local CamdataTemplate = {type="Auto",Posename="find",Ofs=20}
local tempcharacter = {bf=0,dad=0,gf=0}
local tempcharactername = {bf=0,dad=0,gf=0}
local characterselfrag = {bf=true,dad=true,gf=true}
local curcharacterpos = "bf"; 
function onCreate()
    onChangeChardata("bf")
    onChangeChardata("dad")
    onChangeChardata("gf")
end
--boyfriendName
--dadName
--getProperty('gf.curCharacter')

function onChangeChardata(charname)
    --debugPrint(charname)
    if charname == "bf" then
        tempcharactername.bf = boyfriendName;
        characterselfrag.bf = false;
        for i= 1 , #Camdata do
            if Camdata[i].Character == boyfriendName then
                tempcharacter.bf = i;
                characterselfrag.bf = true;
            end
        end
        if not characterselfrag.bf then
            tempcharacter.bf = "template";
        end
    end
    if charname == "dad" then
        tempcharactername.dad = dadName;
        characterselfrag.dad = false;
        for i= 1 , #Camdata do
            if Camdata[i].Character == dadName then
                tempcharacter.dad = i;
                characterselfrag.dad = true;
            end
        end
        if not characterselfrag.dad then
            tempcharacter.dad = "template";
        end
    end
    if charname == "gf" then
        tempcharactername.gf = getProperty('gf.curCharacter');
        characterselfrag.gf = false;
        for i= 1 , #Camdata do
            if Camdata[i].Character == getProperty('gf.curCharacter') then
                tempcharacter.gf = i;
                characterselfrag.gf = true;
            end
        end
        if not characterselfrag.gf then
            tempcharacter.gf = "template";
        end
    end
    --characterselfrag = {bf=false,dad=false,gf=false}
end

function onUpdatePost(elapsed)
    if boyfriendName ~= tempcharactername.bf then
        onChangeChardata("bf")
    end
    if dadName ~= tempcharactername.dad then
        onChangeChardata("dad")
    end
    if getProperty('gf.curCharacter') ~= tempcharactername.gf then
        onChangeChardata("gf")
    end
    camofset = {x=0,y=0}
    --debugPrint("camfx"..getProperty("camFollow.x"))
    --debugPrint("camfy"..getProperty("camFollow.y"))
    if mustHitSection == false then
        if gfSection == false or gfSection == nil then
            curcharacterpos = "dad";
            Cam = {x=getMidpointX('dad') + 150 + getProperty('dad.cameraPosition[0]') + getProperty('opponentCameraOffset[0]'),
            y=getMidpointY('dad') - 100 + getProperty('dad.cameraPosition[1]') + getProperty('opponentCameraOffset[1]')}
            if tempcharacter.dad == "template" then
                camtemp = CamdataTemplate;
            else
                camtemp = Camdata[tempcharacter.dad];
            end
        else
            curcharacterpos = "gf";
            Cam = {x=getMidpointX('gf') + getProperty('gf.cameraPosition[0]') + getProperty('girlfriendCameraOffset[0]'),
            y=getMidpointY('gf') + getProperty('gf.cameraPosition[1]') + getProperty('girlfriendCameraOffset[1]')}
            if tempcharacter.gf == "template" then
                camtemp = CamdataTemplate;
            else
                camtemp = Camdata[tempcharacter.gf];
            end
        end
    else
        curcharacterpos = "boyfriend";
        Cam = {x=getMidpointX('boyfriend') - 100 - getProperty('boyfriend.cameraPosition[0]') + getProperty('boyfriendCameraOffset[0]'),
        y=getMidpointY('boyfriend') - 100 + getProperty('boyfriend.cameraPosition[1]') + getProperty('boyfriendCameraOffset[1]')}
        if tempcharacter.bf == "template" then
            camtemp = CamdataTemplate;
        else
            camtemp = Camdata[tempcharacter.bf];
        end
    end
    if camtemp.type == 'Auto' then
        if camtemp.Posename == "find" then
            if string.find(getProperty(curcharacterpos..'.animation.curAnim.name'),"LEFT") then
                camofset = {x=Cam.x-camtemp.Ofs,y=Cam.y}
            elseif string.find(getProperty(curcharacterpos..'.animation.curAnim.name'),"DOWN") then
                camofset = {x=Cam.x,y=Cam.y+camtemp.Ofs}
            elseif string.find(getProperty(curcharacterpos..'.animation.curAnim.name'),"UP") then
                camofset = {x=Cam.x,y=Cam.y-camtemp.Ofs}
            elseif string.find(getProperty(curcharacterpos..'.animation.curAnim.name'),"RIGHT") then
                camofset = {x=Cam.x+camtemp.Ofs,y=Cam.y}
            else
                camofset = {x=Cam.x,y=Cam.y}
            end
        elseif camtemp.Posename == "match" then
            if getProperty(curcharacterpos..'.animation.curAnim.name') == 'singLEFT' or getProperty(curcharacterpos..'.animation.curAnim.name') == 'singLEFT-alt' then
                camofset = {x=Cam.x-camtemp.Ofs,y=Cam.y}
            elseif getProperty(curcharacterpos..'.animation.curAnim.name') == 'singDOWN' or getProperty(curcharacterpos..'.animation.curAnim.name') == 'singDOWN-alt' then
                camofset = {x=Cam.x,y=Cam.y+camtemp.Ofs}
            elseif getProperty(curcharacterpos..'.animation.curAnim.name') == 'singUP' or getProperty(curcharacterpos..'.animation.curAnim.name') == 'singUP-alt' then
                camofset = {x=Cam.x,y=Cam.y-camtemp.Ofs}
            elseif getProperty(curcharacterpos..'.animation.curAnim.name') == 'singRIGHT' or getProperty(curcharacterpos..'.animation.curAnim.name') == 'singRIGHT-alt' then
                camofset = {x=Cam.x+camtemp.Ofs,y=Cam.y}
            else
                camofset = {x=Cam.x,y=Cam.y}
            end
        end
    elseif camtemp.type == 'manual' then
        if camtemp.Posename == "find" then
            local fragcam = false;
            for i=1,#camtemp.Poselist do
                if string.find(getProperty(curcharacterpos..'.animation.curAnim.name'),camtemp.Poselist[i].name) then
                    camofset = {x=Cam.x+camtemp.Poselist[i].Ofs.x,y=Cam.y+camtemp.Poselist[i].Ofs.y}
                    fragcam = true;
                end
            end
            if not fragcam then
                camofset = {x=Cam.x,y=Cam.y}
            end
        elseif camtemp.Posename == "match" then
            local fragcam = false;
            for i=1,#camtemp.Poselist do
                if getProperty(curcharacterpos..'.animation.curAnim.name') == camtemp.Poselist[i].name then
                    camofset = {x=Cam.x+camtemp.Poselist[i].Ofs.x,y=Cam.y+camtemp.Poselist[i].Ofs.y}
                    fragcam = true;
                end
            end
            if not fragcam then
                camofset = {x=Cam.x,y=Cam.y}
            end
        end
    else
        camofset = {x=Cam.x,y=Cam.y}
    end
    --debugPrint(camtemp.Posename)
    setProperty("camFollow.x",camofset.x)
    setProperty("camFollow.y",camofset.y)
end