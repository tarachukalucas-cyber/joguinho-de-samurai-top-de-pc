extends Node3D

var origin := Vector3.ZERO
var phase := 0.0
var wander_radius := 3.5
var speed := 0.55
var health := 100
var flash_time := 0.0
var legs: Array[Node3D] = []
var core_light: OmniLight3D

func _ready() -> void:
    origin = position
    phase = randf()*TAU
    add_to_group("machines")
    _build_beast()

func _mat(c: Color, metal := 0.7, rough := 0.32, emission := false) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.metallic = metal
    m.roughness = rough
    if emission:
        m.emission_enabled = true
        m.emission = c
        m.emission_energy_multiplier = 2.2
    return m

func _piece(mesh: Mesh, pos: Vector3, color: Color, scale_value := Vector3.ONE, metal := 0.7, emission := false) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    n.mesh = mesh
    n.position = pos
    n.scale = scale_value
    n.material_override = _mat(color,metal,0.3,emission)
    add_child(n)
    return n

func _box(pos: Vector3, size: Vector3, color: Color, rot := Vector3.ZERO, metal := 0.7) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    var n := _piece(mesh,pos,color,Vector3.ONE,metal)
    n.rotation_degrees = rot
    return n

func _sphere(pos: Vector3, radius: float, color: Color, scale_value := Vector3.ONE, emission := false) -> MeshInstance3D:
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius*2.0
    mesh.radial_segments = 20
    mesh.rings = 12
    return _piece(mesh,pos,color,scale_value,0.78,emission)

func _build_beast() -> void:
    var visual_scene: PackedScene = load("res://scenes/machine_visual.tscn")
    var visual := visual_scene.instantiate()
    visual.name = "MachineVisual"
    add_child(visual)
    core_light = OmniLight3D.new()
    core_light.position = Vector3(0,1.1,-0.05)
    core_light.light_color = Color(0.12,0.70,1.0)
    core_light.omni_range = 4.5
    core_light.light_energy = 0.65
    add_child(core_light)

func _process(delta: float) -> void:
    phase += delta*speed
    flash_time = maxf(0.0,flash_time-delta)
    var target := origin+Vector3(cos(phase)*wander_radius,0,sin(phase)*wander_radius)
    var movement := target-position
    position = target
    if movement.length() > 0.001:
        rotation.y = lerp_angle(rotation.y,atan2(-movement.x,-movement.z),delta*2.0)
    for i in range(legs.size()):
        legs[i].rotation.x = sin(phase*2.2+float(i%2)*PI)*0.16
    if is_instance_valid(core_light):
        core_light.light_energy = 0.65+sin(phase*3.0)*0.18

func receive_hit(damage: int) -> void:
    health -= damage
    flash_time = 0.16
    if health <= 0:
        queue_free()
