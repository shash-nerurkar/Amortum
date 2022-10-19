extends KinematicBody2D

signal player_is_dead;
signal player_health_update(health);
signal player_spawned;

onready var sprite = $sprite;
onready var collision = $collision;
onready var weapon = $weapon;
onready var detector = $detector;
onready var spawn_tween = $spawning;
onready var dash_timer = $dash;

var health := 20;
export var vel := Vector2();
var speed := 300;
var gravity = 20;
var max_gravity := 300;
var jump_speed := 500;
var up_dir := Vector2(0, -1);
var wpn := 'for_gun';
var pick_powerup;
var powerup;
var frame_num := {'poleric': [8, 11, 4, 7],
				  'repenter': [8, 11, 4, 7]};
var STATE;
var dash_flag := 0;

func set_character_info():
	for i in range(frame_num[global.character][0]):
		sprite.frames.add_frame('idle', load('res://player/art/' + global.character + '/idle/' + String(i+1) + '.png'));
	for i in range(frame_num[global.character][1]):
		sprite.frames.add_frame('run', load('res://player/art/' + global.character + '/run/' + String(i+1) + '.png'));
	for i in range(frame_num[global.character][2]):
		sprite.frames.add_frame('jump', load('res://player/art/' + global.character + '/jump/' + String(i+1) + '.png'));
	for i in range(frame_num[global.character][3]):
		sprite.frames.add_frame('death', load('res://player/art/' + global.character + '/death/' + String(i+1) + '.png'));

func init(pos):
	show();
	detector.monitoring = true;
	collision.set_deferred('disabled', false);
	position = pos;
	spawn_tween.interpolate_property(self, 'vel', Vector2(100, 0), Vector2(100, 0), 1, Tween.TRANS_LINEAR, Tween.EASE_IN);
	spawn_tween.start();
	STATE = 'SPAWN';
	set_physics_process(true);

func _on_spawning_tween_all_completed():
	weapon.set_process_input(true);
	weapon.set_physics_process(true);
	STATE = 'MOVE';
	emit_signal('player_spawned');

func disable():
	hide();
	vel = Vector2();
	detector.monitoring = false;
	collision.set_deferred('disabled', true);
	set_physics_process(false);
	weapon.set_process_input(false);
	weapon.set_physics_process(false);
	sprite.flip_h = false;

func _input(event):
	if event.is_action_pressed('player_pickup'):
		if pick_powerup != null:
			$Label.text = pick_powerup.type;
			pick_powerup.picked_up();

func _ready():
	weapon.init(wpn);
	set_physics_process(false);

# warning-ignore:unused_argument
func _physics_process(delta):
	match(STATE):
		'SPAWN':
			pass
		'MOVE':
			if Input.is_action_just_pressed("player_left"):
				if dash_flag == 1:
					vel.x = -3*speed;
					dash_flag = -1;
					dash_timer.start(1);
				elif dash_flag == 0:
					dash_flag = 1;
					dash_timer.start(0.2);
			if Input.is_action_just_pressed("player_right"):
				if dash_flag == 2:
					vel.x = 3*speed;
					dash_flag = -1;
					dash_timer.start(1);
				elif dash_flag == 0:
					dash_flag = 2;
					dash_timer.start(0.2);
			if Input.is_action_pressed("player_left"):
				vel = vel.linear_interpolate(Vector2(-1*speed, vel.y), delta*1.5);
				sprite.flip_h = true;
				play('run');
			elif Input.is_action_pressed("player_right"):
				vel = vel.linear_interpolate(Vector2(1*speed, vel.y), delta*1.5);
				sprite.flip_h = false;
				play('run');
			if Input.is_action_pressed("player_up"):
				vel = vel.linear_interpolate(Vector2(vel.x, -1*speed), delta*1.5);
				play('run');
			elif Input.is_action_pressed("player_down"):
				vel = vel.linear_interpolate(Vector2(vel.x, 1*speed), delta*1.5);
				play('run');
			else:
				vel = vel.linear_interpolate(Vector2(), delta*3);
				play('idle');
			
		# warning-ignore:return_value_discarded
			move_and_slide(vel, up_dir);
		'DASH':
			pass
		'DEATH':
			if is_on_ceiling():
				vel.y = gravity;
			elif not is_on_floor():
				vel.y += gravity;
				vel.y = clamp(vel.y, -1*jump_speed, max_gravity);
			else:
				vel.y = gravity;
				set_physics_process(false);
		# warning-ignore:return_value_discarded
			move_and_slide(vel, up_dir);

func _on_dash_timeout():
	dash_flag = 0;

func play(anim):
	if anim == 'jump' or anim == 'death':
		sprite.play(anim);
	else:
		if sprite.animation == 'jump':
			if is_on_floor():
				sprite.play(anim);
		elif sprite.animation == 'death':
			return;
		else:
			sprite.play(anim);

func damage(amount):
	health = health - amount;
	if health <= 0:
		health = 0;
		weapon.queue_free();
		detector.monitoring = false;
		collision.set_deferred('disabled', true);
		play('death');
		STATE = 'DEATH';
	#screenshake
	emit_signal('player_health_update', health);

# warning-ignore:unused_argument
func kill(obs):
	if obs.is_in_group('death_trigger'):
		set_physics_process(false);
	damage(health);

func _on_Area2D_body_entered(body):
	if body.is_in_group('obstacle'):
		body.anim_player.play("light_up");

func _on_Area2D_body_exited(body):
	if body.is_in_group('obstacle'):
		body.anim_player.play("light_down");

func _on_sprite_animation_finished():
	if sprite.animation == 'death':
		emit_signal('player_is_dead');

func _on_detector_area_entered(area):
	if area.is_in_group('powerup'):
		pick_powerup = area;

func _on_detector_area_exited(area):
	if area.is_in_group('powerup'):
		pick_powerup = null;
