extends Node2D

signal rotate_dice(grid_info, dir);

var grid_num;
var dir;

func _on_grid_num_text_entered(new_text):
	grid_num = new_text;

func _on_dir_text_entered(new_text):
	dir = new_text;

func _on_Button_pressed():
	emit_signal("rotate_dice", grid_num, dir);

