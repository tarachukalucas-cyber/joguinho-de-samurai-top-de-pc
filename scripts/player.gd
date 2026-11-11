extends CharacterBody3D

var move_speed := 7.0
var sprint_speed := 12.0
var jump_velocity := 7.5
var camera_pivot: Node3D
var camera: Camera3D
var gravity := 22.0

func _ready() -> void:
    _input_setup()
    _build_model()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input_setup() -> void:
    var keys = {"move_forward":KEY_W,"move_back":KEY_S,"move_left":KEY_A,"move_right":KEY_D,"interact":KEY_E,"explore":KEY_F,"sprint":KEY_SHIFT,"jump":KEY_SPACE}
    for action in keys:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        var event := InputEventKey.new()
        event.physical_keycode = keys[action]
        InputMap.action_add_event(action,event)

func _mat(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.85
    return m

func _build_model() -> void:
    var collider := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.42
    shape.height = 1.9
    collider.shape = shape
    collider.position.y = 0.95
    add_child(collider)
    var body := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.42
    capsule.height = 1.9
    body.mesh = capsule
    body.position.y = 0.95
    body.material_override = _mat(Color(0.22,0.30,0.32))
    add_child(body)
    var head := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.29
    head.mesh = sphere
    head.position = Vector3(0,2.05,0)
    head.material_override = _mat(Color(0.76,0.58,0.43))
    add_child(head)
    var pack := MeshInstance3D.new()
    var pack_mesh := BoxMesh.new()
    pack_mesh.size = Vector3(0.65,0.75,0.35)
    pack.mesh = pack_mesh
    pack.position = Vector3(0,1.12,0.48)
    pack.material_override = _mat(Color(0.43,0.25,0.13))
    add_child(pack)
    camera_pivot = Node3D.new()
    camera_pivot.position = Vector3(0,1.55,0)
    add_child(camera_pivot)
    camera = Camera3D.new()
    camera.position = Vector3(0,2.7,7.4)
    camera.rotation_degrees.x = -18
    camera.current = true
    camera_pivot.add_child(camera)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x*0.003)
        camera_pivot.rotate_x(-event.relative.y*0.003)
        camera_pivot.rotation.x = clamp(camera_pivot.rotation.x,-0.65,0.35)
    if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
    var input_dir := Vector2(Input.get_action_strength("move_right")-Input.get_action_strength("move_left"),Input.get_action_strength("move_back")-Input.get_action_strength("move_forward")).normalized()
    var direction := (transform.basis*Vector3(input_dir.x,0,input_dir.y)).normalized()
    var speed := sprint_speed if Input.is_action_pressed("sprint") else move_speed
    velocity.x = direction.x*speed
    velocity.z = direction.z*speed
    if not is_on_floor():
        velocity.y -= gravity*delta
    else:
        if Input.is_action_just_pressed("jump"):
            velocity.y = jump_velocity
        else:
            velocity.y = 0.0
    move_and_slide()
