package funkin.ui.options;

import funkin.save.Save;
import funkin.ui.transition.Transition;

class SaveDataMenu extends Page<OptionsState.OptionsMenuPageName>
{
  var items:TextMenuList;

  public function new()
  {
    super();

    add(items = new TextMenuList());

    createItem("CLEAR SAVE DATA", openSaveDataPrompt);

    createItem("EXIT", exit);
  }

  function createItem(name:String, callback:Void->Void, fireInstantly = false)
  {
    var item = items.createItem(0, 100 + items.length * 100, name, BOLD, callback);
    item.fireInstantly = fireInstantly;
    item.screenCenter(X);
    return item;
  }

  override function update(elapsed:Float)
  {
    enabled = (prompt == null);
    super.update(elapsed);
  }

  override function set_enabled(value:Bool)
  {
    items.enabled = value;
    return super.set_enabled(value);
  }

  var prompt:Prompt;

  function openConfirmPrompt(text:String,
    yesText:String,
    onYes:Void->Void,
    ?groupToOpenOn:Null<flixel.group.FlxGroup>):Void
  {
    if (prompt != null) return;

    prompt = new Prompt(text, Custom(yesText, "Cancel"));
    prompt.create();
    prompt.createBgFromMargin(100, 0xFFFAFD6D);
    prompt.back.scrollFactor.set(0, 0);
    FlxG.state.add(prompt);
    // Disable page navigation while the prompt is open
    codex.currentPage.enabled = false;

    final closePrompt:() -> Void = () ->
    {
      codex.currentPage.enabled = true;
      prompt.close();
      prompt.destroy();
      prompt = null;
    };

    prompt.onYes = function()
    {
      onYes();

      closePrompt();
    };

    prompt.onNo = closePrompt;
  }

  public function openSaveDataPrompt()
  {
    openConfirmPrompt("This will delete
        \nALL your save data.
        \nAre you sure?
      ", "Delete", function()
    {
      // Clear the save data.
      Save.clearData();

      Transition.switchState(() -> new InitState(), {
        assetQuery: Transition.NO_ASSETS,
        transition: None
      });
    });
  }

  /**
   * True if this page has multiple options, excluding the exit option.
   * If false, there's no reason to ever show this page.
   */
  public function hasMultipleOptions():Bool
  {
    return items.length > 2;
  }
}
