function onCreate()
  makeLuaSprite("solid", nil, -5000, -3000)
  makeGraphic('solid', 10000, 10000, "FFFFFF")
  setScrollFactor("solid", 0.0, 0.0)
  addLuaSprite("solid")

  makeLuaSprite("bg", "bg", -1853, -815)
  setScrollFactor("bg", 0.75, 0.75)
  addLuaSprite("bg")

  makeLuaSprite("fucker", "floor", 790, 625)
  setScrollFactor("fucker", 0.85, 0.85)
  addLuaSprite("fucker")
  setProperty("fucker.alpha", 0)

  makeLuaSprite("backTables", "back-tables", -1857, 267)
  setScrollFactor("backTables", 0.93, 0.93)
  addLuaSprite("backTables")

  makeLuaSprite("backTablesCutscene", "cutscene/counter-stretch", -1858, 377)
  setGraphicSize("backTablesCutscene", 400, 1)
  setScrollFactor("backTablesCutscene", 0.93, 0.93)
  addLuaSprite("backTablesCutscene")

  makeLuaSprite("burgerCutscene", "cutscene/burger-cutscene", -97, 237)
  setScrollFactor("burgerCutscene", 0.93, 0.93)
  addLuaSprite("burgerCutscene")

  makeLuaSprite("backStools", "back-stools", -1357, 426)
  setScrollFactor("backStools", 0.94, 0.94)
  addLuaSprite("backStools")

  makeLuaSprite("backLightColor", "lights/back-light-color", -1241, -949)
  setScrollFactor("backLightColor", 0.93, 0.93)
  addLuaSprite("backLightColor")
  setProperty("backLightColor.alpha", 0)

  makeLuaSprite("backLightWhite", "lights/back-light-white", -771, -599)
  setScrollFactor("backLightWhite", 0.93, 0.93)
  addLuaSprite("backLightWhite")
  setProperty("backLightWhite.alpha", 0)

  makeLuaSprite("truck", "truck-stuff", -983, -707)
  setScrollFactor("truck", 0.95, 0.95)
  addLuaSprite("truck")

  makeLuaSprite("truckDoor", "truck-door", -980, -173)
  setScrollFactor("truckDoor", 0.95, 0.95)
  addLuaSprite("truckDoor")

  makeLuaSprite("truckLight1", "lights/truck-light1", -962, -607)
  setScrollFactor("truckLight1", 0.95, 0.95)
  addLuaSprite("truckLight1")
  setProperty("truckLight1.alpha", 0)

  makeLuaSprite("truckLight2", "lights/truck-light2", -781, -464)
  setScrollFactor("truckLight2", 0.95, 0.95)
  addLuaSprite("truckLight2")
  setProperty("truckLight2.alpha", 0)

  makeLuaSprite("frontStool", "front-stool", -280, 818)
  setScrollFactor("frontStool", 1.0, 1.0)
  addLuaSprite("frontStool", true)

  makeLuaSprite("solidCover", nil, -5000, -3000)
  makeGraphic('solidCover', 10000, 10000, "000000")
  setScrollFactor("solidCover", 0.0, 0.0)
  addLuaSprite("solidCover", true)
  setProperty("solidCover.alpha", 0)
end
