extends CharacterBody3D

@export var walk_speed := 5.2
@export var run_speed := 8.8
@export var mouse_sensitivity := 0.0024
var gravity := 20.0
var pivot: Node3D
var cape: MeshInstance3D
var right_arm: Node3D
var attack_time := 0.0
var cooldown := 0.0
var anim_time := 0.0

func _ready() -> void:
    _input_setup()
    _build_samurai()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input_setup() -> void:
    var keys := {"move_forward":KEY_W,"move_back":KEY_S,"move_left":KEY_A,"move_right":KEY_D,"sprint":KEY_SHIFT,"jump":KEY_SPACE,"attack":KEY_J}
    for action in keys:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        var ev := InputEventKey.new()
        ev.physical_keycode = keys[action]
        InputMap.action_add_event(action, ev)

func _mat(c: Color, metal := 0.0, rough := 0.55) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.metallic = metal
    m.roughness = rough
    return m

func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, rot := Vector3.ZERO, metal := 0.0) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    var n := MeshInstance3D.new()
    n.mesh = mesh
    n.position = pos
    n.rotation_degrees = rot
    n.material_override = _mat(color, metal)
    parent.add_child(n)
    return n

func _sphere(parent: Node3D, pos: Vector3, radius: float, color: Color, metal := 0.0) -> MeshInstance3D:
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    mesh.radial_segments = 20
    mesh.rings = 12
    var n := MeshInstance3D.new()
    n.mesh = mesh
    n.position = pos
    n.material_override = _mat(color, metal)
    parent.add_child(n)
    return n

func _build_samurai() -> void:
    var collider := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.40
    capsule.height = 1.95
    collider.shape = capsule
    collider.position.y = 0.98
    add_child(collider)
    var model := Node3D.new()
    model.name = "SamuraiModel"
    add_child(model)
    # Camadas de armadura yoroi, hakama e placas sode
    _box(model,Vector3(0,0.72,0),Vector3(0.88,0.82,0.60),Color(0.10,0.11,0.17))
    _box(model,Vector3(0,1.23,0),Vector3(0.78,0.68,0.50),Color(0.12,0.16,0.23),Vector3.ZERO,0.28)
    _box(model,Vector3(0,1.46,0.02),Vector3(0.90,0.17,0.56),Color(0.50,0.09,0.08),Vector3.ZERO,0.25)
    for i in range(5):
        _box(model,Vector3(0,1.04+i*0.09,-0.26),Vector3(0.62,0.035,0.035),Color(0.75,0.18,0.12))
    for side in [-1.0,1.0]:
        _box(model,Vector3(side*0.53,1.48,0),Vector3(0.42,0.22,0.62),Color(0.18,0.22,0.29),Vector3(0,0,side*8),0.45)
        for j in range(3):
            _box(model,Vector3(side*0.54,1.34-j*0.12,-0.03),Vector3(0.36,0.075,0.48),Color(0.28,0.30,0.34),Vector3(0,0,side*7),0.38)
        _box(model,Vector3(side*0.23,0.28,0),Vector3(0.30,0.62,0.34),Color(0.12,0.14,0.19))
        _box(model,Vector3(side*0.23,0.07,-0.06),Vector3(0.36,0.15,0.48),Color(0.07,0.08,0.10))
    _sphere(model,Vector3(0,1.86,0),0.24,Color(0.64,0.43,0.31))
    _box(model,Vector3(0,1.70,-0.02),Vector3(0.48,0.22,0.42),Color(0.08,0.10,0.15))
    var helmet := SphereMesh.new()
    helmet.radius = 0.34
    helmet.height = 0.42
    var helm := MeshInstance3D.new()
    helm.mesh = helmet
    helm.position = Vector3(0,2.08,0)
    helm.material_override = _mat(Color(0.09,0.12,0.19),0.62,0.3)
    model.add_child(helm)
    _box(model,Vector3(0,1.99,-0.28),Vector3(0.68,0.10,0.16),Color(0.65,0.15,0.10),Vector3(-8,0,0),0.5)
    _sphere(model,Vector3(0,2.27,-0.02),0.075,Color(0.88,0.65,0.20),0.8)
    for side in [-1.0,1.0]:
        var horn := PrismMesh.new()
        horn.size = Vector3(0.14,0.55,0.12)
        var h := MeshInstance3D.new()
        h.mesh = horn
        h.position = Vector3(side*0.24,2.24,0)
        h.rotation_degrees.z = side*-18
        h.material_override = _mat(Color(0.78,0.58,0.21),0.75,0.3)
        model.add_child(h)
    cape = _box(model,Vector3(0,1.02,0.36),Vector3(0.72,1.20,0.10),Color(0.42,0.045,0.045),Vector3(7,0,0))
    _box(model,Vector3(0,1.50,0.31),Vector3(0.68,0.12,0.12),Color(0.82,0.59,0.20),Vector3.ZERO,0.65)
    for side in [-1.0,1.0]:
        var arm := Node3D.new()
        arm.position = Vector3(side*0.52,1.48,0)
        model.add_child(arm)
        _box(arm,Vector3(0,-0.25,0),Vector3(0.24,0.52,0.26),Color(0.14,0.16,0.22))
        _box(arm,Vector3(0,-0.48,-0.02),Vector3(0.30,0.18,0.34),Color(0.38,0.12,0.10),Vector3.ZERO,0.3)
        _sphere(arm,Vector3(0,-0.58,0),0.12,Color(0.57,0.36,0.26))
        if side > 0:
            right_arm = arm
    # Bainha nas costas e katana na mão
    _box(model,Vector3(-0.35,1.20,0.36),Vector3(0.12,0.12,1.35),Color(0.06,0.07,0.10),Vector3(-18,0,-18),0.35)
    _box(right_arm,Vector3(0,-0.56,-0.24),Vector3(0.09,0.09,0.38),Color(0.12,0.07,0.05))
    _box(right_arm,Vector3(0,-0.57,-0.48),Vector3(0.22,0.055,0.07),Color(0.82,0.60,0.22),Vector3.ZERO,0.8)
    _box(right_arm,Vector3(0,-0.57,-1.02),Vector3(0.075,0.045,1.08),Color(0.78,0.85,0.90),Vector3(-3,0,0),0.9)
    pivot = Node3D.new()
    pivot.position = Vector3(0,1.55,0)
    add_child(pivot)
    var spring := SpringArm3D.new()
    spring.spring_length = 5.4
    spring.margin = 0.25
    spring.add_excluded_object(get_rid())
    pivot.add_child(spring)
    var cam := Camera3D.new()
    cam.position = Vector3.ZERO
    cam.fov = 68.0
    spring.add_child(cam)
    cam.current = true

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        pivot.rotate_y(-event.relative.x*mouse_sensitivity)
        pivot.rotation.x = clamp(pivot.rotation.x-event.relative.y*mouse_sensitivity,-0.72,0.38)
    elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
    anim_time += delta
    cooldown = maxf(0.0,cooldown-delta)
    attack_time = maxf(0.0,attack_time-delta)
    var input_dir := Vector2(Input.get_action_strength("move_right")-Input.get_action_strength("move_left"),Input.get_action_strength("move_back")-Input.get_action_strength("move_forward")).normalized()
    var forward := -pivot.global_transform.basis.z
    var right := pivot.global_transform.basis.x
    forward.y = 0
    right.y = 0
    forward = forward.normalized()
    right = right.normalized()
    var direction := (right*input_dir.x-forward*input_dir.y).normalized()
    var speed := run_speed if Input.is_action_pressed("sprint") else walk_speed
    velocity.x = direction.x*speed
    velocity.z = direction.z*speed
    if direction.length() > 0.1:
        rotation.y = lerp_angle(rotation.y,atan2(-direction.x,-direction.z),10.0*delta)
    if not is_on_floor():
        velocity.y -= gravity*delta
    elif Input.is_action_just_pressed("jump"):
        velocity.y = 6.5
    else:
        velocity.y = 0.0
    if Input.is_action_just_pressed("attack") and cooldown <= 0.0:
        attack_time = 0.34
        cooldown = 0.62
    if attack_time > 0.0:
        right_arm.rotation.x = -1.35*sin((0.34-attack_time)/0.34*PI)
    else:
        right_arm.rotation.x = lerpf(right_arm.rotation.x,0.0,delta*9.0)
    if is_instance_valid(cape):
        cape.rotation.x = 7.0+sin(anim_time*5.0)*5.0+input_dir.length()*8.0
    move_and_slide()
