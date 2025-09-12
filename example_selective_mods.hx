/**
 * Example of how to use selective GitHub mods folder functionality
 */

class ExampleSelectiveMods
{
    public static function setup()
    {
        // Add a GitHub repository that contains multiple mods
        GitHubAPI.addGitHubModsFolder("MyModsPack", "user/my-mods-repository", "main", "", 1);

        // This will discover all mods in the repository
        GitHubAPI.discoverModsInFolder("MyModsPack");

        // Now you can selectively enable/disable individual mods within this folder

        // Enable specific mods
        GitHubAPI.setGitHubFolderModEnabled("MyModsPack", "coolMod1", true);
        GitHubAPI.setGitHubFolderModEnabled("MyModsPack", "awesomeMod2", true);

        // Disable specific mods
        GitHubAPI.setGitHubFolderModEnabled("MyModsPack", "buggyMod3", false);
        GitHubAPI.setGitHubFolderModEnabled("MyModsPack", "testMod4", false);

        // Check if a specific mod is enabled
        if (GitHubAPI.isGitHubFolderModEnabled("MyModsPack", "coolMod1")) {
            trace("coolMod1 is enabled!");
        }

        // Get list of all enabled mods from GitHub folders
        var enabledMods = GitHubAPI.getEnabledGitHubFolderMods();
        trace("Enabled GitHub folder mods: " + enabledMods.join(", "));

        // Get detailed list of mods in a specific folder
        var folderModList = GitHubAPI.getGitHubFolderModList("MyModsPack");
        for (modInfo in folderModList) {
            trace('${modInfo.modName}: ${modInfo.enabled ? "Enabled" : "Disabled"}');
        }

        // The mod loading system will now only load files from enabled mods
        // When GitHubAPI.getAllGitHubModNames() is called, it will only return:
        // - Individual GitHub mods that are enabled
        // - Mods from GitHub folders that are both: folder enabled AND mod enabled
    }
}
