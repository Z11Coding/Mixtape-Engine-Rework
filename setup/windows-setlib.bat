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
