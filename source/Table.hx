
class DTable<T> {
    private var table:Array<Array<T>>;
    private var rows:Int;
    private var cols:Int;

    public function new(rows:Int, cols:Int) {
        this.rows = rows;
        this.cols = cols;
        table = [];
        for (i in 0...Std.parseInt(rows)) {
            table.push(new Array<T>(cols));
        }
    }

    public function fromArray(array:Array<Array<T>>):Void {
        this.rows = array.length;
        this.cols = array[0].length;
        this.table = array;
    }

    public function getCell(row:Int, col:Int):T {
        return table[row][col];
    }

    public function setCell(row:Int, col:Int, value:T):Void {
        table[row][col] = value;
    }

    public function getByLinearIndex(index:Int):T {
        var row = index / cols;
        var col = index % cols;
        return table[row][col];
    }

    public function getRow(row:Int):Array<T> {
        return table[row];
    }

    public function getColumn(col:Int):Array<T> {
        var column:Array<T> = [];
        for (i in 0...Std.parseInt(rows)) {
            column.push(table[i][col]);
        }
        return column;
    }

    public function toString():String {
        var result = "";
        for (row in table) {
            result += row.join(", ") + "\n";
        }
        return result;
    }
    public function fromString(str:String):Void {
        var rows:Array<String> = str.split("\n");
        this.rows = rows.length;
        this.cols = rows[0].split(", ").length;
        table = [];
        for (i in 0...rows.length) {
            table.push(rows[i].split(", "));
        }
    }

    public function toArray():Array<Array<T>> {
        return table;
    }

    public function fromMap(map:Map<String, Dynamic>):Void {
        this.rows = map.get("rows");
        this.cols = map.get("cols");
        table = [];
        for (i in 0...rows) {
            table.push(map.get("row_" + i));
        }
    }

    public function toMap():Map<String, Dynamic> {
        var map:Map<String, Dynamic> = new Map<String, Dynamic>();
        map.set("rows", rows);
        map.set("cols", cols);
        for (i in 0...rows) {
            map.set("row_" + i, table[i]);
        }
        return map;
    }

    public function fromObject(obj:Dynamic):Void {
        this.rows = obj.rows;
        this.cols = obj.cols;
        table = [];
        for (i in 0...rows) {
            table.push(obj["row_" + i]);
        }
    }

    public function toObject():Dynamic {
        var obj:Dynamic = { rows: rows, cols: cols };
        for (i in 0...rows) {
            obj["row_" + i] = table[i];
        }
        return obj;
    }
}
@:allow(HTable)
class Cell<T> {
    public var data:Array<T>;
    public var type:String;
    public var rawInfo:String;
    public var byteData:String;
    public var addressInfo:String;
    public var internalVars:Dynamic;

    public function new(value:T) {
        this.data = [value];
        this.type = Type.getClassName(Type.getClass(value));
        this.rawInfo = Std.string(value);
        this.byteData = haxe.crypto.Base64.encode(haxe.io.Bytes.ofString(Std.string(value)));
        this.addressInfo = "Address: " + Std.string(this);
        this.internalVars = {};
    }

    public function getValue():T {
        return data[0];
    }

    public function setValue(value:T):Void {
        data[0] = value;
        this.rawInfo = Std.string(value);
        this.byteData = haxe.crypto.Base64.encode(haxe.io.Bytes.ofString(Std.string(value)));
    }
}

class HTable<T> {
    private var table:Array<Array<Cell<T>>>;
    private var rows:Int;
    private var cols:Int;

    public function new(rows:Int, cols:Int) {
        this.rows = rows;
        this.cols = cols;
        table = [];
        for (i in 0...rows) {
            var row:Array<Cell<T>> = [];
            for (j in 0...cols) {
                row.push(new Cell<T>(null));
            }
            table.push(row);
        }
    }

    public function fromArray(array:Array<Array<T>>):Void {
        this.rows = array.length;
        this.cols = array[0].length;
        this.table = [];
        for (i in 0...rows) {
            var row:Array<Cell<T>> = [];
            for (j in 0...cols) {
                row.push(new Cell<T>(array[i][j]));
            }
            table.push(row);
        }
    }

    public function getCell(row:Int, col:Int):Cell<T> {
        return table[row][col];
    }

    public function setCell(row:Int, col:Int, value:T):Void {
        table[row][col].setValue(value);
    }

    public function getByLinearIndex(index:Int):Cell<T> {
        var row = index / cols;
        var col = index % cols;
        return table[row][col];
    }

    public function getRow(row:Int):Array<Cell<T>> {
        return table[row];
    }

    public function getColumn(col:Int):Array<Cell<T>> {
        var column:Array<Cell<T>> = [];
        for (i in 0...rows) {
            column.push(table[i][col]);
        }
        return column;
    }

    public function toString():String {
        var result = "";
        for (row in table) {
            for (cell in row) {
                result += cell.getValue() + ", ";
            }
            result = result.substr(0, result.length - 2) + "\n";
        }
        return result;
    }

    public function fromString(str:String):Void {
        var rows:Array<String> = str.split("\n");
        this.rows = rows.length;
        this.cols = rows[0].split(", ").length;
        table = [];
        for (i in 0...rows.length) {
            var row:Array<Cell<T>> = [];
            var values:Array<String> = rows[i].split(", ");
            for (j in 0...values.length) {
                row.push(new Cell<T>(cast values[j] : DTable.T));
            }
            table.push(row);
        }
    }

    public function toArray():Array<Array<T>> {
        var array:Array<Array<T>> = [];
        for (row in table) {
            var arrRow:Array<T> = [];
            for (cell in row) {
                arrRow.push(cell.getValue());
            }
            array.push(arrRow);
        }
        return array;
    }

    public function fromMap(map:Map<String, Dynamic>):Void {
        this.rows = map.get("rows");
        this.cols = map.get("cols");
        table = [];
        for (i in 0...rows) {
            var row:Array<Cell<T>> = [];
            for (j in 0...cols) {
                row.push(new Cell<T>(map.get("row_" + i + "_col_" + j)));
            }
            table.push(row);
        }
    }

    public function toMap():Map<String, Dynamic> {
        var map:Map<String, Dynamic> = new Map<String, Dynamic>();
        map.set("rows", rows);
        map.set("cols", cols);
        for (i in 0...rows) {
            for (j in 0...cols) {
                map.set("row_" + i + "_col_" + j, table[i][j].getValue());
            }
        }
        return map;
    }

    public function fromObject(obj:Dynamic):Void {
        this.rows = obj.rows;
        this.cols = obj.cols;
        table = [];
        for (i in 0...rows) {
            var row:Array<Cell<T>> = [];
            for (j in 0...cols) {
                row.push(new Cell<T>(obj["row_" + i + "_col_" + j]));
            }
            table.push(row);
        }
    }

    public function toObject():Dynamic {
        var obj:Dynamic = { rows: rows, cols: cols };
        for (i in 0...rows) {
            for (j in 0...cols) {
                obj["row_" + i + "_col_" + j] = table[i][j].getValue();
            }
        }
        return obj;
    }
}