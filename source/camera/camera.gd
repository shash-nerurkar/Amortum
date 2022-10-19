extends Camera2D

signal zoom_complete

onready var world = $"..";

var amplitude;
var mode; #true-> horizontal alignment, false-> vertical alignment
var end_point := 0;
var fly_shift := 250;

func reset_cam():
	set_process(false);
	position = Vector2(512, 300);

func _ready():
	set_process(false);

# warning-ignore:unused_argument
func _process(delta):
	if mode:
		if world.player.position.x <= 512 and world.player.position.y <= fly_shift:
			position = position.linear_interpolate(Vector2(512, world.player.position.y), delta*4);
		elif world.player.position.x <= 512 and world.player.position.y > fly_shift:
			position = position.linear_interpolate(Vector2(512, 300), delta*4);
		elif world.player.position.x > 512 and world.player.position.x > end_point and world.player.position.y <= fly_shift:
			position = position.linear_interpolate(Vector2(end_point, world.player.position.y), delta*4);
		elif world.player.position.x > 512 and world.player.position.x > end_point and world.player.position.y > fly_shift:
			position = position.linear_interpolate(Vector2(end_point, 300), delta*4);
		elif world.player.position.x > 512 and world.player.position.x <= end_point and world.player.position.y <= fly_shift:
			position = position.linear_interpolate(world.player.position, delta*4);
		else:
			position = position.linear_interpolate(Vector2(world.player.position.x, 300), delta*4);
	else:
		if world.player.position.y <= 300:
			position = position.linear_interpolate(Vector2(512, 300), delta*4);
		elif world.player.position.y > 300 and world.player.position.y < end_point:
			position = position.linear_interpolate(Vector2(512, world.player.position.y), delta*4);
		else:
			position = position.linear_interpolate(Vector2(512, end_point), delta*4);

onready var offset_tween = $offset_tween;
onready var frequency_timer = $frequency;
onready var duration_timer = $duration;

func screen_shake_requested(amp, freq, dur):
	amplitude = amp;
	frequency_timer.wait_time = freq;
	frequency_timer.start(freq);
	duration_timer.start(dur);
	new_shake();

func reset():
	offset_tween.interpolate_property(self, "offset", offset, Vector2(0, 0), frequency_timer.wait_time, Tween.TRANS_SINE, Tween.EASE_IN_OUT);
	offset_tween.start();

func _on_frequency_timeout():
	new_shake();

func _on_duration_timeout():
	frequency_timer.stop();
	amplitude = 0;
	reset();

func new_shake():
	var rand = Vector2(rand_range(-amplitude, amplitude), rand_range(-amplitude, amplitude));
	offset_tween.interpolate_property(self, "offset", offset, rand, frequency_timer.wait_time, Tween.TRANS_SINE, Tween.EASE_OUT);
	offset_tween.start();

onready var zoom_tween = $zoom_tween;

func zoom_in_out(dest):
	if mode:
		dest.x = clamp(dest.x, dest.x, end_point);
	else:
		dest.y = clamp(dest.y, dest.y, end_point);
	set_process(false);
	zoom_tween.interpolate_property(self, "position", position, dest, 3, Tween.TRANS_SINE, Tween.EASE_OUT);
	zoom_tween.interpolate_property(self, "zoom", zoom, Vector2(2, 2), 1, Tween.TRANS_SINE, Tween.EASE_OUT);
	zoom_tween.start();
	yield(zoom_tween, "tween_completed");
	yield(get_tree().create_timer(1), 'timeout');
	zoom_tween.interpolate_property(self, "zoom", zoom, Vector2(1, 1), 1, Tween.TRANS_SINE, Tween.EASE_OUT);
	zoom_tween.start();
	yield(zoom_tween, "tween_all_completed");
	set_process(true);
	emit_signal('zoom_complete');
