extends CanvasLayer

onready var anim_player = $anim_player;
onready var transition = $transition;
onready var pause_panel = $pause_panel;
onready var world = $"..";

func _ready():
	#OS.window_fullscreen = true;
	transition.anim_player.play("fade_in");

onready var jump_notifier = $jump_notifier;
onready var jump_notifier_tween = $jump_notifier/Tween;

func show_jump(name):
	jump_notifier.modulate.a = 1;
	jump_notifier.rect_position = Vector2(0, 140);
	jump_notifier.text = name;
	jump_notifier_tween.interpolate_property(jump_notifier, "modulate", Color(progress_notifier.modulate.r, progress_notifier.modulate.g, progress_notifier.modulate.b, 1), Color(progress_notifier.modulate.r, progress_notifier.modulate.g, progress_notifier.modulate.b, 0), 0.3, Tween.TRANS_LINEAR, Tween.EASE_OUT, 1.5);
	jump_notifier_tween.interpolate_property(jump_notifier, "rect_position", Vector2(0, 140), Vector2(0, 180), 0.3, Tween.TRANS_LINEAR, Tween.EASE_OUT, 1.5);
	jump_notifier_tween.start();

onready var progress_notifier = $progress_notifier;
onready var progress_notifier_tween = $progress_notifier/Tween;

func show_progress(level_num):
	progress_notifier.modulate.a = 1;
	progress_notifier.rect_position = Vector2(0, 140);
	progress_notifier.text = "LEVEL " + String(level_num);
	progress_notifier_tween.interpolate_property(progress_notifier, "modulate", Color(progress_notifier.modulate.r, progress_notifier.modulate.g, progress_notifier.modulate.b, 1), Color(progress_notifier.modulate.r, progress_notifier.modulate.g, progress_notifier.modulate.b, 0), 0.3, Tween.TRANS_LINEAR, Tween.EASE_OUT, 1.5);
	progress_notifier_tween.interpolate_property(progress_notifier, "rect_position", Vector2(0, 140), Vector2(0, 180), 0.3, Tween.TRANS_LINEAR, Tween.EASE_OUT, 1.5);
	progress_notifier_tween.start();

onready var hp_bar_tween = $health_bar/Tween;
onready var health_bar = $health_bar;
onready var hp_history_bar = $health_bar/hp_history;

func update_health(hp):
	hp_bar_tween.interpolate_property(health_bar, "value", health_bar.value, hp, 0.5, Tween.TRANS_LINEAR, Tween.EASE_OUT);
	hp_bar_tween.start();

onready var weapon_panel = $weapon_panel;
onready var weapon_sprite = $weapon_panel/weapon_sprite;

onready var screen = $screen_stat;

func set_screen_stat(type, val):
	match(type):
		'brightness':
			$screen_stat.material.set_shader_param(type, lerp(0.5, 2, val/100));
		'contrast':
			$screen_stat.material.set_shader_param(type, lerp(0.9, 1.5, val/100));

func set_HUD_parameters(max_health, weapon):
	health_bar.max_value = max_health;
	weapon_sprite.texture = load('res://weapon/art/' + weapon + '/idle.png');

func _on_Tween_tween_completed(object, key):
	if object == health_bar and key == ":value":
		hp_bar_tween.interpolate_property(hp_history_bar, "value", hp_history_bar.value, health_bar.value, 0.2, Tween.TRANS_LINEAR, Tween.EASE_OUT);
		hp_bar_tween.start();

func on_game_load():
	music_mute_button.icon = music_icon_muted if pause_panel.music_slider_val == 0 else music_icon;
	sfx_mute_button.icon = sfx_icon_muted if pause_panel.sfx_slider_val == 0 else sfx_icon;
	pause_panel.on_game_load();

onready var pause_button = $pause_button;

func _on_pause_button_pressed():
	if !get_tree().paused:
		get_tree().paused = true;
		pause_panel.show();
		pause_panel.anim_player.play("start");
	else:
		if pause_panel.pause_bkg.rect_position.x == -450:
			pause_panel.anim_player.play("end");
		elif pause_panel.pause_bkg.rect_position.x == -250:
			pause_panel.anim_player.play("from_sound_end");
		elif pause_panel.pause_bkg.rect_position.x == -200:
			pause_panel.anim_player.play("from_display_end");

onready var sfx_mute_button = $mute_SFX;
var sfx_icon  = preload('res://HUD/art/sfx_icon.png');
var sfx_icon_muted  = preload('res://HUD/art/sfx_icon_muted.png');

func _on_mute_SFX_pressed():
	if pause_panel.sfx_slider.value == 0:
		pause_panel.sfx_slider.value = 70 if pause_panel.sfx_slider_val == 0 else pause_panel.sfx_slider_val; 
		sfx_mute_button.icon = sfx_icon;
	else: 
		pause_panel.sfx_slider_val = pause_panel.sfx_slider.value;
		pause_panel.sfx_slider.value = 0;
		sfx_mute_button.icon = sfx_icon_muted;

onready var music_mute_button = $mute_music;
var music_icon = preload('res://HUD/art/music_icon.png');
var music_icon_muted  = preload('res://HUD/art/music_icon_muted.png');

func _on_mute_music_pressed():
	if pause_panel.music_slider.value == 0:
		pause_panel.music_slider.value = 70 if pause_panel.music_slider_val == 0 else pause_panel.music_slider_val; 
		music_mute_button.icon = music_icon;
	else: 
		pause_panel.music_slider_val = pause_panel.music_slider.value;
		pause_panel.music_slider.value = 0;
		music_mute_button.icon = music_icon_muted;

func change_icon(type, status):
	match(type):
		'music':
			music_mute_button.icon = music_icon_muted if status else music_icon;
		'sfx':
			sfx_mute_button.icon = sfx_icon_muted if status else sfx_icon;

func update_theme():
	var theme = load("res://button_theme.tres");
	var theme_color = global.theme_values[global.theme_id][1];
	var font = load(global.font_values[global.font_id][1]);
	
	sfx_mute_button.self_modulate = theme_color;
	music_mute_button.self_modulate = theme_color;
	health_bar.self_modulate = theme_color;
	weapon_panel.self_modulate = theme_color;
	world.player.modulate = theme_color;
	
	var notifier_font = DynamicFont.new();
	notifier_font.font_data = font;
	notifier_font.size = 48;
	jump_notifier.add_font_override("font", notifier_font);
	progress_notifier.add_font_override("font", notifier_font);
	
	var world_font = DynamicFont.new();
	world_font.font_data = font;
	world_font.size = 16;
	for l in world.label_container.get_children():
		l.add_font_override("font", world_font);
	for l in world.obstacle_container.get_children():
		l.label.add_font_override("font", world_font);
	
	var border_box = theme.get_stylebox('normal', 'Button');
	border_box.border_color = theme_color;
	theme.set_stylebox('normal', 'Button', border_box);
	theme.set_stylebox('hover', 'Button', border_box);
	theme.set_stylebox('pressed', 'Button', border_box);
	theme.set_stylebox('disabled', 'Button', border_box);
	
	var label_underline = theme.get_stylebox('normal', 'Label');
	label_underline.border_color = theme_color;
	theme.set_stylebox('normal', 'Label', label_underline);
	
	var remove_border = StyleBoxFlat.new();
	remove_border.bg_color.a = 0;
	sfx_mute_button.add_stylebox_override('hover', remove_border);
	sfx_mute_button.add_stylebox_override('pressed', remove_border);
	sfx_mute_button.add_stylebox_override('disabled', remove_border);
	sfx_mute_button.add_stylebox_override("normal", remove_border);
	music_mute_button.add_stylebox_override('hover', remove_border);
	music_mute_button.add_stylebox_override('pressed', remove_border);
	music_mute_button.add_stylebox_override('disabled', remove_border);
	music_mute_button.add_stylebox_override("normal", remove_border);
	jump_notifier.add_stylebox_override("normal", remove_border);
	progress_notifier.add_stylebox_override("normal", remove_border);
	
	var theme_label_font = DynamicFont.new();
	theme_label_font.font_data = font;
	theme_label_font.size = 20;
	theme.set_font('font', 'Label', theme_label_font);
	var theme_font = DynamicFont.new();
	theme_font.font_data = font;
	theme_font.size = 16;
	theme.set_default_font(theme_font);
	theme_color.v = 1;
	
	var sb = theme.get_stylebox('hover', 'PopupMenu');
	sb.border_color = theme_color;
	theme.set_stylebox('hover', 'PopupMenu', sb);
	
	theme.set_color('font_color', 'Label', theme_color);
	theme.set_color('font_color_hover', 'Button', theme_color);
	theme.set_color('font_color_hover', 'MenuButton', theme_color);
	theme.set_color('font_color_hover', 'PopupMenu', theme_color);
	theme_color.v = 0.8;
	theme.set_color('font_color', 'Button', theme_color);
	theme.set_color('font_color', 'MenuButton', theme_color);
	theme.set_color('font_color', 'PopupMenu', theme_color);
	theme.set_color('radio_unchecked', 'PopupMenu', theme_color);
	theme_color.v = 0.6;
	theme.set_color('font_color_pressed', 'Button', theme_color);
	theme.set_color('font_color_pressed', 'MenuButton', theme_color);
	theme_color.v = 0.2;
	theme.set_color('font_color_disabled', 'Button', theme_color);
	theme.set_color('font_color_disabled', 'MenuButton', theme_color);
	theme.set_color('font_color_disabled', 'PopupMenu', theme_color);
	
	pause_panel.theme_menu.get_popup().set_item_checked(global.theme_id, true);
	pause_panel.font_menu.get_popup().set_item_checked(global.font_id, true);
	pause_panel.update_theme();
