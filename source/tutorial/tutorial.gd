extends Node2D

var portal = preload('res://portal/portal.tscn');

onready var player = $player;
onready var camera = $camera;
onready var HUD = $HUD;
onready var music = $music;

var code_script = [];
var line_info := {};
var number_of_lines := -1;
var error_lines := [[11, '\terror_line'], 
					[12, '\terror_liney']];
var code_lines := [[11, '\tprintf(n);'], 
				   [10, '\tscanf(n);']];
var extra_lines := 5;

var current_trigger;
var level := 1;
var start_portal;
var rng := RandomNumberGenerator.new();

var tile_size := 22;
var trigger_range := 15.0;
var spawn_offset := 70;

func _notification(what):
	if (what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST):
		savegame();

func _ready():
	rng.randomize();
	player.set_character_info();
	connect_signals();
	loadgame();
	HUD.on_game_load();
	new_level();

func new_level():
	rotate_to = true#randf() < 0.1;
	generate_code();
	draw_labels_and_margins();
	find_platform_positions();
	find_powerup_positions();
	spawn_obstacles();
	spawn_platforms();
	spawn_powerups();
	spawn_triggers();
	update_camera();
	start_portal = create_portal(false, current_func, Vector2(spawn_offset, 300) if rotate_to else Vector2(512, spawn_offset));
	HUD.set_HUD_parameters(player.health, player.wpn);
	HUD.update_theme();
	camera_tween.interpolate_property(camera, "position", camera.position, Vector2(512, camera.end_point + 150) if rotate_to else Vector2(camera.end_point + 150, 300), 2, Tween.TRANS_LINEAR, Tween.EASE_OUT);
	camera_tween.start();
	yield(camera_tween, 'tween_all_completed');
	yield(get_tree().create_timer(2), 'timeout');
	camera_tween.interpolate_property(camera, "position", camera.position, Vector2(512, 300), 1, Tween.TRANS_LINEAR, Tween.EASE_OUT);
	camera_tween.start();
	yield(camera_tween, 'tween_all_completed');
	if rotate_to != rot_state:
		yield(get_tree().create_timer(2), "timeout");
		rotate_world();
	else:
		post_rotation();

onready var camera_tween = $camera_tween;
var rot_state := false; #true -> horizontal alignment, false -> vertical alignment
var rotate_to := true;

func rotate_world():
	rot_state = rotate_to;
	camera.mode = rot_state;
	camera_tween.interpolate_property(label_container, "rotation_degrees", label_container.rotation_degrees, -90 if rot_state else 0, 1, Tween.TRANS_LINEAR, Tween.EASE_OUT);
	camera_tween.interpolate_property(label_container, "position", label_container.position, Vector2(0, 600) if rot_state else Vector2(0, 0), 1, Tween.TRANS_LINEAR, Tween.EASE_OUT);
	camera_tween.interpolate_property(obstacle_container, "rotation_degrees", obstacle_container.rotation_degrees, -90 if rot_state else 0, 1, Tween.TRANS_LINEAR, Tween.EASE_OUT);
	camera_tween.interpolate_property(obstacle_container, "position", obstacle_container.position, Vector2(0, 600) if rot_state else Vector2(0, 0), 1, Tween.TRANS_LINEAR, Tween.EASE_OUT);
	camera_tween.interpolate_property(powerup_container, "rotation_degrees", powerup_container.rotation_degrees, -90 if rot_state else 0, 1, Tween.TRANS_LINEAR, Tween.EASE_OUT);
	camera_tween.interpolate_property(powerup_container, "position", powerup_container.position, Vector2(0, 600) if rot_state else Vector2(0, 0), 1, Tween.TRANS_LINEAR, Tween.EASE_OUT);
	for p in powerup_container.get_children():
		camera_tween.interpolate_property(p, "rotation_degrees", p.rotation_degrees, 90 if rot_state else 0, 1, Tween.TRANS_LINEAR, Tween.EASE_OUT);
	camera_tween.start();
	yield(camera_tween, 'tween_all_completed');
	post_rotation();

func post_rotation():
	for obs in obstacle_container.get_children():
		if obs.type == null: 
			obs.type = 'DUMMY';
			obs.init();
		if obs.type == 'ENEMY' or obs.type == 'POWERUP':
			obs.init();
	yield(get_tree().create_timer(1), 'timeout');
	for obs in obstacle_container.get_children():
		if obs.type == 'OBSTACLE':
			obs.init();
	HUD.show_progress(level);
	powerup_container.show();
	start_portal.spawn();
	yield(start_portal, 'spawn_player');
	player.init(start_portal.position);
	yield(player, "player_spawned");
	camera.set_process(true);
	start_portal.despawn();

func level_cleared():
	level += 1;
	HUD.transition.show();
	HUD.transition.fade_out(null);
	yield(HUD.transition.anim_player, 'animation_finished');
	for t in trigger_container.get_children():
		t.queue_free();
	for o in obstacle_container.get_children():
		o.queue_free();
	for l in label_container.get_children():
		if l.get_name() != 'margin_line': l.queue_free();
	for p in powerup_container.get_children():
		p.queue_free();
	for e in enemy_container.get_children():
		e.queue_free();
	for p in portal_container.get_children():
		p.queue_free();
	yield(get_tree().create_timer(1), "timeout");
	player.disable();
	camera.reset_cam();
	code_script = [];
	line_info = {};
	number_of_lines = -1;
	powerup_list = {};
	platform_list = {};
	func_endpoints = [];
	func_stack = [];
	force_vertical();
	HUD.transition.anim_player.play('fade_in');
	new_level();

func force_vertical(): #delete during deployment
	label_container.rotation_degrees = 0;
	label_container.position = Vector2(0, 0);
	obstacle_container.rotation_degrees = 0;
	obstacle_container.position = Vector2(0, 0);
	powerup_container.rotation_degrees = 0;
	powerup_container.position = Vector2(0, 0);
	rot_state = false;

var func_names = [['\tint a=f(a,b);', 'int', 'f(a,b)'], 
				  ['\tfunc2();', 'void', 'func2()']];
var func_endpoints := [];
var func_stack := [];
var current_func := 0;

func generate_code():
	add_line();
	add_line();
	add_line('#include<stdio.h>', true);
	add_line(' ', true);
	for func_name in func_names:
		add_line(func_name[1] + ' ' + func_name[2] + ';', true);
	add_line(' ', true);
	add_line(' ', true);
	add_line('int main()', true);
	add_line('{', true);
	add_line(' ', true);
	add_line('\tclrscr();', true);
	add_line(' ', true);
	populate_function();
	add_line(' ', true);
	add_line('\treturn 0;', null);
	add_line('}', true);
	func_endpoints.append(number_of_lines);
	for func_name in func_names:
		generate_functions(func_name);

func generate_functions(func_name):
# warning-ignore:unused_variable
	for i in range(10):
		add_line();
	add_line(func_name[1] + ' ' + func_name[2], true);
	func_name.append(Vector2(spawn_offset + number_of_lines*tile_size, 300) if rotate_to else Vector2(512, spawn_offset + number_of_lines*tile_size));
	add_line('{', true);
	add_line(' ', true);
	populate_function();
	add_line('\treturn;', null);
	add_line('}', true);
	func_endpoints.append(number_of_lines);

func populate_function():
	func_endpoints.append(number_of_lines);
# warning-ignore:unused_variable
	for i in range(5 + randi() % 10):
		if rng.randi() % 4 == 0:
			add_line(code_lines[randi() % error_lines.size()][1], false);
		else:
			if rng.randi() % 4 == 0:
				var func_id = randi() % func_names.size();
				add_line(func_names[func_id][0], func_id + 1);
			else:
				add_line(code_lines[randi() % code_lines.size()][1], true);

func add_line(text = '', type = true):
	number_of_lines += 1;
	code_script.append(text);
	line_info[number_of_lines] = [type, text.length(), null];

var trigger = preload("res://trigger/trigger.tscn");
onready var trigger_container = $trigger_container;

func spawn_triggers():
	for j in range(0, func_endpoints.size(), 2):
		var number_of_triggers = ceil((func_endpoints[j+1] - func_endpoints[j])/trigger_range);
		for i in range(number_of_triggers):
			var t_pos = spawn_offset + tile_size*(func_endpoints[j] + trigger_range*i);
# warning-ignore:integer_division
			var t = make_trigger('enemy', t_pos, 300 if rotate_to else 512);
			var end = min(func_endpoints[j] + trigger_range*(i+1), func_endpoints[j+1]);
			for k in range(func_endpoints[j] + trigger_range*i, end):
				if line_info.keys().has(k):
					if line_info[k][0] == null:
						t.portal_list.append([line_info[k][0], k]);
					elif line_info[k][0] is int:
						t.portal_list.append([line_info[k][0], k]);
					elif not line_info[k][0]:
						t.index_list.append(k);
				else:
					break;
# warning-ignore:integer_division
	var death_trigger_pos = spawn_offset + tile_size*number_of_lines/2;
	if rotate_to:
		make_trigger('death', death_trigger_pos, tile_size*10 + death_trigger_pos);
	else:
		make_trigger('death', Vector2(-50, death_trigger_pos), tile_size*10 + death_trigger_pos);
		make_trigger('death', Vector2(1074, death_trigger_pos), tile_size*10 + death_trigger_pos);

func make_trigger(type, pos, size):
	var t = trigger.instance();
	trigger_container.add_child(t);
	t.init(type, rotate_to, pos, size);
	match(type):
		'enemy':
			t.connect("player_entered", self, 'spawn_enemy');
			return t;
		'death':
			t.connect("player_entered", player, 'kill');

var ground_enemy = preload("res://enemy/ground_enemy.tscn");
var fly_enemy = preload("res://enemy/fly_enemy.tscn");
onready var enemy_container = $enemy_container;
onready var kill_timer = $kill_timer;

func spawn_enemy(trigger_obj):
	current_trigger = trigger_obj;
	if trigger_obj.index_list.empty():
		check_container(true);
	else:
		kill_timer.start();
		for t in trigger_container.get_children():
			if t.type == 'enemy':
				t.detector.set_deferred('disabled', true);
		for i in trigger_obj.index_list:
			var e_pos = Vector2(spawn_offset + i*tile_size, 300);
			var e = choose_enemy(e_pos);
			var start_index = obstacle_container.get_children().find(line_info[i][2]);
			for j in range(code_script[i].length()):
				if obstacle_container.get_child(start_index + j).type == 'ENEMY':
					obstacle_container.get_child(start_index + j).converge(e_pos);
					obstacle_container.get_child(start_index).charlist += obstacle_container.get_child(start_index + j).label.text;
			obstacle_container.get_child(start_index).pos_tween.connect('tween_all_completed', obstacle_container.get_child(start_index), 'convergence_complete');
			obstacle_container.get_child(start_index).add_user_signal('send_charlist');
			obstacle_container.get_child(start_index).connect('send_charlist', e, 'init');

func choose_enemy(pos):
	var e = 0#randi() % 2;
	match(e):
		0:
			e = ground_enemy.instance();
		1:
			e = fly_enemy.instance();
	e.player = player;
	e.position = pos;
	enemy_container.call_deferred('add_child', e);
	e.hide();
	e.connect('on_free', self, 'check_container');
	return e;

func check_container(force_check := false):
	if enemy_container.get_child_count() > 1:
		kill_timer.start();
	elif enemy_container.get_child_count() == 1 or force_check:
		on_trigger_finish();

func on_trigger_finish():
	for t in range(current_trigger.portal_list.size()):
		var p = create_portal(true, current_func, Vector2(spawn_offset + tile_size*current_trigger.portal_list[t][1], 300) if rot_state else Vector2(512, spawn_offset + tile_size*current_trigger.portal_list[t][1]), current_trigger.portal_list[t][0]);
		p.spawn();
	current_trigger.queue_free();
	for t in trigger_container.get_children():
		t.detector.set_deferred('disabled', false);

func _on_kill_timer_timeout():
	var p = enemy_container.get_child(0);
	p.play('death');

onready var portal_container = $portal_container;

func create_portal(type, func_id, pos, dest_func_id = null):
	var p = portal.instance();
	portal_container.call_deferred('add_child', p);
	if type:
		if func_id == 0 and dest_func_id == null: 
			p.last_of_level = true; 
			p.connect('level_cleared', self, 'level_cleared');
		elif dest_func_id == null:
			p.connect('return_jump', self, 'return_jump');
		else:
			p.connect('jump', self, 'jump');
	p.set_name(('end_' if type else 'start_') + 'portal' + String(func_id));
	p.modulate = global.theme_values[global.theme_id][1];
	p.init(type, pos, dest_func_id);
	return p;

func jump(src, dest_id):
	if current_func == 0:
		func_stack.push_back([src, current_func]);
	else:
		func_stack.push_back([src, current_func - 1]);
	player.position = func_names[dest_id - 1][3];
	camera.zoom_in_out(func_names[dest_id - 1][3]);
	current_func = dest_id;
	yield(camera, 'zoom_complete');
	HUD.show_jump(func_names[dest_id - 1][2]);
	var p = create_portal(false, dest_id, func_names[dest_id - 1][3]);
	p.spawn();
	yield(p, 'spawn_player');
	player.init(p.position);
	yield(player, "player_spawned");
	p.despawn();

func return_jump():
	var stack_val = func_stack.pop_back();
	var return_pos = stack_val[0];
	var return_func_id = stack_val[1];
	var return_func_name = func_names[return_func_id][2];
	current_func = return_func_id;
	player.position = return_pos;
	camera.zoom_in_out(return_pos);
	yield(camera, 'zoom_complete');
	HUD.show_jump(return_func_name);
	var p = create_portal(false, return_func_id, return_pos);
	p.spawn();
	yield(p, 'spawn_player');
	player.init(p.position);
	yield(player, "player_spawned");
	p.despawn();

var powerup = preload("res://powerup/powerup.tscn");
onready var powerup_container = $powerup_container;
var powerup_types := {0: [2, 2, 2],
					  1: [2, 2, 2, 2, 2],
					  2: [4, 4]};
var powerup_designs := {0: [2, [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(0, 1), Vector2(1, 1), Vector2(2, 1)], Vector2(22, 33), 'while_gun'],
						1: [3, [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0), Vector2(4, 0), Vector2(0, 1), Vector2(1, 1), Vector2(2, 1), Vector2(3, 1), Vector2(4, 1)], Vector2(22, 55), 'for_gun'],
						2: [2, [Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(0, 3), Vector2(1, 0), Vector2(1, 1), Vector2(1, 2), Vector2(1, 3)], Vector2(44, 22), 'print_sword']};
var powerup_list := {};

func find_powerup_positions():
	#deciding positions of powerups
	for j in range(0, func_endpoints.size(), 2):
		var i = func_endpoints[j];
		while i < func_endpoints[j+1]:
			if rng.randi() % 4 == 0:
				powerup_list[i] = randi() % powerup_types.size();
				i = i + powerup_types[powerup_list[i]].size() + 10;
			else: 
				i += 1;
	#adjusting script according to powerup requirements
	for i in powerup_list.keys():
		if number_of_lines - extra_lines - i > powerup_types[powerup_list[i]].size(): #checking availability of length
			for j in range(i, i + powerup_types[powerup_list[i]].size()):
				if line_info[j][1] < powerup_types[powerup_list[i]][j-i]:
					code_script[j] = '\treplaced(n);';#replacing code
					line_info[j] = [true, powerup_types[powerup_list[i]][j-i]];
		else:
			break; 

func spawn_powerups():
	#spawn powerup
	for i in powerup_list.keys():
		var p;
		p = powerup.instance();
		powerup_container.call_deferred('add_child', p);
		p.init(powerup_designs[powerup_list[i]][3], powerup_designs[powerup_list[i]][2]);
		p.connect('picked_up', self, 'release_powerups', [p.get_instance_id()]);
		for j in powerup_designs[powerup_list[i]][1]:
			for o in obstacle_container.get_children():
				if o.mat_id == j + Vector2(i, powerup_designs[powerup_list[i]][0]):
					if j == Vector2():
						p.position = o.position + powerup_designs[powerup_list[i]][2];
						o.connect('disappearance_complete', p, 'show_powerup');
					o.type = 'POWERUP';
					o.powerup_id = p.get_instance_id();

func release_powerups(powerup_id):
	for obs in obstacle_container.get_children():
		if obs.powerup_id == powerup_id:
			obs.release();

var obstacle = preload("res://obstacle/obstacle.tscn");
onready var obstacle_container = $obstacle_container;

func spawn_obstacles():
	for i in range(code_script.size()):
		for j in range(code_script[i].length()):
			var o = obstacle.instance();
			o.mat_id = Vector2(i, j);
			if line_info[i][0] == null:
				o.type = 'OBSTACLE';
			elif line_info[i][0] is int:
				o.type = 'OBSTACLE';
			if not line_info[i][0]:
				if j==0: 
					line_info[i][2] = o;
				if o.type == null: o.type = 'ENEMY';
			elif j == 0: 
				o.type = 'OBSTACLE';
			o.position = Vector2(spawn_offset + j*tile_size, spawn_offset + i*tile_size);
			o.get_node('label').text = code_script[i][j];
			obstacle_container.add_child(o);

var platform_types := {0: [6, 6, 6, 0, 8, 8],
					   1: [5, 5, 5, 5, 5],
					   2: [1, 2, 3, 4],
					   3: [4, 6]};
var platform_designs := {0: [5, [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(4, 2), Vector2(5, 2)]],
						 1: [5, [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0), Vector2(4, 0)]],
						 2: [1, [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(2, 1), Vector2(2, 2), Vector2(3, 2), Vector2(3, 3)]],
						 3: [4, [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(1, 2)]]};
var platform_list := {};

func find_platform_positions():
	#deciding positions of platforms
	for j in range(0, func_endpoints.size(), 2):
		var i = func_endpoints[j];
		while i < func_endpoints[j+1]:
			if rng.randi() % 4 == 0:
				platform_list[i] = randi() % platform_types.size();
				i = i + platform_types[platform_list[i]].size() + 10;
			else: 
				i += 1;
	#adjusting script according to platform requirements
	for i in platform_list.keys():
		if number_of_lines - extra_lines - i > platform_types[platform_list[i]].size(): #checking availability of length
			for j in range(i, i + platform_types[platform_list[i]].size()):
				if line_info[j][1] < platform_types[platform_list[i]][j-i]:
					code_script[j] = '\treplaced(n);';#replacing code
					line_info[j] = [true, platform_types[platform_list[i]][j-i]];
		else:
			break; 

func spawn_platforms():
	#spawn platform
	for i in platform_list.keys():
		for j in platform_designs[platform_list[i]][1]:
			for o in obstacle_container.get_children():
				if o.mat_id == j + Vector2(i, platform_designs[platform_list[i]][0]):
					o.type = 'OBSTACLE';

onready var label_container = $label_container;
onready var margin_line = $label_container/margin_line;

func draw_labels_and_margins():
	var label_underline = StyleBoxFlat.new();
	label_underline.bg_color.a = 0;
	label_underline.border_width_bottom = 1;
	label_underline.border_color.a = 0.5;
	for i in range(number_of_lines + extra_lines):
		var l = Label.new();
		l.align = 0;
		l.valign = 0;
		l.autowrap = true;
		l.rect_size.x = 1024;
		l.rect_position = Vector2(0, spawn_offset + i*tile_size);
		l.text = "    " + String(i);
		l.add_stylebox_override("normal", label_underline);
		label_container.add_child(l);
	var margin = StyleBoxFlat.new();
	margin.bg_color.a = 0;
	margin.border_width_right = 1;
	margin.border_color.a = 0.5;
	margin_line.add_stylebox_override('normal', margin);
	margin_line.rect_size.y = spawn_offset + (number_of_lines + extra_lines + 5)*tile_size;
	number_of_lines += extra_lines;

func update_camera():
	camera.end_point = spawn_offset*2 + (number_of_lines + 1)*tile_size - (512 if rotate_to else 300);

func connect_signals():
	HUD.pause_panel.connect("user_quitting", self, "savegame");
	HUD.pause_panel.connect('change_volume', self, 'set_volume');
	HUD.pause_panel.connect('change_screen_stat', HUD, 'set_screen_stat');
	player.connect('player_is_dead', self, 'endgame');
	player.connect('player_health_update', HUD, 'update_health');
	HUD.pause_panel.connect('change_icon', HUD, 'change_icon');
	HUD.pause_panel.connect('update_theme', HUD, 'update_theme');

func set_volume(node, slider_val):
	match(node):
		'music':
			if slider_val == 0:
				music.volume_db = -60;
			else:
				music.volume_db = lerp(-15, 15, slider_val/100); 
		'sfx':
			if slider_val == 0:
				pass
			else:
				pass

func savegame():
	var save_game = File.new();
	save_game.open("user://amortum_sav_1.save", File.WRITE);
	var node_data = global.save();
	save_game.store_line(to_json(node_data));
	for node in get_tree().get_nodes_in_group("persist"):
		node_data = node.call("save");
		save_game.store_line(to_json(node_data));
	save_game.close();

func loadgame():
	var save_game = File.new();
	if save_game.file_exists("user://amortum_sav_1.save"):
		save_game.open("user://amortum_sav_1.save", File.READ);
	else:
		return;
	var save_nodes = get_tree().get_nodes_in_group("persist");
	var i = 0;
	var node_data = parse_json(save_game.get_line());
	while save_game.get_position() < save_game.get_len():
		node_data = parse_json(save_game.get_line());
		for j in node_data.keys():
			save_nodes[i].set(j, node_data[j]);
		i += 1;
	save_game.close();

func endgame():
	HUD.pause_panel.set_process_input(false);
	HUD.pause_button.disabled = true;
	HUD.music_mute_button.disabled = true;
	HUD.sfx_mute_button.disabled = true;
	HUD.pause_panel.show();
	HUD.pause_panel.anim_player.play('game_end');

func save():
	var save_dict = {
		"name": get_name(),
		"level": level};
	return save_dict;
