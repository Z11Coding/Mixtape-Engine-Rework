@echo off
color 0d
cd ..
@echo on
echo Installing dependencies...
echo This might take a few moments depending on your internet speed.
haxelib git lime https://github.com/FunkinCrew/lime 268dacfb2609766e14bef9ea5b669e91501852d2
haxelib git openfl https://github.com/FunkinCrew/openfl 74a51908a116d6df74be1083e219abb9fa057636
haxelib git flixel https://github.com/FunkinCrew/flixel 141f23c400c0508c76d5a09a143f5ce6790f8122
haxelib git flixel-addons https://github.com/FunkinCrew/flixel-addons 7628435364c4a45440d1e5db656741b66a8cd2ec  --skip-dependencies
haxelib install flixel-ui 2.6.2
haxelib install tjson 1.4.0
haxelib install noisehx 0.0.1
haxelib git haxeui-core https://github.com/FunkinCrew/haxeui-core 998534fb830450ca1e60c47a9524af5730431145  --skip-dependencies
haxelib git haxeui-flixel https://github.com/haxeui/haxeui-flixel 100f2c96beab619cfe72c567a058c41c71e3e998  --skip-dependencies
haxelib install random 1.4.1
haxelib install flxrhythmconductor 0.2.0
haxelib install hxvlc 2.3.0 --skip-dependencies
haxelib install hxdiscord_rpc 1.3.0
haxelib install hxpy 2.0.0
haxelib install moonchart 0.5.1
haxelib install helder.set 0.3.1
haxelib install yaml 2.0.1
haxelib install haxe-concurrent 5.1.3
haxelib install actuate 1.9.0
haxelib install deflatex 1.0.0
haxelib git json2object https://github.com/FunkinCrew/json2object dc945d58c1239a6ab6e37e0a6c128387193c9af5
haxelib git flixel-animate https://github.com/MaybeMaru/flixel-animate c5e3393c70b71a191f20fa902114cea92042e486
haxelib git flxsoundfilters https://github.com/TheZoroForce240/FlxSoundFilters
haxelib git hxWebSockets https://github.com/ianharrigan/hxWebSockets
haxelib git linc_dialogs https://github.com/ceramic-engine/linc_dialogs.git
haxelib git flxanimate https://github.com/Dot-Stuff/flxanimate 768740a56b26aa0c072720e0d1236b94afe68e3e
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit 1906c4a96f6bb6df66562b3f24c62f4c5bba14a7
haxelib git funkin.vis https://github.com/Z11Coding/funkVis-FrequencyFixed
haxelib git grig.audio https://gitlab.com/haxe-grig/grig.audio.git cbf91e2180fd2e374924fe74844086aab7891666 src
haxelib git thx.core https://github.com/fponticelli/thx.core 2bf2b992e06159510f595554e6b952e47922f128
haxelib git thx.semver https://github.com/fponticelli/thx.semver bdb191fe7cf745c02a980749906dbf22719e200b
haxelib install tink_core 1.26.0
haxelib git flixel-text-input https://github.com/FunkinCrew/flixel-text-input 951a0103a17bfa55eed86703ce50b4fb0d7590bc
haxelib git hxcpp https://github.com/FunkinCrew/hxcpp 0376e9b19af9a4d91f9d9afc131a358467856a10
haxelib git tentools https://github.com/TentaRJ/tentools.git
haxelib git systools https://github.com/haya3218/systools
haxelib run lime rebuild systools windows
haxelib install crypto 1.0.4
haxelib install openflCamera 1.0.7
haxelib install openflMicrophone 1.0.1
haxelib install hscript-iris 1.1.3
haxelib install hscript 2.5.0
haxelib git moonchart https://github.com/MaybeMaru/moonchart
echo Finished!
pause
