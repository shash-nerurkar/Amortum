extends Control

signal prompt_answered

onready var anim_player = $transition/anim_player;
onready var transition = $transition;

var prompt_status;

func _ready():
	transition.anim_player.play("fade_in");
	OS.window_fullscreen = true;
	loadgame();
	update_theme();
	if File.new().file_exists("user://amortum_sav_1.save"):
		load_game.disabled = false;

onready var prompt = $margin_setter/prompt_inner_margin;

func _on_new_game_pressed():
	var save_game = Directory.new();
	if save_game.file_exists("user://amortum_sav_1.save"):
		prompt.show();
		yield(self, 'prompt_answered');
		if prompt_status:
			save_game.remove("user://amortum_sav_1.save");
			transition.fade_out('res://character_selection/character_selection.tscn');
		else:
			prompt.hide();
	else:
		transition.fade_out('res://character_selection/character_selection.tscn');

func _on_load_game_pressed():
	transition.fade_out('res://world/world.tscn');

func _on_credits_pressed():
	transition.fade_out('res://credits/credits.tscn');

func _on_quit_game_pressed():
	get_tree().quit();

func loadgame():
	var save_game = File.new();
	if not save_game.file_exists("user://amortum_sav_1.save"):
		return;
	save_game.open("user://amortum_sav_1.save", File.READ);
	var node_data = parse_json(save_game.get_line());
	for j in node_data.keys():
		global.set(j, node_data[j]);
	save_game.close();

onready var title = $margin_setter/parent_container/title;
onready var new_game = $margin_setter/parent_container/button_container/new_game;
onready var load_game = $margin_setter/parent_container/button_container/load_game;
onready var credits = $margin_setter/parent_container/button_container/credits;
onready var quit_game = $margin_setter/parent_container/button_container/quit_game;

func update_theme():
	var theme = load("res://button_theme.tres");
	var theme_color = global.theme_values[global.theme_id][1];
	var font = load(global.font_values[global.font_id][1]);
	
	var button_font = DynamicFont.new();
	button_font.font_data = load(global.font_values[global.font_id][1]);
	button_font.size = 32;
	new_game.add_font_override("font", button_font);
	load_game.add_font_override("font", button_font);
	credits.add_font_override("font", button_font);
	quit_game.add_font_override("font", button_font);
	
	var title_font = DynamicFont.new();
	var title_color = theme_color;
	title_font.font_data = load(global.font_values[global.font_id][1]);
	title_font.size = 66;
	title_color.v = 0.97;
	title.add_color_override("font_color", title_color)
	title.add_font_override("font", title_font);
	
	var theme_label_font = DynamicFont.new();
	theme_label_font.font_data = font;
	theme_label_font.size = 20;
	theme.set_font('font', 'Label', theme_label_font);
	
	var border_box = theme.get_stylebox('normal', 'Button');
	border_box.border_color = Color(0, 0, 0, 0);
	theme.set_stylebox('normal', 'Button', border_box);
	theme.set_stylebox('hover', 'Button', border_box);
	theme.set_stylebox('pressed', 'Button', border_box);
	theme.set_stylebox('disabled', 'Button', border_box);
	
	var label_underline = theme.get_stylebox('normal', 'Label');
	label_underline.border_color = theme_color;
	theme.set_stylebox('normal', 'Label', label_underline);
	
	var theme_font = DynamicFont.new();
	theme_font.font_data = font;
	theme_font.size = 16;
	theme.set_default_font(theme_font);
	
	theme_color.v = 1;
	theme.set_color('font_color', 'Label', theme_color);
	theme.set_color('font_color_hover', 'Button', theme_color);
	theme_color.v = 0.6;
	theme.set_color('font_color', 'Button', theme_color);
	theme_color.v = 0.4;
	theme.set_color('font_color_pressed', 'Button', theme_color);
	theme_color.v = 0.2;
	theme.set_color('font_color_disabled', 'Button', theme_color);


func _on_yes_button_pressed():
	prompt_status = true;
	emit_signal('prompt_answered');

func _on_no_button_pressed():
	prompt_status = false;
	emit_signal('prompt_answered');
