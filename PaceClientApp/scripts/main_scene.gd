extends Control

var time: float = 0.0
var time_ticking: bool = false
var state = "before_start"

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
		$TimeLabel.text = format_time(time)
	
	if state == "before_start":
		$VBoxContainer/StartButton.visible = true
		$VBoxContainer/PauseButton.visible = false
		$VBoxContainer/StopButton.visible = false
	
	if state == "started":
		$VBoxContainer/StartButton.visible = false
		$VBoxContainer/PauseButton.visible = true
		$VBoxContainer/StopButton.visible = true
		
		if time_ticking:
			$VBoxContainer/PauseButton.text = "Pause"
		else:
			$VBoxContainer/PauseButton.text = "Unpause"

func _on_start_button_pressed() -> void:
	time_ticking = true
	state = "started"

func _on_pause_button_pressed() -> void:
	if time_ticking:
		time_ticking = false
		$VBoxContainer/PauseButton.text = "Unpause"
	else:
		time_ticking = true
		$VBoxContainer/PauseButton.text = "Pause"

func _on_stop_button_pressed() -> void:
	Globals.time_length = round(time)
	
	time_ticking = false
	time = 0
	$TimeLabel.text = format_time(time)
	
	get_tree().change_scene_to_file("res://scenes/upload_scene.tscn")

func _on_stats_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/stats_scene.tscn")
