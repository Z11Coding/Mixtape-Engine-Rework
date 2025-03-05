package yutautil;

import haxe.unit.TestCase;
import haxe.unit.TestRunner;
import sys.thread.Thread;

class TestThreader extends TestCase {
    public function new() {
        super();
    }

    public function testRunInQueue():Void {
        var result = 0;
        Threader.runInQueue(macro {
            result += 1;
        }, 2, true);
        Threader.threadQueue.run();
        Threader.threadQueue.waitUntilFinished();
        assertEquals(1, result);
    }

    public function testRunQueue():Void {
        var result = 0;
        Threader.runQueue([
            macro { result += 1; },
            macro { result += 2; }
        ], 2, true);
        Threader.threadQueue.run();
        Threader.threadQueue.waitUntilFinished();
        assertEquals(3, result);
    }

    public function testRunInThread():Void {
        var result = 0;
        Threader.runInThread(macro {
            result += 1;
        }, 0.1, "testThread");
        Threader.waitForThread("testThread");
        assertEquals(1, result);
    }

    public function testThreadQueue():Void {
        var queue = new ThreadQueue(2, true);
        var result = 0;
        queue.add(() -> result += 1);
        queue.add(() -> result += 2);
        queue.run();
        queue.waitUntilFinished();
        assertEquals(3, result);
    }

    public function testMemLimitThreadQ():Void {
        var result = 0;
        var items = [1, 2, 3];
        var action = (item:Int) -> result += item;
        var memQueue = new MemLimitThreadQ(items, action, 2, true);
        memQueue.run();
        memQueue.queue.waitUntilFinished();
        assertEquals(6, result);
    }

    public function testThreadAccess():Void {
        var access = new ThreadAccess(0);
        access.set(5, () -> trace("Value set to 5"));
        access.get((value) -> assertEquals(5, value));
        var result = access.getSync();
        assertEquals(5, result);
    }

    public static function main() {
        var runner = new TestRunner();
        runner.add(new TestThreader());
        runner.run();
    }
}