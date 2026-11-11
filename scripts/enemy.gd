extends CharacterBody3D

var health := 60
var attack_cooldown := 0.0
var flash_time := 0.0
var player: Node3D
var body_material: StandardMaterial3D

func _ready() -> void:
    add_to_group("enemies")
    var collider := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.42
    shape.height = 1.8
    collider.shape = shape
    collider.position.y = 0.9
    add_child(collider)
    var body := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.42
    capsule.height = 1.8
    body.mesh = capsule
    body.position.y = 0.9
    body_material = StandardMaterial3D.new()
    body_material.albedo_color = Color(0.48,0.15,0.12)
    body.material_override = body_material
    add_child(body)
    var helmet := MeshInstance3D.new()
    var helmet_mesh := BoxMesh.new()
    helmet_mesh.size = Vector3(0.9,0.2,0.65)
    helmet.mesh = helmet_mesh
    helmet.position = Vector3(0,1.82,0)
    helmet.material_override = body_material
    add_child(helmet)
    await get_tree().process_frame
    player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
    attack_cooldown = maxf(0.0,attack_cooldown-delta)
    flash_time = maxf(0.0,flash_time-delta)
    if flash_time <= 0.0:
        body_material.albedo_color = Color(0.48,0.15,0.12)
    if not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player")
        return
    var distance := global_position.distance_to(player.global_position)
    if distance < 11.0:
        var direction := (player.global_position-global_position).normalized()
        rotation.y = atan2(-direction.x,-direction.z)
        if distance > 1.9:
            velocity.x = direction.x * 2.2
            velocity.z = direction.z * 2.2
        elif attack_cooldown <= 0.0:
            attack_cooldown = 1.4
            player.receive_attack(12)
    else:
        velocity.x = move_toward(velocity.x,0.0,8.0*delta)
        velocity.z = move_toward(velocity.z,0.0,8.0*delta)
    if not is_on_floor():
        velocity.y -= 22.0 * delta
    else:
        velocity.y = 0.0
    move_and_slide()

func take_hit(damage: int) -> void:
    health -= damage
    flash_time = 0.15
    body_material.albedo_color = Color(1.0,0.72,0.32)
    if health <= 0:
        var world = get_parent()
        if world.has_method("enemy_defeated"):
            world.enemy_defeated()
        queue_free()
