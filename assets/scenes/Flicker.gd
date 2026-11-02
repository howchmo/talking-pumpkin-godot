extends OmniLight3D

@export var flicker_speed = 0.2
var timer = 0.0
var e = 0.25
var increment = 0.0
@export var high=0.4
@export var low = 0.3

# Called when the node enters the scene tree for the first time.
func _ready():
	flicker_speed = randf_range(0.01,0.1)
	increment = (randf_range(high,low) - e)/flicker_speed 
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	timer = timer + delta
	light_energy = e + increment
	if( timer > flicker_speed ):
		flicker_speed = randf_range(0.01,0.4)
		increment = (randf_range(high,low) - e)/flicker_speed
		timer = 0.0
