extends Control

var pace_server
var pace_username
var pace_password

func _ready() -> void:
	$StatsLabel.visible = false
	
	var config = ConfigFile.new()
	var error = config.load("user://serverconfig.cfg.pace")
	if error == OK:
		pace_server = config.get_value("serverconfig", "paceserver")
		pace_username = config.get_value("serverconfig", "paceusername")
		pace_password = config.get_value("serverconfig", "pacepassword")
		var http_req = HTTPRequest.new()
		add_child(http_req)
		http_req.connect("request_completed", _on_got_purchases)
		var auth=str("Basic ", Marshalls.utf8_to_base64(str(pace_username, ":", pace_password))) 
		var headers=["Content-Type: application/json","Authorization: "+auth]
		http_req.request(pace_server + "/api/purchases", headers)
	else:
		get_tree().change_scene_to_file("res://scenes/main_scene.tscn")

func _on_got_purchases(result, response_code, headers, body):
	if response_code == 200:
		var amounts = {
			"hp": 0,
			"speed": 0,
			"attack": 0,
			"defense": 0
		}
		
		var json = JSON.new()
		if json.parse_string(body.get_string_from_utf8())["purchases"] != null:
			var purchases: Array = json.parse_string(body.get_string_from_utf8())["purchases"]
			for purchase in purchases:
				amounts[purchase["Item"]] += 1
		else:
			$StatsLabel.visible = true
			return
		
		$StatsLabel.text = """HP: """ + str(amounts["hp"]) + """
Speed: """ + str(amounts["speed"]) + """
Attack: """ + str(amounts["attack"]) + """
Defense: """ + str(amounts["defense"]) + """

Price: 5 gold
for each upgrade"""
		$StatsLabel.visible = true
	else:
		get_tree().change_scene_to_file("res://scenes/main_scene.tscn")

func _on_x_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_scene.tscn")

func _on_hp_pressed() -> void:
	var config = ConfigFile.new()
	var error = config.load("user://serverconfig.cfg.pace")
	if error == OK:
		pace_server = config.get_value("serverconfig", "paceserver")
		pace_username = config.get_value("serverconfig", "paceusername")
		pace_password = config.get_value("serverconfig", "pacepassword")
		var http_req = HTTPRequest.new()
		add_child(http_req)
		http_req.connect("request_completed", _reload)
		var auth=str("Basic ", Marshalls.utf8_to_base64(str(pace_username, ":", pace_password))) 
		var headers=["Content-Type: application/json","Authorization: "+auth]
		http_req.request(pace_server + "/api/purchase?item=hp&price=5", headers)

func _on_speed_pressed() -> void:
	var config = ConfigFile.new()
	var error = config.load("user://serverconfig.cfg.pace")
	if error == OK:
		pace_server = config.get_value("serverconfig", "paceserver")
		pace_username = config.get_value("serverconfig", "paceusername")
		pace_password = config.get_value("serverconfig", "pacepassword")
		var http_req = HTTPRequest.new()
		add_child(http_req)
		http_req.connect("request_completed", _reload)
		var auth=str("Basic ", Marshalls.utf8_to_base64(str(pace_username, ":", pace_password))) 
		var headers=["Content-Type: application/json","Authorization: "+auth]
		http_req.request(pace_server + "/api/purchase?item=speed&price=5", headers)

func _on_attack_pressed() -> void:
	var config = ConfigFile.new()
	var error = config.load("user://serverconfig.cfg.pace")
	if error == OK:
		pace_server = config.get_value("serverconfig", "paceserver")
		pace_username = config.get_value("serverconfig", "paceusername")
		pace_password = config.get_value("serverconfig", "pacepassword")
		var http_req = HTTPRequest.new()
		add_child(http_req)
		http_req.connect("request_completed", _reload)
		var auth=str("Basic ", Marshalls.utf8_to_base64(str(pace_username, ":", pace_password))) 
		var headers=["Content-Type: application/json","Authorization: "+auth]
		http_req.request(pace_server + "/api/purchase?item=attack&price=5", headers)

func _on_defense_pressed() -> void:
	var config = ConfigFile.new()
	var error = config.load("user://serverconfig.cfg.pace")
	if error == OK:
		pace_server = config.get_value("serverconfig", "paceserver")
		pace_username = config.get_value("serverconfig", "paceusername")
		pace_password = config.get_value("serverconfig", "pacepassword")
		var http_req = HTTPRequest.new()
		add_child(http_req)
		http_req.connect("request_completed", _reload)
		var auth=str("Basic ", Marshalls.utf8_to_base64(str(pace_username, ":", pace_password))) 
		var headers=["Content-Type: application/json","Authorization: "+auth]
		http_req.request(pace_server + "/api/purchase?item=defense&price=5", headers)

func _reload(result, response_code, headers, body):
	if response_code == 400:
		$MeLabel.text = "Insufficent Balance"
		await get_tree().create_timer(0.5).timeout
		$MeLabel.text = "Me"
	else:
		reload()

func reload():
	print()
