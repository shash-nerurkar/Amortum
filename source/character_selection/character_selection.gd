extends Control

onready var transition = $transition;

func _ready():
	transition.anim_player.play("fade_in");
	update_theme();

func _on_poleric_button_pressed():
	global.character = "poleric";
	tutorial_prompt.show();

func _on_repenter_button_pressed():
	global.character = "repenter";
	tutorial_prompt.show();

onready var title = $parent_container/title;
onready var poleric_btn = $parent_container/button_container/poleric_button;
onready var repenter_btn = $parent_container/button_container/repenter_button;
onready var tutorial_prompt = $prompt_bkg;

func _on_tutorial_pressed():
	transition.fade_out('res://tutorial/tutorial.tscn');

func _on_no_tutorial_pressed():
	transition.fade_out('res://world/world.tscn');

func update_theme():
	var title_font = DynamicFont.new();
	title_font.font_data = load(global.font_values[global.font_id][1]);
	title_font.size = 36;
	title.add_font_override("font", title_font);
	var remove_border = StyleBoxFlat.new();
	remove_border.bg_color.a = 0;
	remove_border.border_width_left = 0;
	title.add_stylebox_override("normal", remove_border);
	var button_font = DynamicFont.new();
	button_font.font_data = load(global.font_values[global.font_id][1]);
	button_font.size = 42;
	poleric_btn.add_font_override("font", button_font);
	repenter_btn.add_font_override("font", button_font);
