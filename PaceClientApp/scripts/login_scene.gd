extends Control

func _ready() -> void:
	var config = ConfigFile.new()
	var error = config.load("user://serverconfig.cfg.pace")
	if error == OK:
		$VBoxContainer/PaceServerInput.text = config.get_value("serverconfig", "paceserver")
		$VBoxContainer/PaceUsernameInput.text = config.get_value("serverconfig", "paceusername")
		$VBoxContainer/PacePasswordInput.text = config.get_value("serverconfig", "pacepassword")

func _on_login_button_pressed() -> void:
	$VBoxContainer/LoginButton.disabled = true
	var http_req = HTTPRequest.new()
	add_child(http_req)
	http_req.connect("request_completed", _on_request_completed)
	var user = $VBoxContainer/PaceUsernameInput.text
	var password = $VBoxContainer/PacePasswordInput.text
	var auth=str("Basic ", Marshalls.utf8_to_base64(str(user, ":", password))) 
	var headers=["Content-Type: application/json","Authorization: "+auth]
	var error = http_req.request($VBoxContainer/PaceServerInput.text + "/api/sessions", headers)

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		$VBoxContainer/LoginButton.text = "Login Successful"
		
		var config = ConfigFile.new()
		config.set_value("serverconfig", "paceserver", $VBoxContainer/PaceServerInput.text)
		config.set_value("serverconfig", "paceusername", $VBoxContainer/PaceUsernameInput.text)
		config.set_value("serverconfig", "pacepassword", $VBoxContainer/PacePasswordInput.text)
		config.save("user://serverconfig.cfg.pace")
		
		await get_tree().create_timer(0.4).timeout
		get_tree().change_scene_to_file("res://scenes/main_scene.tscn")
	else:
		$VBoxContainer/LoginButton.text = "Login Failed, Try Again"
		$VBoxContainer/LoginButton.disabled = false
