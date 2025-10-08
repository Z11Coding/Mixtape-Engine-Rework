// Debug script for testing ProxyField
// Place this in your song's script folder and call the functions to test

var testProxy:ProxyField;

function onCreatePost() {
    trace("=== ProxyField Debug Test Started ===");
    testProxyField();
}

function testProxyField() {
    trace("Testing ProxyField creation...");

    // Check if the source field exists and is working
    if (game.dadField == null || game.dadField.noteField == null) {
        trace("ERROR: dadField or dadField.noteField is null!");
        return;
    }

    trace("Source field exists: " + (game.dadField.noteField != null));
    trace("Source field visible: " + game.dadField.noteField.visible);
    trace("Source field alpha: " + game.dadField.noteField.alpha);

    // Create the ProxyField
    testProxy = new ProxyField(game.dadField.noteField);
    trace("ProxyField created successfully");

    // Check basic properties
    trace("ProxyField exists: " + testProxy.exists);
    trace("ProxyField visible: " + testProxy.visible);
    trace("ProxyField alpha: " + testProxy.alpha);
    trace("ProxyField isProxy: " + testProxy.isProxy);

    // Set basic properties
    testProxy.cameras = [game.camHUD];
    testProxy.x = 200;
    testProxy.y = 100;
    testProxy.alpha = 0.8;

    trace("ProxyField configured - x: " + testProxy.x + ", y: " + testProxy.y);

    // Test both approaches:

    // Approach 1: Add to NotefieldRenderer (recommended)
    trace("Adding ProxyField to NotefieldRenderer...");
    game.notefields.add(testProxy);

    // Approach 2: Add to display list (like the examples)
    // trace("Adding ProxyField to display list...");
    // addBehindGF(testProxy);

    trace("ProxyField setup complete");
}

function onUpdate(elapsed) {
    // Debug info every 60 frames (about once per second at 60fps)
    if (testProxy != null && Std.int(Conductor.songPosition) % 1000 < 50) {
        #if debug
        trace(testProxy.debugStatus());
        #end
    }
}

function onDestroy() {
    if (testProxy != null) {
        testProxy.destroy();
        testProxy = null;
    }
}
