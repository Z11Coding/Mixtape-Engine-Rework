package managers;

import backend.RConductor;
/**
 * THE MOTHER OF ALL MANAGERS
 * This bad boy handles every manager so you dont have to!
 * Since every manager is designed to essentally persist forever, all we need now is a place to store em.
 * And this is the place.
 */

class MegaManager {
  public static var conductor:RConductor;
  public static var charaManager:CharacterManager;
  public static var comboManger:ComboManager;
  public static var notePoolManager:NotePoolManager;
  public static var playfield:PlayfieldManager;
  public static var scriptManager:ScriptManager;

  /**
   Freeplay gets 3 specific ones for both scripting and AP sake
   * Omega (Both AP and Normal Freeplay Manager)
   * AP (APFreeplay)
   * Reg (Freeplay)
  */
  public static var omegaFreeplay:FreeplayManager;
  public static var apFreeplay:APFreeplayManager;
  public static var regFreeplay:FreeplayManager;

  public function new() {
    // First, the managers themselves
    new RConductor();
    new CharacterManager();
    new ComboManager();
    new PlayfieldManager();
    new ScriptManager();

    // Then, set the instance to use
    conductor = RConductor.instance;
    charaManager = CharacterManager.instance;
    comboManger = ComboManager.instance;
    omegaFreeplay = FreeplayManager.loadFPManager(true);
    apFreeplay = new APFreeplayManager(true);
    regFreeplay = new FreeplayManager(true);
    notePoolManager = NotePoolManager.getInstance();
    playfield = PlayfieldManager.instance;
    scriptManager = ScriptManager.instance;

  }
}
