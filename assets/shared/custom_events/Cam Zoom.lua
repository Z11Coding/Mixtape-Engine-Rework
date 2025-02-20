function onEvent(name, v1, v2)

camzoom = getProperty('defaultCamZoom') + v1

    if name == 'Cam Zoom' then
        setProperty('defaultCamZoom', camzoom);
    end

end