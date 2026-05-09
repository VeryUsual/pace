extends Control

func _ready() -> void:
	print(Globals.time_length)
	var http_req = HTTPRequest.new()
	add_child(http_req)
	http_req.connect("request_completed", _on_upload_completed)
	var user = "admin"
	var password = "1234"
	var auth=str("Basic ", Marshalls.utf8_to_base64(str(user, ":", password))) 
	var headers=["Content-Type: application/json","Authorization: "+auth]
	var error = http_req.request("http://localhost:8080/api/session/create?length=" + str(int(round(Globals.time_length/60))) + "&desc=Description", headers)
	
func _on_upload_completed(result, response_code, headers, body):
	print("upload done")
	print(body.get_string_from_utf8())
