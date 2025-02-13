package yutautil;

import haxe.crypto.Base64;
import haxe.crypto.Sha256;
import haxe.io.Bytes;
// import haxe.Reflect;
import haxe.rtti.Meta;

class Secure<T> {
    private var encryptedData:String;
    private var key:String;
    private var dataType:String;

    public function new(data:T, key:String) {
        this.key = key;
        this.dataType = Type.getClassName(Type.getClass(data));
        this.encryptedData = encryptData(data);
    }

    private function encryptData(data:T):String {
        var jsonData:String = haxe.Json.stringify(data);
        var base64Data:String = Base64.encode(Bytes.ofString(jsonData));
        var scrambledData:String = scramble(base64Data, key);
        return scrambledData;
    }

    public function decryptData():T {
        var unscrambledData:String = unscramble(encryptedData, key);
        var base64Data:Bytes = Base64.decode(unscrambledData);
        var jsonData:String = base64Data.toString();
        var data:T = haxe.Json.parse(jsonData);
        return data;
    }

    private function scramble(data:String, key:String):String {
        var scrambled:Array<Int> = [];
        for (i in 0...data.length) {
            scrambled.push(data.charCodeAt(i) ^ key.charCodeAt(i % key.length));
        }
        return String.fromCharCode.apply(null, scrambled);
    }

    private function unscramble(data:String, key:String):String {
        return scramble(data, key); // Scrambling and unscrambling are symmetric
    }

    public function getType():String {
        return dataType;
    }
}