extends KinematicBody2D

signal boss_finished

onready var player;
onready var collision = $collision;
onready var state_label = $state;
onready var world;# = $'../..';
onready var attack_timer = $attack_timer;

onready var head = $Head;
onready var right_arm = $RightArm;
onready var left_arm = $LeftArm;
onready var torso = $Torso;
onready var right_leg = $RightLeg;
onready var left_leg = $LeftLeg;

onready var movement_tween = $movement;
onready var attack_tween = $attack;
onready var death_tween = $death;
onready var move_rot_tween = $move_rotation;

var health := 20;
var knockback_dir := Vector2();
var move_dir_x := -1;
var side_track_pos_y := 0;

var vel := Vector2();
var speed := 70;
var vel_rot := 0.0;
var vel_rot_dir := 0.1;

var attack_type;

var dash_speed;
var max_dash_speed;
var dash_dir;
var lift_dir;

var STATE;
var STATE_LOCK = true;

func _ready():
	#player = world.player;
	var limb_array = [head, right_arm, left_arm, torso, right_leg, left_leg];
	for i in [head, right_arm, left_arm, torso, right_leg, left_leg]:
		limb_array += i.get_children();
	var sb = StyleBoxFlat.new();
	sb.border_width_bottom = 0;
	sb.bg_color.a = 0;
	for label in limb_array:
		label.add_stylebox_override('normal', sb);
	
	STATE = 'SPAWN';
	STATE_LOCK = false;
	show();
	
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
			play('idle', true);
			vel = Vector2();
			STATE_LOCK = true;
		'IDLE':
			state_label.text = 'SHILLING';
			play('idle', true);
			call('flip', move_dir_x);
			vel = Vector2();
		'MOVE':
#			if face_ray.is_colliding():
#				if face_ray.get_collider().is_in_group('obstacle'):
#					side_track(face_ray.get_collider());
#			else:
			state_label.text = 'APPROACHING PLAYER';
			play('run', true);
			call('flip', move_dir_x);
			vel = Vector2(move_dir_x*speed, 0).rotated(vel_rot);
# warning-ignore:return_value_discarded
			move_and_slide(vel);
		'SIDE_TRACK':
			state_label.text = 'SIDE-TRACKING';
			play('side_track_anim', true);
# warning-ignore:return_value_discarded
			move_and_slide(vel);
			if abs(position.y - side_track_pos_y) <= 2:
				STATE_LOCK = true;
		'ATTACK':
			state_label.text = 'INITIATING ATTACK';
			if attack_timer.is_stopped():
				play(attack_type, false);
			else:
				play('idle', true);
			call('flip', move_dir_x);
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
	STATE = 'MOVE';

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

# warning-ignore:unused_argument
func idle(flag):
	pass

# warning-ignore:unused_argument
func run(flag):
	pass

# warning-ignore:unused_argument
func side_track_anim(flag):
	pass

# warning-ignore:unused_argument
func flip(flag):
	pass

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

func _on_attack_tween_all_completed():
	call(current_attack_anim, anim_player_pos, anim_move_dir_x);

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
	emit_signal('boss_finished');
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
