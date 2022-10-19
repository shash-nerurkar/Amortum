extends RigidBody2D

signal disappearance_complete

onready var pos_tween = $position;
onready var label = $label;
onready var collision = $collision;
onready var anim_player = $anim_player;
onready var bg_color = $bg_color;

var mat_id := Vector2();
var type;
var flag = true;
var charlist := '';
var powerup_id;

func init():
	match(type):
		'OBSTACLE':
			mode = 1;
			anim_player.play("blink_box");
		'POWERUP':
			collision.set_deferred('disabled', true);
			remove_from_group("obstacle");
			anim_player.play("disappear_powerup");
			bg_color.color = Color(0, 1, 0, 0.12);
		'DUMMY':
			remove_from_group("obstacle");
			anim_player.play("disappear");
			mode = 0;
			gravity_scale = 1;
		'ENEMY':
			collision.set_deferred('disabled', true);
			remove_from_group("obstacle");
			bg_color.color = Color(1, 0, 0, 0.12);
		'PORTAL':
			collision.set_deferred('disabled', true);
			remove_from_group("obstacle");
			bg_color.color = Color(0, 0, 0.12);

func converge(dest):
	pos_tween.interpolate_property(self, 'global_position', global_position, dest, 1, Tween.TRANS_LINEAR, Tween.EASE_OUT);
	pos_tween.start();

func trash():
	if flag:
		flag = false;
		anim_player.play("disappear");
	collision.set_deferred('disabled', true);
	gravity_scale = 0;

func _on_anim_player_animation_finished(anim_name):
	if anim_name == "disappear":
		queue_free();
	elif anim_name == 'disappear_powerup':
		emit_signal('disappearance_complete');

func _on_position_tween_all_completed():
	queue_free();

func convergence_complete():
	match(type):
		'ENEMY':
			emit_signal('send_charlist', charlist);
		'PORTAL':
			emit_signal('spawn_portal');

func release():
	anim_player.play("disappear");
