package yutautil;

import haxe.Exception;
import haxe.PosInfos;
import haxe.Timer;
import haxe.ds.StringMap;

/**
 * Self contained runtime testing / profiling / leak hunting toolbox.
 *
 * Nothing here depends on the rest of yutautil, so it can be dropped into any
 * state, script or test harness without dragging in engine systems.
 *
 * Quick tour:
 *   DevTools.measure("loadChart", () -> loadChart());       // one shot timing
 *   var sw = DevTools.stopwatch("frame"); sw.lap("update"); // multi segment timing
 *   DevTools.bench("sort", () -> arr.sort(cmp), 500);       // repeated timing + stats
 *   DevTools.check(note != null, "note was null");          // runtime assertion
 *   DevTools.track(sprite, "note sprite");                  // weak ref tracking
 *   DevTools.expectCollected(sprite); sprite = null;
 *   trace(DevTools.checkLeaks());                           // still alive => leak
 *   trace(DevTools.findReferences(sprite, FlxG.state));     // who is holding it
 */
class DevTools {
    /** Master switch. When false, timing/tracking calls become no-ops (assertions still evaluate their condition). */
    public static var enabled:Bool = true;

    /** Where every report/failure line goes. Swap for a file writer or on screen console. */
    public static var logger:(line:String, ?pos:PosInfos) -> Void = function(line:String, ?pos:PosInfos) {
        // haxe.Log.trace would null-deref on a missing pos, so fall back to this call site's own.
        if (pos == null) trace(line);
        else trace(line, pos);
    };

    /** How a failed assertion behaves. */
    public static var assertMode:AssertMode = Log;

    /** True when the target can actually prove an object was collected. */
    public static var weakRefsSupported(default, null):Bool = #if cpp true #else false #end;
    static var pulseTimer:Timer = null;

    // ------------------------------------------------------------------ timing

    static var timings:StringMap<TimerStat> = new StringMap();
    static var openScopes:StringMap<Float> = new StringMap();
    static var scopeStack:Array<String> = [];

    /** Starts a named scope. Nested scopes get a "parent/child" name. */
    public static function begin(name:String):String {
        if (!enabled) return name;
        var full = scopeStack.length > 0 ? scopeStack[scopeStack.length - 1] + "/" + name : name;
        scopeStack.push(full);
        openScopes.set(full, Timer.stamp());
        return full;
    }

    /** Closes the most recent scope (or a named one) and returns its duration in ms. */
    public static function end(?name:String):Float {
        if (!enabled) return 0;
        var full = name;
        if (full == null) {
            if (scopeStack.length == 0) return 0;
            full = scopeStack.pop();
        } else {
            if (!openScopes.exists(full) && scopeStack.length > 0) full = scopeStack[scopeStack.length - 1];
            scopeStack.remove(full);
        }
        var started = openScopes.get(full);
        if (started == null) return 0;
        openScopes.remove(full);
        var ms = (Timer.stamp() - started) * 1000;
        record(full, ms);
        return ms;
    }

    /** Times a single call, records it under `name` and passes the result through. */
    public static function measure<T>(name:String, fn:Void->T):T {
        if (!enabled) return fn();
        var t = Timer.stamp();
        var result = fn();
        record(name, (Timer.stamp() - t) * 1000);
        return result;
    }

    /** Same as measure but logs the duration immediately. */
    public static function measureLog<T>(name:String, fn:Void->T, ?pos:PosInfos):T {
        var t = Timer.stamp();
        var result = fn();
        var ms = (Timer.stamp() - t) * 1000;
        record(name, ms);
        logger('[time] $name: ${fmt(ms)}ms  @ ${where(pos)}', pos);
        return result;
    }

    /** Creates an independent stopwatch, useful for overlapping / segmented measurements. */
    public static function stopwatch(name:String, autoStart:Bool = true):Stopwatch {
        return new Stopwatch(name, autoStart);
    }

    /** Runs `fn` repeatedly and returns min/max/avg/median stats. */
    public static function bench(name:String, fn:Void->Void, iterations:Int = 100, warmup:Int = 0):BenchResult {
        for (i in 0...warmup) fn();

        var samples = new Array<Float>();
        samples.resize(iterations);
        var total = 0.0;
        for (i in 0...iterations) {
            var t = Timer.stamp();
            fn();
            var ms = (Timer.stamp() - t) * 1000;
            samples[i] = ms;
            total += ms;
        }

        var sorted = samples.copy();
        sorted.sort(function(a, b) return a < b ? -1 : (a > b ? 1 : 0));
        var median = iterations == 0 ? 0.0 : (iterations % 2 == 1 ? sorted[Std.int(iterations / 2)] : (sorted[Std.int(iterations / 2) - 1] + sorted[Std.int(iterations / 2)]) / 2);
        var average = iterations == 0 ? 0.0 : total / iterations;

        var result:BenchResult = {
            name: name,
            iterations: iterations,
            total: total,
            average: average,
            min: iterations == 0 ? 0 : sorted[0],
            max: iterations == 0 ? 0 : sorted[iterations - 1],
            median: median,
            opsPerSecond: average > 0 ? 1000 / average : 0
        };
        record(name, total);
        return result;
    }

    /** Benchmarks several implementations of the same thing and reports the winner. */
    public static function compare(cases:Map<String, Void->Void>, iterations:Int = 100, warmup:Int = 5):Array<BenchResult> {
        var results = new Array<BenchResult>();
        for (key => fn in cases) results.push(bench(key, fn, iterations, warmup));
        results.sort(function(a, b) return a.average < b.average ? -1 : (a.average > b.average ? 1 : 0));

        var lines = ['[compare] $iterations iterations each'];
        var best = results.length > 0 ? results[0].average : 0;
        for (r in results) {
            var ratio = best > 0 ? r.average / best : 1;
            lines.push('  ${r.name}: avg ${fmt(r.average)}ms  min ${fmt(r.min)}  max ${fmt(r.max)}  median ${fmt(r.median)}  (${fmt(ratio)}x)');
        }
        logger(lines.join("\n"));
        return results;
    }

    /** Feeds an externally measured duration into the shared timing table. */
    static function record(name:String, ms:Float):Void {
        var stat = timings.get(name);
        if (stat == null) {
            timings.set(name, {name: name, calls: 1, total: ms, min: ms, max: ms, last: ms});
            return;
        }
        stat.calls++;
        stat.total += ms;
        stat.last = ms;
        if (ms < stat.min) stat.min = ms;
        if (ms > stat.max) stat.max = ms;
    }

    public static function timingStats():Array<TimerStat> {
        var out = new Array<TimerStat>();
        for (s in timings) out.push(s);
        out.sort(function(a, b) return a.total < b.total ? 1 : (a.total > b.total ? -1 : 0));
        return out;
    }

    public static function timingReport(log:Bool = true):String {
        var lines = ["=== DevTools timings (slowest first) ==="];
        for (s in timingStats()) {
            lines.push('  ${s.name}: ${s.calls} calls, total ${fmt(s.total)}ms, avg ${fmt(s.total / s.calls)}ms, min ${fmt(s.min)}, max ${fmt(s.max)}, last ${fmt(s.last)}');
        }
        var text = lines.join("\n");
        if (log) logger(text);
        return text;
    }

    public static function resetTimings():Void {
        timings = new StringMap();
        openScopes = new StringMap();
        scopeStack = [];
    }

    // ---------------------------------------------------------------- counters

    static var counters:StringMap<Int> = new StringMap();

    /** Cheap event counter, e.g. how many times a pool actually missed. */
    public static function count(name:String, amount:Int = 1):Int {
        var current = counters.exists(name) ? counters.get(name) + amount : amount;
        counters.set(name, current);
        return current;
    }

    public static function getCount(name:String):Int {
        return counters.exists(name) ? counters.get(name) : 0;
    }

    public static function counterReport(log:Bool = true):String {
        var lines = ["=== DevTools counters ==="];
        for (key in counters.keys()) lines.push('  $key: ${counters.get(key)}');
        var text = lines.join("\n");
        if (log) logger(text);
        return text;
    }

    public static function resetCounters():Void counters = new StringMap();

    // ---------------------------------------------------------- value watchers

    static var markedValues:Array<MarkedValue<Dynamic>> = [];

    /**
     * Marks a value for change detection. The getter is intentional: it lets the
     * watched value remain a normal variable or object with methods.
     */
    public static function mark<T>(label:String, getter:Void->T, ?onChange:TrackedChange<T>->Void, deep:Bool = false):MarkedValue<T> {
        var marked = new MarkedValue<T>(label, getter, onChange, deep);
        markedValues.push(cast marked);
        return marked;
    }

    /** Checks every marked value and emits each change at most once per poll. */
    public static function pollMarked():Int {
        var changed = 0;
        for (marked in markedValues) if (marked.check()) changed++;
        return changed;
    }

    /** Runs one watcher pulse, suitable for a state update or engine signal. */
    public static function pulse():Int {
        return pollMarked();
    }

    /** Starts periodic watcher pulses without requiring callers to add update code. */
    public static function startPulse(intervalMs:Int = 16):Void {
        stopPulse();
        if (intervalMs < 1) intervalMs = 1;
        pulseTimer = new Timer(intervalMs);
        pulseTimer.run = function() pulse();
    }

    /** Stops automatic watcher pulses. */
    public static function stopPulse():Void {
        if (pulseTimer == null) return;
        pulseTimer.stop();
        pulseTimer = null;
    }

    public static inline function pulseActive():Bool return pulseTimer != null;

    /** Removes a marked watcher. */
    public static function unmark<T>(marked:MarkedValue<T>):Void {
        markedValues.remove(cast marked);
    }

    // -------------------------------------------------------------- assertions

    public static var assertionsRun(default, null):Int = 0;
    public static var assertionsFailed(default, null):Int = 0;

    /** Every failure message collected so far, in order. */
    public static var failures(default, null):Array<String> = [];

    /** Core assertion. Returns whether the condition held, so it can guard code paths too. */
    public static function check(condition:Bool, ?message:String, ?pos:PosInfos):Bool {
        assertionsRun++;
        if (condition) return true;
        fail(message == null ? "assertion failed" : message, pos);
        return false;
    }

    public static function isTrue(value:Bool, ?message:String, ?pos:PosInfos):Bool {
        return check(value == true, message == null ? "expected true, got false" : message, pos);
    }

    public static function isFalse(value:Bool, ?message:String, ?pos:PosInfos):Bool {
        return check(value == false, message == null ? "expected false, got true" : message, pos);
    }

    public static function notNull(value:Dynamic, ?message:String, ?pos:PosInfos):Bool {
        return check(value != null, message == null ? "expected a non null value" : message, pos);
    }

    public static function isNull(value:Dynamic, ?message:String, ?pos:PosInfos):Bool {
        return check(value == null, message == null ? 'expected null, got ${stringify(value)}' : message, pos);
    }

    /** Structural equality for primitives, arrays and plain objects. */
    public static function equals(actual:Dynamic, expected:Dynamic, ?message:String, ?pos:PosInfos):Bool {
        var ok = valueEquals(actual, expected);
        return check(ok, message == null ? 'expected ${stringify(expected)}, got ${stringify(actual)}' : message, pos);
    }

    public static function notEquals(actual:Dynamic, unexpected:Dynamic, ?message:String, ?pos:PosInfos):Bool {
        return check(!valueEquals(actual, unexpected), message == null ? 'did not expect ${stringify(unexpected)}' : message, pos);
    }

    /** Identity check, ignores structural equality entirely. */
    public static function same(a:Dynamic, b:Dynamic, ?message:String, ?pos:PosInfos):Bool {
        return check(a == b, message == null ? "expected the very same instance" : message, pos);
    }

    /** Type assertion. `exact` rejects subclasses, matching CollectionUtils.isType's NoSupers flag. */
    public static function isOfType(value:Dynamic, type:Class<Dynamic>, ?message:String, ?exact:Bool, ?pos:PosInfos):Bool {
        var ok = value != null && CollectionUtils.isType(value, type, exact == true);
        var expected = typeNameOf(type) + (exact == true ? " (exactly)" : "");
        return check(ok, message == null ? 'expected $expected, got ${value == null ? "null" : typeOf(value)}' : message, pos);
    }

    public static function inRange(value:Float, min:Float, max:Float, ?message:String, ?pos:PosInfos):Bool {
        return check(value >= min && value <= max, message == null ? '$value is outside [$min, $max]' : message, pos);
    }

    /** Float comparison with tolerance. */
    public static function nearly(actual:Float, expected:Float, tolerance:Float = 0.0001, ?message:String, ?pos:PosInfos):Bool {
        var delta = actual - expected;
        if (delta < 0) delta = -delta;
        return check(delta <= tolerance, message == null ? 'expected $expected (+-$tolerance), got $actual' : message, pos);
    }

    /** Passes when `fn` throws. The caught value is returned for further inspection. */
    public static function throws(fn:Void->Void, ?message:String, ?pos:PosInfos):Dynamic {
        try {
            fn();
        } catch (e:Dynamic) {
            check(true, message, pos);
            return e;
        }
        check(false, message == null ? "expected an exception, none was thrown" : message, pos);
        return null;
    }

    public static function noThrow(fn:Void->Void, ?message:String, ?pos:PosInfos):Bool {
        try {
            fn();
        } catch (e:Dynamic) {
            return check(false, message == null ? 'unexpected exception: ${Std.string(e)}' : message, pos);
        }
        return check(true, message, pos);
    }

    /** Fails when `fn` takes longer than `budgetMs`. Handy for frame budget guards. */
    public static function withinBudget(name:String, budgetMs:Float, fn:Void->Void, ?pos:PosInfos):Float {
        var t = Timer.stamp();
        fn();
        var ms = (Timer.stamp() - t) * 1000;
        record(name, ms);
        check(ms <= budgetMs, '$name took ${fmt(ms)}ms, budget was ${fmt(budgetMs)}ms', pos);
        return ms;
    }

    static function fail(message:String, ?pos:PosInfos):Void {
        assertionsFailed++;
        var line = '[assert] $message  @ ${where(pos)}';
        failures.push(line);
        switch (assertMode) {
            case Throw: throw new AssertionError(line);
            case Log: logger(line, pos);
            case Silent:
        }
    }

    public static function resetAssertions():Void {
        assertionsRun = 0;
        assertionsFailed = 0;
        failures = [];
    }

    // ------------------------------------------------------------------- tests

    /** Creates a runnable suite of named runtime tests. */
    public static function suite(name:String):TestSuite {
        return new TestSuite(name);
    }

    // -------------------------------------------------------- object tracking

    static var tracked:Array<TrackedRef> = [];
    static var nextTrackId:Int = 1;

    /**
     * Registers a weak reference to `obj`. The tracker never keeps the object alive,
     * so anything still reported as alive is being held somewhere else.
     */
    public static function track(obj:Dynamic, ?tag:String, ?pos:PosInfos):Int {
        if (!enabled || obj == null) return -1;
        var existing = findRef(obj);
        if (existing != null) return existing.id;

        var ref = new TrackedRef(nextTrackId++, obj, tag == null ? typeOf(obj) : tag, where(pos));
        tracked.push(ref);
        return ref.id;
    }

    /** Records "the object was seen here, at this time". Builds up a reference trail. */
    public static function touch(obj:Dynamic, ?note:String, ?pos:PosInfos):Void {
        if (!enabled || obj == null) return;
        var ref = findRef(obj);
        if (ref == null) {
            track(obj, null, pos);
            ref = findRef(obj);
            if (ref == null) return;
        }
        ref.sightings.push({time: Timer.stamp(), where: where(pos), note: note});
        if (ref.sightings.length > maxSightings) ref.sightings.shift();
    }

    /** How many sightings are kept per object before the oldest are dropped. */
    public static var maxSightings:Int = 64;

    /** Everywhere the object has been seen since it was tracked. */
    public static function whereIs(obj:Dynamic):Array<Sighting> {
        var ref = findRef(obj);
        return ref == null ? [] : ref.sightings.copy();
    }

    /** Declares that from now on the object should be unreachable; checkLeaks() verifies it. */
    public static function expectCollected(obj:Dynamic, ?pos:PosInfos):Void {
        if (obj == null) return;
        var ref = findRef(obj);
        if (ref == null) {
            track(obj, null, pos);
            ref = findRef(obj);
            if (ref == null) return;
        }
        ref.expectedDead = true;
        ref.disposedAt = where(pos);
        ref.release();
    }

    public static function untrack(obj:Dynamic):Void {
        var ref = findRef(obj);
        if (ref != null) tracked.remove(ref);
    }

    public static function isTracked(obj:Dynamic):Bool return findRef(obj) != null;

    /** Returns whether a tracked object is still reachable through its weak handle. */
    public static function weakAlive(id:Int):Bool {
        for (ref in tracked) if (ref.id == id) return ref.isAlive();
        return false;
    }

    /** Checks a weak handle and optionally logs when its object is no longer alive. */
    public static function checkWeak(id:Int, log:Bool = true):Bool {
        var alive = weakAlive(id);
        if (log && !alive) logger('[weak] tracked object #$id is no longer alive', null);
        return alive;
    }

    public static function infoOf(obj:Dynamic):Null<TrackedInfo> {
        var ref = findRef(obj);
        return ref == null ? null : ref.toInfo();
    }

    /** Drops entries whose object was collected; returns how many were freed. */
    public static function sweep():Int {
        var freed = 0;
        var i = tracked.length;
        while (i-- > 0) {
            if (!tracked[i].isAlive()) {
                tracked.splice(i, 1);
                freed++;
            }
        }
        return freed;
    }

    public static function liveObjects():Array<TrackedInfo> {
        var out = new Array<TrackedInfo>();
        for (ref in tracked) if (ref.isAlive()) out.push(ref.toInfo());
        return out;
    }

    public static function aliveCount():Int {
        var n = 0;
        for (ref in tracked) if (ref.isAlive()) n++;
        return n;
    }

    /**
     * Forces a collection and returns every object that was expected to die but is
     * still reachable, i.e. a leak. Requires weak reference support to be meaningful.
     */
    public static function checkLeaks(forceGc:Bool = true, log:Bool = true):Array<TrackedInfo> {
        if (forceGc) collectGarbage(true);

        var leaks = new Array<TrackedInfo>();
        for (ref in tracked) if (ref.expectedDead && ref.isAlive()) leaks.push(ref.toInfo());

        if (log) {
            if (!weakRefsSupported) {
                logger("[leaks] weak references are unavailable on this target, results are inconclusive");
            } else if (leaks.length == 0) {
                logger("[leaks] none, every disposed object was collected");
            } else {
                var lines = ['[leaks] ${leaks.length} object(s) still reachable after GC:'];
                for (l in leaks) {
                    lines.push('  #${l.id} ${l.type} "${l.tag}" tracked at ${l.origin}, disposed at ${l.disposedAt}, ${l.sightings.length} sighting(s)');
                    if (l.sightings.length > 0) lines.push('    last seen: ${l.sightings[l.sightings.length - 1].where}');
                }
                logger(lines.join("\n"));
            }
        }
        return leaks;
    }

    /** Tracked objects grouped by tag, sorted by how many are alive. Good for spotting growth. */
    public static function trackerReport(log:Bool = true):String {
        var byTag = new StringMap<Int>();
        for (ref in tracked) {
            if (!ref.isAlive()) continue;
            byTag.set(ref.tag, (byTag.exists(ref.tag) ? byTag.get(ref.tag) : 0) + 1);
        }
        var lines = ['=== DevTools tracker (${aliveCount()} alive / ${tracked.length} tracked) ==='];
        for (tag in byTag.keys()) lines.push('  $tag: ${byTag.get(tag)}');
        var text = lines.join("\n");
        if (log) logger(text);
        return text;
    }

    public static function resetTracker():Void {
        tracked = [];
    }

    static function findRef(obj:Dynamic):Null<TrackedRef> {
        for (ref in tracked) if (ref.get() == obj) return ref;
        return null;
    }

    // ----------------------------------------------------- reference searching

    /**
     * Walks `root` looking for anything holding `target`, returning the field paths
     * that lead to it. This is the "who is still referencing my sprite" tool.
     */
    public static function findReferences(target:Dynamic, root:Dynamic, maxDepth:Int = 6, maxNodes:Int = 20000, ?rootName:String):Array<String> {
        var found = new Array<String>();
        if (target == null || root == null) return found;

        var visited = new haxe.ds.ObjectMap<{}, Bool>();
        var nodes = 0;

        function walk(node:Dynamic, path:String, depth:Int):Void {
            if (node == null || depth > maxDepth || nodes > maxNodes) return;
            if (!Reflect.isObject(node) || Reflect.isFunction(node)) return;
            if (Std.isOfType(node, String)) return;

            var key:{} = cast node;
            if (visited.exists(key)) return;
            visited.set(key, true);
            nodes++;

            for (child in childrenOf(node)) {
                if (child.value == null) continue;
                var childPath = path + child.name;
                if (child.value == target) {
                    found.push(childPath);
                    continue;
                }
                walk(child.value, childPath, depth + 1);
            }
        }

        walk(root, rootName == null ? typeOf(root) : rootName, 0);
        return found;
    }

    static function childrenOf(node:Dynamic):Array<{name:String, value:Dynamic}> {
        var out = new Array<{name:String, value:Dynamic}>();

        if (Std.isOfType(node, Array)) {
            var arr:Array<Dynamic> = cast node;
            for (i in 0...arr.length) out.push({name: '[$i]', value: arr[i]});
            return out;
        }

        if (Std.isOfType(node, haxe.Constraints.IMap)) {
            try {
                var map:Map<Dynamic, Dynamic> = cast node;
                for (k => v in map) out.push({name: '["${Std.string(k)}"]', value: v});
            } catch (e:Dynamic) {}
            return out;
        }

        for (field in fieldsOf(node)) {
            var value:Dynamic = null;
            try {
                value = Reflect.getProperty(node, field);
            } catch (e:Dynamic) {
                continue;
            }
            if (Reflect.isFunction(value)) continue;
            out.push({name: '.$field', value: value});
        }
        return out;
    }

    static function fieldsOf(node:Dynamic):Array<String> {
        var cls = Type.getClass(node);
        if (cls == null) return Reflect.fields(node);
        var out = new Array<String>();
        try {
            for (f in Type.getInstanceFields(cls)) if (out.indexOf(f) == -1) out.push(f);
        } catch (e:Dynamic) {}
        for (f in Reflect.fields(node)) if (out.indexOf(f) == -1) out.push(f);
        return out;
    }

    // ------------------------------------------------------------------ memory

    static var snapshots:StringMap<MemorySnapshot> = new StringMap();

    /** Bytes currently used by the GC heap (0 when the target cannot report it). */
    public static function memoryUsage():Float {
        #if cpp
        var used:Float = cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
        return used;
        #elseif openfl
        var used:Float = openfl.system.System.totalMemory;
        return used;
        #else
        return 0;
        #end
    }

    public static function collectGarbage(major:Bool = true):Void {
        #if cpp
        cpp.vm.Gc.run(major);
        if (major) cpp.vm.Gc.compact();
        #elseif hl
        hl.Gc.major();
        #elseif neko
        neko.vm.Gc.run(major);
        #elseif java
        java.lang.System.gc();
        #end
    }

    /** Stores a labelled memory reading for later comparison. */
    public static function snapshot(label:String):MemorySnapshot {
        var snap:MemorySnapshot = {
            label: label,
            time: Timer.stamp(),
            bytes: memoryUsage(),
            trackedAlive: aliveCount()
        };
        snapshots.set(label, snap);
        return snap;
    }

    /** Difference between a stored snapshot and right now. */
    public static function since(label:String, log:Bool = true):Null<MemoryDelta> {
        var before = snapshots.get(label);
        if (before == null) return null;
        var now = snapshot(label + ":now");
        var delta:MemoryDelta = {
            label: label,
            bytes: now.bytes - before.bytes,
            trackedAlive: now.trackedAlive - before.trackedAlive,
            seconds: now.time - before.time
        };
        if (log) logger('[memory] $label: ${formatBytes(delta.bytes)} over ${fmt(delta.seconds * 1000)}ms, tracked alive ${delta.trackedAlive >= 0 ? "+" : ""}${delta.trackedAlive}');
        return delta;
    }

    /**
     * Runs `fn` `iterations` times and reports the memory retained afterwards.
     * A steadily growing value across runs is the signature of a leak.
     */
    public static function leakProbe(name:String, fn:Void->Void, iterations:Int = 10, log:Bool = true):Float {
        collectGarbage(true);
        var before = memoryUsage();
        for (i in 0...iterations) fn();
        collectGarbage(true);
        var retained = memoryUsage() - before;
        if (log) logger('[leakProbe] $name retained ${formatBytes(retained)} after $iterations run(s) (${formatBytes(retained / (iterations == 0 ? 1 : iterations))} per run)');
        return retained;
    }

    public static function formatBytes(bytes:Float):String {
        var sign = bytes < 0 ? "-" : "";
        var v = bytes < 0 ? -bytes : bytes;
        if (v < 1024) return sign + fmt(v) + " B";
        if (v < 1024 * 1024) return sign + fmt(v / 1024) + " KB";
        if (v < 1024 * 1024 * 1024) return sign + fmt(v / (1024 * 1024)) + " MB";
        return sign + fmt(v / (1024 * 1024 * 1024)) + " GB";
    }

    // -------------------------------------------------------- object debugging

    /** Readable recursive dump of any value, with cycle protection. */
    public static function dump(value:Dynamic, depth:Int = 2, log:Bool = true):String {
        var text = dumpInner(value, depth, 0, new haxe.ds.ObjectMap<{}, Bool>());
        if (log) logger(text);
        return text;
    }

    static function dumpInner(value:Dynamic, maxDepth:Int, depth:Int, seen:haxe.ds.ObjectMap<{}, Bool>):String {
        if (value == null) return "null";
        if (!Reflect.isObject(value) || Std.isOfType(value, String)) return stringify(value);
        if (Reflect.isFunction(value)) return "<function>";
        if (depth > maxDepth) return "<" + typeOf(value) + " ...>";

        var key:{} = cast value;
        if (seen.exists(key)) return "<cycle: " + typeOf(value) + ">";
        seen.set(key, true);

        var pad = StringTools.rpad("", " ", (depth + 1) * 2);
        var closePad = StringTools.rpad("", " ", depth * 2);
        var parts = new Array<String>();
        for (child in childrenOf(value)) {
            parts.push(pad + child.name + " = " + dumpInner(child.value, maxDepth, depth + 1, seen));
        }
        if (parts.length == 0) return typeOf(value) + " {}";
        return typeOf(value) + " {\n" + parts.join(",\n") + "\n" + closePad + "}";
    }

    /** One line summary: type, field count, and identity of the value. */
    public static function describe(value:Dynamic):String {
        if (value == null) return "null";
        if (!Reflect.isObject(value)) return '${typeOf(value)}(${stringify(value)})';
        return '${typeOf(value)} with ${childrenOf(value).length} field(s)';
    }

    static var watchedFields:StringMap<StringMap<String>> = new StringMap();

    /** Remembers the current field values of an object under `label`. */
    public static function watch(label:String, obj:Dynamic):Void {
        var snap = new StringMap<String>();
        for (child in childrenOf(obj)) snap.set(child.name, stringify(child.value));
        watchedFields.set(label, snap);
    }

    /** Lists which watched fields changed since the last `watch` call, and re-arms the watch. */
    public static function changes(label:String, obj:Dynamic, log:Bool = true):Array<String> {
        var before = watchedFields.get(label);
        var out = new Array<String>();
        if (before == null) {
            watch(label, obj);
            return out;
        }
        for (child in childrenOf(obj)) {
            var old = before.get(child.name);
            var now = stringify(child.value);
            if (old != now) out.push('${child.name}: $old -> $now');
        }
        watch(label, obj);
        if (log && out.length > 0) logger('[changes] $label\n  ' + out.join("\n  "));
        return out;
    }

    /** Field level difference between two objects of the same shape. */
    public static function diff(a:Dynamic, b:Dynamic, log:Bool = true):Array<String> {
        var out = new Array<String>();
        var bValues = new StringMap<String>();
        for (child in childrenOf(b)) bValues.set(child.name, stringify(child.value));
        for (child in childrenOf(a)) {
            var left = stringify(child.value);
            var right = bValues.get(child.name);
            if (left != right) out.push('${child.name}: $left != $right');
        }
        if (log && out.length > 0) logger("[diff]\n  " + out.join("\n  "));
        return out;
    }

    // ------------------------------------------------------------------ shared

    /** Full status dump: timings, counters, assertions, tracker, memory. */
    public static function report():String {
        var lines = [
            "================ DevTools report ================",
            'memory: ${formatBytes(memoryUsage())}',
            'assertions: $assertionsRun run, $assertionsFailed failed',
            timingReport(false),
            counterReport(false),
            trackerReport(false)
        ];
        if (failures.length > 0) lines.push("failures:\n  " + failures.join("\n  "));
        var text = lines.join("\n");
        logger(text);
        return text;
    }

    public static function resetAll():Void {
        stopPulse();
        resetTimings();
        resetCounters();
        resetAssertions();
        resetTracker();
        markedValues = [];
        snapshots = new StringMap();
        watchedFields = new StringMap();
    }

    public static function typeOf(value:Dynamic):String {
        if (value == null) return "null";
        var cls = Type.getClass(value);
        if (cls != null) return Type.getClassName(cls);
        var en = Type.getEnum(value);
        if (en != null) return Type.getEnumName(en);
        return switch (Type.typeof(value)) {
            case TInt: "Int";
            case TFloat: "Float";
            case TBool: "Bool";
            case TFunction: "Function";
            case TObject: "Object";
            default: "Unknown";
        }
    }

    static function typeNameOf(type:Class<Dynamic>):String {
        var name = Type.getClassName(type);
        return name == null ? Std.string(type) : name;
    }

    static function valueEquals(a:Dynamic, b:Dynamic):Bool {
        if (a == b) return true;
        if (a == null || b == null) return false;

        if (Std.isOfType(a, Array) && Std.isOfType(b, Array)) {
            var arrA:Array<Dynamic> = cast a;
            var arrB:Array<Dynamic> = cast b;
            if (arrA.length != arrB.length) return false;
            for (i in 0...arrA.length) if (!valueEquals(arrA[i], arrB[i])) return false;
            return true;
        }

        if (Type.getClass(a) == null && Type.getClass(b) == null && Reflect.isObject(a) && Reflect.isObject(b)) {
            var fieldsA = Reflect.fields(a);
            var fieldsB = Reflect.fields(b);
            if (fieldsA.length != fieldsB.length) return false;
            for (f in fieldsA) if (!valueEquals(Reflect.field(a, f), Reflect.field(b, f))) return false;
            return true;
        }

        try {
            if (Reflect.compare(a, b) == 0) return true;
        } catch (e:Dynamic) {}
        return false;
    }

    static function stringify(value:Dynamic):String {
        if (value == null) return "null";
        if (Std.isOfType(value, String)) return '"' + Std.string(value) + '"';
        try {
            return Std.string(value);
        } catch (e:Dynamic) {
            return "<unprintable " + typeOf(value) + ">";
        }
    }

    static function where(?pos:PosInfos):String {
        if (pos == null) return "unknown";
        return '${pos.fileName}:${pos.lineNumber} (${pos.className}.${pos.methodName})';
    }

    static function fmt(value:Float):String {
        var rounded = Math.round(value * 1000) / 1000;
        return Std.string(rounded);
    }
}

/** Independent, pausable, lap capable timer. */
class Stopwatch {
    public var name(default, null):String;
    public var running(default, null):Bool = false;
    public var laps(default, null):Array<{name:String, ms:Float}> = [];
    public var elapsed(get, never):Float;

    var startedAt:Float = 0;
    var accumulated:Float = 0;
    var lastLapAt:Float = 0;

    public function new(name:String, autoStart:Bool = true) {
        this.name = name;
        if (autoStart) start();
    }

    public function start():Stopwatch {
        if (running) return this;
        running = true;
        startedAt = Timer.stamp();
        lastLapAt = startedAt;
        return this;
    }

    /** Records the time since the previous lap (or since start) and returns it in ms. */
    public function lap(label:String):Float {
        var now = Timer.stamp();
        var ms = (now - lastLapAt) * 1000;
        lastLapAt = now;
        laps.push({name: label, ms: ms});
        return ms;
    }

    public function pause():Float {
        if (!running) return accumulated;
        accumulated += (Timer.stamp() - startedAt) * 1000;
        running = false;
        return accumulated;
    }

    public function resume():Stopwatch {
        return start();
    }

    /** Stops the watch and feeds the total into the shared timing table. */
    public function stop(share:Bool = true):Float {
        var total = pause();
        if (share) @:privateAccess DevTools.record(name, total);
        return total;
    }

    public function reset():Stopwatch {
        accumulated = 0;
        laps = [];
        startedAt = Timer.stamp();
        lastLapAt = startedAt;
        return this;
    }

    function get_elapsed():Float {
        return running ? accumulated + (Timer.stamp() - startedAt) * 1000 : accumulated;
    }

    public function report(log:Bool = true):String {
        var lines = ['[stopwatch] $name: ${Math.round(elapsed * 1000) / 1000}ms'];
        for (l in laps) lines.push('  ${l.name}: ${Math.round(l.ms * 1000) / 1000}ms');
        var text = lines.join("\n");
        if (log) DevTools.logger(text);
        return text;
    }
}

/** Runtime test suite: register named tests, run them, get pass/fail plus timings. */
class TestSuite {
    public var name(default, null):String;
    public var results(default, null):Array<TestResult> = [];

    public var beforeEach:Null<Void->Void> = null;
    public var afterEach:Null<Void->Void> = null;

    var tests:Array<{name:String, fn:Void->Void}> = [];

    public function new(name:String) {
        this.name = name;
    }

    public function add(testName:String, fn:Void->Void):TestSuite {
        tests.push({name: testName, fn: fn});
        return this;
    }

    /** Runs every test. Assertion failures and thrown exceptions both mark a test failed. */
    public function run(log:Bool = true):Array<TestResult> {
        results = [];
        var previousMode = DevTools.assertMode;
        DevTools.assertMode = Silent;

        for (test in tests) {
            var failuresBefore = DevTools.failures.length;
            var assertionsBefore = DevTools.assertionsRun;
            var error:String = null;
            var t = Timer.stamp();

            try {
                if (beforeEach != null) beforeEach();
                test.fn();
                if (afterEach != null) afterEach();
            } catch (e:Dynamic) {
                error = Std.string(e);
            }

            var ms = (Timer.stamp() - t) * 1000;
            var newFailures = DevTools.failures.slice(failuresBefore);
            if (error == null && newFailures.length > 0) error = newFailures.join(" | ");

            results.push({
                name: test.name,
                passed: error == null,
                error: error,
                durationMs: ms,
                assertions: DevTools.assertionsRun - assertionsBefore
            });
        }

        DevTools.assertMode = previousMode;
        if (log) report();
        return results;
    }

    public function passed():Bool {
        for (r in results) if (!r.passed) return false;
        return true;
    }

    public function report(log:Bool = true):String {
        var passCount = 0;
        var lines = ['=== TestSuite: $name ==='];
        for (r in results) {
            if (r.passed) passCount++;
            var status = r.passed ? "PASS" : "FAIL";
            lines.push('  [$status] ${r.name} (${Math.round(r.durationMs * 1000) / 1000}ms, ${r.assertions} assertion(s))');
            if (!r.passed) lines.push('         ${r.error}');
        }
        lines.push('  $passCount/${results.length} passed');
        var text = lines.join("\n");
        if (log) DevTools.logger(text);
        return text;
    }
}

class AssertionError extends Exception {}

enum AssertMode {
    /** Throw an AssertionError on failure. */
    Throw;

    /** Log the failure and keep going. */
    Log;

    /** Only record the failure. */
    Silent;
}

typedef TimerStat = {
    var name:String;
    var calls:Int;
    var total:Float;
    var min:Float;
    var max:Float;
    var last:Float;
}

typedef BenchResult = {
    var name:String;
    var iterations:Int;
    var total:Float;
    var average:Float;
    var min:Float;
    var max:Float;
    var median:Float;
    var opsPerSecond:Float;
}

typedef Sighting = {
    var time:Float;
    var where:String;
    var note:Null<String>;
}

typedef TestResult = {
    var name:String;
    var passed:Bool;
    var error:Null<String>;
    var durationMs:Float;
    var assertions:Int;
}

typedef TrackedInfo = {
    var id:Int;
    var tag:String;
    var type:String;
    var origin:String;
    var disposedAt:Null<String>;
    var createdAt:Float;
    var alive:Bool;
    var expectedDead:Bool;
    var sightings:Array<Sighting>;
}

typedef MemorySnapshot = {
    var label:String;
    var time:Float;
    var bytes:Float;
    var trackedAlive:Int;
}

typedef MemoryDelta = {
    var label:String;
    var bytes:Float;
    var trackedAlive:Int;
    var seconds:Float;
}

typedef TrackedChange<T> = {
    var label:String;
    var oldValue:T;
    var newValue:T;
}

/** Getter-backed watcher for values that cannot conveniently be wrapped. */
@:access(yutautil.DevTools)
class MarkedValue<T> {
    public var label(default, null):String;
    public var getter(default, null):Void->T;
    public var deep(default, null):Bool;
    public var changed(default, null):Bool = false;

    var onChange:Null<TrackedChange<T>->Void>;
    var previous:T;
    public function new(label:String, getter:Void->T, onChange:Null<TrackedChange<T>->Void>, deep:Bool) {
        this.label = label;
        this.getter = getter;
        this.onChange = onChange;
        this.deep = deep;
        previous = getter();
        DevTools.logger('[marked] created "$label" with ${DevTools.stringify(previous)}', null);
    }

    /** Polls the getter and reports whether its value changed since the last poll. */
    public function check(?pos:PosInfos):Bool {
        var current = getter();
        var isDifferent = deep
            ? !DevTools.valueEquals(previous, current)
            : previous != current;
        if (!isDifferent) return false;

        var oldValue = previous;
        previous = current;
        changed = true;
        var change:TrackedChange<T> = {label: label, oldValue: oldValue, newValue: current};
        DevTools.logger('[marked] "$label" changed from ${DevTools.stringify(oldValue)} to ${DevTools.stringify(current)} @ ${DevTools.where(pos)}', pos);
        if (onChange != null) onChange(change);
        return true;
    }

    public function reset():Void {
        previous = getter();
        changed = false;
    }
}

/** Weak handle to a tracked object; never keeps the object alive on targets that support it. */
private class TrackedRef {
    public var id(default, null):Int;
    public var tag:String;
    public var type:String;
    public var origin:String;
    public var createdAt:Float;
    public var expectedDead:Bool = false;
    public var disposedAt:Null<String> = null;
    public var sightings:Array<Sighting> = [];

    #if cpp
    var ref:cpp.vm.WeakRef<Dynamic>;
    #else
    var released:Bool = false;
    var strong:Dynamic;
    #end

    public function new(id:Int, obj:Dynamic, tag:String, origin:String) {
        this.id = id;
        this.tag = tag;
        this.type = DevTools.typeOf(obj);
        this.origin = origin;
        this.createdAt = Timer.stamp();
        #if cpp
        this.ref = new cpp.vm.WeakRef<Dynamic>(obj);
        #else
        this.strong = obj;
        #end
    }

    public function get():Dynamic {
        #if cpp
        return ref.get();
        #else
        return released ? null : strong;
        #end
    }

    /** Without weak references the tracker must let go itself, or it becomes the leak. */
    public function release():Void {
        #if !cpp
        released = true;
        strong = null;
        #end
    }

    public function isAlive():Bool {
        return get() != null;
    }

    public function toInfo():TrackedInfo {
        return {
            id: id,
            tag: tag,
            type: type,
            origin: origin,
            disposedAt: disposedAt,
            createdAt: createdAt,
            alive: isAlive(),
            expectedDead: expectedDead,
            sightings: sightings.copy()
        };
    }
}

private class TrackedValueData<T> {
    public var value:T;

    public function new(value:T) {
        this.value = value;
    }
}

/**
 * Small typed value wrapper for observing assignments made through set().
 * Raw values convert implicitly, and the wrapper converts back to T when read.
 */
@:generic
@:access(yutautil.DevTools)
@:forward
abstract TrackedValue<T>(TrackedValueData<T>) {
    public function new(value:T, ?pos:PosInfos) {
        this = new TrackedValueData<T>(value);
        DevTools.logger('[tracked] created with ${DevTools.stringify(value)} @ ${DevTools.where(pos)}', pos);
    }

    @:from
    public static function fromValue<T>(value:T):TrackedValue<T> {
        return new TrackedValue<T>(value);
    }

    @:to
    public inline function toValue():T {
        DevTools.logger('[tracked] read ${DevTools.stringify(this.value)}', null);
        return this.value;
    }

    @:op(a.b)
    public inline function get_field(field:String):Dynamic {
        DevTools.logger('[tracked] read field ${field} = ${DevTools.stringify(Reflect.field(this.value, field))}', null);
        return Reflect.field(this.value, field);
    }

    @:op(a.b)
    public inline function set_field(field:String, value:Dynamic):Dynamic {
        var oldValue = Reflect.field(this.value, field);
        Reflect.setField(this.value, field, value);
        DevTools.logger('[tracked] ${field} changed from ${DevTools.stringify(oldValue)} to ${DevTools.stringify(value)}', null);
        return value;
    }

    public inline function get():T {
        return this.value;
    }

    public function set(value:T, ?pos:PosInfos):Void {
        var oldValue = this.value;
        this.value = value;
        DevTools.logger('[tracked] changed from ${DevTools.stringify(oldValue)} to ${DevTools.stringify(value)} @ ${DevTools.where(pos)}', pos);
    }
}
