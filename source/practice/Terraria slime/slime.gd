extends KinematicBody2D

onready var sprite = $sprite;
onready var bez_timer = $Timer;


export var vel := Vector2();
var speed := 300;
var gravity = 20;
var max_gravity := 300;
var jump_speed := 400;
var up_dir := Vector2(0, -1);

var offset_mid := Vector2();
var src_pos := Vector2();
var dest_pos := Vector2();

export var rand_color = true
var shard_count = 32
var shard_velocity_map = {}

func _ready():
	randomize()

# warning-ignore:unused_argument
func _physics_process(delta):
	if is_on_floor():
		if Input.is_action_pressed('player_left'):
			vel = Vector2(-1*speed, -1*jump_speed);
			sprite.flip_h = true;
			sprite.play('run');
			sprite.set_frame(0);
		elif Input.is_action_pressed("player_right"):
			vel = Vector2(1*speed, -1*jump_speed);
			sprite.flip_h = false;
			sprite.play('run');
			sprite.set_frame(0);
		else:
			vel = Vector2(0, gravity);
			sprite.play('idle');
	elif is_on_ceiling():
		vel.y = gravity;
	elif not is_on_floor():
		vel.y += gravity;
		vel.y = clamp(vel.y, -1*jump_speed, max_gravity);
	
# warning-ignore:return_value_discarded
	move_and_slide(vel, up_dir);

func bez(t : float):
	var p1 = src_pos.linear_interpolate(offset_mid,t);
	var p2 = offset_mid.linear_interpolate(dest_pos,t);
	var pos =  p1.linear_interpolate(p2,t);
	return pos;

func bez_init(src, dest):
	src_pos = src;
	dest_pos = dest;
	offset_mid = (dest_pos - src_pos).abs()/2;
	offset_mid.x += min(src_pos.x, dest_pos.x);
	offset_mid.y = min(src_pos.y, dest_pos.y)/1.5;
	bez_timer.start();

func explode_init():
	#this will let us add more points to our polygon later on
# warning-ignore:unassigned_variable
	var points #= polygon
# warning-ignore:unused_variable
	for i in range(shard_count):
		points.append(Vector2(randi()%128, randi()%128))
	
	
	var delaunay_points = Geometry.triangulate_delaunay_2d(points)
	
	if not delaunay_points:
		print("serious error occurred no delaunay points found")
	
	#loop over each returned triangle
# warning-ignore:integer_division
	for index in len(delaunay_points) / 3:
		var shard_pool = PoolVector2Array()
		#find the center of our triangle
		var center = Vector2.ZERO
		
		# loop over the three points in our triangle
		for n in range(3):
			shard_pool.append(points[delaunay_points[(index * 3) + n]])
			center += points[delaunay_points[(index * 3) + n]]
			
		# adding all the points and dividing by the number of points gets the mean position
		center /= 3
		
		#create a new polygon to give these points to
		
		var shard = Polygon2D.new()
		shard.polygon = shard_pool
		
		if rand_color:
			shard.color = Color(randf(), randf(), randf(), 1)
		else:
# warning-ignore:standalone_expression
			shard.texture# = texture
			
		shard_velocity_map[shard] = Vector2(64, 64) - center #position relative to center of sprite
			
			
		add_child(shard)
		print(shard)
		
	#this will make our base sprite invisible
	#color.a = 0

func reset():
	#color.a = 1
	for child in get_children():
		if child.name != "Camera2D":
			child.queue_free()
	shard_velocity_map = {}

# Called every frame. 'delta' is the elapsed time since the previous frame.
func explode(delta):
	#we wan't to chuck our traingles out from the center of the parent
	for child in shard_velocity_map.keys():
		child.position -= shard_velocity_map[child] * delta * 30
		child.rotation -= shard_velocity_map[child].x * delta * 0.2
		#apply gravity to the velocity map so the triangle falls
		shard_velocity_map[child].y -= delta * 55
