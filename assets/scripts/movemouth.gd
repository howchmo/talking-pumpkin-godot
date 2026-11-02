extends Node3D

@export var mouth_speed = 0.05
@export var mouth_limit = 0.18
@export var sound_threshold = -50.0
@export var frequency_high = 110
@export var frequency_low = 110

var timer

var spectrum
var skel
var mouth_upper
var mouth_lower
var mouth_distance = 0.0
var mouth_close = false

# Called when the node enters the scene tree for the first time.
func _ready():
	mouth_close = true
	spectrum = AudioServer.get_bus_effect_instance(0,0)
	timer = 0
	skel = get_node("Armature/Skeleton3D/")
	mouth_upper = skel.get_bone_pose(2)
	mouth_lower = skel.get_bone_pose(1)
	
func is_mic_volume_high( threshold ):
	var mag = spectrum.get_magnitude_for_frequency_range(frequency_low,frequency_high,1)
	mag = linear_to_db(mag.length())
	if mag < threshold:
		return false
	else:
		return true

func move_mouth( mouth_distance ):
	mouth_upper = mouth_upper.rotated(Vector3(-1,0,0), mouth_distance)
	skel.set_bone_pose(2, mouth_upper)
	mouth_lower = mouth_lower.rotated(Vector3(1,0,0), mouth_distance)
	skel.set_bone_pose(1, mouth_lower)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	timer = timer + delta
	if is_mic_volume_high(sound_threshold):
		mouth_close = false
	else:
		mouth_close = true
	if mouth_close:
		if mouth_distance < mouth_limit and mouth_distance >= -mouth_speed:
			mouth_distance += mouth_speed
			move_mouth(mouth_speed)
	else:
		if mouth_distance >= 0.0:
			mouth_distance -= mouth_speed
			move_mouth(-mouth_speed)
