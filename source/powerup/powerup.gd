extends Area2D

signal picked_up

onready var sprite = $sprite;
onready var collision = $collision;
onready var anim_player = $anim_player;

var type;

func init(powerup_type, dim):
	type = powerup_type;
	$collision.shape.extents = Vector2(dim.y, dim.x);
	var tex = load("res://weapon/art/" + type + "/idle.png")
	$sprite.texture = tex;
	dim /= 1.5;
	if dim.x > dim.y:
		$sprite.scale = Vector2(dim.x/tex.get_width(), dim.x/tex.get_width());
	else:
		$sprite.scale = Vector2(dim.y/tex.get_height(), dim.y/tex.get_height());

func show_powerup():
	anim_player.play('show');

func _on_anim_player_animation_finished(anim_name):
	if anim_name == 'show':
		collision.set_deferred('disabled', false);
	elif anim_name == 'disappear':
		queue_free();

func picked_up():
	anim_player.play("disappear");
	emit_signal("picked_up");
