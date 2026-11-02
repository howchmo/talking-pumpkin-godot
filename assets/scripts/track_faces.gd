extends Node3D

@export_group("Network Setup")
@export var udp_port: int = 4242

@export_group("Motion & Limits")
@export var smooth_speed: float = 6.0          # Interpolation speed (higher = faster, lower = smoother)
@export var max_pitch_deg: float = 30.0        # Max up/down rotation limit
@export var max_yaw_deg: float = 60.0          # Max left/right rotation limit
@export var invert_yaw: bool = false
@export var invert_pitch: bool = false

@export_group("Targeting Behavior")
@export var return_to_center_delay: float = 2.5 # Seconds before resetting if nobody is detected

var peer: PacketPeerUDP = PacketPeerUDP.new()
var target_rotation: Vector3 = Vector3.ZERO
var default_rotation: Vector3 = Vector3.ZERO
var time_since_last_packet: float = 0.0

func _ready() -> void:
	default_rotation = rotation
	var err = peer.bind(udp_port)
	if err != OK:
		push_error("Failed to bind UDP port %d. Error code: %d" % [udp_port, err])
	else:
		print("Listening for Python face tracking stream on UDP port: ", udp_port)

func _process(delta: float) -> void:
	time_since_last_packet += delta
	
	# Process incoming UDP packets
	while peer.get_available_packet_count() > 0:
		var raw_packet = peer.get_packet().get_string_from_utf8()
		_parse_payload(raw_packet)

	# Timeout check: Return pumpkin to default center position if no faces are seen
	if time_since_last_packet > return_to_center_delay:
		target_rotation = default_rotation

	# Smoothly rotate toward the target head pose using spherical linear interpolation (slerp)
	var current_quat = Quaternion.from_euler(rotation)
	var target_quat = Quaternion.from_euler(target_rotation)
	var lerped_quat = current_quat.slerp(target_quat, clamp(delta * smooth_speed, 0.0, 1.0))
	
	rotation = lerped_quat.get_euler()

func _parse_payload(json_str: String) -> void:
	var json = JSON.new()
	var parse_result = json.parse(json_str)
	if parse_result != OK:
		return

	var data = json.get_data()
	if not data.has("faces") or data["faces"].size() == 0:
		return

	# Reset timer since valid data was received
	time_since_last_packet = 0.0

	# Extract Rank #1 (highest priority candidate evaluated by Python script)
	var primary_face = data["faces"][0]
	
	# Normalized screen coordinates: X [0.0 left to 1.0 right], Y [0.0 top to 1.0 bottom]
	var pos_x: float = primary_face["pos_x"]
	var pos_y: float = primary_face["pos_y"]

	# Remap [0.0, 1.0] to centered angular range [-1.0, 1.0]
	var norm_x: float = (pos_x - 0.5) * 2.0
	var norm_y: float = (pos_y - 0.5) * 2.0

	# Calculate target yaw and pitch angles in radians
	var yaw_angle = deg_to_rad(-norm_x * max_yaw_deg) * (-1.0 if invert_yaw else 1.0)
	var pitch_angle = deg_to_rad(-norm_y * max_pitch_deg) * (-1.0 if invert_pitch else 1.0)

	target_rotation = Vector3(pitch_angle, yaw_angle, default_rotation.z)
