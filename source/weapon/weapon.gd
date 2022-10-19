extends Node2D

var bullet = preload('res://bullet/bullet.tscn');

onready var anim_player = $anim_player;
onready var muzzle = $sprite/muzzle;
onready var bullet_container = $bullet_container;
onready var sprite = $sprite;
onready var tween = $tween;
onready var melee_sprite = $melee_weapon/sprite;
onready var melee_coll = $melee_weapon/collision;
onready var melee_weapon = $melee_weapon;
onready var melee_particles = $melee_weapon/sprite/particles;

var muzzle_pos = {'for_gun': [Vector2(54, -11), Vector2(54, 11)],
				  'while_gun': [Vector2(54, -11), Vector2(54, 11)]};

var bullet_id = {'for_gun': 'for_bullet',
				 'while_gun': 'while_bullet'};

var wpn_scale := {'for_gun': Vector2(0.15, 0.15),
				  'while_gun': Vector2(0.15, 0.15),
				  'print_sword': Vector2(0.3, 0.3)};

var wpn_type := {'for_gun': 'ranged',
				 'while_gun': 'ranged' ,
				 'print_sword': 'melee'};

var melee_damage := {'print_sword': 5};

var can_shoot := true;
var id;
var type;

func _ready():
	set_process_input(false);
	set_physics_process(false);

func _input(event):
	if event.is_action_pressed("player_shoot") and can_shoot:
		if type == 'ranged':
			shoot_anim();
			shoot(muzzle.global_position, get_global_mouse_position());
			can_shoot = false;
		else:
			anim_player.play("attack");
			melee_particles.emitting = true;
			melee_weapon.monitoring = true;

# warning-ignore:unused_argument
func _physics_process(delta):
	if type == 'ranged':
		sprite.global_rotation_degrees = rad2deg(get_angle_to(get_global_mouse_position()));
		if sprite.global_rotation_degrees < -90 or sprite.global_rotation_degrees > 90:
			sprite.flip_v = true;
			muzzle.position = muzzle_pos[id][1];
		else:
			sprite.flip_v = false;
			muzzle.position = muzzle_pos[id][0];
	else:
		set_physics_process(false);

func init(wpn_id):
	id = wpn_id;
	type = wpn_type[id];
	if type == 'ranged':
		muzzle.position = muzzle_pos[id][0];
		melee_weapon.queue_free();
		sprite.set_texture(load('res://weapon/art/' + id + '/idle.png'));
	else:
		bullet_container.queue_free();
		sprite.queue_free();
		melee_sprite.set_texture(load('res://weapon/art/' + id + '/idle.png'));
		melee_particles.process_material.emission_box_extents = Vector3(melee_sprite.get_texture().get_width(), melee_sprite.get_texture().get_height(), 0);
	scale = wpn_scale[id];

func shoot(pos, dest):
	var b = bullet.instance();
	bullet_container.add_child(b);
	b.init(pos, dest, scale, bullet_id[id]);

func shoot_anim():
	if sprite.flip_v:
		tween.interpolate_property(self, 'rotation_degrees', rotation_degrees, rotation_degrees - 9, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN);
		tween.interpolate_property(self, 'position', position, position + Vector2(14, -6), 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN);
		tween.start();
		yield(get_tree().create_timer(0.1), "timeout");
		tween.interpolate_property(self, 'rotation_degrees', rotation_degrees, rotation_degrees + 6, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
		tween.interpolate_property(self, 'position', position, position + Vector2(-9, 0), 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
		tween.start();
		yield(get_tree().create_timer(0.2), "timeout");
		tween.interpolate_property(self, 'rotation_degrees', rotation_degrees, rotation_degrees + 3, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN);
		tween.interpolate_property(self, 'position', position, position + Vector2(-5, 6), 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN);
		tween.start();
		yield(get_tree().create_timer(0.1), "timeout");
		can_shoot = true;
	else:
		tween.interpolate_property(self, 'rotation_degrees', rotation_degrees, rotation_degrees + 9, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN);
		tween.interpolate_property(self, 'position', position, position + Vector2(-14, -6), 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN);
		tween.start();
		yield(get_tree().create_timer(0.1), "timeout");
		tween.interpolate_property(self, 'rotation_degrees', rotation_degrees, rotation_degrees - 6, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
		tween.interpolate_property(self, 'position', position, position + Vector2(9, 0), 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN);
		tween.start();
		yield(get_tree().create_timer(0.2), "timeout");
		tween.interpolate_property(self, 'rotation_degrees', rotation_degrees, rotation_degrees - 3, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN);
		tween.interpolate_property(self, 'position', position, position + Vector2(5, 6), 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN);
		tween.start();
		yield(get_tree().create_timer(0.1), "timeout");
		can_shoot = true;

func _on_anim_player_animation_finished(anim_name):
	if anim_name == 'attack':
		melee_particles.emitting = false;
		melee_weapon.monitoring = false;
		anim_player.stop(true);

func _on_melee_weapon_body_entered(body):
	if body.is_in_group('enemy'):
		body.damage(melee_damage[id], (body.position - position).normalized());
