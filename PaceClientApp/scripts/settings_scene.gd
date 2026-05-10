extends Control

func _ready() -> void:
	$Panel/VBoxContainer/GoalPerDay/LineEdit.placeholder_text = str(Globals.goal_per_day)
	$Panel/VBoxContainer/GoalPerDay/LineEdit.text = str(Globals.goal_per_day)

func _on_save_button_pressed() -> void:
	if int($Panel/VBoxContainer/GoalPerDay/LineEdit.text):
		Globals.goal_per_day = int($Panel/VBoxContainer/GoalPerDay/LineEdit.text)
		get_tree().change_scene_to_file("res://scenes/main_scene.tscn")
