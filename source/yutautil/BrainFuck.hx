package yutautil;

class BrainFuck {
    public static function interpret(code:String, input:String = "", native:Bool = false):String {
        var memory:Array<Int> = [];
        var pointer:Int = 0;
        var output:String = "";
        var inputIndex:Int = 0;
        var loopStack:Array<Int> = [];
        var memorySize:Int = native ? 256 : 30000; // Use 256 for native, 30000 for Haxe.

        // Initialize memory
        for (j in 0...memorySize) memory.push(0);

        for (i in 0...code.length) {
            var cmd = code.charAt(i);
            switch (cmd) {
                case '>':
                    pointer++;
                    if (pointer >= memorySize) throw "Pointer out of bounds";
                case '<':
                    pointer--;
                    if (pointer < 0) throw "Pointer out of bounds";
                case '+':
                    memory[pointer] = (memory[pointer] + 1) % 256;
                case '-':
                    memory[pointer] = (memory[pointer] - 1 + 256) % 256;
                case '.':
                    output += String.fromCharCode(memory[pointer]);
                case ',':
                    if (inputIndex < input.length) {
                        memory[pointer] = input.charCodeAt(inputIndex++);
                    } else {
                        memory[pointer] = 0; // EOF
                    }
                case '[':
                    if (memory[pointer] == 0) {
                        // Jump to the matching ']'
                        var depth:Int = 1;
                        while (depth > 0 && i < code.length - 1) {
                            i++;
                            if (code.charAt(i) == '[') depth++;
                            else if (code.charAt(i) == ']') depth--;
                        }
                    } else {
                        loopStack.push(i);
                    }
                case ']':
                    if (memory[pointer] != 0) {
                        if (loopStack.length == 0) throw "Unmatched ']' found";
                        i = loopStack[loopStack.length - 1];
                    } else {
                        loopStack.pop();
                    }
            }
        }

        return output;
    }
}