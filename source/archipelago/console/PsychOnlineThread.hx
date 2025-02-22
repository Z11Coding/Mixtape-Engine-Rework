package archipelago.console;

import haxe.Exception;

class PsychOnlineThread {
    public static function run(func:Void->Void, ?onException:Exception->Void) {
        sys.thread.Thread.create(() -> {
            try {
                func();
            }
            catch (exc) {
                Waiter.put(() -> { // waiter more errors please!
					if (onException != null)
                        onException(exc);
                    else
                        throw exc;
                });
            }
        });
    }

	public static function repeat(func:Void->Void, everySeconds:Float, ?onException:Exception->Void) {
		sys.thread.Thread.create(() -> {
            var running = true;
			try {
				while (running) {
					func();
					Sys.sleep(everySeconds);
                }
			}
			catch (exc) {
				running = false;
				Waiter.put(() -> { // waiter more errors please!
					if (onException != null)
						onException(exc);
					else
						throw exc;
				});
			}
		});
    }

	public static function safeCatch(task:Void->Void, ?onException:Exception->Void) {
		try {
			task();
		}
		catch (exc:Dynamic) {
			Waiter.put(() -> {
				if (onException != null)
					onException(exc);
				else
					throw exc;
			});
		}
	}
}