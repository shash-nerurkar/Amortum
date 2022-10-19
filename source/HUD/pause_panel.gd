extends ColorRect

signal update_theme
signal user_quitting
signal change_volume(type, vol);
signal change_screen_stat(type, val);
signal change_icon(type, status);

onready var anim_player = $anim_player;
onready var main_panel = $pause_background/margin_setter/parent_container/main_panel;
onready var sound_panel = $pause_background/margin_setter/parent_container/sound_panel;
onready var display_panel = $pause_background/margin_setter/parent_container/display_panel;
onready var panel_title = $pause_background/margin_setter/parent_container/title;
onready var HUD = $"..";
onready var pause_bkg = $pause_background;
onready var restart_button = $pause_background/margin_setter/parent_container/endgame_panel/restart_button;

var local_theme_id;
var local_font_id;
var to_change := [false, false];
var music_slider_val = 70;
var sfx_slider_val = 70;
var brightness_slider_val = 70;
var contrast_slider_val = 70;

func _on_sound_settings_pressed():
	HUD.set_process_input(false);
	anim_player.play("to_sound_panel");

func _on_display_settings_pressed():
	HUD.set_process_input(false);
	anim_player.play("to_display_panel");

func _on_display_back_button_pressed():
	HUD.set_process_input(true);
	anim_player.play("from_display_to_main_panel");

func _on_sound_back_button_pressed():
	HUD.set_process_input(true);
	anim_player.play("from_sound_to_main_panel");

func _on_anim_player_animation_finished(anim_name):
	if anim_name == "end" or anim_name == 'from_sound_end' or anim_name == 'from_display_end':
		get_tree().paused = false;
		hide();
		set_process_input(true);
	if anim_name == "start" or anim_name == "from_display_to_main_panel" or anim_name == "from_sound_to_main_panel":
		set_process_input(true);

# warning-ignore:unused_argument
func _on_anim_player_animation_started(anim_name):
	if anim_name == 'game_end':
		HUD.world.level = 0;
		var save_file = Directory.new();
		if save_file.file_exists("user://amortum_sav_1.save"):
			save_file.remove("user://amortum_sav_1.save");

func _on_main_back_button_pressed():
	anim_player.play("end");

func _on_restart_button_pressed():
# warning-ignore:return_value_discarded
	get_tree().reload_current_scene();

func _on_exit_button_pressed():
	get_tree().paused = false;
	HUD.set_process_input(false);
	HUD.transition.fade_out('res://main_menu/main_menu.tscn');
	emit_signal("user_quitting");

func _on_exit_on_losing_button_pressed():
	get_tree().paused = false;
	HUD.set_process_input(false);
	HUD.transition.fade_out('res://main_menu/main_menu.tscn');

onready var theme_menu = $pause_background/margin_setter/parent_container/display_panel/theme_menu;
onready var font_menu = $pause_background/margin_setter/parent_container/display_panel/font_menu;
onready var apply_theme_button = $pause_background/margin_setter/parent_container/display_panel/HBoxContainer/apply_button;

func set_display_settings_menus():
	var popup = theme_menu.get_popup();
	for i in range(global.theme_values.size()):
		popup.add_radio_check_item(global.theme_values[i][0]);
	popup.connect("id_pressed", self, "change_theme");
	popup = font_menu.get_popup();
	for i in range(global.font_values.size()):
		popup.add_radio_check_item(global.font_values[i][0]);
	popup.connect("id_pressed", self, "change_font");

func change_theme(id):
	for i in range(global.theme_values.size()):
		theme_menu.get_popup().set_item_checked(i, true if i == id else false);
	local_theme_id = id;
	to_change[0] = true;
	apply_theme_button.disabled = false;

func change_font(id):
	for i in range(global.font_values.size()):
		font_menu.get_popup().set_item_checked(i, true if i == id else false);
	local_font_id = id;
	to_change[1] = true;
	apply_theme_button.disabled = false;

onready var music_slider_label = $pause_background/margin_setter/parent_container/sound_panel/music_container/label;
onready var sfx_slider_label = $pause_background/margin_setter/parent_container/sound_panel/sfx_container/label;

func update_theme():
	color = global.theme_values[global.theme_id][1];
	color.a = 0.1;
	pause_bkg.self_modulate = global.theme_values[global.theme_id][1];
	var slider_font = DynamicFont.new();
	slider_font.font_data = load(global.font_values[global.font_id][1]);
	slider_font.size = 16;
	music_slider_label.add_font_override("font", slider_font);
	sfx_slider_label.add_font_override("font", slider_font);

func _on_apply_button_pressed():
	if to_change[0]: global.theme_id = local_theme_id;
	if to_change[1]: global.font_id = local_font_id;
	emit_signal("update_theme");
	apply_theme_button.disabled = true;

onready var music_slider = $pause_background/margin_setter/parent_container/sound_panel/music_container/music_slider;

func _on_music_slider_value_changed(value):
	if value == 0: 
		emit_signal('change_icon', 'music', true);
	elif value != 0 and HUD.music_mute_button.icon == HUD.music_icon_muted: 
		emit_signal('change_icon', 'music', false); 
	emit_signal('change_volume', 'music', value);

onready var sfx_slider = $pause_background/margin_setter/parent_container/sound_panel/sfx_container/sfx_slider;

func _on_sfx_slider_value_changed(value):
	if value == 0: 
		emit_signal('change_icon', 'sfx', true);
	elif value != 0 and HUD.sfx_mute_button.icon == HUD.sfx_icon_muted: 
		emit_signal('change_icon', 'sfx', false); 
	emit_signal('change_volume', 'sfx', value);

onready var brightness_slider = $pause_background/margin_setter/parent_container/display_panel/brightness_container/brightness_slider;

func _on_brightness_slider_value_changed(value):
	emit_signal('change_screen_stat', 'brightness', value);

onready var contrast_slider = $pause_background/margin_setter/parent_container/display_panel/contrast_container/contrast_slider;

func _on_contrast_slider_value_changed(value):
	emit_signal('change_screen_stat', 'contrast', value);

func on_game_load():
	set_display_settings_menus();
	music_slider.value = music_slider_val;
	sfx_slider.value = sfx_slider_val;
	brightness_slider.value = brightness_slider_val;
	contrast_slider.value = contrast_slider_val;

func save():
	var save_dict = {
		"name": "global",
		"music_slider_val": music_slider.value,
		"sfx_slider_val": sfx_slider.value,
		"brightness_slider_val": brightness_slider.value,
		"contrast_slider_val": contrast_slider.value};
	return save_dict;
