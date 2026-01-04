@echo off
color 0a
cd ..
@echo on
echo Setting dependencies...
echo This might take a few moments depending on your internet speed and if the library version isn't installed.
haxelib set lime 8.2.2
haxelib set openfl 9.4.1
haxelib set flixel 5.6.2
haxelib set flixel-addons 3.3.2
haxelib set flixel-tools 1.5.1
haxelib set hscript-iris 1.1.3
haxelib set tjson 1.4.0
haxelib set hxdiscord_rpc 1.2.4
haxelib set hxvlc 2.0.1 --skip-dependencies
haxelib set helder.set 0.3.1
haxelib set yaml 2.0.1
haxelib set haxe-concurrent 5.1.3
haxelib set actuate 1.9.0
haxelib set flixel-ui 2.6.1
haxelib set hscript 2.5.0
haxelib set noisehx 0.0.1
haxelib set haxeui-core 1.7.0
haxelib set haxeui-flixel 1.7.0
haxelib set deflatex 1.0.0
haxelib set crypto 1.0.4
haxelib set openflCamera 1.0.7
haxelib set openflMicrophone 1.0.1
haxelib set hxpy 2.0.0
haxelib set flxsoundfilters git
haxelib set hxWebSockets git
haxelib set linc_dialogs git
haxelib set flxanimate git
haxelib set linc_luajit git
haxelib set funkin.vis git
haxelib set grig.audio git
haxelib set flixel-text-input git
haxelib set FlxPartialSound git
haxelib set moonchart git
haxelib set tentools git
haxelib set systools git
REM Add more haxelib set commands here if you add more versioned libraries above
echo All required library versions have been set.
