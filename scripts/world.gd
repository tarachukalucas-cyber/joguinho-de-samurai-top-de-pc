extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
var player: CharacterBody3D
var hud: Label
var message: Label
var discovered := {}
var landmarks := [
    {"id":"bosque","name":"Bosque das Lanternas","pos":Vector3(-34,0,-24),"hint":"Uma clareira antiga escondida entre as árvores."},
    {"id":"ruinas","name":"Ruínas do Sol","pos":Vector3(31,0,-35),"hint":"Pedras antigas marcadas por símbolos esquecidos."},
    {"id":"lago","name":"Lago Espelhado","pos":Vector3(-38,0,35),"hint":"A água reflete as montanhas ao redor."},
    {"id":"torre","name":"Torre do Vento","pos":Vector3(39,0,34),"hint":"Uma torre de observação no alto do vale."}
]
var quest_text := "Explore os quatro lugares marcados no horizonte."

func _ready() -> void:
    _environment()
    _build_world()
    _spawn_player()
    _spawn_guide()
    _build_hud()
    _show_message("Explorador: Encontre os quatro marcos antigos. O vale guarda a história de uma civilização perdida.")

func material(color: Color, roughness := 1.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = roughness
    return m

func add_box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, label := "Objeto") -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = label
    body.position = pos
    var mesh := MeshInstance3D.new()
    var shape_mesh := BoxMesh.new()
    shape_mesh.size = size
    mesh.mesh = shape_mesh
    mesh.material_override = material(color)
    body.add_child(mesh)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    parent.add_child(body)
    return body

func add_mesh(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.mesh = mesh
    instance.position = pos
    instance.material_override = material(color)
    parent.add_child(instance)
    return instance

func _environment() -> void:
    var world_env := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.16,0.28,0.42)
    sky_mat.sky_horizon_color = Color(0.72,0.76,0.67)
    sky_mat.ground_bottom_color = Color(0.12,0.16,0.12)
    sky_mat.ground_horizon_color = Color(0.48,0.52,0.42)
    sky.sky_material = sky_mat
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.62,0.68,0.72)
    env.ambient_light_energy = 0.8
    world_env.environment = env
    add_child(world_env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48,-28,0)
    sun.light_energy = 1.25
    sun.shadow_enabled = true
    add_child(sun)

func _build_world() -> void:
    add_box(self,Vector3(0,-0.8,0),Vector3(190,1.6,190),Color(0.30,0.39,0.27),"Vale")
    # Colinas e formações rochosas no limite da região
    for p in [Vector3(-78,5,-60),Vector3(-60,7,70),Vector3(75,8,-68),Vector3(78,6,65),Vector3(0,9,-84),Vector3(0,7,83)]:
        var rock := SphereMesh.new()
        rock.radius = 13
        rock.height = 20
        add_mesh(self,rock,p,Color(0.34,0.38,0.36))
    # Caminhos de pedra conectam os pontos de interesse
    for i in range(25):
        var stone := BoxMesh.new()
        stone.size = Vector3(4.0,0.18,2.4)
        var inst := add_mesh(self,stone,Vector3(0,0.05,-46+i*3.8),Color(0.54,0.51,0.42))
        inst.rotation.y = sin(float(i)*0.5)*0.12
    # Bosque
    for x in range(-7,8):
        for z in range(-7,8):
            var p := Vector3(x*7.0,0,z*7.0)
            if Vector2(p.x,p.z).length() > 18 and randf() > 0.22:
                _tree(p)
    # Quatro marcos exploráveis
    _build_grove(landmarks[0].pos)
    _build_ruins(landmarks[1].pos)
    _build_lake(landmarks[2].pos)
    _build_tower(landmarks[3].pos)
    # Acampamento inicial
    add_box(self,Vector3(0,0.8,8),Vector3(4,1.6,3),Color(0.42,0.29,0.17),"Abrigo")
    _campfire(Vector3(4,0,9))

func _tree(p: Vector3) -> void:
    var trunk := CylinderMesh.new()
    trunk.top_radius = 0.18
    trunk.bottom_radius = 0.38
    trunk.height = 3.8
    add_mesh(self,trunk,p+Vector3(0,1.9,0),Color(0.30,0.19,0.12))
    for i in range(3):
        var crown := PrismMesh.new()
        crown.size = Vector3(3.2-i*0.55,2.6,3.0-i*0.5)
        add_mesh(self,crown,p+Vector3(0,3.2+i*1.0,0),[Color(0.12,0.31,0.20),Color(0.16,0.37,0.22),Color(0.21,0.42,0.25)][i])

func _campfire(p: Vector3) -> void:
    var fire := SphereMesh.new()
    fire.radius = 0.55
    fire.height = 1.0
    var flame := add_mesh(self,fire,p+Vector3(0,0.6,0),Color(1.0,0.48,0.12))
    flame.scale = Vector3(0.65,1.2,0.65)
    var light := OmniLight3D.new()
    light.position = p+Vector3(0,1.2,0)
    light.light_color = Color(1.0,0.55,0.24)
    light.omni_range = 9
    light.light_energy = 1.2
    add_child(light)

func _marker(p: Vector3, color: Color) -> void:
    var pillar := CylinderMesh.new()
    pillar.top_radius = 0.35
    pillar.bottom_radius = 0.55
    pillar.height = 3.0
    add_mesh(self,pillar,p+Vector3(0,1.5,0),Color(0.34,0.36,0.33))
    var crystal := PrismMesh.new()
    crystal.size = Vector3(1.2,1.7,1.2)
    var gem := add_mesh(self,crystal,p+Vector3(0,3.8,0),color)
    gem.rotation_degrees = Vector3(0,45,0)
    var glow := OmniLight3D.new()
    glow.position = p+Vector3(0,3.8,0)
    glow.light_color = color
    glow.omni_range = 8
    glow.light_energy = 1.0
    add_child(glow)

func _build_grove(p: Vector3) -> void:
    for i in range(8):
        var angle := TAU*float(i)/8.0
        _tree(p+Vector3(cos(angle)*8,0,sin(angle)*8))
    _marker(p,Color(0.35,0.85,0.62))

func _build_ruins(p: Vector3) -> void:
    for i in range(5):
        add_box(self,p+Vector3(-8+i*4,2,0),Vector3(1.4,4,1.4),Color(0.55,0.53,0.45),"Coluna antiga")
    add_box(self,p+Vector3(0,4,-0.2),Vector3(18,1.2,1.6),Color(0.55,0.53,0.45),"Arco das ruínas")
    _marker(p,Color(0.92,0.72,0.30))

func _build_lake(p: Vector3) -> void:
    var water := CylinderMesh.new()
    water.top_radius = 12
    water.bottom_radius = 12
    water.height = 0.12
    add_mesh(self,water,p+Vector3(0,0.08,0),Color(0.16,0.48,0.58))
    _marker(p+Vector3(14,0,0),Color(0.35,0.75,0.95))

func _build_tower(p: Vector3) -> void:
    add_box(self,p+Vector3(0,3,0),Vector3(5,6,5),Color(0.43,0.42,0.36),"Torre")
    add_box(self,p+Vector3(0,6.3,0),Vector3(7,0.7,7),Color(0.27,0.28,0.25),"Plataforma")
    for x in [-2.2,2.2]:
        add_box(self,p+Vector3(x,8,0),Vector3(0.5,3,0.5),Color(0.38,0.30,0.20),"Pilar da torre")
    _marker(p+Vector3(0,9,0),Color(0.80,0.55,0.95))

func _spawn_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Explorador"
    player.set_script(PlayerScript)
    player.position = Vector3(0,0,15)
    add_child(player)

func _spawn_guide() -> void:
    var npc := StaticBody3D.new()
    npc.position = Vector3(-5,0,9)
    var body := CapsuleMesh.new()
    body.radius = 0.48
    body.height = 1.8
    add_mesh(npc,body,Vector3(0,0.9,0),Color(0.72,0.57,0.34))
    var head := SphereMesh.new()
    head.radius = 0.28
    add_mesh(npc,head,Vector3(0,1.95,0),Color(0.83,0.68,0.49))
    add_child(npc)
    npc.add_to_group("guide")

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(root)
    hud = Label.new()
    hud.position = Vector2(26,22)
    hud.add_theme_font_size_override("font_size",22)
    hud.add_theme_color_override("font_color",Color(0.94,0.91,0.76))
    root.add_child(hud)
    var panel := PanelContainer.new()
    panel.position = Vector2(24,560)
    panel.size = Vector2(920,105)
    root.add_child(panel)
    message = Label.new()
    message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    message.add_theme_font_size_override("font_size",18)
    panel.add_child(message)
    var controls := Label.new()
    controls.text = "WASD mover  |  Shift correr  |  Espaço pular  |  Mouse olhar  |  F explorar/observar  |  E conversar"
    controls.position = Vector2(24,680)
    controls.add_theme_font_size_override("font_size",15)
    root.add_child(controls)

func _process(_delta: float) -> void:
    if not is_instance_valid(player):
        return
    var count := discovered.size()
    hud.text = "CAMINHO DO VALE   |   MARCOS %d/4\n%s" % [count,quest_text]
    if Input.is_action_just_pressed("interact"):
        if player.global_position.distance_to(Vector3(-5,0,9)) < 3.5:
            _show_message("Guia: Siga os cristais antigos. Cada marco revela um fragmento da história deste vale.")
        else:
            _show_message("O vento sopra entre as árvores. Explore os cristais luminosos para descobrir este lugar.")
    if Input.is_action_just_pressed("explore"):
        _discover_nearest()

func _discover_nearest() -> void:
    var nearest = null
    var nearest_distance := 999999.0
    for place in landmarks:
        var d: float = player.global_position.distance_to(place.pos)
        if d < nearest_distance:
            nearest_distance = d
            nearest = place
    if nearest == null or nearest_distance > 15.0:
        _show_message("Não há nenhum marco antigo próximo. Procure os cristais luminosos no horizonte.")
        return
    var key: String = nearest.id
    if discovered.has(key):
        _show_message(nearest.name + ": " + nearest.hint + " Você já registrou este local.")
        return
    discovered[key] = true
    _show_message("LOCAL DESCOBERTO — " + nearest.name + ". " + nearest.hint)
    if discovered.size() == 4:
        quest_text = "Todos os marcos foram descobertos. A história do vale foi revelada!"
        _show_message("Você explorou todo o vale! Os quatro marcos formam um mapa da civilização perdida.")

func _show_message(line: String) -> void:
    if is_instance_valid(message):
        message.text = line
