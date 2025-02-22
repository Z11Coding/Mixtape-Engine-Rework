package backend;

typedef DWORD = Int;
typedef LONG = Int;
typedef BOOL = Int;
typedef BYTE = Int;

class HexCode {
    public var value: String;

    public function new(value: String) {
        if (!isValidHex(value)) {
            throw "Invalid Hex Code";
        }
        this.value = value;
    }

    private function isValidHex(value: String): Bool {
        return ~/^#?([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$/.match(value);
    }

    public function toInt(): Int {
        return Std.parseInt(value.replace("#", "0x"));
    }
}

class RGB {
    public var r: Int;
    public var g: Int;
    public var b: Int;

    public function new(r: Int, g: Int, b: Int) {
        this.r = r;
        this.g = g;
        this.b = b;
    }

    public function toHex(): String {
        return StringTools.hex(r, 2) + StringTools.hex(g, 2) + StringTools.hex(b, 2);
    }
}

class Binary {
    public var value: String;

    public function new(value: String) {
        if (!isValidBinary(value)) {
            throw "Invalid Binary String";
        }
        this.value = value;
    }

    private function isValidBinary(value: String): Bool {
        return ~/^[01]+$/.match(value);
    }

    public function toInt(): Int {
        return Std.parseInt(value, 2);
    }
}

class DWORDType {
    public var value: DWORD;

    public function new(value: Int) {
        if (!isValidDWORD(value)) {
            throw "Invalid DWORD value";
        }
        this.value = value;
    }

    private function isValidDWORD(value: Int): Bool {
        return value >= 0 && value <= 0xFFFFFFFF;
    }

    public function toHex(): String {
        return StringTools.hex(value, 8);
    }
}

class LONGType {
    public var value: LONG;

    public function new(value: Int) {
        if (!isValidLONG(value)) {
            throw "Invalid LONG value";
        }
        this.value = value;
    }

    private function isValidLONG(value: Int): Bool {
        return value >= -2147483648 && value <= 2147483647;
    }

    public function toHex(): String {
        return StringTools.hex(value, 8);
    }
}

class BOOLType {
    public var value: BOOL;

    public function new(value: Int) {
        if (!isValidBOOL(value)) {
            throw "Invalid BOOL value";
        }
        this.value = value;
    }

    private function isValidBOOL(value: Int): Bool {
        return value == 0 || value == 1;
    }

    public function toString(): String {
        return value == 1 ? "TRUE" : "FALSE";
    }
}