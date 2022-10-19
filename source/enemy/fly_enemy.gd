extends KinematicBody2D

var bullet = preload('res://bullet/enemy_bullet.tscn');
var homing_bullet = preload('res://bullet/homing_bullet.tscn');

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
onready var face_ray = $face;

onready var muzzle;
onready var muzzle2;
onready var muzzle3;

onready var laser_ray;
onready var laser_line;
onready var laser_tween;

onready var melee_coll;

onready var pulse_timer;

onready var head = $Head;
onready var right_arm = $RightArm;
onready var left_arm = $LeftArm;
onready var torso = $Torso;
onready var tail = $Tail;

var head2;
var head3;
var stick;

onready var movement_tween = $movement;
onready var attack_tween = $attack;
onready var death_tween = $death;
onready var move_rot_tween;


var health := 20;
var knockback_dir := Vector2();
var move_dir_x := -1;
var side_track_pos_y := 0;

var vel := Vector2();
var speed := 70;
var vel_rot := 0.0;
var vel_rot_dir := 0.1;
var body_rot_angle := 0.0;

var dash_speed;
var max_dash_speed;
var dash_dir;
var dash_duration;
var lift_dir;

var STATE;
var STATE_LOCK = true;

var attack_type;
var bullet_type;
var attack_range;
var attack_class;
var enemy_body_type := '';

func init(char_list, at_class, at_type = ''): 
	
	var limb_array = [head, right_arm, left_arm, torso, tail];
	
	attack_class = at_class;
	
	match(attack_class):
		'shoot':
			
			attack_type = at_type;
			
			match(attack_type):
				'homing':
					head2 = bone_scene.instance();
					add_child(head2);
					move_child(head2, 2);
					head3 = bone_scene.instance();
					add_child(head3);
					move_child(head3, 3);
					
					for h in ['', '2', '3']:
						set('muzzle' + h, muzzle_scene.instance());
						get('head' + h).add_child(get('muzzle' + h));
						get('muzzle' + h).position = Vector2(5, 0);
					limb_array.insert(1, head2);
					limb_array.insert(2, head3);
					enemy_body_type = '_3_headed';
				
				'pulse':
					muzzle = muzzle_scene.instance();
					head.add_child(muzzle);
					muzzle.position = Vector2(5, 0);
				
				'bomber':
					pulse_timer = Timer.new();
					pulse_timer.set_one_shot(true);
					add_child(pulse_timer);
					pulse_timer.connect("timeout", self, '_on_pulse_timeout');
					
					muzzle = muzzle_scene.instance();
					add_child(muzzle);
					
					stick = bone_scene.instance();
					add_child(stick);
					move_child(stick, 0);
					limb_array.insert(0, stick);
					
					max_dash_speed = speed;
					pulse_count = 3;
					enemy_body_type = '_bomber';
				
				'dash_bomber':
					pulse_timer = Timer.new();
					pulse_timer.set_one_shot(true);
					add_child(pulse_timer);
					pulse_timer.connect("timeout", self, '_on_pulse_timeout');
					
					muzzle = muzzle_scene.instance();
					add_child(muzzle);
					
					stick = bone_scene.instance();
					add_child(stick);
					move_child(stick, 0);
					limb_array.insert(0, stick);
					
					max_dash_speed = 500;
					pulse_count = 5;
					enemy_body_type = '_bomber';
				
			var bullet_type_dict := {'homing': 'homing_bullet',
									 'pulse': 'pulse_bullet',
									 'bomber': 'bomb_bullet',
									 'dash_bomber': 'bomber_bullet'};
			bullet_type = bullet_type_dict[attack_type];
			
			var attack_range_dict := {'homing': 600,
									  'pulse': 200,
									  'bomber': 10,
									  'dash_bomber': 50};
			attack_range = attack_range_dict[attack_type];
			
		'laser':
			
			laser_ray = laser_scene.instance();
			add_child(laser_ray);
			laser_ray.position = Vector2(6, 12.5);
			laser_line = laser_ray.get_node('Line2D');
			laser_tween = laser_ray.get_node('laser');
			laser_tween.connect("tween_all_completed", self, '_on_laser_tween_all_completed')
			
			move_rot_tween = Tween.new();
			add_child(move_rot_tween);
			move_rot_tween.connect("tween_all_completed", self, '_on_move_rotation_tween_all_completed');
			
			var attack_type_array := ['laser'];
			attack_type = attack_type_array[randi() % attack_type_array.size()];
			
			enemy_body_type = '_drone';
			body_rot_angle = (randi() % 360)*sign(randf() - 0.5);
			
			move_rot_tween.interpolate_property(self, 'vel_rot', vel_rot, vel_rot + vel_rot_dir, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN);
			move_rot_tween.start();
			
			var attack_range_dict := {'laser': 70};
			attack_range = attack_range_dict[attack_type];
			
		'melee':
			
			melee_coll = melee_scene.instance();
			head.add_child(melee_coll);
			melee_coll.position = Vector2(6.5, 12.5);
			melee_coll.connect("body_entered", self, '_on_melee_coll_body_entered');
			
			var attack_type_array := ['dive'];
			attack_type = attack_type_array[randi() % attack_type_array.size()];
			
			var attack_range_dict := {'dive': 200};
			attack_range = attack_range_dict[attack_type];
			
			max_dash_speed = 1000;
			enemy_body_type = '_diver';
	
	var limb_index = -1;
	var current_limb = limb_array[limb_index];
	for i in char_list.length():
		if char_list[i] == '\t' or char_list[i] == ' ': 
			continue; 
		elif i == limb_array.size() - 1:
			break;
		limb_index += 1;
		current_limb = limb_array[limb_index];
		current_limb.text = char_list[i];
	while limb_index < limb_array.size() - 1:
		limb_index += 1;
		current_limb = limb_array[limb_index];
		current_limb.text = char(65 + randi()%26);
	
	match(attack_class):
		'shoot':
			match(attack_type):
				'homing':
					head2.text = head.text;
					head3.text = head.text;
				
				'bomber':
					stick.text = '|';
				
				'dash_bomber':
					stick.text = '|';
	
	var sb = StyleBoxFlat.new();
	sb.border_width_bottom = 0;
	sb.bg_color.a = 0;
	for label in limb_array:
		label.add_stylebox_override('normal', sb);
	
	match(enemy_body_type):
		'':
			var dest_pos = [Vector2(15, -5), Vector2(0, -6), Vector2(-7, -14), Vector2(0, -5), Vector2(-6, 4)];
			var dest_rot = [130, -40, -50, 30, 30];
			var i := 0;
			for node in limb_array:
				limb_array[i].rect_position = dest_pos[i];
				limb_array[i].rect_rotation = dest_rot[i];
				i += 1;
			torso.modulate = Color(0.7, 0.7, 0.7);
		
		'_3_headed':
			var dest_pos = [Vector2(15, -5), Vector2(15, -14), Vector2(12, 2), 
							Vector2(0, -6), Vector2(-7, -14), Vector2(0, -5), Vector2(-6, 4)];
			var dest_rot = [140, 100, 180, -40, -50, 30, 30];
			var i := 0;
			for node in limb_array:
				limb_array[i].rect_position = dest_pos[i];
				limb_array[i].rect_rotation = dest_rot[i];
				i += 1;
			torso.modulate = Color(0.7, 0.7, 0.7);
		
		'_bomber':
			var dest_pos = [Vector2(7, -3), Vector2(0, -20), Vector2(-14, -20), 
							Vector2(-6.5, -3), Vector2(-20, -6), Vector2(-2, -10)];
			var dest_rot = [90, -90, -90, 90, -240, 0];
			var i := 0;
			for node in limb_array:
				limb_array[i].rect_position = dest_pos[i];
				limb_array[i].rect_rotation = dest_rot[i];
				i += 1;
			
		'_drone':
			var i := 0;
			var dest_pos := [];
			var dest_rot := [180, 240, 300, 360, 60];
			for rot in dest_rot:
				dest_pos.append(Vector2(Vector2().distance_to(Vector2(6, -12.5)), 0).rotated(deg2rad(rot)));
			for node in limb_array:
				limb_array[i].rect_position = dest_pos[i];
				limb_array[i].rect_rotation = dest_rot[i];
				i += 1;
			
		'_diver':
			var i := 0;
			var dest_pos = [Vector2(8, -12.5), Vector2(-4, -19), Vector2(-15, -29), Vector2(-4, -6), Vector2(-15, 4)];
			var dest_rot = [90, 120, 140, 60, 40];
			for node in limb_array:
				limb_array[i].rect_position = dest_pos[i];
				limb_array[i].rect_rotation = dest_rot[i];
				i += 1;
	
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
			vel = Vector2();
			STATE_LOCK = true;
		'IDLE':
			state_label.text = 'SHILLING';
			play('idle' + enemy_body_type, true);
			call('flip' + enemy_body_type, move_dir_x);
			vel = Vector2();
		'MOVE':
			if face_ray.is_colliding():
				if face_ray.get_collider().is_in_group('obstacle'):
					side_track(face_ray.get_collider());
			else:
				state_label.text = 'APPROACHING PLAYER';
				play('run' + enemy_body_type, true);
				call('flip' + enemy_body_type, move_dir_x);
				vel = Vector2(move_dir_x*speed, 0).rotated(vel_rot);
# warning-ignore:return_value_discarded
			move_and_slide(vel);
		'SIDE_TRACK':
			state_label.text = 'SIDE-TRACKING';
			play('side_track_anim' + enemy_body_type, true);
# warning-ignore:return_value_discarded
			move_and_slide(vel);
			if abs(position.y - side_track_pos_y) <= 2:
				STATE_LOCK = true;
		'ATTACK':
			state_label.text = 'INITIATING ATTACK';
			if attack_timer.is_stopped():
				play(attack_type, false);
			else:
				play('idle' + enemy_body_type, true);
			call('flip' + enemy_body_type, move_dir_x);
			vel = Vector2();
		'ATTACKING':
			state_label.text = 'ATTACKING';
			vel = Vector2();
		'DASH':
			state_label.text = 'DASHING!';
			vel = dash_dir*dash_speed;
# warning-ignore:return_value_discarded
			move_and_slide(vel);
		'LIFT':
			state_label.text = 'LIFTING';
# warning-ignore:return_value_discarded
			move_and_slide(lift_dir*2*speed);
		'CC':
			state_label.text = 'KNOCKED BACK';
			play('damage_anim', true);
# warning-ignore:return_value_discarded
			move_and_slide(knockback_dir);
		'DEATH':
			state_label.text = 'DYING';
			call('death');
			vel.x = 0;
			if is_on_floor():
				vel.y = 20;
			else:
				vel.y += 20 if vel.y < 300 else 0;
# warning-ignore:return_value_discarded
			move_and_slide(vel, Vector2(0, -1));

func side_track(obs):
	STATE_LOCK = false;
	STATE = 'SIDE_TRACK';
	vel = Vector2(30*move_dir_x, speed*-1);
	side_track_pos_y = obs.global_position.y - 22;

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
			anim_move_dir_x = move_dir_x;
			call(current_move_anim, anim_move_dir_x);
	else:
		STATE = 'ATTACKING';
		STATE_LOCK = false;
		attack_anim_step = 0;
		current_attack_anim = anim_name;
		anim_move_dir_x = move_dir_x;
		anim_player_pos = player.position;
		call(current_attack_anim, anim_player_pos, move_dir_x);

var current_move_anim;
var current_attack_anim;
var move_anim_step := 0;
var attack_anim_step := 0;
var anim_move_dir_x;
var anim_player_pos;

func idle(flag):
	flap(flag, 0.5, 0.3);

func run(flag):
	flap(flag, 0.4, 0.2);

func side_track_anim(flag):
	flap(flag, 0.3, 0.15);

func flip(flag):
	face_ray.cast_to = Vector2(flag*44, 0);
	if flag == 1:
		move_child(right_arm, 3);
		right_arm.modulate = Color(1, 1, 1);
		move_child(left_arm, 1);
		left_arm.modulate = Color(0.4, 0.4, 0.4);
	else:
		move_child(right_arm, 1);
		right_arm.modulate = Color(0.4, 0.4, 0.4);
		move_child(left_arm, 3);
		left_arm.modulate = Color(1, 1, 1);

func idle_3_headed(flag):
	flap_3_headed(flag, 0.5, 0.3);

func run_3_headed(flag):
	flap_3_headed(flag, 0.4, 0.2);

func side_track_anim_3_headed(flag):
	flap_3_headed(flag, 0.3, 0.15);

func flip_3_headed(flag):
	face_ray.cast_to = Vector2(flag*44, 0);
	if flag == 1:
		move_child(right_arm, 6);
		right_arm.modulate = Color(1, 1, 1);
		move_child(left_arm, 4);
		left_arm.modulate = Color(0.4, 0.4, 0.4);
	else:
		move_child(right_arm, 4);
		right_arm.modulate = Color(0.4, 0.4, 0.4);
		move_child(left_arm, 6);
		left_arm.modulate = Color(1, 1, 1);

func idle_bomber(flag):
	flap_bomber(flag, 0.5);

func run_bomber(flag):
	flap_bomber(flag, 0.4);

func side_track_anim_bomber(flag):
	flap_bomber(flag, 0.3);

func flip_bomber(flag):
	face_ray.cast_to = Vector2(flag*44, 0);

# warning-ignore:unused_argument
func idle_drone(flag):
	flap_drone(0.0005);

# warning-ignore:unused_argument
func run_drone(flag):
	flap_drone(0.0001);

# warning-ignore:unused_argument
func side_track_anim_drone(flag):
	flap_drone(0.0003);

func flip_drone(flag):
	face_ray.cast_to = Vector2(flag*44, 0);

func idle_diver(flag):
	flap_diver(flag);

func run_diver(flag):
	move_anim_step += 1;
	var i = 0;
	var dest_pos;
	var dest_rot;
	match(move_anim_step):
		1:
			dest_pos = [Vector2(flag*8, -12.5), Vector2(flag*-4, -19), Vector2(flag*-15, -29), 
						Vector2(flag*-4, -6), Vector2(flag*-15, 4)];
			dest_rot = [flag*90, flag*120, flag*140, flag*60, flag*40];
			for node in [head, right_arm, torso, left_arm, tail]:
				movement_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.4, Tween.TRANS_LINEAR, Tween.EASE_IN);
				movement_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, dest_rot[i], 0.4, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			movement_tween.start();
		2:
			dash_speed = max_dash_speed/2;
			STATE_LOCK = false;
			STATE = 'DASH';
			movement_tween.interpolate_property(self, 'dash_speed', dash_speed, speed, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
			dash_dir = Vector2(flag, 0);
			
			dest_pos = [Vector2(flag*10, -12.5), Vector2(flag*-5, -15), Vector2(flag*-16, -19), 
						Vector2(flag*-5, -7), Vector2(flag*-17, -4)];
			dest_rot = [flag*90, flag*95, flag*95, flag*85, flag*85];
			for node in [head, right_arm, torso, left_arm, tail]:
				movement_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				movement_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, dest_rot[i], 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			movement_tween.start();
		3:
			dash_speed = max_dash_speed;
			STATE_LOCK = true;
			dest_pos = [Vector2(flag*8, -12.5), Vector2(flag*-2, -15), Vector2(flag*-13, -19), 
						Vector2(flag*-2, -7), Vector2(flag*-14, -4)];
			dest_rot = [flag*90, flag*100, flag*100, flag*80, flag*80];
			for node in [head, right_arm, torso, left_arm, tail]:
				movement_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.7, Tween.TRANS_LINEAR, Tween.EASE_IN);
				movement_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, dest_rot[i], 0.7, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			movement_tween.start();
		4:
			current_move_anim = null;

func side_track_anim_diver(flag):
	flap_diver(flag);

func flip_diver(flag):
	face_ray.cast_to = Vector2(flag*44, 0);

func flap(flag, dur1, dur2):
	move_anim_step += 1;
	var i = 0;
	var dest_pos;
	var dest_rot;
	match(move_anim_step):
		1:
			dest_pos = [Vector2(flag*15, -5), Vector2(0, -6), Vector2(-7, -14), Vector2(0, -5), Vector2(flag*-6, 4)];
			dest_rot = [flag*130, flag*-40, flag*-50, flag*30, flag*30];
			if flag == -1:
				dest_pos[1] = Vector2(7, -14);
				dest_pos[2] = Vector2(0, -6);
			for node in [head, right_arm, left_arm, torso, tail]:
				movement_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], dur1, Tween.TRANS_LINEAR, Tween.EASE_IN);
				movement_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, dest_rot[i], dur1, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			movement_tween.start();
		2:
			dest_pos = [Vector2(flag*15, -11), Vector2(5, 0), Vector2(-2, -8), Vector2(0, -11), Vector2(flag*-6, -2)];
			dest_rot = [flag*120, flag*-25, flag*-35, flag*30, flag*50];
			if flag == -1:
				dest_pos[1] = Vector2(2, -8);
				dest_pos[2] = Vector2(-5, 0);
			for node in [head, right_arm, left_arm, torso, tail]:
				movement_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], dur2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				movement_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, dest_rot[i], dur2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			movement_tween.start();
		3:
			current_move_anim = null;

func flap_3_headed(flag, dur1, dur2):
	move_anim_step += 1;
	var i = 0;
	var dest_pos;
	var dest_rot;
	match(move_anim_step):
		1:
			dest_pos = [Vector2(flag*15, -5), Vector2(flag*15, -14), Vector2(flag*12, 2), 
						Vector2(0, -6), Vector2(-7, -14), Vector2(0, -5), Vector2(flag*-6, 4)];
			dest_rot = [flag*140, flag*100, flag*180, flag*-40, flag*-50, flag*30, flag*30];
			if flag == -1:
				dest_pos[3] = Vector2(7, -14);
				dest_pos[4] = Vector2(0, -6);
			for node in [head, head2, head3, right_arm, left_arm, torso, tail]:
				movement_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], dur1, Tween.TRANS_LINEAR, Tween.EASE_IN);
				movement_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, dest_rot[i], dur1, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			movement_tween.start();
		2:
			dest_pos = [Vector2(flag*15, -11), Vector2(flag*15, -20), Vector2(flag*12, -4), 
						Vector2(5, 0), Vector2(-2, -8), Vector2(0, -11), Vector2(flag*-6, -2)];
			dest_rot = [flag*110, flag*70, flag*150, flag*-25, flag*-35, flag*30, flag*50];
			if flag == -1:
				dest_pos[3] = Vector2(2, -8);
				dest_pos[4] = Vector2(-5, 0);
			for node in [head, head2, head3, right_arm, left_arm, torso, tail]:
				movement_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], dur2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				movement_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, dest_rot[i], dur2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			movement_tween.start();
		3:
			current_move_anim = null;

func flap_bomber(flag, dur):
	move_anim_step += 1;
	var i = 0;
	var dest_pos;
	match(move_anim_step):
		1:
			dest_pos = [Vector2(flag*7, -3), Vector2(0, -20), Vector2(-14, -20), 
						Vector2(flag*-6.5, -3), Vector2(flag*-20, -6), Vector2(-2, -10)];
			var dest_rot = [flag*90, -90, -90, flag*90, flag*-240, 0];
			if flag == -1:
				dest_pos[1] = Vector2(14, -20);
				dest_pos[2] = Vector2(0, -20);
				dest_pos[5] = Vector2(8, -10);
			for node in [head, right_arm, left_arm, torso, tail, stick]:
				movement_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], dur, Tween.TRANS_LINEAR, Tween.EASE_IN);
				movement_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, dest_rot[i], dur, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			movement_tween.start();
		2:
			dest_pos = [Vector2(flag*7, 0), Vector2(0, -17), Vector2(-14, -17), 
						Vector2(flag*-6.5, 0), Vector2(flag*-20, -3), Vector2(-2, -7)];
			if flag == -1:
				dest_pos[1] = Vector2(14, -17);
				dest_pos[2] = Vector2(0, -17);
				dest_pos[5] = Vector2(8, -10);
			for node in [head, right_arm, left_arm, torso, tail, stick]:
				movement_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], dur, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			movement_tween.start();
		3:
			current_move_anim = null;

func flap_drone(dur):
	move_anim_step += 1;
	match(move_anim_step):
		1:
			if abs(body_rot_angle) < 10:
				body_rot_angle = (randi() % 360)*sign(randf() - 0.5);
			var rot_angle = -10*sign(body_rot_angle);
			for node in [head, right_arm, left_arm, torso, tail]:
				var dest_pos = node.rect_position.rotated(deg2rad(rot_angle));
				movement_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos, dur, Tween.TRANS_CUBIC, Tween.EASE_IN);
				movement_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, node.rect_rotation + rot_angle, dur, Tween.TRANS_LINEAR, Tween.EASE_IN);
			movement_tween.start();
			body_rot_angle += rot_angle;
		2:
			current_move_anim = null;

func flap_diver(flag):
	move_anim_step += 1;
	var i = 0;
	var dest_pos;
	var dest_rot;
	match(move_anim_step):
		1:
			dest_pos = [Vector2(flag*8, -12.5), Vector2(flag*-3, -16), Vector2(flag*-14, -20), 
						Vector2(flag*-3, -6), Vector2(flag*-15, -3)];
			dest_rot = [flag*90, flag*105, flag*105, flag*85, flag*85];
			for node in [head, right_arm, torso, left_arm, tail]:
				movement_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN);
				movement_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, dest_rot[i], 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			movement_tween.start();
		2:
			dest_pos = [Vector2(flag*8, -12.5), Vector2(flag*-2, -15), Vector2(flag*-13, -19), 
						Vector2(flag*-2, -7), Vector2(flag*-14, -4)];
			dest_rot = [flag*90, flag*100, flag*100, flag*80, flag*80];
			for node in [head, right_arm, torso, left_arm, tail]:
				movement_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN);
				movement_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, dest_rot[i], 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			movement_tween.start();
		3:
			current_move_anim = null;

# warning-ignore:unused_argument
func damage_anim(flag):
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

func _on_movement_tween_all_completed():
	call(current_move_anim, anim_move_dir_x);

# warning-ignore:unused_argument
func bomber(player_pos, flag):
	attack_anim_step += 1;
	match(attack_anim_step):
		1:
			movement_tween.stop_all();
			dash_duration = 1.0;
			dash_speed = max_dash_speed;
			STATE = 'DASH';
			dash_dir = Vector2(flag, 0);
			attack_tween.interpolate_property(self, 'dash_speed', dash_speed, speed, dash_duration, Tween.TRANS_QUAD, Tween.EASE_IN);
			
			shoot(Vector2(0, 1));
				
			var i := 0;
			var dest_pos = [Vector2(flag*8, 4), Vector2(7, -12), Vector2(-7, -17), Vector2(flag*-4, -1), Vector2(flag*-16, -8), Vector2(2, -3)];
			var dest_rot = [110, -70, -70, 110, -220, 20];
			if flag == -1:
				dest_pos[1] = Vector2(7, -17);
				dest_pos[2] = Vector2(-7, -12);
				dest_pos[5] = Vector2(8, -3);
				dest_rot = [-110, -110, -110, -110, 220, -20];
			for node in [head, right_arm, left_arm, torso, tail, stick]:
				attack_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				attack_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, dest_rot[i], 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			attack_tween.start();
		2:
			movement_tween.resume_all();
			STATE_LOCK = true;
			attack_timer.start();

# warning-ignore:unused_argument
func dash_bomber(player_pos, flag):
	attack_anim_step += 1;
	match(attack_anim_step):
		1:
			movement_tween.stop_all();
			dash_duration = 0.2;
			dash_speed = max_dash_speed;
			STATE = 'DASH';
			dash_dir = Vector2(flag, 0);
			attack_tween.interpolate_property(self, 'dash_speed', dash_speed, speed, dash_duration, Tween.TRANS_QUAD, Tween.EASE_IN);
			
			temp_pulse_count = pulse_count;
			pulse_timer.set_wait_time(dash_duration/temp_pulse_count);
			pulse_dir = Vector2(0, 1);
			shoot_pulse(pulse_dir);
			
			var i := 0;
			var dest_pos = [Vector2(flag*8, 4), Vector2(7, -12), Vector2(-7, -17), Vector2(flag*-4, -1), Vector2(flag*-16, -8), Vector2(2, -3)];
			var dest_rot = [110, -70, -70, 110, -220, 20];
			if flag == -1:
				dest_pos[1] = Vector2(7, -17);
				dest_pos[2] = Vector2(-7, -12);
				dest_pos[5] = Vector2(8, -3);
				dest_rot = [-110, -110, -110, -110, 220, -20];
			for node in [head, right_arm, left_arm, torso, tail, stick]:
				attack_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN);
				attack_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, dest_rot[i], 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			attack_tween.start();
		2:
			movement_tween.resume_all();
			dash_speed = max_dash_speed;
			STATE_LOCK = true;
			attack_timer.start();

var temp_pulse_count;
var pulse_count;
var pulse_dir;

func shoot_pulse(dir):
	if temp_pulse_count > 0:
		temp_pulse_count -= 1;
		pulse_timer.start();
		var b = bullet.instance();
		enemy_container.add_child(b);
		b.init(muzzle.global_position, dir, scale, bullet_type);

func _on_pulse_timeout():
	shoot_pulse(pulse_dir);

func pulse(player_pos, flag):
	attack_anim_step += 1;
	var dest_pos;
	var dest_rot;
	var aim_angle = (180 - rad2deg(get_angle_to(player_pos))) if flag == 1 else -rad2deg(get_angle_to(player_pos));
	var i := 0;
	match(attack_anim_step):
		1:
			dest_pos = [Vector2(flag*15, -5), Vector2(0, -6), Vector2(-7, -14), Vector2(0, -5), Vector2(flag*-6, 4)];
			dest_rot = [aim_angle, flag*-40, flag*-50, flag*30, flag*30];
			if flag == -1:
				dest_pos[1] = Vector2(7, -14);
				dest_pos[2] = Vector2(0, -6);
			for node in [head, right_arm, left_arm, torso, tail]:
				attack_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				attack_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, dest_rot[i], 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			attack_tween.start();
		2:
			shoot((player_pos - position).normalized());
			var new_aim_angle = aim_angle + 15*flag;
			dest_pos = Vector2(flag*10, -8);
			attack_tween.interpolate_property(head, 'rect_position', head.rect_position, dest_pos, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN);
			attack_tween.interpolate_property(head, 'rect_rotation', head.rect_rotation, new_aim_angle, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN);
			attack_tween.start();
		3:
			dest_pos = Vector2(flag*15, -5);
			attack_tween.interpolate_property(head, 'rect_position', head.rect_position, dest_pos, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN);
			attack_tween.interpolate_property(head, 'rect_rotation', head.rect_rotation, aim_angle, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN);
			attack_tween.start();
		4:
			shoot((player_pos - position).normalized());
			var new_aim_angle = aim_angle + 15*flag;
			dest_pos = Vector2(flag*10, -8);
			attack_tween.interpolate_property(head, 'rect_position', head.rect_position, dest_pos, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN);
			attack_tween.interpolate_property(head, 'rect_rotation', head.rect_rotation, new_aim_angle, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN);
			attack_tween.start();
		5:
			dest_pos = Vector2(flag*15, -5);
			attack_tween.interpolate_property(head, 'rect_position', head.rect_position, dest_pos, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN);
			attack_tween.interpolate_property(head, 'rect_rotation', head.rect_rotation, aim_angle, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN);
			attack_tween.start();
		6:
			shoot((player_pos - position).normalized());
			var new_aim_angle = aim_angle + 15*flag;
			dest_pos = Vector2(flag*10, -8) if flag == -1 else Vector2(10, -8);
			attack_tween.interpolate_property(head, 'rect_position', head.rect_position, dest_pos, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN);
			attack_tween.interpolate_property(head, 'rect_rotation', head.rect_rotation, new_aim_angle, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN);
			attack_tween.start();
		7:
			dest_pos = Vector2(flag*15, -5);
			attack_tween.interpolate_property(head, 'rect_position', head.rect_position, dest_pos, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN);
			attack_tween.interpolate_property(head, 'rect_rotation', head.rect_rotation, aim_angle, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN);
			attack_tween.start();
		8:
			STATE_LOCK = true;
			attack_timer.start();

func shoot(dir):
	var b = bullet.instance();
	enemy_container.add_child(b);
	b.init(muzzle.global_position, dir, scale, bullet_type);

# warning-ignore:unused_argument
func homing(player_pos, flag):
	attack_anim_step += 1;
	var dest_pos;
	var dest_rot;
	var i := 0;
	match(attack_anim_step):
		1:
			dest_rot = [flag*140, flag*100, flag*180];
			dest_pos = [Vector2(flag*15, -5), Vector2(flag*15, -14), Vector2(flag*12, 2)];
			for node in [head, head2, head3]:
				attack_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				attack_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, dest_rot[i], 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			attack_tween.start();
		2:
			shoot_homing();
			dest_rot = [flag*115, flag*75, flag*155];
			dest_pos = [Vector2(flag*10, -8), Vector2(flag*10, -17), Vector2(flag*7, -1)];
			for node in [head, head2, head3]:
				attack_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN);
				attack_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, dest_rot[i], 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			attack_tween.start();
		3:
			dest_rot = [flag*140, flag*100, flag*180];
			dest_pos = [Vector2(flag*15, -5), Vector2(flag*15, -14), Vector2(flag*12, 2)];
			for node in [head, head2, head3]:
				attack_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				attack_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, dest_rot[i], 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			attack_tween.start();
		4:
			STATE_LOCK = true;
			attack_timer.start();

func shoot_homing():
	for muz in [muzzle, muzzle2, muzzle3]:
		var b = homing_bullet.instance();
		enemy_container.add_child(b);
		b.init(muz.global_position, Vector2(0, -1).rotated(deg2rad(muz.get_parent().rect_rotation)), scale, bullet_type);

# warning-ignore:unused_argument
func laser(player_pos, flag):
	attack_anim_step += 1;
	match(attack_anim_step):
		1:
			var dest_pos := [];
			var dest_rot := [];
			var i := 0;
			if flag == 1:
				dest_rot = [120, 180, 240, 300, 360];
			else:
				dest_rot = [180, 240, 300, 360, 60];
			for rot in dest_rot:
				dest_pos.append(Vector2(Vector2().distance_to(Vector2(6, -12.5)), 0).rotated(deg2rad(rot)));
			for node in [head, right_arm, torso, left_arm, tail]:
				attack_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.5, Tween.TRANS_CUBIC, Tween.EASE_IN);
				attack_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, dest_rot[i], 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			attack_tween.start();
		2:
			shoot_laser(flag);
			anim_delay(attack_tween, 2);
		3:
			STATE_LOCK = true;
			attack_timer.start();

func shoot_laser(dir):
	if dir == 1:
		laser_ray.cast_to = Vector2(100000, 0).rotated(deg2rad(60));
	else:
		laser_ray.cast_to = Vector2(100000, 0).rotated(deg2rad(120));
	laser_ray.force_raycast_update();
	if laser_ray.is_colliding():
		laser_line.points[1] = to_local(laser_ray.get_collision_point());
	else:
		laser_line.points[1] = to_local(laser_ray.cast_to);
	laser_tween.interpolate_property(laser_line, 'width', 0, 10, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN);
	laser_tween.start();

func _on_laser_tween_all_completed():
	if laser_line.width == 10:
		laser_tween.interpolate_property(laser_line, 'width', 10, 0, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN, 1);
		laser_tween.start();
	else:
		emit_signal('laser_done');

func _on_attack_tween_all_completed():
	call(current_attack_anim, anim_player_pos, anim_move_dir_x);

# warning-ignore:unused_argument
# warning-ignore:unused_argument
func dive(player_pos, flag):
	movement_tween.stop_all();
	attack_anim_step += 1;
	var i = 0;
	var dest_pos;
	var dest_rot;
	match(attack_anim_step):
		1:
			dest_pos = [Vector2(flag*8, -12.5), Vector2(flag*-4, -19), Vector2(flag*-15, -29), 
						Vector2(flag*-4, -6), Vector2(flag*-15, 4)];
			dest_rot = [flag*90, flag*120, flag*140, flag*60, flag*40];
			dash_dir = (player_pos - position).normalized();
			attack_tween.interpolate_property(self, 'rotation', rotation, Vector2(flag, 0).angle_to(dash_dir), 0.4, Tween.TRANS_LINEAR, Tween.EASE_IN);
			for node in [head, right_arm, torso, left_arm, tail]:
				attack_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], 0.4, Tween.TRANS_LINEAR, Tween.EASE_IN);
				attack_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, dest_rot[i], 0.4, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			attack_tween.start();
		2:
			dash_speed = max_dash_speed;
			STATE = 'DASH';
			var tween_duration = position.distance_to(player_pos)/((dash_speed + speed)/2);
			attack_tween.interpolate_property(self, 'dash_speed', dash_speed, speed, tween_duration, Tween.TRANS_QUAD, Tween.EASE_IN);
			melee_coll.set_monitoring(true);
			
			dest_pos = [Vector2(flag*10, -12.5), Vector2(flag*-5, -15), Vector2(flag*-16, -19), 
						Vector2(flag*-5, -7), Vector2(flag*-17, -4)];
			dest_rot = [flag*90, flag*95, flag*95, flag*85, flag*85];
			for node in [head, right_arm, torso, left_arm, tail]:
				attack_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], tween_duration, Tween.TRANS_LINEAR, Tween.EASE_IN);
				attack_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, dest_rot[i], tween_duration, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			attack_tween.start();
		3:
			STATE = 'LIFT';
			lift_dir = (Vector2(player_pos.x + 200*flag, 200) - player_pos).normalized();
			var tween_duration = position.distance_to(Vector2(player_pos.x + 200*flag, 200))/(2*speed);
			attack_tween.interpolate_property(self, 'rotation', rotation, 0, tween_duration/2, Tween.TRANS_LINEAR, Tween.EASE_IN);
			melee_coll.set_monitoring(false);
			
			dest_pos = [Vector2(flag*8, -12.5), Vector2(flag*-2, -15), Vector2(flag*-13, -19), 
						Vector2(flag*-2, -7), Vector2(flag*-14, -4)];
			dest_rot = [flag*90, flag*100, flag*100, flag*80, flag*80];
			for node in [head, right_arm, torso, left_arm, tail]:
				attack_tween.interpolate_property(node, 'rect_position', node.rect_position, dest_pos[i], tween_duration, Tween.TRANS_LINEAR, Tween.EASE_IN);
				attack_tween.interpolate_property(node, 'rect_rotation', node.rect_rotation, dest_rot[i], tween_duration, Tween.TRANS_LINEAR, Tween.EASE_IN);
				i += 1;
			attack_tween.start();
		4:
			movement_tween.resume_all();
			STATE_LOCK = true;
			attack_timer.start();

# warning-ignore:unused_argument
func _on_melee_coll_body_entered(body):
	print('FLY ENEMY MELEE PLAYER DAMAGE CODE UNWRITTEN. WRITE IT IDIOT');
	melee_coll.set_deferred('monitoring', false);

func death():
	movement_tween.stop_all();
	attack_tween.stop_all();
	death_tween.interpolate_property(self, 'modulate', Color(1, 1, 1, 1), Color(1, 1, 1, 0), 1, Tween.TRANS_LINEAR, Tween.EASE_IN);
	death_tween.start();
	set_collision_mask_bit(2, false);

func anim_delay(tween, amount):
	tween.interpolate_property(head, 'rect_position', head.rect_position, head.rect_position, amount, Tween.TRANS_LINEAR, Tween.EASE_IN);
	tween.start();

func _on_death_tween_all_completed():
	emit_signal('on_free');
	queue_free();

func damage(amount, dir):
	if health > amount:
		health -= amount;
		STATE_LOCK = false;
		STATE = 'CC';
		knockback_dir.x = sign(dir.x)*300;
	else: 
		health = 0;
		STATE_LOCK = false;
		STATE = 'DEATH';

func _on_move_rotation_tween_all_completed():
	if rad2deg(vel_rot) >= 45:
		vel_rot_dir = -0.2;
	elif rad2deg(vel_rot) <= -45:
		vel_rot_dir = 0.2;
	move_rot_tween.interpolate_property(self, 'vel_rot', vel_rot, vel_rot + vel_rot_dir, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN);
	move_rot_tween.start();
