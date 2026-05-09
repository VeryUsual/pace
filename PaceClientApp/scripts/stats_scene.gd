extends Control

var pace_server
var pace_username
var pace_password

func make_minutes_minutes_and_hours(mins: int) -> String:
	var hours := mins / 60
	var minutes := mins % 60
	return "%d hour%s, %d minute%s" % [
		hours,
		"" if hours == 1 else "s",
		minutes,
		"" if minutes == 1 else "s"
	]

func _ready() -> void:
	var config = ConfigFile.new()
	var error = config.load("user://serverconfig.cfg.pace")
	if error == OK:
		pace_server = config.get_value("serverconfig", "paceserver")
		pace_username = config.get_value("serverconfig", "paceusername")
		pace_password = config.get_value("serverconfig", "pacepassword")
	else:
		get_tree().change_scene_to_file("res://scenes/main_scene.tscn")
		return
	var http_req = HTTPRequest.new()
	add_child(http_req)
	http_req.connect("request_completed", _on_api_get_sessions_completed)
	var auth=str("Basic ", Marshalls.utf8_to_base64(str(pace_username, ":", pace_password))) 
	var headers=["Content-Type: application/json","Authorization: "+auth]
	http_req.request(pace_server + "/api/sessions", headers)

func _on_api_get_sessions_completed(result, response_code, headers, body):
	var json = JSON.new()
	var sessions: Array = json.parse_string(body.get_string_from_utf8())["sessions"]
	
	var date_dict = Time.get_datetime_dict_from_system()
	var today_formatted = "%04d-%02d-%02d" % [date_dict["year"], date_dict["month"], date_dict["day"]]
	var time_logged_today = 0
	
	for session in sessions:
		if session["Datetime"].begins_with(today_formatted):
			time_logged_today += int(session["Length_minutes"])
	
	$Label.text = "Today, you've logged " + make_minutes_minutes_and_hours(time_logged_today) + "."

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_scene.tscn")
