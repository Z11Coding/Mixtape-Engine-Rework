# Archipelago Randomizer Configuration / Setup Guide

Archipelago is a Multiworld Randomizer, meaning it randomizes a bunch of games into one randomizer pool, and it challenges you to conplete all of the games.

## How to set up Archipelago with this Engine
1. Download the latest Engine Build.
2. Go to the Archipelago Option in the Main Menu.
3. Use the NEW Menu. (The old one will be removed soon.)
4. Install or Output the APWorld File associated with the Engine.
5. Once the APWorld is added where it should be, use the YAML or Settings button to access YAML Options.
6. Choose the settings for your run.
7. Export your YAML. A PlayerSettings folder will appear with your YAML
8. Do as usual. Give your YAML to a hoster, or put it in yourself, and generate a game with the APWorld installed.
9. Have fun!

### NOTICE:
Certain settings may not yet be implemented, and will be ignored by the APWorld until they are.

When updating the Engine, make sure to use the Update/Install APWorld Button to ensure that the latest APWorld is being used.

### Need help?
Join our [Test Discord Server](https://discord.gg/KJXvEVUfZX) to get assistance with issues, or to submit a bug report.

# Mixtape Engine
Mixtape is a fork of [Psych Engine](https://gamebanana.com/mods/309789) (another one, oh the horror!), with the goal of being the most compatible engine ever. Eventually, we want to be able to have *every* mod from *every* engine compatible all in one *right here*.

## Installation:

Refer to [the Build Instructions](/docs/BUILDING.md)

## Customization:

if you wish to disable things like *Lua Scripts* or *Video Cutscenes*, you can read over to `Project.xml`

inside `Project.xml`, you will find several variables to customize Psych Engine to your liking

to start you off, disabling Videos should be simple, simply Delete the line `"VIDEOS_ALLOWED"` or comment it out by wrapping the line in XML-like comments, like this `<!-- YOUR_LINE_HERE -->`

same goes for *Lua Scripts*, comment out or delete the line with `LUA_ALLOWED`, this and other customization options are all available within the `Project.xml` file

## Credits:
* Shadow Mario - Head Developer, Programmer.
* Riveren - Main Artist.

### Special Thanks
* bbpanzu - Ex-Team Member (Programmer).
* crowplexus - HScript Iris, Input System v3, and Other PRs.
* Kamizeta - Creator of Pessy, Psych Engine's mascot.
* MaxNeton - Loading Screen Easter Egg Artist/Animator.
* Keoiki - Note Splash Animations and Latin Alphabet.
* SqirraRNG - Crash Handler and Base code for Chart Editor's Waveform.
* EliteMasterEric - Runtime Shaders support and Other PRs.
* MAJigsaw77 - .MP4 Video Loader Library (hxvlc).
* Tahir Toprak Karabekiroglu - Note Splash Editor and Other PRs.
* iFlicky - Composer of Psync, Tea Time and some sound effects.
* KadeDev - Fixed some issues on Chart Editor and Other PRs.
* superpowers04 - LUA JIT Fork.
* CheemsAndFriends - Creator of FlxAnimate.
* Ezhalt - Pessy's Easter Egg Jingle.
* MaliciousBunny - Video for the Final Update.
_____________________________________

# Features

* TWO Modchart systems (courtesy of Troll Engine, an awesome engine i highly recommend at least checking out, and Funkin Modchart, a way past cool Modchart System that I recommend personally)
* Customizable Menus (As of right now, only freeplay and the chart editor is customizable, however the other menus (Main menu, Story Menu, Options, etc.) Are planned to be customizable *and* scriptable)
* Archipelago Support (legit like, half the engine i think lol, very fun game with friends and even a very chill and cool community (rare!))
* Proper backwards support of 0.7.x and 0.6.x mods (still a w.i.p but its there)
* Custom Songs built right into the engine! (Because as the slogan of my engine, I want to mix things up a bit, and its rare to see an engine have custom songs in it)
* A BUNCH of QoL things (like, a near unlistable amount)
* NEW/Reimplimented Base-Game mechanics (W.I.P, planned to reimpliment scrapped base game mechanics, as well as attempt to give other songs on as well, all of which planned to be completely usable outside of its designated stage (looking at you, phillyLights event))
* MORE ACHIEVEMENTS (Base Game + a few custom ones too cuz i gotta give the 100% people SOMETHING to do lol)
* Secrets! (Fun lil things/codes I've hidden around the engine, with more to come in the future. Not everything is how it seems...)
* Even more options! (Things like the new Base Game FPS counter, A new Custom Noteskin, and a literal whole category of stuff that wouldn't fit within discord's character limit.)
* MINIGAMES (Because why play *just* fnf, when I can play UNO too?)
* Time-Specific Events! (The engine could be absolutely bugging for some reason during April Fools, It could be snowing in the menus during Christmas, The menus could be a rainbow during Pride Month, etc.)
* Streamer Vs. Chat Support! (Planned, not fully implemented, but yeah, this is gonna be here too)
* MORE LUA/HScript callbacks! (Because we needed more thats why)
* An entirely new scripting language called YScript, which integrates Haxe, Lua, And Hscript all into one neat lil language (made by my good friend and Co-developer Yutamon, Who is making their own library within the engine called YutaUtil, thats essentially the backbone of this engine)
* New Modifiers (Random Playback Speed, Mix-Up Mode a.k.a Survival Mode, Loop Mode a.k.a Endless Mode, with more planned for the future.)
* Support for almost any mod from any engine (not just psych mods!) (W.I.P, Not yet implemented although planned to be very soon)
* Playlist Mode! (Make a playlist of all your favorite songs across your different mods into one neat list so you dont have to go scouring for them all the time!)
* Lagless Notes! (W.I.P, ***I will get this working istg***)
* 30+ minute song times without the engine dying (W.I.P, ditto from above)
* More Events! (Fake Time, Rave Mode, Chrom Beat, etc.)
* V-Slice Album and Difficulty Stars support!
* Multiple Accuracy/Ranking Systems! (V-Slice and Mixtape, as well as Accuracy Types like ITG, DJMAX, StepMania, etc.)
* Python Scripting System ( Because Lua and Hscript weren't enough for Yuta lol)
* Freeplay Categories! (Can be defined by the week file, or can be sorted by mod)
* Modified Crash Handler (The engine avoids closing when it crashes as best as possible, because its annoying to have to reopen the game everytime something breaks)
* In-Game Toggleable debug features (You can turn on/off traces, throttle them, enable/disable the Garbage Collector, etc)
* BPM Tweens (Yes, you read that right)
* Cause of Death (Shows how you died, when you die. Also has modded support)
