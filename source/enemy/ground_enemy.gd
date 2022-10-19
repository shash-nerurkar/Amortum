extends KinematicBody2D

var bullet = preload('res://bullet/enemy_bullet.tscn');

var bone_scene = preload('res://enemy/elements/bone.tscn');
var muzzle_scene = preload('res://enemy/elements/muzzle.tscn');
var laser_scene = preload('res://enemy/elements/laser_ray.tscn');
var melee_scene = preload('res://enemy/elements/melee_coll.tscn');

signal on_free
signal laser_done

onready var player;
onready var collision = $collision;
onready var state_label = $state;
onready var enemy_container = $'..';
onready var attack_timer = $attack_timer;

onready var sight = $sight;
onready var sight_floor = $sight/floor;
onready var sight_torso = $sight/torso;
onready var sight_face = $sight/face;

onready var muzzle;

onready var melee_coll;

onready var laser_ray;
onready var laser_line;
onready var laser_tween;

onready var attack_particles;

var health := 20;
var knockback_dir := Vector2(0, 20);
var move_dir_x := -1;

var vel := Vector2(0, 20);
var speed := 30;
var gravity = 20;

var STATE;
var STATE_LOCK = true;

var jump_mul := 1.0;
var jump_obs;
var jump_speed := 300;

var attack_type;
var bullet_type;
var attack_range;
var attack_class;
var enemy_body_type := '';

func init(char_list, at_class, at_type = ''):
	
	var limb_array = [head, right_arm, left_arm, torso, right_leg, left_leg];
	
	attack_class = at_class;
	
	match(attack_class):
		'shoot':
			
			muzzle = muzzle_scene.instance();
			left_arm.add_child(muzzle);
			attack_particles = muzzle.get_node('particles');
			
			attack_type = at_type;
			
			var bullet_type_dict := {'shotgun': 'shotgun_bullet',
									 'pulse': 'pulse_bullet',
									 'sniper': 'sniper_bullet'};
			bullet_type = bullet_type_dict[attack_type];
			
			var attack_range_dict := {'shotgun': 200,
									  'pulse': 300,
									  'sniper': 700};
			attack_range = attack_range_dict[attack_type];
			
		'laser':
			
			laser_ray = laser_scene.instance();
			left_arm.add_child(laser_ray);
			laser_line = laser_ray.get_node('Line2D');
			laser_tween = laser_ray.get_node('laser');
			laser_tween.connect("tween_all_completed", self, '_on_laser_tween_all_completed')
			
			var attack_type_array := ['laser'];
			attack_type = attack_type_array[randi() % attack_type_array.size()];
			
			var attack_range_dict := {'laser': 1000};
			attack_range = attack_range_dict[attack_type];
			
		'melee':
			
			melee_coll = melee_scene.instance();
			left_arm.add_child(melee_coll);
			melee_coll.position = Vector2(6.5, 12.5);
			melee_coll.connect("body_entered", self, '_on_melee_coll_body_entered');
			
			var attack_type_array := ['melee'];
			attack_type = attack_type_array[randi() % attack_type_array.size()];
			
			var attack_range_dict := {'melee': 100};
			attack_range = attack_range_dict[attack_type];
	
	var limb_index = -1;
	var current_limb = limb_array[limb_index];
	for i in char_list.length():
		if char_list[i] == '\t' or char_list[i] == ' ': 
			continue; 
		elif i == 5:
			break;
		limb_index += 1;
		current_limb = limb_array[limb_index];
		current_limb.text = char_list[i];
	while limb_index < 5:
		limb_index += 1;
		current_limb = limb_array[limb_index];
		current_limb.text = char(65 + randi()%26);
	
	var sb = StyleBoxFlat.new();
	sb.border_width_bottom = 0;
	sb.bg_color.a = 0;
	for label in limb_array:
		label.add_stylebox_override('normal', sb);
	
	match(enemy_body_type):
		'':
			var dest_pos = [Vector2(-6, -33), Vector2(-11, -14), Vector2(2, -15), Vector2(-5, -13), Vector2(-9, 5), Vector2(-3, 5)];
			var i := 0;
			for node in limb_array:
				limb_array[i].rect_position = dest_pos[i];
				limb_array[i].rect_rotation = 0;
				i += 1;
			torso.modulate = Color(0.7, 0.7, 0.7);
	
	STATE = 'SPAWN';
	STATE_LOCK = false;
	show();
	set_physics_process(true);

func _ready():
	set_physics_process(false);

# warning-ignore:unused_argument
func _physics_process(delta):
	$TextureProgress.value = 1 - attack_timer.get_time_left();
# warning-ignore:narrowing_conversion
	move_dir_x = sign(player.position.x - position.x);
	if STATE_LOCK:
		choose_state();
	match(STATE):
		'SPAWN':
			play('idle' + enemy_body_type, true);
			vel.x = 5;
			if not is_on_floor():
				vel.y += gravity;
				vel.y = clamp(vel.y, -300, 300);
			else:
				vel.y = 20;
				STATE_LOCK = true;
# warning-ignore:return_value_discarded
			move_and_slide(vel, Vector2(0, -1));
		'IDLE':
			state_label.text = 'SHILLING';
			play('idle' + enemy_body_type, true);
			call('flip' + enemy_body_type, move_dir_x);
			vel.x = 0;
			if is_on_floor():
				vel.y = 20;
			else:
				vel.y += 20 if vel.y < 300 else 0;
# warning-ignore:return_value_discarded
			move_and_slide(vel, Vector2(0, -1));
		'MOVE':
			sight.cast_to = Vector2(move_dir_x*22, 0);
			sight_floor.position = Vector2(move_dir_x*22, 0);
			sight_torso.position = Vector2(move_dir_x*22, 0);
			sight_face.position = Vector2(move_dir_x*22, -22);
			if sight.is_colliding():
				if sight.get_collider().is_in_group('obstacle'):
					jump(sight);
			elif sight_torso.is_colliding():
				if sight_torso.get_collider().is_in_group('obstacle'):
					jump(sight_torso);
			elif sight_face.is_colliding():
				if sight_face.get_collider().is_in_group('obstacle'):
					jump(sight_face);
			elif not sight_floor.is_colliding():
				jump(sight_floor);
			else:
				play('run' + enemy_body_type, true);
				call('flip' + enemy_body_type, move_dir_x);
				state_label.text = 'APPROACHING PLAYER';
				vel.x = move_dir_x*speed;
				if is_on_floor():
					vel.y = 20;
				else:
					vel.y += 20 if vel.y < 300 else 0;
# warning-ignore:return_value_discarded
			move_and_slide(vel, Vector2(0, -1));
		'JUMP':
			state_label.text = 'JUMPING';
			if not is_on_floor():
				vel.y += gravity;
				vel.y = clamp(vel.y, -300, 300);
			else:
				play('jump_anim_revert' + enemy_body_type, true);
				vel.y = 20;
				STATE_LOCK = true;
# warning-ignore:return_value_discarded
			move_and_slide(vel, Vector2(0, -1));
		'ATTACK':
			state_label.text = 'INITIATING ATTACK';
			if attack_timer.is_stopped():
				play(attack_type, false);
			else:
				play('idle', true);
			call('flip' + enemy_body_type, move_dir_x);
			vel.x = 0;
			if is_on_floor():
				vel.y = 20;
			else:
				vel.y += 20 if vel.y < 300 else 0;
# warning-ignore:return_value_discarded
			move_and_slide(vel, Vector2(0, -1));
		'ATTACKING':
			state_label.text = 'ATTACKING';
			vel.x = 0;
			if is_on_floor():
				vel.y = 20;
			else:
				vel.y += 20 if vel.y < 300 else 0;
# warning-ignore:return_value_discarded
			move_and_slide(vel, Vector2(0, -1));
		'CC':
			state_label.text = 'KNOCKED BACK';
# warning-ignore:return_value_discarded
			move_and_slide(knockback_dir);
		'DEATH':
			state_label.text = 'DYING';
			vel.x = 0;
			if is_on_floor():
				vel.y = 20;
			else:
				vel.y += 20 if vel.y < 300 else 0;
# warning-ignore:return_value_discarded
			move_and_slide(vel, Vector2(0, -1));

func jump(ray):
	play('jump_anim' + enemy_body_type, true);
	if ray.get_collider() == jump_obs:
		jump_mul += 1.0;
	else:
		jump_mul = 1.0;
	jump_obs = ray.get_collider();
	vel.y = -jump_speed*jump_mul;
	vel.x = move_dir_x*jump_speed;
	STATE = 'JUMP';
	STATE_LOCK = false;

func choose_state():
	if abs(position.x - player.position.x) > attack_range:
		STATE = 'MOVE';
	else:
		STATE = 'ATTACK';

func play(anim_name, type):
	if type:
		if current_move_anim != anim_name:
			move_anim_step = 0;
			current_move_anim = anim_name;
			call(current_move_anim);
	else:
		STATE = 'ATTACKING';
		STATE_LOCK = false;
		attack_anim_step = 0;
		current_attack_anim = anim_name;
		anim_move_dir_x = move_dir_x;
		anim_player_pos = player.position;
		call(current_attack_anim, anim_player_pos, move_dir_x);

onready var head = $Head;
onready var right_arm = $RightArm;
onready var left_arm = $LeftArm;
onready var torso = $Torso;
onready var right_leg = $RightLeg;
onready var left_leg = $LeftLeg;

onready var movement_tween = $movement;
onready var attack_tween = $attack;
onready var death_tween = $death;

var current_move_anim;
var current_attack_anim;
var move_anim_step := 0;
var attack_anim_step := 0;
var anim_move_dir_x;
var anim_player_pos;

func idle():
	move_anim_step += 1;
	var dest_pos;
	match(move_anim_step):
		1:
			var i := 0;
			dest_pos = [Vector2(-6, -33), Vector2(-11, -14), Vector2(2, -15), Vector2(-5, -13), Vector2(-9, 5), Vector2(-3, 5)];
			for node in [head, right_arm, left_arm, torso, right_leg, left_leg]:
				movement_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN);
				movement_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, 0, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			movement_tween.start();
		2:
			var i = 0;
			dest_pos = [Vector2(-6, -30), Vector2(-11, -12), Vector2(2, -13)];
			for node in [head, right_arm, left_arm]:
				movement_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			movement_tween.start();
		3:
			current_move_anim = null;

func run():
	move_anim_step += 1;
	var i = 0;
	var dest_pos;
	var dest_rot;
	match(move_anim_step):
		1:
			if move_dir_x == 1:
				dest_pos = [Vector2(-7, 1), Vector2(0, 2)];
				dest_rot = [-10, 0];
			else:
				dest_pos = [Vector2(-11, 1), Vector2(-6, 2)];
				dest_rot = [10, 0];
			for node in [right_leg, left_leg]:
				movement_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				movement_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, dest_rot[i], 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			movement_tween.start();
		2:
			if move_dir_x == 1:
				dest_pos = [Vector2(-6, 2), Vector2(-5, 5)];
				dest_rot = [0, 15];
			else:
				dest_pos = [Vector2(-12, 2), Vector2(-1, 5)];
				dest_rot = [0, -15];
			for node in [right_leg, left_leg]:
				movement_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				movement_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, dest_rot[i], 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			movement_tween.start();
		3:
			if move_dir_x == 1:
				dest_pos = [Vector2(-11, 5), Vector2(-1, 1)];
				dest_rot = [15, -10];
			else:
				dest_pos = [Vector2(-7, 5), Vector2(-5, 1)];
				dest_rot = [-15, 10];
			for node in [right_leg, left_leg]:
				movement_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				movement_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, dest_rot[i], 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			movement_tween.start();
		4:
			current_move_anim = null;

func jump_anim():
	move_anim_step += 1;
	match(move_anim_step):
		1:
			var i := 0;
			var dest_pos = [Vector2(-6, -23), Vector2(-11, -4), Vector2(2, -5), Vector2(-5, -3), Vector2(-9, 5), Vector2(-3, 5)];
			for node in [head, right_arm, left_arm, torso, right_leg, left_leg]:
				movement_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN);
				movement_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, -15, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			movement_tween.start();

func jump_anim_revert():
	move_anim_step += 1;
	match(move_anim_step):
		1:
			var i := 0;
			var dest_pos = [Vector2(-6, -33), Vector2(-11, -14), Vector2(2, -15), Vector2(-5, -13)];
			for node in [head, right_arm, left_arm, torso]:
				movement_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 1, Tween.TRANS_LINEAR, Tween.EASE_IN);
				movement_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, 0, 1, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			movement_tween.start();

func damage_anim():
	move_anim_step += 1;
	match(move_anim_step):
		1:
			movement_tween.interpolate_property(self, 'modulate', Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN);
			movement_tween.start();
		2:
			movement_tween.interpolate_property(self, 'modulate', Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN);
			movement_tween.start();
		3:
			STATE_LOCK = true;

func flip(flag):
	var df = DynamicFont.new();
	if flag == 1:
		df.font_data = load(global.font_values[global.font_id][1]);
		move_child(right_arm, 3);
		right_arm.modulate = Color(1, 1, 1);
		move_child(left_arm, 1);
		left_arm.modulate = Color(0.4, 0.4, 0.4);
		move_child(right_leg, 5);
		right_leg.modulate = Color(1, 1, 1);
		move_child(left_leg, 4);
		left_leg.modulate = Color(0.4, 0.4, 0.4);
	else:
		df.font_data = load(global.font_values[global.font_id][1].insert(global.font_values[global.font_id][1].find('.ttf'), '_flipped'));
		move_child(right_arm, 1);
		right_arm.modulate = Color(0.4, 0.4, 0.4);
		move_child(left_arm, 3);
		left_arm.modulate = Color(1, 1, 1);
		move_child(right_leg, 4);
		right_leg.modulate = Color(0.4, 0.4, 0.4);
		move_child(left_leg, 5);
		left_leg.modulate = Color(1, 1, 1);
	for label in [$Head, $LeftArm, $RightArm, $Torso, $LeftLeg, $RightLeg]:
		label.add_font_override("font", df);

func _on_movement_tween_all_completed():
	call(current_move_anim);

func shotgun(player_pos, flag):
	attack_anim_step += 1;
	var dest_pos;
	var dest_rot;
	var aim_angle = rad2deg(get_angle_to(player_pos)) + (-90 if sign(get_angle_to(player_pos)) == 1 else (270 if move_dir_x == -1 else -90));
	var i := 0;
	match(attack_anim_step):
		1:
			dest_pos = [Vector2(-6, -33), Vector2(-14, -22) if flag == 1 else Vector2(-8, -22), Vector2(-4, -22) if flag == 1 else Vector2(5, -22), Vector2(-5, -13), Vector2(-12, 5), Vector2(0, 5)];
			dest_rot = [0, aim_angle, aim_angle, 0, 0, 0];
			for node in [head, right_arm, left_arm, torso, right_leg, left_leg]:
				attack_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				attack_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, dest_rot[i], 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			attack_tween.start();
		2:
			anim_delay('attack_tween', 0.1);
		3:
		# warning-ignore:unused_variable
			for j in range(5):
				shoot((player_pos - position).normalized().rotated(deg2rad(rand_range(-10, 10))));
			dest_pos = [Vector2(-25, -22) if flag == 1 else Vector2(3, -22), Vector2(-15, -22) if flag == 1 else Vector2(16, -22)];
			for node in [right_arm, left_arm]:
				attack_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			attack_tween.start();
		4:
			dest_pos = [Vector2(-11, -12), Vector2(2, -13)];
			for node in [right_arm, left_arm]:
				attack_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN);
				attack_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, 0, 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			attack_tween.start();
		5:
			STATE_LOCK = true;
			attack_timer.start();

func pulse(player_pos, flag):
	attack_anim_step += 1;
	var dest_pos;
	var dest_rot;
	var aim_angle = rad2deg(get_angle_to(player_pos)) + (-90 if sign(get_angle_to(player_pos)) == 1 else (270 if move_dir_x == -1 else -90));
	var i := 0;
	match(attack_anim_step):
		1:
			dest_pos = [Vector2(-6, -33), Vector2(-14, -22) if flag == 1 else Vector2(-8, -22), Vector2(-4, -22) if flag == 1 else Vector2(5, -22), Vector2(-5, -13), Vector2(-12, 5), Vector2(0, 5)];
			dest_rot = [0, aim_angle, aim_angle, 0, 0, 0];
			for node in [head, right_arm, left_arm, torso, right_leg, left_leg]:
				attack_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				attack_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, dest_rot[i], 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			attack_tween.start();
		2:
			var new_aim_angle = aim_angle + (-15 if sign(get_angle_to(player_pos)) == 1 else (15 if flag == -1 else -15));
			shoot((player_pos - position).normalized());
			dest_pos = [Vector2(-25, -22) if flag == 1 else Vector2(3, -22), Vector2(-15, -22) if flag == 1 else Vector2(16, -22)];
			for node in [right_arm, left_arm]:
				attack_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN);
				attack_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, new_aim_angle, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			attack_tween.start();
		3:
			dest_pos = [Vector2(-14, -22) if flag == 1 else Vector2(-8, -22), Vector2(-4, -22) if flag == 1 else Vector2(5, -22)];
			for node in [right_arm, left_arm]:
				attack_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN);
				attack_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, aim_angle, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			attack_tween.start();
		4:
			var new_aim_angle = aim_angle + (-15 if sign(get_angle_to(player_pos)) == 1 else (15 if flag == -1 else -15));
			shoot((player_pos - position).normalized());
			dest_pos = [Vector2(-25, -22) if flag == 1 else Vector2(3, -22), Vector2(-15, -22) if flag == 1 else Vector2(16, -22)];
			for node in [right_arm, left_arm]:
				attack_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN);
				attack_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, new_aim_angle, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			attack_tween.start();
		5:
			dest_pos = [Vector2(-14, -22) if flag == 1 else Vector2(-8, -22), Vector2(-4, -22) if flag == 1 else Vector2(5, -22)];
			for node in [right_arm, left_arm]:
				attack_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN);
				attack_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, aim_angle, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			attack_tween.start();
		6:
			var new_aim_angle = aim_angle + (-15 if sign(get_angle_to(player_pos)) == 1 else (15 if flag == -1 else -15));
			shoot((player_pos - position).normalized());
			dest_pos = [Vector2(-25, -22) if flag == 1 else Vector2(3, -22), Vector2(-15, -22) if flag == 1 else Vector2(16, -22)];
			for node in [right_arm, left_arm]:
				attack_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN);
				attack_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, new_aim_angle, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			attack_tween.start();
		7:
			dest_pos = [Vector2(-14, -22) if flag == 1 else Vector2(-8, -22), Vector2(-4, -22) if flag == 1 else Vector2(5, -22)];
			for node in [right_arm, left_arm]:
				attack_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN);
				attack_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, aim_angle, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			attack_tween.start();
		8:
			dest_pos = [Vector2(-11, -12), Vector2(2, -13)];
			for node in [right_arm, left_arm]:
				attack_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN);
				attack_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, 0, 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			attack_tween.start();
		9:
			STATE_LOCK = true;
			attack_timer.start();

func sniper(player_pos, flag):
	attack_anim_step += 1;
	var dest_pos;
	var dest_rot;
	var aim_angle = rad2deg(get_angle_to(player_pos)) + (-90 if sign(get_angle_to(player_pos)) == 1 else (270 if move_dir_x == -1 else -90));
	var i := 0;
	match(attack_anim_step):
		1:
			dest_pos = [Vector2(-6, -33), Vector2(1, -22) if flag == 1 else Vector2(-11, -12), Vector2(2, -13) if flag == 1 else Vector2(-10, -22), Vector2(-5, -13), Vector2(-12, 5), Vector2(0, 5)];
			dest_rot = [0, aim_angle if flag == 1 else 0, 0 if flag == 1 else aim_angle, 0, 0, 0];
			for node in [head, right_arm, left_arm, torso, right_leg, left_leg]:
				attack_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				attack_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, dest_rot[i], 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			attack_tween.start();
		2:
			anim_delay('attack_tween', 0.1);
		3:
			shoot((player_pos - position).normalized());
			aim_angle += -15 if sign(get_angle_to(player_pos)) == 1 else (15 if flag == -1 else -15);
			if flag == 1:
				dest_pos = Vector2(-19, -22);
				attack_tween.interpolate_property(right_arm, 'rect_position', right_arm.rect_position, dest_pos, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN);
				attack_tween.interpolate_property(right_arm, 'rect_rotation', right_arm.rect_rotation, aim_angle, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN);
			else:
				dest_pos = Vector2(10, -22);
				attack_tween.interpolate_property(left_arm, 'rect_position', left_arm.rect_position, dest_pos, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN);
				attack_tween.interpolate_property(left_arm, 'rect_rotation', left_arm.rect_rotation, aim_angle, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN);
			attack_tween.start();
		4:
			if flag == 1:
				dest_pos = Vector2(-11, -12);
				attack_tween.interpolate_property(right_arm, 'rect_position', right_arm.rect_position, dest_pos, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				attack_tween.interpolate_property(right_arm, 'rect_rotation', right_arm.rect_rotation, 0, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
			else:
				dest_pos = Vector2(2, -13);
				attack_tween.interpolate_property(left_arm, 'rect_position', left_arm.rect_position, dest_pos, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				attack_tween.interpolate_property(left_arm, 'rect_rotation', left_arm.rect_rotation, 0, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
			attack_tween.start();
		5:
			STATE_LOCK = true;
			attack_timer.start();

func shoot(dir):
	if sign(dir.x) == 1 and muzzle.get_parent() != right_arm:
		left_arm.remove_child(muzzle);
		right_arm.add_child(muzzle);
		muzzle.position = Vector2(6.5, 20);
	elif sign(dir.x) != 1 and muzzle.get_parent() != left_arm:
		right_arm.remove_child(muzzle);
		left_arm.add_child(muzzle);
		muzzle.position = Vector2(7, 20);
	var b = bullet.instance();
	enemy_container.add_child(b);
	b.init(muzzle.global_position, dir, scale, bullet_type);

# warning-ignore:unused_argument
func laser(player_pos, flag):
	attack_anim_step += 1;
	var dest_pos;
	var dest_rot;
	var aim_angle = -90 if flag == 1 else 90;
	var i := 0;
	match(attack_anim_step):
		1:
			dest_pos = [Vector2(-6, -33), Vector2(-1, -12) if flag == 1 else Vector2(-11, -12), Vector2(2, -13) if flag == 1 else Vector2(-8, -13), Vector2(-5, -13), Vector2(-9, 5), Vector2(-3, 5)];
			dest_rot = [0, aim_angle, aim_angle, 0, 0, 0];
			for node in [head, right_arm, left_arm, torso, right_leg, left_leg]:
				attack_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN);
				attack_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, dest_rot[i], 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			attack_tween.start();
		2:
			shoot_laser(flag);
			dest_pos = [Vector2(-10, -12) if flag == 1 else Vector2(-2, -12), Vector2(-7, -13) if flag == 1 else Vector2(1, -13)];
			for node in [right_arm, left_arm]:
				attack_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			attack_tween.start();
		3:
			dest_pos = [Vector2(-11, -12), Vector2(2, -13)];
			for node in [right_arm, left_arm]:
				attack_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN);
				attack_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, 0, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			attack_tween.start();
		4:
			STATE_LOCK = true;
			attack_timer.start();

func shoot_laser(dir):
	if dir == 1 and laser_ray.get_parent() != right_arm:
		left_arm.remove_child(laser_ray);
		right_arm.add_child(laser_ray);
		laser_ray.position = Vector2(6.5, 20);
	elif dir != 1 and laser_ray.get_parent() != left_arm:
		right_arm.remove_child(laser_ray);
		left_arm.add_child(laser_ray);
		laser_ray.position = Vector2(7, 20);
	laser_ray.cast_to = Vector2(0, 100000);
	laser_ray.force_raycast_update();
	if laser_ray.is_colliding():
		laser_line.points[1] = Vector2(to_local(laser_ray.get_collision_point()).x, 0).rotated(-deg2rad(laser_ray.get_parent().rect_rotation));
	else:
		laser_line.points[1] = Vector2(to_local(laser_ray.cast_to).x, 0).rotated(deg2rad(laser_ray.get_parent().rect_rotation * (1 if dir == 1 else -1)));
	laser_tween.interpolate_property(laser_line, 'width', 0, 10, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN);
	laser_tween.start();

func _on_laser_tween_all_completed():
	if laser_line.width == 10:
		yield(get_tree().create_timer(1), 'timeout');
		laser_tween.interpolate_property(laser_line, 'width', 10, 0, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN);
		laser_tween.start();
	else:
		emit_signal('laser_done');

func melee(player_pos, flag):
	attack_anim_step += 1;
	var dest_pos;
	var dest_rot;
	var punch_hand = right_arm if move_dir_x == 1 else left_arm;
	var aim_angle = rad2deg(get_angle_to(player_pos)) + (-90 if sign(get_angle_to(player_pos)) == 1 else (270 if move_dir_x == -1 else -90));
	var i := 0;
	match(attack_anim_step):
		1:
			dest_pos = [Vector2(-6, -33), Vector2(-11, -14), Vector2(2, -15), Vector2(-5, -13), Vector2(-9, 5), Vector2(-3, 5)];
			dest_rot = [0, 0, 0, 0, 0, 0];
			if flag == 1:
				dest_pos[1] = Vector2(-18, -20);
				dest_rot[1] = aim_angle;
			else:
				dest_pos[2] = Vector2(9, -20);
				dest_rot[2] = aim_angle;
			for node in [head, right_arm, left_arm, torso, right_leg, left_leg]:
				attack_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				attack_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, dest_rot[i], 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			attack_tween.start();
		2:
			dest_pos = Vector2(0, -20) if flag == 1 else Vector2(-9, -20);
			punch(flag);
			attack_tween.interpolate_property(punch_hand, 'rect_position', punch_hand.rect_position, dest_pos, 0.02, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.1);
			attack_tween.start();
		3:
			melee_coll.set_monitoring(false);
			dest_pos = Vector2(-11, -14) if flag == 1 else Vector2(2, -15);
			attack_tween.interpolate_property(punch_hand, 'rect_rotation', punch_hand.rect_rotation, 0, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN);
			attack_tween.interpolate_property(punch_hand, 'rect_position', punch_hand.rect_position, dest_pos, 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN);
			attack_tween.start();
		4:
			STATE_LOCK = true;
			attack_timer.start();

func punch(dir):
	if dir == 1 and melee_coll.get_parent() != right_arm:
		left_arm.remove_child(melee_coll);
		right_arm.add_child(melee_coll);
		melee_coll.position = Vector2(6.5, 12.5);
	elif dir != 1 and melee_coll.get_parent() != left_arm:
		right_arm.remove_child(melee_coll);
		left_arm.add_child(melee_coll);
		melee_coll.position = Vector2(7, 12.5);
	melee_coll.set_monitoring(true);

func _on_attack_tween_all_completed():
	call(current_attack_anim, anim_player_pos, anim_move_dir_x);

func death():
	movement_tween.stop_all();
	attack_tween.stop_all();
	death_tween.interpolate_property(self, 'modulate', Color(1, 1, 1, 1), Color(1, 1, 1, 0), 1, Tween.TRANS_LINEAR, Tween.EASE_IN);
	death_tween.start();
	set_collision_mask_bit(2, false);

func _on_death_tween_all_completed():
	emit_signal('on_free');
	queue_free();

func anim_delay(type, amount):
	get(type).interpolate_property(head, 'rect_position', head.rect_position, head.rect_position, amount, Tween.TRANS_LINEAR, Tween.EASE_IN);
	get(type).start();

func damage(amount, dir):
	if health > amount:
		health -= amount;
		STATE_LOCK = false;
		STATE = 'CC';
		play('damage_anim', true);
		knockback_dir.x = sign(dir.x)*300;
	else: 
		health = 0;
		STATE_LOCK = false;
		STATE = 'DEATH';
		call('death');

# warning-ignore:unused_argument
func _on_melee_coll_body_entered(body):
	print('FLY ENEMY MELEE PLAYER DAMAGE CODE UNWRITTEN. WRITE IT IDIOT');
	melee_coll.set_deferred('monitoring', false);
