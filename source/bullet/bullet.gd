extends RigidBody2D

onready var anim_player = $anim_player;
onready var sprite = $sprite;
onready var particles = $particles;
onready var collision = $collision;

var coll_info = {'for_bullet': ['CIRCLE', 16.5, 0, Vector2()],
				 'while_bullet': ['CIRCLE', 16.5, 0, Vector2()]};

var bullet_rigid_props := {'for_bullet': [0.5, 1]};

var bullet_speed := {'for_bullet': 300,
					 'while_bullet': 700};

var bullet_damage := {'for_bullet': 3,
					  'while_bullet': 5};

var collide_anim_num := {'for_bullet': 6,
						 'while_bullet': 6};

var bullet_type = {'for_bullet': 'RIGID',
				   'while_bullet': 'KINEMATIC'};

var id;
var knockback_dir;

func init(pos, dest, scal, bullet_id):
	id = bullet_id;
	if bullet_type[id] == 'KINEMATIC':
		gravity_scale = 0;
	elif bullet_type[id] == 'RIGID':
		var ph = PhysicsMaterial.new();
		ph.bounce = bullet_rigid_props[id][0];
		ph.friction = bullet_rigid_props[id][1];
		set_physics_material_override(ph);
	
	var coll_shape;
	match(coll_info[id][0]):
		'CIRCLE':
			coll_shape = CircleShape2D.new();
			coll_shape.radius = coll_info[id][1];
		'CAPSULE':
			coll_shape = CapsuleShape2D.new();
			coll_shape.height = coll_info[id][1];
			coll_shape.radius = coll_info[id][2];
		'RECTANGLE':
			coll_shape = CircleShape2D.new();
			coll_shape.extents = coll_info[id][1];
	collision.shape = coll_shape;
	collision.position = coll_info[id][3];
	collision.scale = scal;
	
	var sf = SpriteFrames.new();
	sf.add_animation('fly');
	sf.set_animation_speed('fly', 5);
	sf.add_frame('fly', load('res://bullet/art/player_bullet/' + id + '/idle.png'));
	sf.add_animation('collide');
	sf.set_animation_loop('collide', false);
	sf.set_animation_speed('collide', 5);
	for i in range(collide_anim_num[bullet_id]):
		sf.add_frame('collide', load('res://bullet/art/player_bullet/' + id + '/collide_' + String(i + 1) + '.png'));
	sprite.frames = sf;
	sprite.scale = scal;
	
	particles.process_material = load('res://bullet/particles_material/' + id + '.tres');
	particles.texture = load('res://bullet/art/player_bullet/' + id + '/idle.png');
	particles.process_material.scale = scal.x;
	
	position = pos; 
	sprite.play('fly');
	knockback_dir = (dest - pos).normalized();
	linear_velocity = bullet_speed[bullet_id]*knockback_dir;

func _on_bullet_body_entered(body):
	if body.is_in_group('enemy'):
		body.damage(bullet_damage[id], knockback_dir);
	if body.is_in_group('enemy') or body.is_in_group('obstacle') or body.is_in_group('practice_obstacle'):
		sprite.play('collide');
		particles.emitting = false;
		linear_velocity = Vector2();
		angular_velocity = 0;
		collision.set_deferred('disabled', true);
		gravity_scale = 0;

func _on_sprite_animation_finished():
	if sprite.get_animation() == 'collide':
		queue_free();
