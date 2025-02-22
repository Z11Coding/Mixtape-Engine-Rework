package archipelago;

class BitSets {
  inline public static function remove (bits:Int, mask:Int):Int {
    return bits & ~mask;
  }
  inline public static function add(bits:Int, mask:Int):Int {
    return bits | mask;
  }
  inline public static function contains (bits :Int, mask :Int) :Bool {
    return bits & mask != 0;
  }
}