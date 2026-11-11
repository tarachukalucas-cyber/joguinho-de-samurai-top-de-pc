extends Node3D

var origin := Vector3.ZERO
var phase := 0.0
var wander_radius := 4.0
var speed := 0.45

func _ready() -> void:
    origin = position
    phase = randf()*TAU
    _build_model()

func _part(mesh: Mesh, pos: Vector3, color: Color, rot := Vector3.ZERO) -> void:
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.position = pos
    node.rotation_degrees = rot
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = 0.55
    mat.roughness = 0.38
    node.material_override = mat
    add_child(node)

func _build_model() -> void:
    var core := BoxMesh.new()
    core.size = Vector3(1.4,0.8,2.0)
    _part(core,Vector3(0,1.15,0),Color(0.28,0.39,0.42),Vector3(0,0,0))
    var head := SphereMesh.new()
    head.radius = 0.48
    head.height = 0.85
    _part(head,Vector3(0,1.45,-1.15),Color(0.36,0.48,0.48))
    var sensor := SphereMesh.new()
    sensor.radius = 0.16
    _part(sensor,Vector3(0,1.55,-1.56),Color(0.25,0.85,0.95))
    for side in [-1.0,1.0]:
        for front in [-1.0,1.0]:
            var leg := CylinderMesh.new()
            leg.top_radius = 0.12
            leg.bottom_radius = 0.18
            leg.height = 1.15
            _part(leg,Vector3(side*0.55,0.58,front*0.62),Color(0.20,0.28,0.31),Vector3(0,0,side*12.0))
            var foot := BoxMesh.new()
            foot.size = Vector3(0.38,0.18,0.48)
            _part(foot,Vector3(side*0.58,0.12,front*0.68),Color(0.46,0.50,0.45))
    var fin := PrismMesh.new()
    fin.size = Vector3(0.7,0.6,0.8)
    _part(fin,Vector3(0,1.85,0.35),Color(0.68,0.55,0.30),Vector3(0,0,0))

func _process(delta: float) -> void:
    phase += delta*speed
    var next_pos := origin + Vector3(cos(phase)*wander_radius,0,sin(phase)*wander_radius)
    var movement := next_pos-position
    position = next_pos
    if movement.length() > 0.001:
        rotation.y = atan2(-movement.x,-movement.z)
