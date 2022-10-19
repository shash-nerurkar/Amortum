extends Node2D

var obstacle = preload("res://obstacle/obstacle.tscn");

onready var obstacle_container = $obstacle_container;
onready var ground_enemy = $enemy_container/ground_enemy;
onready var fly_enemy = $enemy_container/fly_enemy;
onready var player = $player;

var i = 0;

func _ready():
	for i in range(40):
		for j in range(2):
			if i == 30 or i == 10 or i == 9: 
				continue;
			spawn_obs(Vector2(66 + 22*i, 354 + 22*j));
#	spawn_obs(Vector2(70 + 22 *30, 350 + 22*0 - 22*2));
#	spawn_obs(Vector2(70 + 22 *25, 350 + 22*0 - 22*5));
#	spawn_obs(Vector2(70 + 22 *25, 350 + 22*0 - 22*8));
#	spawn_obs(Vector2(70 + 22 *25, 350 + 22*0 - 22*9));
#	spawn_obs(Vector2(70 + 22 *20, 350 + 22*0 - 22*6));
#	spawn_obs(Vector2(70 + 22 *15, 350 + 22*0 - 22*7));
#	spawn_obs(Vector2(70 + 22 *15, 350 + 22*0 - 22*8));
	fly_enemy.player = player;
	fly_enemy.init('BULLET', 'shoot', 'dash_bomber');
	ground_enemy.player = player;
	ground_enemy.init('BULLET', 'shoot', 'shotgun');
	player.set_character_info();
	player.init(Vector2(350, 300));
	
	fly_enemy.queue_free();
#	ground_enemy.queue_free();

func spawn_obs(pos):
	var o = obstacle.instance();
	o.position = pos;
	o.type = 'OBSTACLE';
	obstacle_container.add_child(o);
	o.label.text = String(i);
	o.set_name('obstacle' + String(i));
	o.init();
	i += 1;
