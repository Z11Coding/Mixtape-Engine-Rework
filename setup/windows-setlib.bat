@echo off
color 0d
cd ..
@echo on
echo Setting dependencies...
echo This might take a few moments depending on your internet speed and if the library version isn't installed.
haxelib set lime git
haxelib set openfl git
haxelib set flixel git
haxelib set flixel-addons git
haxelib set flixel-ui 2.6.2
haxelib set tjson 1.4.0
haxelib set noisehx 0.0.1
haxelib set haxeui-core git
haxelib set haxeui-flixel git
haxelib set random 1.4.1
haxelib set flxrhythmconductor 0.2.0
haxelib set hxvlc 2.3.0 --skip-dependencies
haxelib set hxdiscord_rpc 1.3.0
haxelib set hxpy 2.0.0
haxelib set moonchart 0.5.1
haxelib set helder.set 0.3.1
haxelib set yaml 2.0.1
haxelib set haxe-concurrent 5.1.3
haxelib set actuate 1.9.0
haxelib set deflatex 1.0.0
haxelib set json2object git
haxelib set flixel-animate git
haxelib set flxsoundfilters git
haxelib set hxWebSockets git
haxelib set linc_dialogs git
haxelib set flxanimate git
haxelib set linc_luajit git
haxelib set funkin.vis git
haxelib set grig.audio git
haxelib set thx.core git
haxelib set thx.semver git
haxelib set tink_core 1.26.0
haxelib set flixel-text-input git
haxelib set hxcpp git
haxelib set tentools git
haxelib set systools git
haxelib set crypto 1.0.4
haxelib set openflCamera 1.0.7
haxelib set openflMicrophone 1.0.1
haxelib set hscript-iris 1.1.3
haxelib set hscript 2.5.0
haxelib set moonchart git
REM Add more haxelib set commands here if you add more versioned libraries above
echo All required library versions have been set.
