extends CharacterBody3D

var health := 100
var posture := 0
var move_speed := 6.0
var attack_wait := 0.0
var dodge_time := 0.0
var parry_time := 0.0
var camera_pivot: Node3D
var sword: MeshInstance3D

func _ready() -> void:
    add_to_group("player")
    _input_setup()
    _build_model()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input_setup() -> void:
    var keys = {"move_forward":KEY_W,"move_back":KEY_S,"move_left":KEY_A,"move_right":KEY_D,"interact":KEY_E,"dodge":KEY_SPACE,"parry":KEY_Q}
    for action in keys:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        var key_event := InputEventKey.new()
        key_event.physical_keycode = keys[action]
        InputMap.action_add_event(action,key_event)
    if not InputMap.has_action("attack"):
        InputMap.add_action("attack")
    var click := InputEventMouseButton.new()
    click.button_index = MOUSE_BUTTON_LEFT
    InputMap.action_add_event("attack",click)

func _material(color: Color, rough := 0.8) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = rough
    return m

func _build_model() -> void:
    var collider := CollisionShape3D.new()
    var capsule_shape := CapsuleShape3D.new()
    capsule_shape.radius = 0.4
    capsule_shape.height = 1.8
    collider.shape = capsule_shape
    collider.position.y = 0.9
    add_child(collider)
    var body := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.4
    capsule.height = 1.8
    body.mesh = capsule
    body.position.y = 0.9
    body.material_override = _material(Color(0.12,0.17,0.25))
    add_child(body)
    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.28
    head.mesh = head_mesh
    head.position = Vector3(0,1.95,0)
    head.material_override = _material(Color(0.72,0.52,0.37))
    add_child(head)
    sword = MeshInstance3D.new()
    var blade := BoxMesh.new()
    blade.size = Vector3(0.07,0.07,1.35)
    sword.mesh = blade
    sword.position = Vector3(0.48,1.05,-0.62)
    sword.material_override = _material(Color(0.78,0.84,0.9),0.25)
    add_child(sword)
    camera_pivot = Node3D.new()
    camera_pivot.position = Vector3(0,1.5,0)
    add_child(camera_pivot)
    var camera := Camera3D.new()
    camera.position = Vector3(0,2.5,6.6)
    camera.rotation_degrees.x = -15
    camera.current = true
    camera_pivot.add_child(camera)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * 0.003)
        camera_pivot.rotate_x(-event.relative.y * 0.003)
        camera_pivot.rotation.x = clamp(camera_pivot.rotation.x,-0.55,0.3)
    if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
    attack_wait = maxf(0.0,attack_wait-delta)
    dodge_time = maxf(0.0,dodge_time-delta)
    parry_time = maxf(0.0,parry_time-delta)
    var input_dir := Vector2(Input.get_action_strength("move_right")-Input.get_action_strength("move_left"),Input.get_action_strength("move_back")-Input.get_action_strength("move_forward")).normalized()
    var direction := (transform.basis * Vector3(input_dir.x,0,input_dir.y)).normalized()
    if dodge_time > 0.0:
        velocity.x = -global_transform.basis.z.x * 13.0
        velocity.z = -global_transform.basis.z.z * 13.0
    else:
        velocity.x = direction.x * move_speed
        velocity.z = direction.z * move_speed
    if not is_on_floor():
        velocity.y -= 22.0 * delta
    else:
        velocity.y = 0.0
    if Input.is_action_just_pressed("dodge") and dodge_time <= 0.0:
        dodge_time = 0.32
    if Input.is_action_just_pressed("parry"):
        parry_time = 0.3
        posture = maxi(0,posture-12)
    if Input.is_action_just_pressed("attack"):
        _attack()
    move_and_slide()

func _attack() -> void:
    if attack_wait > 0.0:
        return
    attack_wait = 0.5
    sword.rotation.x = -1.0
    await get_tree().create_timer(0.15).timeout
    if not is_instance_valid(sword):
        return
    sword.rotation.x = 0.0
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if global_position.distance_to(enemy.global_position) <= 2.7:
            var toward := (enemy.global_position-global_position).normalized()
            if (-global_transform.basis.z).dot(toward) > 0.1:
                enemy.take_hit(25)

func receive_attack(damage: int) -> void:
    if parry_time > 0.0:
        posture = maxi(0,posture-20)
        return
    if dodge_time > 0.0:
        return
    health = maxi(0,health-damage)
    if health <= 0:
        health = 100
        posture = 0
        global_position = Vector3(0,0,11)
