extends Node3D

var origin := Vector3.ZERO
var phase := 0.0
var wander_radius := 3.5
var speed := 0.55
var legs: Array[Node3D] = []
var core_light: OmniLight3D

func _ready() -> void:
    origin = position
    phase = randf()*TAU
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
    # Four-legged ancient machine: plated spine, reactor, neck and sensor head
    _box(Vector3(0,1.30,0),Vector3(1.35,0.72,2.15),Color(0.18,0.25,0.29))
    _box(Vector3(0,1.66,0.05),Vector3(1.12,0.20,1.72),Color(0.35,0.39,0.39),Vector3.ZERO,0.88)
    _sphere(Vector3(0,1.36,0.08),0.48,Color(0.10,0.76,0.92),Vector3(0.72,0.72,0.72),true)
    _box(Vector3(0,1.72,0.76),Vector3(0.78,0.32,0.78),Color(0.22,0.29,0.34),Vector3(-12,0,0))
    # Neck and angular head
    _box(Vector3(0,1.55,-1.12),Vector3(0.72,0.56,0.90),Color(0.25,0.33,0.36),Vector3(18,0,0))
    _sphere(Vector3(0,1.72,-1.62),0.43,Color(0.29,0.38,0.41),Vector3(1.0,0.78,1.25))
    _box(Vector3(0,1.48,-1.90),Vector3(0.52,0.20,0.48),Color(0.15,0.20,0.23),Vector3(12,0,0))
    _sphere(Vector3(0,1.79,-1.96),0.15,Color(1.0,0.13,0.06),Vector3(1.3,0.75,0.55),true)
    # Horn-like antennae and back fins
    for side in [-1.0,1.0]:
        var horn := PrismMesh.new()
        horn.size = Vector3(0.22,0.95,0.22)
        var h := _piece(horn,Vector3(side*0.28,2.10,-1.45),Color(0.48,0.53,0.53),Vector3.ONE,0.9)
        h.rotation_degrees.z = side*20.0
        var side_plate := _box(Vector3(side*0.68,1.35,0.15),Vector3(0.28,0.62,1.25),Color(0.22,0.29,0.34),Vector3(0,0,side*8))
        _sphere(Vector3(side*0.72,1.43,0.20),0.13,Color(0.95,0.22,0.08),Vector3.ONE,true)
    for i in range(4):
        var fin := PrismMesh.new()
        fin.size = Vector3(0.30,0.78,0.50)
        var f := _piece(fin,Vector3(0,2.05,0.60+float(i)*0.25),Color(0.40,0.44,0.43),Vector3.ONE,0.88)
        f.rotation_degrees.x = -18
    # Four segmented legs with visible joints and broad feet
    for side in [-1.0,1.0]:
        for front in [-1.0,1.0]:
            var leg := Node3D.new()
            leg.position = Vector3(side*0.48,1.0,front*0.70)
            add_child(leg)
            legs.append(leg)
            var upper := CylinderMesh.new()
            upper.top_radius = 0.16
            upper.bottom_radius = 0.22
            upper.height = 0.70
            var u := _piece(upper,Vector3(0,-0.35,0),Color(0.20,0.28,0.32),Vector3.ONE,0.85)
            u.rotation_degrees.z = side*9.0
            _sphere(Vector3(0,-0.70,0),0.19,Color(0.50,0.55,0.54))
            var lower := CylinderMesh.new()
            lower.top_radius = 0.11
            lower.bottom_radius = 0.15
            lower.height = 0.72
            var l := _piece(lower,Vector3(0,-1.02,0.02),Color(0.15,0.22,0.27),Vector3.ONE,0.9)
            l.rotation_degrees.z = -side*7.0
            _box(Vector3(0,-1.40,-0.06),Vector3(0.38,0.18,0.55),Color(0.40,0.44,0.43))
            _sphere(Vector3(0,-1.48,-0.26),0.08,Color(0.12,0.76,0.95),Vector3.ONE,true)
    # segmented tail with a glowing tip
    for i in range(4):
        var tail := _sphere(Vector3(0,1.42,1.20+float(i)*0.38),0.22-0.025*float(i),Color(0.27,0.34,0.37))
    _sphere(Vector3(0,1.42,2.55),0.16,Color(0.95,0.24,0.08),Vector3.ONE,true)
    core_light = OmniLight3D.new()
    core_light.position = Vector3(0,1.4,0)
    core_light.light_color = Color(0.12,0.70,1.0)
    core_light.omni_range = 5.5
    core_light.light_energy = 0.8
    add_child(core_light)

func _process(delta: float) -> void:
    phase += delta*speed
    var target := origin+Vector3(cos(phase)*wander_radius,0,sin(phase)*wander_radius)
    var movement := target-position
    position = target
    if movement.length() > 0.001:
        rotation.y = lerp_angle(rotation.y,atan2(-movement.x,-movement.z),delta*2.0)
    for i in range(legs.size()):
        legs[i].rotation.x = sin(phase*2.2+float(i%2)*PI)*0.16
    if is_instance_valid(core_light):
        core_light.light_energy = 0.65+sin(phase*3.0)*0.18
