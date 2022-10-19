extends RigidBody2D

onready var sprite = $sprite;
onready var particles = $particles;
onready var collision = $collision;
onready var life_timer = $lifetime;
onready var redirect_tween = $redirect;
onready var world = $'../..';

var id;
var rate_of_homing;
var speed;
var damage;

func init(pos, dir, scal, bullet_id):
	
	id = bullet_id;
	
	var coll_info = {'homing_bullet': ['CIRCLE', 16.5, 0, Vector2()]};
	
	var bullet_speed := {'homing_bullet': 400};
	
	var bullet_damage := {'homing_bullet': 5};
	
	var collide_anim_num := {'homing_bullet': 6};
	
	var bullet_lifetime := {'homing_bullet': 3};
	
	var rate_of_homing_dict := {'homing_bullet': 0.5};
	
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
	sf.add_frame('fly', load('res://bullet/art/enemy_bullet/' + id + '/idle.png'));
	sf.add_animation('collide');
	sf.set_animation_loop('collide', false);
	sf.set_animation_speed('collide', 5);
	for i in range(collide_anim_num[id]):
		sf.add_frame('collide', load('res://bullet/art/enemy_bullet/' + id + '/collide_' + String(i + 1) + '.png'));
	sprite.frames = sf;
	sprite.scale = scal;
	
	particles.process_material = load('res://bullet/particles_material/' + id + '.tres');
	particles.texture = load('res://bullet/art/enemy_bullet/' + id + '/idle.png');
	particles.process_material.scale = scal.x;
	
	position = pos; 
	sprite.play('fly');
	
	damage = bullet_damage[id];
	if bullet_lifetime[id] != null:
		life_timer.start(bullet_lifetime[id]);
	speed = bullet_speed[id];
	rate_of_homing = rate_of_homing_dict[id];
	
	linear_velocity = dir * speed;
	redirect_tween.interpolate_property(self, 'linear_velocity', linear_velocity, (world.player.position - position).normalized() * speed, 0.5, Tween.TRANS_LINEAR, Tween.EASE_OUT);
	redirect_tween.start();

func _on_bullet_body_entered(body):
	if body.is_in_group('player'):
		pass#body.damage(bullet_damage[id], linear_velocity.normalized());
	if body.is_in_group('player') or body.is_in_group('obstacle') or body.is_in_group('practice_obstacle'):
		sprite.play('collide');
		redirect_tween.stop_all();
		particles.emitting = false;
		linear_velocity = Vector2();
		angular_velocity = 0;
		collision.set_deferred('disabled', true);

func _on_sprite_animation_finished():
	if sprite.get_animation() == 'collide':
		queue_free();

func _on_lifetime_timeout():
	sprite.play('collide');

func _on_redirect_tween_all_completed():
	var rotate_to = (world.player.position - position).normalized();
	if rad2deg(linear_velocity.angle_to(rotate_to)) > 45:
		rotate_to = linear_velocity.rotated(45);
	elif rad2deg(linear_velocity.angle_to(rotate_to)) < -45:
		rotate_to = linear_velocity.rotated(-45);
	redirect_tween.interpolate_property(self, 'linear_velocity', linear_velocity, rotate_to*speed, 0.5, Tween.TRANS_LINEAR, Tween.EASE_OUT, 0.75);
	redirect_tween.start();
