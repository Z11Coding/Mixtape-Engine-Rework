import psychlua.LuaUtils;

var lightsStop:Bool = false; // state of the traffic lights
var lastChange:Int = 0;
var changeInterval:Int = 8; // make sure it doesnt change until AT LEAST this many beats

var carWaiting:Bool = false; // if the car is waiting at the lights and is ready to go on green
var carInterruptable:Bool = true; // if the car can be reset
var car2Interruptable:Bool = true;

//stage parts
var sky:FlxSprite;
var buildings:FlxSprite;
var wall:FlxSprite;
var spotlight:FlxSprite;
var stairs:FlxSprite;
var tint:FlxSprite;

var phillyCars:FlxSprite;
var phillyCars2:FlxSprite;
var phillyTraffic:FlxSprite;

function onCreate()
{
    sky = new FlxSprite(0, 0).loadGraphic(Paths.image("stages/fanta/sky"));
    sky.screenCenter();
    addBehindGF(sky);

    buildings = new FlxSprite(400, -200).loadGraphic(Paths.image("stages/fanta/back_building"));
    addBehindGF(buildings);

    phillyCars = new FlxSprite(-300, 200);
    phillyCars.frames = Paths.getSparrowAtlas('stages/fanta/phillyCars');
    phillyCars.animation.addByPrefix('car1','car1',24, false);
    phillyCars.animation.addByPrefix('car2','car2',24, false);
    phillyCars.animation.addByPrefix('car3','car3',24, false);
    phillyCars.animation.addByPrefix('car4','car4',24, false);

    phillyCars2 = new FlxSprite(-300, 200);
    phillyCars2.frames = Paths.getSparrowAtlas('stages/fanta/phillyCars');
    phillyCars2.animation.addByPrefix('car1','car1',24, false);
    phillyCars2.animation.addByPrefix('car2','car2',24, false);
    phillyCars2.animation.addByPrefix('car3','car3',24, false);
    phillyCars2.animation.addByPrefix('car4','car4',24, false);
    addBehindGF(phillyCars2);
    addBehindGF(phillyCars); //Layering fix

    phillyTraffic = new FlxSprite(1200, 200);
    phillyTraffic.frames = Paths.getSparrowAtlas('stages/fanta/phillyTraffic');
    phillyTraffic.animation.addByPrefix('togreen','redtogreen',24, false);
    phillyTraffic.animation.addByPrefix('tored',  'greentored',24, false);
    //addBehindGF(phillyTraffic); JD doesn't think it fits. He's right, but i still think one would have been cool.

    wall = new FlxSprite(0, 0).loadGraphic(Paths.image("stages/fanta/main_floor"));
    wall.screenCenter();
    addBehindGF(wall);

    spotlight = new FlxSprite(0, 0).loadGraphic(Paths.image("stages/fanta/spotlight_ADD"));
    spotlight.screenCenter();
    spotlight.blend = LuaUtils.blendModeFromString('add');
    add(spotlight);

    stairs = new FlxSprite(1200, -600).loadGraphic(Paths.image("stages/fanta/front_stairs"));
    add(stairs);

    tint = new FlxSprite(0, 0).loadGraphic(Paths.image("stages/fanta/purple_tint_OVERLAY"));
    tint.screenCenter();
    tint.blend = LuaUtils.blendModeFromString('overlay');
    tint.alpha = 0.2;
    add(tint);

    resetCar(true, true);

    if (game.songName == "Funky Fanta")
        game.startCallback = doIntro;
}

function doIntro() {
    game.startVideo('fanta_cutscene_wip_lol', false);
}

/*
  * Changes the current state of the traffic lights.
  * Updates the next change accordingly and will force cars to move when ready
*/
function changeLights(beat:Int)
{
    lastChange = beat;
    lightsStop = !lightsStop;

    if(lightsStop){
        phillyTraffic.animation.play('tored');
        changeInterval = 20;
    } else {
        phillyTraffic.animation.play('togreen');
        changeInterval = 30;

        if(carWaiting == true) finishCarLights(phillyCars);
    }
}

/*
  * Resets every value of a car and hides it from view.
*/
function resetCar(left:Bool, right:Bool){
    if(left){
        carWaiting = false;
        carInterruptable = true;
        var cars = phillyCars;
        if (cars != null) {
            FlxTween.cancelTweensOf(cars);
            cars.x = 400;
            cars.y = 300;
            cars.angle = 0;
        }
    }

    if(right){
        car2Interruptable = true;
        var cars2 = phillyCars2;
        if (cars2 != null) {
            FlxTween.cancelTweensOf(cars2);
            phillyCars2.x = 400;
            phillyCars2.y = 400;
            phillyCars2.angle = 0;
        }
    }
}

function onSongStart() resetCar(true, true);

function onBeatHit()
{
    // Try driving a car when its possible
    if (FlxG.random.bool(10) && curBeat != (lastChange + changeInterval) && carInterruptable == true)
    {
        if(lightsStop == false){
            //driveCar(phillyCars);
        }else{
            driveCarLights(phillyCars);
        }
    }

    // try driving one on the right too. in this case theres no red light logic, it just can only spawn on green lights
    if(FlxG.random.bool(10) && curBeat != (lastChange + changeInterval) && car2Interruptable == true && lightsStop == false) driveCarBack(phillyCars2);

    // After the interval has been hit, change the light state.
    if (curBeat == (lastChange + changeInterval)) changeLights(curBeat);
}

function onCountdownStarted() {
    resetCar(true, true);
}

function onDestroy() {
    super.onDestroy();

    var cars = phillyCars;
    if (cars != null) FlxTween.cancelTweensOf(cars);
    var cars2 = phillyCars2;
    if (cars2 != null) FlxTween.cancelTweensOf(cars2);
}

/*
  * Drive the car away from the lights to the end of the road.
  * Used when the lights turn green and the car is waiting in position.
*/
function finishCarLights(sprite:FlxSprite)
{
    carWaiting = false;
    var duration:Float = FlxG.random.float(1.8, 3);
    var rotations:Array<Int> = [-5, 18];
    var offset:Array<Float> = [306.6, 168.3];
    var startdelay:Float = FlxG.random.float(0.2, 1.2);

    var path:Array<FlxPoint> = [
        FlxPoint.get(1106 - offset[0], 400),
        FlxPoint.get(1500 - offset[0], 400),
        FlxPoint.get(3000 - offset[0], 400)
    ];

    //FlxTween.angle(sprite, rotations[0], rotations[1], duration, {ease: FlxEase.sineIn, startDelay: startdelay} );
    FlxTween.quadPath(sprite, path, duration, true,
    {
        ease: FlxEase.sineIn,
        startDelay: startdelay,
        onComplete: function(_) {
            carInterruptable = true;
        }
    });
}

/*
* Drives a car towards the lights and stops.
* Used when a car tries to drive while the lights are red.
*/
function driveCarLights(sprite:FlxSprite){
    carInterruptable = false;
    FlxTween.cancelTweensOf(sprite);
    var variant:Int = FlxG.random.int(1,4);
    sprite.animation.play('car' + variant);
    var extraOffset = [0, 0];
    var duration:Float = 2;

    switch(variant){
        case 1:
            duration = FlxG.random.float(1, 1.7);
        case 2:
            extraOffset = [20, -15];
            duration = FlxG.random.float(0.9, 1.5);
        case 3:
            extraOffset = [30, 50];
            duration = FlxG.random.float(1.5, 2.5);
        case 4:
            extraOffset = [10, 60];
            duration = FlxG.random.float(1.5, 2.5);
    }
    var rotations:Array<Int> = [-7, -5];
    var offset:Array<Float> = [306.6, 168.3];
    sprite.offset.set(extraOffset[0], extraOffset[1]);

    var path:Array<FlxPoint> = [
        FlxPoint.get(0, 400),
        FlxPoint.get(200, 400),
        FlxPoint.get(800, 400)
    ];
    // debug shit!!! keeping it here just in case
    // for(point in path){
    // 	var debug:FlxSprite = new FlxSprite(point.x - 5, point.y - 5).makeGraphic(10, 10, 0xFFFF0000);
    // 	add(debug);
    // }
    //FlxTween.angle(sprite, rotations[0], rotations[1], duration, {ease: FlxEase.cubeOut} );
    FlxTween.quadPath(sprite, path, duration, true,
    {
        ease: FlxEase.cubeOut,
        onComplete: function(_) {
            carWaiting = true;
            if(lightsStop == false) finishCarLights(phillyCars);
        }
    });
}

/*
* Drives a car across the screen without stopping.
* Used when the lights are green.
*/
function driveCar(sprite:FlxSprite){
    carInterruptable = false;
    FlxTween.cancelTweensOf(sprite);
    var variant:Int = FlxG.random.int(1,4);
    sprite.animation.play('car' + variant);
    // setting an offset here because the current implementation of stage prop offsets was not working at all for me
    // if possible id love to not have to do this but im keeping this for now
    var extraOffset = [0, 0];
    var duration:Float = 2;
    // set different values of speed for the car types (and the offset)
    switch(variant){
        case 1:
            duration = FlxG.random.float(1, 1.7);
        case 2:
            extraOffset = [20, -15];
            duration = FlxG.random.float(0.6, 1.2);
        case 3:
            extraOffset = [30, 50];
            duration = FlxG.random.float(1.5, 2.5);
        case 4:
            extraOffset = [10, 60];
            duration = FlxG.random.float(1.5, 2.5);
    }
    // random arbitrary values for getting the cars in place
    // could just add them to the points but im LAZY!!!!!!
    var offset:Array<Float> = [306.6, 168.3];
    sprite.offset.set(extraOffset[0], extraOffset[1]);
    // start/end rotation
    var rotations:Array<Int> = [-8, 18];
    // the path to move the car on
    var path:Array<FlxPoint> = [
            FlxPoint.get(0 - offset[0], 400),
            FlxPoint.get(1000 - offset[0], 400),
            FlxPoint.get(3000 - offset[0], 400)
    ];

    //FlxTween.angle(sprite, rotations[0], rotations[1], duration, null );
    FlxTween.quadPath(sprite, path, duration, true,
    {
        ease: null,
            onComplete: function(_) {
            carInterruptable = true;
        }
    });
}

function driveCarBack(sprite:FlxSprite){
    car2Interruptable = false;
    FlxTween.cancelTweensOf(sprite);
    var variant:Int = FlxG.random.int(1,4);
    sprite.animation.play('car' + variant);
    // setting an offset here because the current implementation of stage prop offsets was not working at all for me
    // if possible id love to not have to do this but im keeping this for now
    var extraOffset = [0, 0];
    var duration:Float = 2;
    // set different values of speed for the car types (and the offset)
    switch(variant){
        case 1:
            duration = FlxG.random.float(1, 1.7);
        case 2:
            extraOffset = [20, -15];
            duration = FlxG.random.float(0.6, 1.2);
        case 3:
            extraOffset = [30, 50];
            duration = FlxG.random.float(1.5, 2.5);
        case 4:
            extraOffset = [10, 60];
            duration = FlxG.random.float(1.5, 2.5);
    }
    // random arbitrary values for getting the cars in place
    // could just add them to the points but im LAZY!!!!!!
    var offset:Array<Float> = [306.6, 168.3];
    sprite.offset.set(extraOffset[0], extraOffset[1]);
    // start/end rotation
    var rotations:Array<Int> = [18, -8];
    // the path to move the car on
    var path:Array<FlxPoint> = [
        FlxPoint.get(0, 300),
        FlxPoint.get(1000, 300),
        FlxPoint.get(2000, 300)
    ];

    //FlxTween.angle(sprite, rotations[0], rotations[1], duration, null );
    FlxTween.quadPath(sprite, path, duration, true,
    {
        ease: null,
        onComplete: function(_) {
            car2Interruptable = true;
        }
    });
}

/*
* Resets the values tied to the lights that need to be accounted for on a restart.
*/
function resetStageValues(){
    lastChange = 0;
    changeInterval = 8;
    var traffic = phillyTraffic;
    if (traffic != null) {
        traffic.animation.play('togreen');
    }
    lightsStop = false;
}
