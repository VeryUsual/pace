extends Control

var gold_earned = 0
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	gold_earned = int(round((Globals.time_length/60)/5))
	$VBoxContainer/DurationLabel.text = "Duration: " + str(int(round(Globals.time_length/60)))
	if rng.randi_range(1, 26) == 2:
		gold_earned = gold_earned * 10
		$VBoxContainer/EarnedGoldLabel.text = "Earned " + str(gold_earned) + " gold with 10x BONUS!"
	elif rng.randi_range(1, 10) == 2:
		gold_earned = gold_earned * 3
		$VBoxContainer/EarnedGoldLabel.text = "Earned " + str(gold_earned) + " gold with 3x BONUS!"
	else:
		$VBoxContainer/EarnedGoldLabel.text = "Earned " + str(gold_earned) + " gold"
	var config = ConfigFile.new()
	var error = config.load("user://serverconfig.cfg.pace")
	if error == OK:
		$VBoxContainer/PaceServerInput.text = config.get_value("serverconfig", "paceserver")
		$VBoxContainer/PaceUsernameInput.text = config.get_value("serverconfig", "paceusername")
		$VBoxContainer/PacePasswordInput.text = config.get_value("serverconfig", "pacepassword")

func _on_upload_button_pressed() -> void:
	$VBoxContainer/UploadButton.disabled = true
	var http_req = HTTPRequest.new()
	add_child(http_req)
	http_req.connect("request_completed", _on_upload_completed)
	var user = $VBoxContainer/PaceUsernameInput.text
	var password = $VBoxContainer/PacePasswordInput.text
	var auth=str("Basic ", Marshalls.utf8_to_base64(str(user, ":", password))) 
	var headers=["Content-Type: application/json","Authorization: "+auth]
	var error = http_req.request($VBoxContainer/PaceServerInput.text + "/api/session/create?length=" + str(int(round(Globals.time_length/60))) + "&desc=" + $VBoxContainer/SessionDescInput.text.uri_encode(), headers)
	
func _on_upload_completed(result, response_code, headers, body):
	if response_code == 200:
		var http_req = HTTPRequest.new()
		add_child(http_req)
		http_req.connect("request_completed", _on_gold_update_completed)
		var user = $VBoxContainer/PaceUsernameInput.text
		var password = $VBoxContainer/PacePasswordInput.text
		var auth=str("Basic ", Marshalls.utf8_to_base64(str(user, ":", password))) 
		var webreqheaders=["Content-Type: application/json","Authorization: "+auth]
		var error = http_req.request($VBoxContainer/PaceServerInput.text + "/api/gold/add?amount=" + str(gold_earned), webreqheaders)
	else:
		$VBoxContainer/UploadButton.text = "Upload Failed, Try Again"
		$VBoxContainer/UploadButton.disabled = false

func _on_gold_update_completed(result, response_code, headers, body):
	print("upload done")
	print(body.get_string_from_utf8())
	if response_code == 200:
		$VBoxContainer/UploadButton.text = "Upload Successful"
		
		var config = ConfigFile.new()
		config.set_value("serverconfig", "paceserver", $VBoxContainer/PaceServerInput.text)
		config.set_value("serverconfig", "paceusername", $VBoxContainer/PaceUsernameInput.text)
		config.set_value("serverconfig", "pacepassword", $VBoxContainer/PacePasswordInput.text)
		config.save("user://serverconfig.cfg.pace")
		
		await get_tree().create_timer(0.4).timeout
		get_tree().change_scene_to_file("res://scenes/main_scene.tscn")
	else:
		print("Gold Upload Failed")
		get_tree().change_scene_to_file("res://scenes/main_scene.tscn")
