extends Control

var pace_server
var pace_username
var pace_password
var sessions: Array

var time: float = 0.0
var time_ticking: bool = false
var state = "before_start"

func _ready() -> void:
	if get_window().size != Vector2i(1152, 648):
		print("Wrong window size")
	
	var config = ConfigFile.new()
	var error = config.load("user://serverconfig.cfg.pace")
	if error == OK:
		pace_server = config.get_value("serverconfig", "paceserver")
		pace_username = config.get_value("serverconfig", "paceusername")
		pace_password = config.get_value("serverconfig", "pacepassword")
		var http_req = HTTPRequest.new()
		add_child(http_req)
		http_req.connect("request_completed", _on_api_get_sessions_completed)
		var auth=str("Basic ", Marshalls.utf8_to_base64(str(pace_username, ":", pace_password))) 
		var headers=["Content-Type: application/json","Authorization: "+auth]
		http_req.request(pace_server + "/api/sessions", headers)
		
		var http_req2 = HTTPRequest.new()
		add_child(http_req2)
		http_req2.connect("request_completed", _on_api_get_gold_completed)
		http_req2.request(pace_server + "/api/gold", headers)
		
		$LoginButton.text = "Switch Account"

func _on_api_get_sessions_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.new()
		if json.parse_string(body.get_string_from_utf8())["sessions"] != null:
			sessions = json.parse_string(body.get_string_from_utf8())["sessions"]
			
			var time_logs = []
			var total_time_logged = 0
			
			for session in sessions:
				time_logs.append(int(session["Length_minutes"]))
				total_time_logged += int(session["Length_minutes"])
			
			$LvlLabel.text = "Lvl " + str(round((total_time_logged + len(time_logs))/100))
	else:
		$LvlLevel.text = str(response_code) + " response code from server"

func _on_api_get_gold_completed(result, response_code, headers, body):
	var json = JSON.new()
	var gold_amount = int(json.parse_string(body.get_string_from_utf8())["gold_amount"])
	$GoldLabel.text = str(gold_amount) + " gold"

func format_time(t: float) -> String:
	var hours = int(t / 3600.0)
	var minutes = int(t / 60.0) % 60
	var seconds = int(t) % 60
	
	var sec_str = "%02d" % seconds
	var min_str = "%02d" % minutes
	var hour_str = "%d" % hours
	
	if hours > 0:
		return "%d:%s:%s" % [hour_str, min_str, sec_str]
	elif minutes > 0:
		return "%s:%s" % [min_str, sec_str]
	else:
		return "0:%s" % [sec_str]

func _process(delta: float) -> void:
	if time_ticking:
		time += delta
		$Control/TimeLabel.text = format_time(time)
	
	if state == "before_start":
		$Control/VBoxContainer/StartButton.visible = true
		$Control/VBoxContainer/PauseButton.visible = false
		$Control/VBoxContainer/StopButton.visible = false
	
	if state == "started":
		$Control/VBoxContainer/StartButton.visible = false
		$Control/VBoxContainer/PauseButton.visible = true
		$Control/VBoxContainer/StopButton.visible = true
		
		if time_ticking:
			$Control/VBoxContainer/PauseButton.text = "Pause"
		else:
			$Control/VBoxContainer/PauseButton.text = "Unpause"

func _on_start_button_pressed() -> void:
	time_ticking = true
	state = "started"

func _on_pause_button_pressed() -> void:
	if time_ticking:
		time_ticking = false
		$Control/VBoxContainer/PauseButton.text = "Unpause"
	else:
		time_ticking = true
		$Control/VBoxContainer/PauseButton.text = "Pause"

func _on_stop_button_pressed() -> void:
	Globals.time_length = round(time)
	
	time_ticking = false
	time = 0
	$Control/TimeLabel.text = format_time(time)
	
	get_tree().change_scene_to_file("res://scenes/upload_scene.tscn")

func _on_stats_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/stats_scene.tscn")

func _on_login_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/login_scene.tscn")

func _on_me_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/me_scene.tscn")
