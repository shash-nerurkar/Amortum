extends RigidBody2D

onready var anim_player = $anim_player;
onready var sprite = $sprite;
onready var particles = $particles;
onready var collision = $collision;
onready var life_timer = $lifetime;
onready var AOE_collision = $AOE/CollisionShape2D;
onready var AOE = $AOE;

var coll_info = {'bomber_bullet': ['CIRCLE', 16.5, 0, Vector2()],
				 'sniper_bullet': ['CIRCLE', 16.5, 0, Vector2()],
				 'pulse_bullet': ['CIRCLE', 16.5, 0, Vector2()],
				 'shotgun_bullet': ['CIRCLE', 16.5, 0, Vector2()],
				 'bomb_bullet': ['CIRCLE', 16.5, 0, Vector2()]};

var rigid_props := {'bomber_bullet': [0.5, 1],
					'bomb_bullet': [0.5, 1]};

var speed := {'bomber_bullet': 300,
			  'sniper_bullet': 1500,
			  'pulse_bullet': 800,
			  'shotgun_bullet': 1000,
			  'bomb_bullet': 150};

var damage := {'bomber_bullet': 3,
			   'sniper_bullet': 5,
			   'pulse_bullet': 5,
			   'shotgun_bullet': 5,
			   'bomb_bullet': 7};

var anim_info := {'fly': {'bomber_bullet': [1, 5],
						  'sniper_bullet': [1, 5],
						  'pulse_bullet': [1, 5],
						  'shotgun_bullet': [1, 5],
						  'bomb_bullet': [1, 5]},
				
				  'collide': {'bomber_bullet': [8, 10],
							  'sniper_bullet': [6, 10],
							  'pulse_bullet': [6, 10],
							  'shotgun_bullet': [6, 25],
							  'bomb_bullet': [10, 10]},
				
				  'collide2': {'bomb_bullet': [16, 10]}};

var type := {'bomber_bullet': 'RIGID',
			 'sniper_bullet': 'KINEMATIC',
			 'pulse_bullet': 'KINEMATIC',
			 'shotgun_bullet': 'KINEMATIC',
			 'bomb_bullet': 'CHARACTER'};

var lifetime := {'bomber_bullet': 7,
				 'sniper_bullet': 7,
				 'pulse_bullet': 7,
				 'shotgun_bullet': 0.2,
				 'bomb_bullet': 7};

var AOE_info := {'bomb_bullet': 50};

var particle_info := {'amount': {'bomber_bullet': 8,
								 'sniper_bullet': 20,
								 'pulse_bullet': 8,
								 'shotgun_bullet': 2,
								 'bomb_bullet': 8},
					
					  'lifetime': {'bomber_bullet': 1,
								   'sniper_bullet': 0.1,
								   'pulse_bullet': 1,
								   'shotgun_bullet': 1,
								   'bomb_bullet': 1},
					
					  'local_coords': {'bomber_bullet': false,
									   'sniper_bullet': true,
									   'pulse_bullet': false,
									   'shotgun_bullet': false,
									   'bomb_bullet': false},
					
					  'one_shot': {'bomber_bullet': false,
								  'sniper_bullet': false,
								  'pulse_bullet': false,
								  'shotgun_bullet': true,
								  'bomb_bullet': false},
					
					  'explosiveness': {'bomber_bullet': 0,
										'sniper_bullet': 0,
										'pulse_bullet': 0,
										'shotgun_bullet': 1,
										'bomb_bullet': 0}};

var scal := {'bomber_bullet': Vector2(0.4, 0.4),
			 'sniper_bullet': Vector2(0.2, 0.2),
			 'pulse_bullet': Vector2(0.2, 0.2),
			 'shotgun_bullet': Vector2(0.2, 0.2),
			 'bomb_bullet': Vector2(0.4, 0.4)};

var id;
var knockback_dir;

func init(pos, dir, enemy_scal, bullet_id):
	
	id = bullet_id;
	
	sprite.scale = enemy_scal*scal[id];
	collision.scale = enemy_scal*scal[id];
	AOE.scale = enemy_scal*scal[id];
	
	match(type[id]):
		'KINEMATIC':
			gravity_scale = 0;
			
		'RIGID':
			var ph = PhysicsMaterial.new();
			ph.bounce = rigid_props[id][0];
			ph.friction = rigid_props[id][1];
			set_physics_material_override(ph);
			
		'CHARACTER':
			var ph = PhysicsMaterial.new();
			ph.bounce = rigid_props[id][0];
			ph.friction = rigid_props[id][1];
			set_physics_material_override(ph);
			mode = RigidBody2D.MODE_CHARACTER;
	
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
	
	var sf = SpriteFrames.new();
	for anim in anim_info.keys():
		if anim_info[anim].keys().has(id):
			sf.add_animation(anim);
			sf.set_animation_speed(anim, anim_info[anim][id][1]);
			for i in range(anim_info[anim][id][0]):
				sf.add_frame(anim, load('res://bullet/art/enemy_bullet/' + id + '/' + anim + '_' + String(i + 1) + '.png'));	
	sprite.frames = sf;
	
	particles.process_material = load('res://bullet/particles_material/' + id + '.tres');
	particles.texture = load('res://bullet/art/enemy_bullet/' + id + '/particle.png');
	for prop in particle_info.keys():
		particles.process_material.set(prop, particle_info[prop][id]);
	particles.process_material.angle = -rad2deg(rotation);
#	particles.process_material.direction = Vector3(dir.x, dir.y, 0);
	particles.process_material.scale = scal[id].x;
	
	position = pos; 
	rotation = Vector2(1, 0).angle_to(dir);
	linear_velocity = dir * speed[id];
	knockback_dir = dir;
	
	if lifetime[id] != null:
		life_timer.start(0.02);
	
	if AOE_info.keys().has(id):
		AOE_collision.shape.radius = AOE_info[id];
	else:
		AOE.queue_free();
		
	sprite.play('fly');

func _on_bullet_body_entered(body):
	if body.is_in_group('player') or body.is_in_group('obstacle'):
		collision.set_deferred('disabled', true);
		particles.emitting = false;
		linear_velocity = Vector2();
		angular_velocity = 0;
		gravity_scale = 0;
	if body.is_in_group('player'):
		pass#body.damage(bullet_damage[id], knockback_dir);
		sprite.play('collide');
	elif body.is_in_group('obstacle'):
		if AOE_info.keys().has(id):
			for body in AOE.get_overlapping_bodies():
				if body.is_in_group('player'):
					pass#body.damage(bullet_damage[id], knockback_dir);
		if sprite.frames.has_animation('collide2'):
			sprite.play('collide2');
		else:
			sprite.play('collide');

func _on_sprite_animation_finished():
	if sprite.get_animation() == 'collide' or sprite.get_animation() == 'collide2':
		queue_free();

func _on_lifetime_timeout():
	if not particles.emitting:
		particles.emitting = true;
		life_timer.start(lifetime[id] - 0.02);
	else:
		sprite.play('collide');
