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
    var keys := {"move_forward":KEY_W,"move_back":KEY_S,"move_left":KEY_A,"move_right":KEY_D,"sprint":KEY_SHIFT,"jump":KEY_SPACE,"pulse":KEY_J,"interact":KEY_E,"explore":KEY_F}
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

    # A aparência do personagem está na cena samurai_visual.tscn.
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
    if Input.is_action_just_pressed("pulse") and cooldown <= 0.0:
        attack_time = 0.34
        cooldown = 0.62
        _pulse_machines()
    # O modelo usa animação visual independente; o pulso não depende de uma arma.
    move_and_slide()

func _pulse_machines() -> void:
    var forward := -global_transform.basis.z
    for target in get_tree().get_nodes_in_group("machines"):
        if not is_instance_valid(target):
            continue
        var offset: Vector3 = target.global_position-global_position
        var distance := offset.length()
        if distance <= 3.2 and distance > 0.01 and offset.normalized().dot(forward) > 0.05:
            if target.has_method("receive_hit"):
                target.receive_hit(35)
