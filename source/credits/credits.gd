extends Control

onready var anim_player = $transition/anim_player;
onready var transition = $transition;

func _ready():
	transition.anim_player.play("fade_in");
	update_theme();

func _on_back_button_pressed():
	transition.fade_out('res://main_menu/main_menu.tscn');

onready var title = $title;
onready var back_button = $back_button;

func update_theme():
	var title_font = DynamicFont.new();
	title_font.font_data = load(global.font_values[global.font_id][1]);
	title_font.size = 32;
	title.add_font_override("font", title_font);
	var button_font = DynamicFont.new();
	button_font.font_data = load(global.font_values[global.font_id][1]);
	button_font.size = 24;
	back_button.add_font_override("font", button_font);
