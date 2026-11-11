extends CharacterBody3D

var move_speed := 5.8
var sprint_speed := 9.5
var jump_velocity := 7.0
var camera_pivot: Node3D
var spring_arm: SpringArm3D
var camera: Camera3D
var gravity := 22.0
var camera_sensitivity := 0.0025
var turn_speed := 10.0
var sword_pivot: Node3D

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

func _mat(color: Color, roughness := 0.72, metallic := 0.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = roughness
    m.metallic = metallic
    return m

func _add_piece(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color, rot := Vector3.ZERO, roughness := 0.72, metallic := 0.0) -> MeshInstance3D:
    var part := MeshInstance3D.new()
    part.mesh = mesh
    part.position = pos
    part.rotation_degrees = rot
    part.material_override = _mat(color,roughness,metallic)
    parent.add_child(part)
    return part

func _build_model() -> void:
    var collider := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.4
    shape.height = 1.85
    collider.shape = shape
    collider.position.y = 0.93
    add_child(collider)
    # Silhueta de samurai viajante, com placas e tecido em camadas
    var torso := CapsuleMesh.new()
    torso.radius = 0.39
    torso.height = 1.1
    _add_piece(self,torso,Vector3(0,1.22,0),Color(0.16,0.20,0.23))
    var robe := BoxMesh.new()
    robe.size = Vector3(0.95,0.75,0.58)
    _add_piece(self,robe,Vector3(0,0.72,0),Color(0.30,0.12,0.10))
    var head := SphereMesh.new()
    head.radius = 0.25
    _add_piece(self,head,Vector3(0,2.0,0),Color(0.68,0.49,0.36))
    var helmet := SphereMesh.new()
    helmet.radius = 0.34
    helmet.height = 0.25
    _add_piece(self,helmet,Vector3(0,2.16,0),Color(0.12,0.15,0.17),Vector3.ZERO,0.38,0.65)
    var shoulder := BoxMesh.new()
    shoulder.size = Vector3(1.12,0.22,0.62)
    _add_piece(self,shoulder,Vector3(0,1.63,0),Color(0.25,0.29,0.30),Vector3.ZERO,0.42,0.55)
    for side in [-1.0,1.0]:
        var plate := BoxMesh.new()
        plate.size = Vector3(0.38,0.55,0.16)
        _add_piece(self,plate,Vector3(side*0.43,1.28,-0.08),Color(0.42,0.29,0.17),Vector3(0,0,side*-8),0.48,0.35)
        var leg := BoxMesh.new()
        leg.size = Vector3(0.34,0.72,0.38)
        _add_piece(self,leg,Vector3(side*0.22,0.22,0),Color(0.12,0.15,0.17))
    sword_pivot = Node3D.new()
    sword_pivot.position = Vector3(0.42,1.0,-0.12)
    add_child(sword_pivot)
    var grip := CylinderMesh.new()
    grip.top_radius = 0.045
    grip.bottom_radius = 0.045
    grip.height = 0.52
    _add_piece(sword_pivot,grip,Vector3(0,0.0,0),Color(0.12,0.09,0.08))
    var blade := BoxMesh.new()
    blade.size = Vector3(0.07,0.06,1.35)
    _add_piece(sword_pivot,blade,Vector3(0,0.0,-0.86),Color(0.72,0.79,0.82),Vector3.ZERO,0.22,0.85)
    camera_pivot = Node3D.new()
    camera_pivot.position = Vector3(0,1.55,0)
    add_child(camera_pivot)
    spring_arm = SpringArm3D.new()
    spring_arm.spring_length = 6.2
    spring_arm.margin = 0.25
    spring_arm.position = Vector3(0,0.35,0)
    camera_pivot.add_child(spring_arm)
    camera = Camera3D.new()
    camera.position = Vector3.ZERO
    camera.fov = 72.0
    spring_arm.add_child(camera)
    camera.current = true

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        camera_pivot.rotate_y(-event.relative.x*camera_sensitivity)
        camera_pivot.rotation.x = clamp(camera_pivot.rotation.x-event.relative.y*camera_sensitivity,-0.85,0.42)
    if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
    var input_dir := Vector2(Input.get_action_strength("move_right")-Input.get_action_strength("move_left"),Input.get_action_strength("move_back")-Input.get_action_strength("move_forward")).normalized()
    var camera_basis := camera_pivot.global_transform.basis
    var forward := -camera_basis.z
    var right := camera_basis.x
    forward.y = 0
    right.y = 0
    forward = forward.normalized()
    right = right.normalized()
    var direction := (right*input_dir.x+forward*(-input_dir.y)).normalized()
    var speed := sprint_speed if Input.is_action_pressed("sprint") else move_speed
    velocity.x = direction.x*speed
    velocity.z = direction.z*speed
    if direction.length() > 0.1:
        var target_angle := atan2(-direction.x,-direction.z)
        rotation.y = lerp_angle(rotation.y,target_angle,turn_speed*delta)
    if not is_on_floor():
        velocity.y -= gravity*delta
    elif Input.is_action_just_pressed("jump"):
        velocity.y = jump_velocity
    else:
        velocity.y = 0.0
    move_and_slide()
