#!/bin/sh
# SETUP FOR MAC SYSTEMS!!!
# IT'S DIFFERENT BECAUSE SYSTOOLS NEEDS IT TO BE
# REMINDER THAT YOU NEED HAXE INSTALLED PRIOR TO USING THIS
# https://haxe.org/download
cd ..
echo Makking the main haxelib and setuping folder in same time..
mkdir ~/haxelib && haxelib setup ~/haxelib
echo Installing dependencies...
echo This might take a few moments depending on your internet speed.
haxelib --global update haxelib
haxelib fixrepo
haxelib install lime 8.2.2
haxelib install openfl 9.4.1
haxelib install flixel 5.6.2
haxelib install flixel-addons 3.3.2
haxelib install flixel-tools 1.5.1
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
haxelib install funkin-modchart 1.2.3
haxelib install deflatex 1.0.0
haxelib install crypto 1.0.4
haxelib install openflCamera 1.0.7
haxelib install openflMicrophone 1.0.1
haxelib set lime 8.1.2
haxelib set openfl 9.3.3
haxelib git flxsoundfilters https://github.com/TheZoroForce240/FlxSoundFilters
haxelib git hxWebSockets https://github.com/ianharrigan/hxWebSockets
haxelib git linc_dialogs https://github.com/snowkit/linc_dialogs.git
haxelib git flxanimate https://github.com/Dot-Stuff/flxanimate 768740a56b26aa0c072720e0d1236b94afe68e3e
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit 1906c4a96f6bb6df66562b3f24c62f4c5bba14a7
haxelib git funkin.vis https://github.com/beihu235/funkVis-FrequencyFixed
haxelib git grig.audio https://gitlab.com/haxe-grig/grig.audio.git cbf91e2180fd2e374924fe74844086aab7891666
haxelib git haxeui-core https://github.com/haxeui/haxeui-core 51c23588614397089a5ce182cddea729f0be6fa0
haxelib git haxeui-flixel https://github.com/haxeui/haxeui-flixel da27e833947f32ef007ed11f523aa5524f5a5d54
haxelib git flixel-text-input https://github.com/FunkinCrew/flixel-text-input 951a0103a17bfa55eed86703ce50b4fb0d7590bc
haxelib git FlxPartialSound https://github.com/FunkinCrew/FlxPartialSound.git f986332ba5ab02abd386ce662578baf04904604a
haxelib git moonchart https://github.com/MaybeMaru/moonchart
haxelib git tentools https://github.com/TentaRJ/tentools.git
haxelib git systools https://github.com/haya3218/systools
haxelib run lime rebuild systools mac
echo Finished!
