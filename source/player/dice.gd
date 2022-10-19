extends Node2D

onready var rot_timer = $rotation;
onready var state = $state;
onready var state_tween = $state/modulate;

onready var face_1 = $'1';
onready var face_2 = $'2';
onready var face_3 = $'3';
onready var face_4 = $'4';
onready var face_5 = $'5';
onready var face_6 = $'6';
onready var face_7 = $'7';
onready var face_8 = $'8';
onready var face_9 = $'9';

var rot_type := {1: {'left': 'left_rotate_left',
					 'up': 'top_rotate_up',
					 'right': 'left_rotate_right',
					 'down': 'top_rotate_down'},
				
				 2: {'left': 'middle_rotate_left',
					 'up': 'top_rotate_up',
					 'right': 'middle_rotate_right',
					 'down': 'top_rotate_down'},
				
				 3: {'left': 'right_rotate_left',
					 'up': 'top_rotate_up',
					 'right': 'right_rotate_right',
					 'down': 'top_rotate_down'},
				
				 4: {'left': 'left_rotate_left',
					 'up': 'middle_rotate_up',
					 'right': 'left_rotate_right',
					 'down': 'middle_rotate_down'},
				
				 5: {'left': 'middle_rotate_left',
					 'up': 'middle_rotate_up',
					 'right': 'middle_rotate_right',
					 'down': 'middle_rotate_down'},
				
				 6: {'left': 'right_rotate_left',
					 'up': 'middle_rotate_up',
					 'right': 'right_rotate_right',
					 'down': 'middle_rotate_down'},
				
				 7: {'left': 'left_rotate_left',
					 'up': 'bottom_rotate_up',
					 'right': 'left_rotate_right',
					 'down': 'bottom_rotate_down'},
				
				 8: {'left': 'middle_rotate_left',
					 'up': 'bottom_rotate_up',
					 'right': 'middle_rotate_right',
					 'down': 'bottom_rotate_down'},
				
				 9: {'left': 'right_rotate_left',
					 'up': 'bottom_rotate_up',
					 'right': 'right_rotate_right',
					 'down': 'bottom_rotate_down'}};

var rotate_times;
var fade_state := false;
var stance_list := ['owl', 'tiger', 'lion', 'turtle'];

func _ready():
	randomize();

func change_stance():
	rotate_times = 5 + randi()%15;
	rotate_times -= 1;
	rot_timer.start(0.17);
	rot();

func _on_rotation_timeout():
	if rotate_times > 0:
		rotate_times -= 1;
		rot_timer.start(0.17);
		rot();
	else:
		state.texture = load('res://player/art/dice/stances/' + stance_list[randi() % stance_list.size()] + '.png');
		state_tween.interpolate_property(state, 'modulate', Color(1, 1, 1, 0), Color(1, 1, 1, 1), 1, Tween.TRANS_LINEAR, Tween.EASE_OUT);
		state_tween.start();
		fade_state = true;

func _on_modulate_tween_completed(object, key):
	if object == state and key == ':modulate':
		if fade_state:
			state_tween.interpolate_property(state, 'modulate', Color(1, 1, 1, 1), Color(1, 1, 1, 0), 1, Tween.TRANS_LINEAR, Tween.EASE_OUT, 3);
			state_tween.start();
			fade_state = false;

func rot():
	var types := [['R1', 'left'],
				  ['R1', 'right'],
				  ['R2', 'left'],
				  ['R2', 'right'],
				  ['R3', 'left'],
				  ['R3', 'right'],
				  ['C1', 'up'],
				  ['C1', 'down'],
				  ['C2', 'up'],
				  ['C2', 'down'],
				  ['C3', 'up'],
				  ['C3', 'down']];
	var pick = randi() % types.size();
	_on_practice3_rotate_dice(types[pick][0], types[pick][1]);

func _on_practice3_rotate_dice(grid_info, dir):
	var to_rotate := [];
	match(grid_info[0]):
		'R':
			match(int(grid_info[1])):
				1:
					to_rotate = [1, 2, 3];
					
				2:
					to_rotate = [4, 5, 6];
					
				3:
					to_rotate = [7, 8, 9];
					
			
		'C':
			match(int(grid_info[1])):
				1:
					to_rotate = [1, 4, 7];
					
				2:
					to_rotate = [2, 5, 8];
					
				3:
					to_rotate = [3, 6, 9];
					
	for i in to_rotate:
		get('face_' + String(i)).play(rot_type[i][dir]);

func _on_1_animation_finished():
	face_1.play('idle');

func _on_2_animation_finished():
	face_2.play('idle');

func _on_3_animation_finished():
	face_3.play('idle');

func _on_4_animation_finished():
	face_4.play('idle');

func _on_5_animation_finished():
	face_5.play('idle');

func _on_6_animation_finished():
	face_6.play('idle');

func _on_7_animation_finished():
	face_7.play('idle');

func _on_8_animation_finished():
	face_8.play('idle');

func _on_9_animation_finished():
	face_9.play('idle');
