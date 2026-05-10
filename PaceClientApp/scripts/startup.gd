extends Control

var pace_server = ""

func _ready() -> void:
	$ColorRect.visible = false
	
	var config = ConfigFile.new()
	var error = config.load("user://serverconfig.cfg.pace")
	if error == OK:
		pace_server = config.get_value("serverconfig", "paceserver")
		var http_req = HTTPRequest.new()
		add_child(http_req)
		http_req.connect("request_completed", _on_api_get_users_completed)
		http_req.request(pace_server + "/api/users")
	else:
		get_tree().change_scene_to_file("res://scenes/main_scene.tscn")

func _on_api_get_users_completed(result, response_code, headers, body):
	if response_code == 200:
		get_tree().change_scene_to_file("res://scenes/main_scene.tscn")
	else:
		if pace_server != "":
			OS.shell_open(pace_server)
			get_tree().change_scene_to_file("res://scenes/login_scene.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/login_scene.tscn")

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/login_scene.tscn")

func _on_show_color_rect_timeout() -> void:
	$ColorRect.visible = true
