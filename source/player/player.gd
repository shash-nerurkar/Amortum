extends KinematicBody2D

onready var sprite = $sprite;
onready var collision = $collision;
onready var jump_tween = $jump_tween;
onready var weapon = $weapon;

var speed := 200;
export var velocity := Vector2();
var gravity := Vector2(0, 198);
var j_flag := true;
var STATE = "IDLE";
var STATE_LOCK = true;

func _ready():
	weapon.init('ranged', 'while_gun');
	pass#set_physics_process(false);

# warning-ignore:unused_argument
func _physics_process(delta):
	if Input.is_action_pressed("player_left"):
		sprite.flip_h = true;
		velocity = velocity.linear_interpolate(Vector2(-1, velocity.y), delta);
		if STATE_LOCK: STATE = 'RUN';
	elif Input.is_action_pressed("player_right"):
		sprite.flip_h = false;
		velocity = velocity.linear_interpolate(Vector2(1, velocity.y), delta);
		if STATE_LOCK: STATE = 'RUN';
	elif j_flag and velocity.y == 0:
		velocity = velocity.linear_interpolate(Vector2(0, velocity.y), delta*4);
		if STATE_LOCK: STATE = 'IDLE';
	if Input.is_action_just_pressed("player_up") and j_flag:
		STATE = 'JUMP';
		j_flag = false;
		jump_tween.interpolate_property(self, 'velocity', Vector2(velocity.x, 0), Vector2(velocity.x, -4), 0.3, Tween.TRANS_SINE, Tween.EASE_IN);
		jump_tween.start();
	match(STATE):
		'IDLE':
			sprite.play('idle');
		'RUN':
			sprite.play('run');
		'JUMP':
			sprite.play('jump_up');
			STATE_LOCK = false;
# warning-ignore:return_value_discarded
	move_and_slide(velocity*speed);
# warning-ignore:return_value_discarded
	move_and_slide(gravity);

func _on_Area2D_body_entered(body):
	if body.is_in_group('obstacle'):
		body.anim_player.play("light_up");
	elif body.is_in_group('practice_obstacle'):
		body.get_node('AnimationPlayer').play("light_up");

func _on_Area2D_body_exited(body):
	if body.is_in_group('obstacle'):
		body.anim_player.play("light_down");
	elif body.is_in_group('practice_obstacle'):
		body.get_node('AnimationPlayer').play("light_down");
