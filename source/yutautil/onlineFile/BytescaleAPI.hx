package yutautil.onlineFile;

import haxe.Http;

class BytescaleAPI {
    private var apiKey:String;
    private var baseUrl:String = "https://api.bytescale.com/v1";

    public function new(apiKey:String) {
        this.apiKey = apiKey;
    }

    // Will be fleshed out later. This is a placeholder for the actual API call. A different class is used for
    // anti-virus scanning. DO NOT TOUCH THIS YET.

    public function uploadFile(filePath:String, onComplete:Dynamic->Void, onError:Dynamic->Void):Void {
        var url = baseUrl + "/upload";
        var http = new Http(url);
        
        http.setHeader("Authorization", "Bearer " + apiKey);
        http.setHeader("Content-Type", "multipart/form-data");
        
        // Assuming filePath is a valid path to the file to upload
        var boundary = "------------------------" + Std.string(Math.random());
        var fileContent = sys.io.File.getBytes(filePath);
        var fileName = filePath.split("/").pop();
        var body = "--" + boundary + "\r\n" +
                   "Content-Disposition: form-data; name=\"file\"; filename=\"" + fileName + "\"\r\n" +
                   "Content-Type: application/octet-stream\r\n\r\n" +
                   fileContent.toString() + "\r\n" +
                   "--" + boundary + "--\r\n";

        http.setHeader("Content-Type", "multipart/form-data; boundary=" + boundary);

        // Post the file content
        http.setPostData(body);
        http.request(true);
        
        http.onData = function(response:String) {
            onComplete(response);
        };

        http.onError = function(error:String) {
            onError(error);
        };
    }

    public function deleteFile(fileId:String, onComplete:Dynamic->Void, onError:Dynamic->Void):Void {
        var url = baseUrl + "/files/" + fileId;
        var http = new Http(url);

        http.setHeader("Authorization", "Bearer " + apiKey);
        http.request(false);

        http.onData = function(response:String) {
            onComplete(response);
        };

        http.onError = function(error:String) {
            onError(error);
        };
    }
}

