@echo off
color 0d
cd ..
@echo on
echo Installing dependencies...
echo This might take a few moments depending on your internet speed.
haxelib install lime 8.2.2
haxelib install openfl 9.4.1
haxelib install flixel 5.6.2
haxelib install flixel-addons 3.3.2
haxelib install hscript-iris 1.1.3
haxelib install tjson 1.4.0
haxelib install hxdiscord_rpc 1.2.4
haxelib install hxvlc 2.0.1 --skip-dependencies
haxelib install helder.set 0.3.1
haxelib install yaml 2.0.1
haxelib install haxe-concurrent 5.1.3
haxelib install actuate 1.9.0
haxelib install flixel-ui 2.6.1
haxelib install hscript 2.5.0
haxelib install noisehx 0.0.1
haxelib install haxeui-core 1.7.0
haxelib install haxeui-flixel 1.7.0
haxelib install deflatex 1.0.0
haxelib install crypto 1.0.4
haxelib install openflCamera 1.0.7
haxelib install openflMicrophone 1.0.1
haxelib install hxpy 2.0.0
haxelib install random 1.4.1
haxelib set lime 8.2.2
haxelib set openfl 9.4.1
haxelib git flixel-animate https://github.com/MaybeMaru/flixel-animate c61476f4b3a3d225631ab3065e4e925a4b63c076
haxelib git flxsoundfilters https://github.com/TheZoroForce240/FlxSoundFilters
haxelib git hxWebSockets https://github.com/ianharrigan/hxWebSockets
haxelib git linc_dialogs https://github.com/ceramic-engine/linc_dialogs.git
haxelib git flxanimate https://github.com/Dot-Stuff/flxanimate 768740a56b26aa0c072720e0d1236b94afe68e3e
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit 1906c4a96f6bb6df66562b3f24c62f4c5bba14a7
haxelib git funkin.vis https://github.com/NovaFlare-Engine-haxelib/funkVis-FrequencyFixed e129b15df24d731fc502cba3d4186c1e7c8bef2d
haxelib git grig.audio https://gitlab.com/haxe-grig/grig.audio.git cbf91e2180fd2e374924fe74844086aab7891666
haxelib git thx.core https://github.com/fponticelli/thx.core 2bf2b992e06159510f595554e6b952e47922f128
haxelib git flixel-text-input https://github.com/FunkinCrew/flixel-text-input 951a0103a17bfa55eed86703ce50b4fb0d7590bc
haxelib git FlxPartialSound https://github.com/FunkinCrew/FlxPartialSound.git f986332ba5ab02abd386ce662578baf04904604a
haxelib git moonchart https://github.com/MaybeMaru/moonchart
haxelib git tentools https://github.com/TentaRJ/tentools.git
haxelib git systools https://github.com/haya3218/systools
haxelib run lime rebuild systools windows
echo Finished!
pause

REM Ask user if they want to ensure the exact required versions
set /p ensure_versions="Do you want to ensure the exact required library versions? (y/n): "
if /i "%ensure_versions%"=="y" (
    haxelib set lime 8.2.2
    haxelib set openfl 9.4.1
    haxelib set flixel 5.6.2
    haxelib set flixel-addons 3.3.2
    haxelib set flixel-tools 1.5.1
    haxelib set hscript-iris 1.1.3
    haxelib set tjson 1.4.0
    haxelib set hxdiscord_rpc 1.3.0
    haxelib set hxvlc 2.0.1
    haxelib set helder.set 0.3.1
    haxelib set yaml 2.0.1
    haxelib set hxWebSockets git
    haxelib set haxe-concurrent 5.1.3
    haxelib set actuate 1.9.0
    haxelib set flixel-ui 2.6.1
    haxelib set hscript 2.5.0
    haxelib set noisehx 0.0.1
    REM Add more haxelib set commands here if you add more versioned libraries above
    echo All required library versions have been set.
)
