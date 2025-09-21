package substates;

import backend.Highscore;
import backend.Mods;
import backend.MusicBeatSubstate;
import backend.Paths;
import backend.Song;
import backend.WeekData;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.ui.FlxUIInputText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import managers.FreeplayManager;
import objects.Alphabet;
import objects.HealthIcon;
import states.CategoryState;

/**
 * A substate for selecting songs, similar to freeplay but designed for use in settings/configuration
 */
class SongSelectSubState extends MusicBeatSubstate
{
    // Callback function to call when a song is selected - passes song data object
    public var onSongSelected:(songData:Dynamic)->Void;

    // Callback function to call when cancelled
    public var onCancel:Void->Void;

    // UI elements
    private var grpSongs:FlxTypedGroup<Alphabet>;
    private var grpCategories:FlxTypedGroup<Alphabet>;
    private var iconArray:Array<HealthIcon> = [];
    private var bg:FlxSprite;
    private var titleText:FlxText;
    private var instructText:FlxText;
    private var categoryText:FlxText;
    private var searchField:FlxUIInputText;
    private var searchLabel:FlxText;

    // Search functionality
    private var searchTerm:String = "";
    private var isSearching:Bool = false;

    // Selection variables
    private var curSelected:Int = 0;
    private var curCategorySelected:Int = 0;
    private var fpManager:FreeplayManager;
    private var inCategorySelection:Bool = false;

    // Available categories (discovered dynamically like CategoryState)
    public var categories:Array<String> = [];
    private var currentCategory:String = "All";

    // Mod selection variables
    private var inModSelection:Bool = false;
    private var availableMods:Array<String> = [];
    private var curModSelected:Int = 0;
    private var selectionMode:String = "categories"; // "categories" or "mods"

    // Title for the selection (e.g. "Select Starting Song", "Select Victory Song")
    public var selectionTitle:String = "Select Song";

    public function new(?title:String = "Select Song")
    {
        super();

        selectionTitle = title;

        // Initialize categories by discovering them like CategoryState does
        discoverCategories();
    }

    function discoverCategories():Void
    {
        // Start with base categories
        categories = ["All", "Base", "Erect", "Pico"];

        // Check for secrets
        if (FlxG.save.data.gotIntoAnArgument || FlxG.save.data.gotbeatbattle || FlxG.save.data.gotbeatbattle2) {
            categories.push("Secrets");
        }

        // Check for special categories
        if (FlxG.save.data.specialbabyboy || FlxG.save.data.specialbabygirl) {
            categories.push("Special");
        }

        // Load week data to check for modded categories
        WeekData.reloadWeekFiles(false);
        var weeks:Array<WeekData> = [];
        for (i in 0...WeekData.weeksList.length) {
            weeks.push(WeekData.weeksLoaded.get(WeekData.weeksList[i]));
        }

        var mods:Bool = false;
        var existingCategories:Array<String> = [];
        for (item in categories) {
            existingCategories.push(item.toLowerCase());
        }

        // Check for mods category
        for (i in 0...weeks.length) {
            if (mods) break;

            var leWeek:WeekData = weeks[i];
            if (leWeek.category == null) {
                mods = true;
                if (!categories.contains("Mods")) {
                    categories.push("Mods");
                }
                break;
            }
        }

        // Check for custom categories from weeks
        for (week in weeks) {
            if (week.category != null) {
                if (Std.isOfType(week.category, String)) {
                    var category:String = cast week.category;
                    if (!existingCategories.contains(category.toLowerCase())) {
                        categories.push(category);
                        existingCategories.push(category.toLowerCase());
                    }
                } else if (Std.isOfType(week.category, Array)) {
                    var weekCategories:Array<String> = cast week.category;
                    for (cat in weekCategories) {
                        if (!existingCategories.contains(cat.toLowerCase())) {
                            categories.push(cat);
                            existingCategories.push(cat.toLowerCase());
                        }
                    }
                }
            }
        }

        // Check for enabled mods as categories
        try {
            var enabledMods = backend.Mods.parseList().enabled;
            for (mod in enabledMods) {
                if (!existingCategories.contains(mod.toLowerCase())) {
                    categories.push(mod);
                    existingCategories.push(mod.toLowerCase());
                }
            }
        } catch (e:Dynamic) {
            // If Mods.parseList fails, just continue without mod categories
            trace("Warning: Could not parse mod list: " + e);
        }

        // Remove duplicates and ensure "All" is first
        var filteredCategories:Array<String> = [];
        for (cat in categories) {
            if (!filteredCategories.contains(cat)) {
                filteredCategories.push(cat);
            }
        }

        // Move "All" to front if it exists
        if (filteredCategories.contains("All")) {
            filteredCategories.remove("All");
            filteredCategories.insert(0, "All");
        }

        categories = filteredCategories;

        trace("Discovered categories: " + categories);
    }

    function discoverMods():Void
    {
        // Start with "All" for mods too
        availableMods = ["All"];

        try {
            // Get enabled mods from backend.Mods
            var enabledMods = backend.Mods.parseList().enabled;
            for (mod in enabledMods) {
                if (!availableMods.contains(mod)) {
                    availableMods.push(mod);
                }
            }
        } catch (e:Dynamic) {
            // If Mods.parseList fails, just continue with empty mod list
            trace("Warning: Could not parse mod list for mod selection: " + e);
        }

        trace("Discovered mods: " + availableMods);
    }

    override function create()
    {
        super.create();

        // Set default category if CategoryState.loadWeekForce is null
        if (CategoryState.loadWeekForce == null) {
            CategoryState.loadWeekForce = "all";
            currentCategory = "All";
        } else {
            // Find matching category from loadWeekForce
            var lowerForce = CategoryState.loadWeekForce.toLowerCase();
            currentCategory = "All"; // Default
            for (cat in categories) {
                if (cat.toLowerCase() == lowerForce) {
                    currentCategory = cat;
                    break;
                }
            }
            // If no match found and we have categories, use the first one
            if (currentCategory == "All" && !categories.contains("All") && categories.length > 0) {
                currentCategory = categories[0];
                CategoryState.loadWeekForce = currentCategory.toLowerCase();
            }
        }

        // Initialize FreeplayManager
        fpManager = FreeplayManager.loadFPManager(true);

        // Create background
        bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0x88000000);
        add(bg);

        // Create title text
        titleText = new FlxText(0, 30, FlxG.width, selectionTitle);
        titleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 2;
        add(titleText);

        // Create category text
        categoryText = new FlxText(0, 80, FlxG.width, "Category: " + currentCategory + " (TAB to change)");
        categoryText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.YELLOW, CENTER, OUTLINE, FlxColor.BLACK);
        categoryText.borderSize = 1;
        add(categoryText);

        // Create search label
        searchLabel = new FlxText(50, 120, 100, "Search:");
        searchLabel.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.CYAN, LEFT, OUTLINE, FlxColor.BLACK);
        searchLabel.borderSize = 1;
        add(searchLabel);

        // Create search field
        searchField = new FlxUIInputText(150, 115, 300, "", 18);
        searchField.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT);
        searchField.backgroundColor = FlxColor.fromRGB(20, 20, 40);
        searchField.borderStyle = OUTLINE;
        searchField.borderColor = FlxColor.CYAN;
        searchField.borderSize = 2;
        searchField.callback = onSearchTextChange;
        add(searchField);

        // Create instruction text
        instructText = new FlxText(0, FlxG.height - 100, FlxG.width,
            "ENTER - Select | ESC - Cancel | UP/DOWN - Navigate | TAB - Category | F - Search | SHIFT+TAB - Mods");
        instructText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        instructText.borderSize = 1;
        add(instructText);

        // Create category group
        grpCategories = new FlxTypedGroup<Alphabet>();
        add(grpCategories);

        // Create song group
        grpSongs = new FlxTypedGroup<Alphabet>();
        add(grpSongs);

        // Load categories
        loadCategoryList();

        // Load songs
        loadSongList();

        // Set initial selection
        changeSelection(0);
    }

    function loadCategoryList()
    {
        // Clear existing items
        grpCategories.clear();

        // Ensure we have at least "All" category
        if (categories.length == 0) {
            categories = ["All"];
        }

        // Add categories
        for (i in 0...categories.length)
        {
            var categoryText:Alphabet = new Alphabet(90, 150, categories[i], true);
            categoryText.isMenuItem = true;
            categoryText.targetY = i;
            categoryText.alpha = categories[i] == currentCategory ? 1.0 : 0.6;
            grpCategories.add(categoryText);
        }

        // Set current category selection
        curCategorySelected = categories.indexOf(currentCategory);
        if (curCategorySelected == -1) {
            curCategorySelected = 0;
            if (categories.length > 0) {
                currentCategory = categories[0];
            }
        }

        // Initially hide categories
        grpCategories.visible = false;
    }

    function loadModList()
    {
        // Clear existing items
        grpCategories.clear();

        // Ensure we have at least "All" mod
        if (availableMods.length == 0) {
            availableMods = ["All"];
        }

        // Add mods to categories group (reusing the UI)
        for (i in 0...availableMods.length)
        {
            var modText:Alphabet = new Alphabet(90, 150, availableMods[i], true);
            modText.isMenuItem = true;
            modText.targetY = i;
            modText.alpha = i == curModSelected ? 1.0 : 0.6;
            grpCategories.add(modText);
        }

        // Show categories (which now contains mods)
        grpCategories.visible = true;
        grpSongs.visible = false;

        // Hide song icons
        for (icon in iconArray) {
            if (icon != null) icon.visible = false;
        }
    }

    function loadSongList()
    {
        // Clear existing items and clean up old icons
        grpSongs.clear();

        // Properly dispose of old icons
        for (icon in iconArray) {
            if (icon != null) {
                remove(icon);
                icon.destroy();
            }
        }
        iconArray = [];

        // Set the category before loading songs
        CategoryState.loadWeekForce = currentCategory.toLowerCase();

        // Recreate FreeplayManager with the new category and search term
        fpManager = new FreeplayManager(true);
        // Use refresh=false when we have a search term, true when no search
        fpManager.reloadFreeplay(searchTerm == "" || searchTerm == null, searchTerm);

        // Add songs from FreeplayManager
        if (fpManager != null && fpManager.songList != null)
        {
            for (i in 0...fpManager.songList.length)
            {
                var songData = fpManager.songList[i];
                if (songData == null) continue;

                // Create song text
                var songText:Alphabet = new Alphabet(90, 320, songData.songName, true);
                songText.isMenuItem = true;
                songText.targetY = i;
                grpSongs.add(songText);

                // Create icon
                var icon:HealthIcon = new HealthIcon(songData.songCharacter);
                icon.sprTracker = songText;
                iconArray.push(icon);
                add(icon);
            }
        }

        // Handle case where no songs are available
        if (grpSongs.length == 0)
        {
            var noSongsText:Alphabet = new Alphabet(90, 320, searchTerm != "" ? "No Songs Found" : "No Songs Available", true);
            noSongsText.isMenuItem = true;
            noSongsText.targetY = 0;
            grpSongs.add(noSongsText);
        }

        // Ensure songs and icons are visible and categories are hidden (unless in specific modes)
        if (!inCategorySelection && !inModSelection) {
            grpSongs.visible = true;
            grpCategories.visible = false;
            for (icon in iconArray) {
                if (icon != null) icon.visible = true;
            }
        }
    }

    function onSearchTextChange(text:String, action:String)
    {
        searchTerm = text;
        loadSongList();
        changeSelection(0); // Reset selection to first item
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        // Handle TAB key to toggle category selection mode
        if (FlxG.keys.justPressed.TAB)
        {
            if (FlxG.keys.pressed.SHIFT)
            {
                // SHIFT+TAB for mod selection mode (future feature)
                toggleModSelectionMode();
            }
            else
            {
                toggleCategoryMode();
            }
        }

        // Handle F key to focus search field
        if (FlxG.keys.justPressed.F)
        {
            toggleSearch();
        }

        // Handle input based on current mode
        if (isSearching)
        {
            // Search mode - let FlxUIInputText handle typing
            if (controls.BACK || FlxG.keys.justPressed.ESCAPE)
            {
                toggleSearch();
            }
            return; // Don't process other controls while searching
        }
        else if (inModSelection)
        {
            // Mod selection mode
            if (controls.UI_UP_P)
                changeModSelection(-1);
            if (controls.UI_DOWN_P)
                changeModSelection(1);
            if (controls.UI_LEFT_P)
                changeModSelection(-1);
            if (controls.UI_RIGHT_P)
                changeModSelection(1);

            if (controls.ACCEPT)
            {
                selectCurrentMod();
            }
        }
        else if (inCategorySelection)
        {
            // Category selection mode
            if (controls.UI_LEFT_P)
                changeCategorySelection(-1);
            if (controls.UI_RIGHT_P)
                changeCategorySelection(1);
            if (controls.UI_UP_P)
                changeCategorySelection(-1);
            if (controls.UI_DOWN_P)
                changeCategorySelection(1);

            if (controls.ACCEPT)
            {
                selectCurrentCategory();
            }
        }
        else
        {
            // Song selection mode
            if (controls.UI_UP_P)
                changeSelection(-1);
            if (controls.UI_DOWN_P)
                changeSelection(1);

            if (controls.ACCEPT)
            {
                selectCurrentSong();
            }
        }

        // Common controls
        if (controls.BACK)
        {
            if (isSearching)
            {
                toggleSearch();
            }
            else if (inModSelection)
            {
                toggleModSelectionMode(); // Exit mod selection mode
            }
            else if (inCategorySelection)
            {
                toggleCategoryMode(); // Exit category mode
            }
            else
            {
                cancel(); // Cancel the substate
            }
        }

        // Update lerp for smooth selection movement
        var lerpVal:Float = Math.exp(-elapsed * 9.6);

        // Update songs
        for (i in 0...grpSongs.members.length)
        {
            var item = grpSongs.members[i];
            if (item != null)
            {
                var scaledY = FlxMath.remapToRange(item.targetY, 0, 1, 0, 1.3);
                item.y = FlxMath.lerp(item.y, (scaledY * 120) + (FlxG.height * 0.48), lerpVal);
                item.x = FlxMath.lerp(item.x, (item.targetY * 20) + 90, lerpVal);
            }
        }

        // Update categories
        for (i in 0...grpCategories.members.length)
        {
            var item = grpCategories.members[i];
            if (item != null)
            {
                var scaledY = FlxMath.remapToRange(item.targetY, 0, 1, 0, 1.3);
                item.y = FlxMath.lerp(item.y, (scaledY * 60) + 180, lerpVal);
                item.x = FlxMath.lerp(item.x, (item.targetY * 10) + 90, lerpVal);
            }
        }
    }

    function toggleCategoryMode():Void
    {
        inCategorySelection = !inCategorySelection;

        if (inCategorySelection)
        {
            // Entering category selection mode
            inModSelection = false; // Ensure we're not in mod selection

            // Show categories, hide songs and icons
            grpCategories.visible = true;
            grpSongs.visible = false;
            for (icon in iconArray) {
                if (icon != null) icon.visible = false;
            }

            categoryText.text = "Selecting Category: " + categories[curCategorySelected] + " (ENTER to confirm)";
            instructText.text = "ENTER - Select Category | ESC - Back to Songs | LEFT/RIGHT - Navigate";
        }
        else
        {
            // Exiting category selection mode
            // Show songs and icons, hide categories
            grpCategories.visible = false;
            grpSongs.visible = true;
            for (icon in iconArray) {
                if (icon != null) icon.visible = true;
            }

            categoryText.text = "Category: " + currentCategory + " (TAB to change)";
            updateInstructionText();
        }

        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
    }

    function toggleSearch():Void
    {
        isSearching = !isSearching;

        if (isSearching)
        {
            // Entering search mode
            inCategorySelection = false;
            inModSelection = false;

            // Focus search field
            searchField.hasFocus = true;
            searchField.borderColor = FlxColor.YELLOW;
            searchLabel.color = FlxColor.YELLOW;
            instructText.text = "Type to search | ESC - Exit Search";
        }
        else
        {
            // Exiting search mode
            // Unfocus search field
            searchField.hasFocus = false;
            searchField.borderColor = FlxColor.CYAN;
            searchLabel.color = FlxColor.CYAN;

            // Clear search term and reload all songs
            searchTerm = "";
            searchField.text = "";
            loadSongList();
            changeSelection(0); // Reset selection

            updateInstructionText();
        }

        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
    }

    function toggleModSelectionMode():Void
    {
        if (selectionMode == "categories") {
            // Switch to mod selection mode
            selectionMode = "mods";
            inModSelection = true;
            inCategorySelection = false;

            // Discover available mods
            discoverMods();
            loadModList();

            // Update UI text
            categoryText.text = "Selecting Mod: " + availableMods[curModSelected] + " (ENTER to confirm)";
            instructText.text = "ENTER - Select Mod | SHIFT+TAB - Back to Categories | UP/DOWN - Navigate";
        } else {
            // Switch back to category selection mode
            selectionMode = "categories";
            inModSelection = false;
            inCategorySelection = false;

            // Reload the category list and songs
            loadCategoryList();
            loadSongList();

            // Ensure proper visibility states
            grpCategories.visible = false;
            grpSongs.visible = true;

            // Show song icons
            for (icon in iconArray) {
                if (icon != null) icon.visible = true;
            }

            // Update UI text
            categoryText.text = "Category: " + currentCategory + " (TAB to change)";
            updateInstructionText();
        }

        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
    }

    function changeCategorySelection(change:Int = 0):Void
    {
        if (!inCategorySelection) return;

        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

        curCategorySelected += change;

        if (curCategorySelected < 0)
            curCategorySelected = categories.length - 1;
        if (curCategorySelected >= categories.length)
            curCategorySelected = 0;

        var bullShit:Int = 0;
        for (item in grpCategories.members)
        {
            item.targetY = bullShit - curCategorySelected;
            bullShit++;

            item.alpha = 0.6;
            if (item.targetY == 0)
                item.alpha = 1;
        }

        categoryText.text = "Selecting Category: " + categories[curCategorySelected] + " (ENTER to confirm)";
    }

    function selectCurrentCategory():Void
    {
        if (!inCategorySelection || curCategorySelected < 0 || curCategorySelected >= categories.length)
            return;

        currentCategory = categories[curCategorySelected];
        CategoryState.loadWeekForce = currentCategory.toLowerCase();

        FlxG.sound.play(Paths.sound('confirmMenu'));

        // Reload songs with new category
        loadSongList();

        // Reset song selection
        curSelected = 0;
        changeSelection(0);

        // Exit category mode
        inCategorySelection = false;
        inModSelection = false; // Ensure clean state

        // Ensure proper visibility
        grpCategories.visible = false;
        grpSongs.visible = true;
        for (icon in iconArray) {
            if (icon != null) icon.visible = true;
        }

        // Update UI text
        categoryText.text = "Category: " + currentCategory + " (TAB to change)";
        updateInstructionText();
    }

    function changeModSelection(change:Int = 0):Void
    {
        if (!inModSelection) return;

        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

        curModSelected += change;

        if (curModSelected < 0)
            curModSelected = availableMods.length - 1;
        if (curModSelected >= availableMods.length)
            curModSelected = 0;

        var bullShit:Int = 0;
        for (item in grpCategories.members)
        {
            item.targetY = bullShit - curModSelected;
            bullShit++;

            item.alpha = 0.6;
            if (item.targetY == 0)
                item.alpha = 1;
        }

        categoryText.text = "Selecting Mod: " + availableMods[curModSelected] + " (ENTER to confirm)";
    }

    function selectCurrentMod():Void
    {
        if (!inModSelection || curModSelected < 0 || curModSelected >= availableMods.length)
            return;

        var selectedMod = availableMods[curModSelected];

        // Set the category to the selected mod (or "Mods" if "All" is selected)
        if (selectedMod == "All") {
            currentCategory = "Mods";
            CategoryState.loadWeekForce = "mods";
        } else {
            currentCategory = selectedMod;
            CategoryState.loadWeekForce = selectedMod.toLowerCase();
        }

        FlxG.sound.play(Paths.sound('confirmMenu'));

        // Exit mod selection mode and return to regular song selection
        selectionMode = "categories";
        inModSelection = false;
        inCategorySelection = false;

        // Reload songs with new mod/category
        loadSongList();

        // Reset song selection
        curSelected = 0;
        changeSelection(0);

        // Ensure proper visibility states
        grpCategories.visible = false;
        grpSongs.visible = true;

        // Show song icons
        for (icon in iconArray) {
            if (icon != null) icon.visible = true;
        }

        // Update UI text
        categoryText.text = "Category: " + currentCategory + " (TAB to change)";
        updateInstructionText();
    }

    function changeSelection(change:Int = 0):Void
    {
        if (inCategorySelection) return;

        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

        curSelected += change;

        if (curSelected < 0)
            curSelected = grpSongs.length - 1;
        if (curSelected >= grpSongs.length)
            curSelected = 0;

        var bullShit:Int = 0;
        for (item in grpSongs.members)
        {
            item.targetY = bullShit - curSelected;
            bullShit++;

            item.alpha = 0.6;
            if (item.targetY == 0)
                item.alpha = 1;
        }

        // Update icons
        for (i in 0...iconArray.length)
        {
            if (iconArray[i] != null)
            {
                iconArray[i].alpha = 0.6;
                if (i == curSelected)
                    iconArray[i].alpha = 1;
            }
        }
    }

    function selectCurrentSong():Void
    {
        if (fpManager == null || fpManager.songList == null ||
            curSelected < 0 || curSelected >= fpManager.songList.length)
        {
            // No valid selection
            FlxG.sound.play(Paths.sound('cancelMenu'));
            return;
        }

        var selectedSong = fpManager.songList[curSelected];
        if (selectedSong == null)
        {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            return;
        }

        FlxG.sound.play(Paths.sound('confirmMenu'));

        // Create comprehensive song data object to pass back
        var songData = {
            songName: selectedSong.songName,
            folder: selectedSong.folder,
            week: selectedSong.week,
            songCharacter: selectedSong.songCharacter,
            index: curSelected
        };

        // Call the callback with the song data object
        if (onSongSelected != null)
        {
            onSongSelected(songData);
        }

        // Close the substate
        close();
    }

    function cancel():Void
    {
        FlxG.sound.play(Paths.sound('cancelMenu'));

        // Call the cancel callback if provided
        if (onCancel != null)
        {
            onCancel();
        }

        // Close the substate
        close();
    }

    function updateInstructionText():Void
    {
        instructText.text = "ENTER - Select | ESC - Cancel | UP/DOWN - Navigate | TAB - Category | F - Search | SHIFT+TAB - Mods";
    }
}
