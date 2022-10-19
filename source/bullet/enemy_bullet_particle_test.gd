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

var bullet_rigid_props := {'bomber_bullet': [0.5, 1],
						   'bomb_bullet': [0.5, 1]};

var bullet_speed := {'bomber_bullet': 300,
					 'sniper_bullet': 1500,
					 'pulse_bullet': 800,
					 'shotgun_bullet': 1000,
					 'bomb_bullet': 150};

var bullet_damage := {'bomber_bullet': 3,
					  'sniper_bullet': 5,
					  'pulse_bullet': 5,
					  'shotgun_bullet': 5,
					  'bomb_bullet': 7};

var collide_anim_info := {'bomber_bullet': [1, 8],
						 'sniper_bullet': [1, 6],
						 'pulse_bullet': [1, 6],
						 'shotgun_bullet': [1, 6],
						 'bomb_bullet': [2, 10, 16]};

var bullet_type := {'bomber_bullet': 'RIGID',
					'sniper_bullet': 'KINEMATIC',
					'pulse_bullet': 'KINEMATIC',
					'shotgun_bullet': 'KINEMATIC',
					'bomb_bullet': 'CHARACTER'};

var bullet_lifetime := {'bomber_bullet': 7,
						'sniper_bullet': 7,
						'pulse_bullet': 7,
						'shotgun_bullet': 0.2,
						'bomb_bullet': 7};

var bullet_AOE_info := {'bomb_bullet': 50};

var id;
var knockback_dir;
var move_tween;
var start_pos := Vector2(924, 300);
var move_dir := Vector2(-1, 0);

func _ready():
	
	id = 'sniper_bullet';
	
	var pos = Vector2(100, 300);
	var dir = Vector2(1, 0);
	scale = Vector2(1, 1);
	
	match(bullet_type[id]):
		'KINEMATIC':
			gravity_scale = 0;
			
		'RIGID':
			var ph = PhysicsMaterial.new();
			ph.bounce = bullet_rigid_props[id][0];
			ph.friction = bullet_rigid_props[id][1];
			set_physics_material_override(ph);
			
		'CHARACTER':
			var ph = PhysicsMaterial.new();
			ph.bounce = bullet_rigid_props[id][0];
			ph.friction = bullet_rigid_props[id][1];
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
	sf.add_animation('fly');
	sf.set_animation_speed('fly', 5);
	sf.add_frame('fly', load('res://bullet/art/enemy_bullet/' + id + '/idle.png'));
	
	sf.add_animation('collide');
	sf.set_animation_loop('collide', false);
	sf.set_animation_speed('collide', 10);
	for i in range(collide_anim_info[id][1]):
		sf.add_frame('collide', load('res://bullet/art/enemy_bullet/' + id + '/collide_' + String(i + 1) + '.png'));
	
	if collide_anim_info[id][0] == 2:
		sf.add_animation('collide2');
		sf.set_animation_loop('collide2', false);
		sf.set_animation_speed('collide2', 10);
		for i in range(collide_anim_info[id][2]):
			sf.add_frame('collide2', load('res://bullet/art/enemy_bullet/' + id + '/collide2_' + String(i + 1) + '.png'));
	
	sprite.frames = sf;
	sprite.play('fly');
	
	particles.process_material = load('res://bullet/particles_material/' + id + '.tres');
	particles.texture = load('res://bullet/art/enemy_bullet/' + id + '/idle.png');
	particles.process_material.scale = scale.x;
	
	position = pos; 
	knockback_dir = dir;
	rotation = Vector2(1, 0).angle_to(knockback_dir);
	particles.process_material.angle = -rad2deg(rotation);
	particles.process_material.direction = Vector3(-1*knockback_dir.x, -1*knockback_dir.y, 0);
	linear_velocity = knockback_dir * bullet_speed[id];
	
	if bullet_lifetime[id] != null:
		life_timer.start(0.1);
	
	if bullet_AOE_info.keys().has(id):
		AOE_collision.shape.radius = bullet_AOE_info[id];
	else:
		AOE.queue_free();
	
	move_tween = Tween.new();
	add_child(move_tween);
	
	bullet_lifetime[id] = 300;

# warning-ignore:unused_argument
func _physics_process(delta):
	if position.distance_to(start_pos) <= 100:
		start_pos.x = 100 if start_pos.x == 924 else 924;
		move_tween.interpolate_property(self, 'linear_velocity', linear_velocity, linear_velocity*move_dir, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN);
		particles.process_material.direction *= Vector3(-1, -1, 0);
		move_tween.start();

func _on_bullet_body_entered(body):
	if body.is_in_group('player') or body.is_in_group('obstacle'):
		particles.emitting = false;
		linear_velocity = Vector2();
		angular_velocity = 0;
		collision.set_deferred('disabled', true);
		gravity_scale = 0;
	if body.is_in_group('player'):
		print('ENEMY BULLET PLAYER DAMAGE CODE UNWRITTEN');#body.damage(bullet_damage[id], knockback_dir);
		sprite.play('collide');
	elif body.is_in_group('obstacle'):
		if bullet_AOE_info.keys().has(id):
			for body in AOE.get_overlapping_bodies():
				if body.is_in_group('player'):
					print('ENEMY AOE BULLET PLAYER DAMAGE CODE UNWRITTEN');#body.damage(bullet_damage[id], knockback_dir);
		if sprite.frames.has_animation('collide2'):
			sprite.play('collide2');
		else:
			sprite.play('collide');

func _on_lifetime_timeout():
	if not particles.emitting:
		particles.emitting = true;
		life_timer.start(bullet_lifetime[id] - 0.1);
	else:
		sprite.play('collide');

func _on_sprite_animation_finished():
	if sprite.get_animation() == 'collide':
		queue_free();
