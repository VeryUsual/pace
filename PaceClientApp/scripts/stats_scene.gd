extends Control

var pace_server
var pace_username
var pace_password
var sessions: Array

func make_minutes_minutes_and_hours(mins: int, shorthand = false) -> String:
	var hours := mins / 60
	var minutes := mins % 60
	
	if shorthand:
		return "%dh %dm" % [
			hours,
			minutes
		]
	else:
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
	sessions = json.parse_string(body.get_string_from_utf8())["sessions"]
	
	var date_dict = Time.get_datetime_dict_from_system()
	var today_formatted = "%04d-%02d-%02d" % [date_dict["year"], date_dict["month"], date_dict["day"]]
	var time_logged_today = 0
	var total_time_logged = 0
	var unix_time := Time.get_unix_time_from_datetime_dict(date_dict)
	var time_logs = []
	
	for session in sessions:
		if session["Datetime"].begins_with(today_formatted):
			time_logged_today += int(session["Length_minutes"])
	$Label.text = "Today, you've logged " + make_minutes_minutes_and_hours(time_logged_today) + "."
	
	for session in sessions:
		time_logs.append(int(session["Length_minutes"]))
		total_time_logged += int(session["Length_minutes"])
	$ColorRect/Label2.text = make_minutes_minutes_and_hours(total_time_logged, true)
	
	$ColorRect6/Label2.text = str(time_logs.max()) + " minutes"
	
	var sum = time_logs.reduce(func(a, n): return a + n)
	$ColorRect5/Label2.text = str(sum / time_logs.size()) + " minutes"
	
	var streak = 0
	while true:
		print(Time.get_date_string_from_unix_time(unix_time))
		for session in sessions:
			if session["Datetime"].begins_with(today_formatted):
				unix_time -= 86400
				streak += 1
				continue
		break
	$ColorRect2/Label2.text = str(streak) + " day(s)"

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_scene.tscn")

func _on_export_button_pressed() -> void:
	var json = JSON.new()
	DisplayServer.clipboard_set(json.stringify(sessions))
	$ExportButton.disabled = true
	$ExportButton.text = "Saved to clipboard!"
	await get_tree().create_timer(1.0).timeout
	$ExportButton.disabled = false
	$ExportButton.text = "Export Data"
