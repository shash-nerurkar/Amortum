extends Area2D

onready var detector = $detector;

signal player_entered(trigger_obj)

var index_list := [];
var portal_list := [];
var type;

func init(trigger_type, orientation, pos, size):
	type = trigger_type;
	match(type):
		'death':
			if orientation:
				rotation_degrees = 0;
				position = Vector2(pos, 650);
				detector.shape.extents.x = size;
			else:
				rotation_degrees = 90;
				position = pos;
				detector.shape.extents.x = size;
		'enemy':
			if orientation:
				rotation_degrees = 90;
				position = Vector2(pos, 300);
				detector.shape.extents.x = size;
			else:
				rotation_degrees = 0;
				position = Vector2(512, pos);
				detector.shape.extents.x = size;

func _on_trigger_body_entered(body):
	if body.is_in_group('player'):
		match(type):
			'death':
				emit_signal('player_entered', self);
			'enemy':
				emit_signal('player_entered', self);
