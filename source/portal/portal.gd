extends Area2D

signal level_cleared
signal jump
signal return_jump
signal spawn_player

onready var sprite = $sprite;
onready var collision = $collision;

var status;
var last_of_level;
var dest_id;

func init(stat, pos, d_id):
	modulate = global.theme_values[global.theme_id][1];
	position = pos;
	status = stat;
	if status: 
		dest_id = d_id;
		$sprite.flip_h = true;

func disable():
	hide();
	if status: 
		collision.set_deferred('disabled', true);

func _on_sprite_animation_finished():
	if sprite.animation == 'spawn':
		sprite.play('idle');
		emit_signal('spawn_player');
	elif sprite.animation == 'despawn':
		if status:
			if last_of_level: 
				emit_signal('level_cleared');
			elif dest_id == null:
				emit_signal('return_jump');
			else:
				emit_signal('jump', position, dest_id);
		queue_free();

func spawn():
	show();
	$sprite.play('spawn');
	if status: 
		$collision.set_deferred('disabled', false);

func despawn():
	sprite.play('despawn');

# warning-ignore:unused_argument
func _on_portal_body_entered(body):
	if status:
		if not last_of_level and dest_id == null:
			emit_signal('return_jump');
		else:
			sprite.play('despawn');
		body.disable();
