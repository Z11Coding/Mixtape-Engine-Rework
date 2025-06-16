package states.editors;

import substates.StickerSubState;
import states.editors.MasterEditorMenu;

class StickerTest extends MusicBeatState {
    private var stickerSet:String;
    private var stickerPack:String;
    private var stickerSubState:StickerSubState;
	var stickerSetInput:PsychUIInputText;
	var stickerPackInput:PsychUIInputText;

	public function new(?stickers:StickerSubState = null,set:String = "stickers-set-1",pack:String = "all"){
        stickerPack = pack;
        stickerSet = set;
        if (stickers != null)
        {
            stickerSubState = stickers;
        }
        super();
    }

    override function create() {
        FlxG.sound.music.pause();
        FlxG.mouse.visible = true;
        Paths.clearUnusedMemory();
        if (stickerSubState != null)
        {
            Paths.clearStoredWithoutStickers();
            openSubState(stickerSubState);
            stickerSubState.degenStickers();
        }
		else Paths.clearStoredMemory();
        

        var BG = new FlxSprite(0,0,Paths.image(ClientPrefs.getBGImage()));
        BG.setGraphicSize(FlxG.width,FlxG.height);
        BG.updateHitbox();
        add(BG);
        addEditorBox();
        super.create();
        MusicManager.playEditorMusic(ClientPrefs.data.editorMusVol);
    }

    var UI_box:PsychUIBox;
	function addEditorBox() {
		UI_box = new PsychUIBox(FlxG.width, FlxG.height, 250, 200, ['Sticker']);
		UI_box.x -= UI_box.width;
		UI_box.y -= UI_box.height;
		UI_box.scrollFactor.set();
		add(UI_box);

        stickerSetInput = new PsychUIInputText(20,50,100,stickerSet);
        stickerPackInput = new PsychUIInputText(20,100,100,stickerPack);
		
		UI_box.selectedName = 'Sticker';
        var tab = UI_box.getTab('Sticker').menu;
		add(UI_box);

        tab.add(new FlxText(stickerSetInput.x, stickerSetInput.y - 15, 100, 'Sticker set:'));
		tab.add(stickerSetInput);

        tab.add(new FlxText(stickerPackInput.x, stickerPackInput.y - 15, 100, 'Sticker pack:'));
		tab.add(stickerPackInput);


		var loadWeekButton:PsychUIButton = new PsychUIButton(20, 150, "Play", function() {
            StickerSubState.STICKER_PACK = stickerPackInput.text;
            StickerSubState.STICKER_SET = stickerSetInput.text;
            openSubState(new StickerSubState(null,s -> new StickerTest(s,stickerSetInput.text,stickerPackInput.text)));
        });
		tab.add(loadWeekButton);
	}

    override function update(elapsed:Float) {
        super.update(elapsed);
        if(PsychUIInputText.focusOn == null)
            {
                ClientPrefs.toggleVolumeKeys(true);
                var b_tapped = false;
                
                #if TOUCH_CONTROLS_ALLOWED
                b_tapped = touchPad.buttonB.justPressed;
                #end

                if(controls.BACK || b_tapped){
                    
                    MusicManager.playMenuMusic(1);
                    FlxG.mouse.visible = false;
                    MusicBeatState.startTransition(new MasterEditorMenu());
                }
            }
            else ClientPrefs.toggleVolumeKeys(false);
    }
}