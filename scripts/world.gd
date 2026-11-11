extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
var player: CharacterBody3D
var dialogue: Label
var status: Label
var enemies_remaining := 0

func _ready() -> void:
    _environment()
    _map()
    _spawn_player()
    _spawn_characters()
    _ui()
    _say("MONge: O caminho para o santuário está tomado. Aprenda a aparar antes de enfrentar o guardião.")

func mat(color: Color, rough := 1.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = rough
    return m

func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, label := "Objeto") -> StaticBody3D:
    var b := StaticBody3D.new()
    b.name = label
    b.position = pos
    var mesh := MeshInstance3D.new()
    var shape_mesh := BoxMesh.new()
    shape_mesh.size = size
    mesh.mesh = shape_mesh
    mesh.material_override = mat(color)
    b.add_child(mesh)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    b.add_child(collision)
    parent.add_child(b)
    return b

func _environment() -> void:
    var env_node := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    sky.sky_material = ProceduralSkyMaterial.new()
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.48, 0.56, 0.62)
    env.ambient_light_energy = 0.7
    env_node.environment = env
    add_child(env_node)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -32, 0)
    sun.light_energy = 1.15
    sun.shadow_enabled = true
    add_child(sun)

func _map() -> void:
    box(self, Vector3(0, -0.6, 0), Vector3(48, 1.2, 48), Color(0.25,0.31,0.23), "Chao do vale")
    for i in range(11):
        box(self, Vector3(0, 0.03, -20 + i * 3.8), Vector3(5,0.16,2.8), Color(0.48,0.45,0.36), "Pedra da trilha")
    for x in [-22,22]:
        box(self, Vector3(x,2,0), Vector3(2,5,48), Color(0.20,0.24,0.23), "Parede rochosa")
    for p in [Vector3(-9,0,-9),Vector3(10,0,-12),Vector3(-12,0,8),Vector3(13,0,9),Vector3(8,0,1),Vector3(-3,0,15)]:
        _tree(p)
    # Portao de entrada
    box(self, Vector3(0,3,-19), Vector3(9,0.55,0.8), Color(0.48,0.16,0.10), "Viga do torii")
    for x in [-3.6,3.6]:
        box(self, Vector3(x,1.5,-19), Vector3(0.65,3.5,0.65), Color(0.42,0.12,0.08), "Pilar do torii")
    # Casa de chá e telhado
    box(self, Vector3(14,1.1,-5), Vector3(5,2.2,5), Color(0.43,0.31,0.20), "Casa de chá")
    box(self, Vector3(14,2.45,-5), Vector3(6.2,0.35,6.2), Color(0.19,0.15,0.13), "Telhado")
    # Lanternas low-poly
    for p in [Vector3(-5,0,-2),Vector3(5,0,-14),Vector3(10,0,5)]:
        _lantern(p)

func _tree(p: Vector3) -> void:
    var trunk := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 0.16
    cylinder.bottom_radius = 0.34
    cylinder.height = 2.8
    trunk.mesh = cylinder
    trunk.position = p + Vector3(0,1.4,0)
    trunk.material_override = mat(Color(0.28,0.17,0.10))
    add_child(trunk)
    for i in range(3):
        var crown := MeshInstance3D.new()
        var cone := PrismMesh.new()
        cone.size = Vector3(2.6 - i*0.45, 1.9, 2.4 - i*0.4)
        crown.mesh = cone
        crown.position = p + Vector3(0,2.5+i*0.65,0)
        crown.material_override = mat(Color(0.12 + i*0.02,0.28,0.18))
        add_child(crown)

func _lantern(p: Vector3) -> void:
    box(self,p+Vector3(0,0.8,0),Vector3(0.25,1.6,0.25),Color(0.28,0.19,0.12),"Poste da lanterna")
    box(self,p+Vector3(0,1.75,0),Vector3(0.8,0.65,0.8),Color(0.22,0.14,0.10),"Lanterna")
    box(self,p+Vector3(0,1.75,0),Vector3(0.45,0.42,0.45),Color(0.95,0.58,0.20),"Luz da lanterna")

func _spawn_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.set_script(PlayerScript)
    player.position = Vector3(0,0,11)
    add_child(player)

func _spawn_characters() -> void:
    _make_npc(Vector3(-6,0,-5))
    for p in [Vector3(0,0,-7),Vector3(7,0,-13),Vector3(-8,0,5)]:
        var enemy := CharacterBody3D.new()
        enemy.set_script(EnemyScript)
        enemy.position = p
        add_child(enemy)
        enemies_remaining += 1

func _make_npc(p: Vector3) -> void:
    var npc := StaticBody3D.new()
    npc.position = p
    var mesh := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.48
    capsule.height = 1.8
    mesh.mesh = capsule
    mesh.position.y = 0.9
    mesh.material_override = mat(Color(0.72,0.57,0.32))
    npc.add_child(mesh)
    add_child(npc)
    npc.add_to_group("monge")

func _ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(root)
    status = Label.new()
    status.position = Vector2(24,20)
    status.add_theme_font_size_override("font_size",22)
    status.add_theme_color_override("font_color",Color(1,0.86,0.62))
    root.add_child(status)
    var panel := PanelContainer.new()
    panel.position = Vector2(24,550)
    panel.size = Vector2(900,115)
    root.add_child(panel)
    dialogue = Label.new()
    dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    dialogue.add_theme_font_size_override("font_size",19)
    panel.add_child(dialogue)
    var controls := Label.new()
    controls.text = "WASD mover  |  Mouse olhar  |  Clique atacar  |  Q aparar  |  ESPAÇO esquivar  |  E conversar"
    controls.position = Vector2(24,690)
    controls.add_theme_font_size_override("font_size",15)
    root.add_child(controls)

func _process(_delta: float) -> void:
    if is_instance_valid(player):
        status.text = "VIDA %d     POSTURA %d     ADVERSÁRIOS %d" % [player.health, player.posture, enemies_remaining]
    if Input.is_action_just_pressed("interact"):
        if player.global_position.distance_to(Vector3(-6,0,-5)) < 3.2:
            _say("Monge: Não ataque sem pensar. Observe o movimento do inimigo e use Q no instante do golpe.")
        else:
            _say("O vento atravessa o vale. Não há ninguém por perto.")

func _say(line: String) -> void:
    if is_instance_valid(dialogue):
        dialogue.text = line

func enemy_defeated() -> void:
    enemies_remaining = max(0, enemies_remaining - 1)
    if enemies_remaining == 0:
        _say("Monge: O caminho está aberto. O Guardião do Santuário espera além do portão.")
