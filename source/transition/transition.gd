extends ColorRect

onready var anim_player = $anim_player;
onready var parent = $"..";

var scene_to_load;

func fade_out(dest):
	show();
	scene_to_load = dest;
	anim_player.play("fade_out");

func _on_anim_player_animation_finished(anim_name):
	if anim_name == "fade_in":
		hide();
	elif anim_name == "fade_out":
		if scene_to_load != null:
# warning-ignore:return_value_discarded
				get_tree().change_scene(scene_to_load);
