extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const MachineScript = preload("res://scripts/machine.gd")
var player: CharacterBody3D
var hud: Label
var message: Label
var discovered := {}
var landmarks := [
    {"id":"santuario","name":"Santuário das Cerejeiras","pos":Vector3(-48,0,-38),"hint":"Um santuário antigo escondido sob as cerejeiras."},
    {"id":"forja","name":"Forja Abandonada","pos":Vector3(48,0,-42),"hint":"Uma oficina esquecida onde as máquinas eram construídas."},
    {"id":"lago","name":"Lago das Brumas","pos":Vector3(-52,0,48),"hint":"Um lago cercado por penhascos e névoa."},
    {"id":"torre","name":"Torre do Guardião","pos":Vector3(55,0,48),"hint":"Uma torre de vigia sobre o vale."}
]
var quest_text := "Explore os quatro locais antigos."

func _ready() -> void:
    randomize()
    _environment()
    _terrain()
    _mountain_range()
    _build_world()
    _spawn_player()
    _spawn_guide()
    _build_hud()
    _show_message("CAMINHOS DO VALE — Encontre os quatro marcos antigos e descubra por que as máquinas despertaram.")

func mat(c: Color, rough := 0.8, metal := 0.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = rough
    m.metallic = metal
    return m

func mesh_piece(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color, scale_value := Vector3.ONE, metal := 0.0) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    n.mesh = mesh
    n.position = pos
    n.scale = scale_value
    n.material_override = mat(color,0.78,metal)
    parent.add_child(n)
    return n

func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, rot := Vector3.ZERO, collision := false) -> Node3D:
    var holder: Node3D
    if collision:
        holder = StaticBody3D.new()
    else:
        holder = Node3D.new()
    holder.position = pos
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_piece(holder,mesh,Vector3.ZERO,color)
    if collision:
        var cs := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        cs.shape = shape
        holder.add_child(cs)
    holder.rotation_degrees = rot
    parent.add_child(holder)
    return holder

func _environment() -> void:
    var we := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.12,0.22,0.38)
    sky_mat.sky_horizon_color = Color(0.78,0.66,0.58)
    sky_mat.ground_bottom_color = Color(0.12,0.16,0.14)
    sky_mat.ground_horizon_color = Color(0.45,0.43,0.36)
    sky.sky_material = sky_mat
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_energy = 0.72
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.tonemap_exposure = 1.12
    env.glow_enabled = true
    env.glow_intensity = 0.35
    env.fog_enabled = true
    env.fog_light_color = Color(0.57,0.62,0.65)
    env.fog_density = 0.006
    we.environment = env
    add_child(we)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-43,-32,0)
    sun.light_energy = 1.35
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 160.0
    add_child(sun)

func _height(x: float, z: float) -> float:
    var edge := maxf(absf(x),absf(z))
    var ridge := pow(clampf((edge-68.0)/48.0,0.0,1.0),1.6)*12.0
    return -1.2 + ridge + sin(x*0.045)*0.8 + cos(z*0.052)*0.7 + sin((x+z)*0.025)*0.9

func _terrain() -> void:
    var verts := PackedVector3Array()
    var indices := PackedInt32Array()
    var resolution := 72
    var extent := 130.0
    for z in range(resolution+1):
        for x in range(resolution+1):
            var wx := -extent + float(x)/resolution*extent*2.0
            var wz := -extent + float(z)/resolution*extent*2.0
            verts.append(Vector3(wx,_height(wx,wz),wz))
    for z in range(resolution):
        for x in range(resolution):
            var a := z*(resolution+1)+x
            var b := a+1
            var c := a+resolution+1
            var d := c+1
            indices.append_array(PackedInt32Array([a,c,b,b,c,d]))
    var normals := PackedVector3Array()
    normals.resize(verts.size())
    for i in range(normals.size()):
        normals[i] = Vector3.ZERO
    for i in range(0,indices.size(),3):
        var ia: int = indices[i]
        var ib: int = indices[i+1]
        var ic: int = indices[i+2]
        var normal := (verts[ib]-verts[ia]).cross(verts[ic]-verts[ia]).normalized()
        normals[ia] += normal
        normals[ib] += normal
        normals[ic] += normal
    for i in range(normals.size()):
        normals[i] = normals[i].normalized()
    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = verts
    arrays[Mesh.ARRAY_NORMAL] = normals
    arrays[Mesh.ARRAY_INDEX] = indices
    var terrain_mesh := ArrayMesh.new()
    terrain_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    var surface := MeshInstance3D.new()
    surface.mesh = terrain_mesh
    surface.material_override = mat(Color(0.25,0.34,0.22),1.0)
    add_child(surface)
    var body := StaticBody3D.new()
    var collision := CollisionShape3D.new()
    collision.shape = terrain_mesh.create_trimesh_shape()
    body.add_child(collision)
    add_child(body)

func _mountain_range() -> void:
    for i in range(17):
        var x := -130.0 + float(i)*16.0
        var z := -112.0 - randf_range(0,12)
        var h := randf_range(22,42)
        var rock := SphereMesh.new()
        rock.radius = 1.0
        rock.height = 2.0
        mesh_piece(self,rock,Vector3(x,h*0.38,z),Color(0.25,0.30,0.34),Vector3(randf_range(9,17),h,randf_range(9,17)))
        var snow := SphereMesh.new()
        snow.radius = 1.0
        snow.height = 2.0
        mesh_piece(self,snow,Vector3(x,h*0.90,z),Color(0.62,0.66,0.67),Vector3(4,4,4))
    for i in range(14):
        var x2 := -130.0 + float(i)*19.0
        var z2 := 112.0 + randf_range(0,12)
        var rock2 := SphereMesh.new()
        rock2.radius = 1.0
        rock2.height = 2.0
        mesh_piece(self,rock2,Vector3(x2,13,z2),Color(0.29,0.32,0.33),Vector3(13,27,13))

func _build_world() -> void:
    # Stone road from the starting village toward the old gateway
    for i in range(34):
        var z := 20.0 - float(i)*4.0
        var stone := BoxMesh.new()
        stone.size = Vector3(randf_range(2.2,3.8),0.16,randf_range(1.4,2.4))
        var n := mesh_piece(self,stone,Vector3(sin(float(i)*0.3)*1.8,_height(0,z)+0.08,z),Color(0.43,0.42,0.37))
        n.rotation.y = randf_range(-0.16,0.16)
    # Forest bands with varied tree silhouettes
    for i in range(210):
        var x := randf_range(-105,105)
        var z := randf_range(-100,100)
        if Vector2(x,z).length() > 18 and Vector2(x,z).distance_to(Vector2(-48,-38)) > 17 and Vector2(x,z).distance_to(Vector2(48,-42)) > 17:
            _tree(Vector3(x,_height(x,z),z),randf_range(0.72,1.55),randf() < 0.24)
    # Cherry trees framing the shrine and the main valley
    for i in range(22):
        var a := TAU*float(i)/22.0
        _tree(Vector3(-48+cos(a)*15,_height(-48+cos(a)*15,-38+sin(a)*15),-38+sin(a)*15),randf_range(0.9,1.3),true)
    _village(Vector3(0,_height(0,16),16))
    _torii(Vector3(0,_height(0,-20),-20))
    _shrine(landmarks[0].pos)
    _forge(landmarks[1].pos)
    _lake(landmarks[2].pos)
    _tower(landmarks[3].pos)
    _camp()
    _spawn_machine(Vector3(-20,_height(-20,-12),-12))
    _spawn_machine(Vector3(28,_height(28,24),24))
    _spawn_machine(Vector3(72,_height(72,-4),-4))
    _flowers()

func _tree(p: Vector3, scale_value: float, cherry: bool) -> void:
    var trunk := CylinderMesh.new()
    trunk.top_radius = 0.18*scale_value
    trunk.bottom_radius = 0.34*scale_value
    trunk.height = 4.6*scale_value
    mesh_piece(self,trunk,p+Vector3(0,2.3*scale_value,0),Color(0.25,0.15,0.10),Vector3.ONE)
    for j in range(3):
        var crown := SphereMesh.new()
        crown.radius = 1.65*scale_value*(1.0-float(j)*0.12)
        crown.height = 2.2*scale_value
        var color := Color(0.48,0.20,0.28) if cherry else [Color(0.10,0.26,0.18),Color(0.13,0.34,0.22),Color(0.18,0.39,0.25)][j]
        mesh_piece(self,crown,p+Vector3(randf_range(-0.5,0.5),3.8*scale_value+j*0.75*scale_value,randf_range(-0.4,0.4)),color)

func _flowers() -> void:
    for i in range(190):
        var x := randf_range(-90,90)
        var z := randf_range(-90,90)
        var petal := SphereMesh.new()
        petal.radius = 0.11
        petal.height = 0.10
        var color := [Color(0.90,0.62,0.65),Color(0.91,0.78,0.42),Color(0.72,0.78,0.58)][i%3]
        mesh_piece(self,petal,Vector3(x,_height(x,z)+0.16,z),color,Vector3(1.0,0.45,1.0))

func _village(p: Vector3) -> void:
    for i in range(4):
        var x := p.x + float(i%2)*13.0-7.0
        var z := p.z + float(i/2)*10.0-5.0
        _house(Vector3(x,p.y,z),i==0)
    for i in range(6):
        box(self,p+Vector3(-13+i*5,0.8,-13),Vector3(0.22,1.6,0.22),Color(0.32,0.22,0.14))
    # banners and lanterns
    for side in [-1.0,1.0]:
        var lamp := SphereMesh.new()
        lamp.radius = 0.36
        mesh_piece(self,lamp,p+Vector3(side*8,2.0,8),Color(1.0,0.58,0.22))
        var glow := OmniLight3D.new()
        glow.position = p+Vector3(side*8,2.0,8)
        glow.light_color = Color(1.0,0.46,0.18)
        glow.omni_range = 7.0
        glow.light_energy = 1.1
        add_child(glow)

func _house(p: Vector3, main_house: bool) -> void:
    var w := 7.0 if main_house else 5.0
    var h := 4.2 if main_house else 3.4
    box(self,p+Vector3(0,h*0.5,0),Vector3(w,h,w*0.78),Color(0.34,0.22,0.15),Vector3.ZERO,true)
    box(self,p+Vector3(0,h+0.3,0),Vector3(w+2.0,0.35,w),Color(0.15,0.13,0.12))
    for side in [-1.0,1.0]:
        box(self,p+Vector3(side*(w*0.43),h*0.5,-w*0.42),Vector3(0.18,h,0.18),Color(0.18,0.12,0.09))
    var roof := PrismMesh.new()
    roof.size = Vector3(w+2.8,2.0,w+1.4)
    mesh_piece(self,roof,p+Vector3(0,h+1.2,0),Color(0.13,0.16,0.20),Vector3(1,1,1))
    box(self,p+Vector3(0,1.2,-w*0.40),Vector3(1.5,2.4,0.12),Color(0.12,0.10,0.08))

func _torii(p: Vector3) -> void:
    for x in [-3.2,3.2]:
        box(self,p+Vector3(x,2.7,0),Vector3(0.55,5.4,0.55),Color(0.55,0.10,0.08))
    box(self,p+Vector3(0,5.35,0),Vector3(9.2,0.55,0.8),Color(0.57,0.11,0.08))
    box(self,p+Vector3(0,4.75,0),Vector3(7.6,0.28,0.55),Color(0.25,0.13,0.10))

func _shrine(p: Vector3) -> void:
    _torii(p+Vector3(0,0,8))
    _house(p+Vector3(0,0,-3),true)
    for i in range(9):
        var stone := SphereMesh.new()
        stone.radius = 0.75
        mesh_piece(self,stone,p+Vector3(-8+i*2,0.5,8),Color(0.42,0.42,0.39),Vector3(1,0.7,1))
    _marker(p,Color(0.92,0.62,0.25))

func _forge(p: Vector3) -> void:
    box(self,p+Vector3(0,2,0),Vector3(12,4,10),Color(0.27,0.25,0.22),Vector3.ZERO,true)
    for x in [-4.0,0.0,4.0]:
        box(self,p+Vector3(x,4.8,-3),Vector3(0.55,2.0,0.55),Color(0.32,0.27,0.20))
    var chimney := CylinderMesh.new()
    chimney.top_radius = 0.55
    chimney.bottom_radius = 0.8
    chimney.height = 6.0
    mesh_piece(self,chimney,p+Vector3(4,6,2),Color(0.18,0.18,0.18))
    _marker(p+Vector3(0,0,9),Color(0.25,0.78,0.94))

func _lake(p: Vector3) -> void:
    var water := CylinderMesh.new()
    water.top_radius = 15
    water.bottom_radius = 15
    water.height = 0.18
    var w := mesh_piece(self,water,p+Vector3(0,0.16,0),Color(0.10,0.37,0.48))
    w.material_override = mat(Color(0.12,0.42,0.55),0.16,0.18)
    for i in range(16):
        var rock := SphereMesh.new()
        rock.radius = randf_range(1.0,2.4)
        rock.height = randf_range(1.5,3.2)
        var a := TAU*float(i)/16.0
        mesh_piece(self,rock,p+Vector3(cos(a)*18,1.0,sin(a)*18),Color(0.34,0.37,0.37),Vector3(1,1.2,1))
    _marker(p+Vector3(18,0,0),Color(0.24,0.75,0.94))

func _tower(p: Vector3) -> void:
    box(self,p+Vector3(0,4,0),Vector3(7,8,7),Color(0.34,0.29,0.22),Vector3.ZERO,true)
    box(self,p+Vector3(0,8.3,0),Vector3(10,0.55,10),Color(0.13,0.16,0.19))
    var roof := PrismMesh.new()
    roof.size = Vector3(12,3,12)
    mesh_piece(self,roof,p+Vector3(0,10,0),Color(0.12,0.14,0.17))
    _marker(p+Vector3(0,12,0),Color(0.84,0.48,0.27))

func _camp() -> void:
    box(self,Vector3(7,_height(7,17)+0.65,17),Vector3(4,1.3,3),Color(0.34,0.23,0.15),Vector3.ZERO,true)
    var flame := SphereMesh.new()
    flame.radius = 0.5
    flame.height = 1.0
    mesh_piece(self,flame,Vector3(4,_height(4,18)+0.7,18),Color(1.0,0.35,0.08),Vector3(0.7,1.2,0.7))
    var light := OmniLight3D.new()
    light.position = Vector3(4,_height(4,18)+1.5,18)
    light.light_color = Color(1.0,0.38,0.12)
    light.omni_range = 12
    light.light_energy = 1.5
    add_child(light)

func _marker(p: Vector3, color: Color) -> void:
    var pillar := CylinderMesh.new()
    pillar.top_radius = 0.32
    pillar.bottom_radius = 0.52
    pillar.height = 2.8
    mesh_piece(self,pillar,p+Vector3(0,1.4,0),Color(0.31,0.33,0.33),Vector3.ONE,0.35)
    var crystal := PrismMesh.new()
    crystal.size = Vector3(0.9,1.7,0.9)
    var gem := mesh_piece(self,crystal,p+Vector3(0,3.5,0),color,Vector3.ONE,0.35)
    gem.rotation_degrees = Vector3(0,45,0)
    var light := OmniLight3D.new()
    light.position = p+Vector3(0,3.5,0)
    light.light_color = color
    light.omni_range = 10
    light.light_energy = 1.4
    add_child(light)

func _spawn_machine(p: Vector3) -> void:
    var machine := Node3D.new()
    machine.set_script(MachineScript)
    machine.position = p
    add_child(machine)

func _spawn_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Samurai"
    player.set_script(PlayerScript)
    player.position = Vector3(0,_height(0,26)+0.2,26)
    add_child(player)

func _spawn_guide() -> void:
    var npc := Node3D.new()
    npc.position = Vector3(-6,_height(-6,17),17)
    var body := CapsuleMesh.new()
    body.radius = 0.36
    body.height = 1.55
    mesh_piece(npc,body,Vector3(0,0.85,0),Color(0.70,0.52,0.33))
    var head := SphereMesh.new()
    head.radius = 0.25
    mesh_piece(npc,head,Vector3(0,1.78,0),Color(0.77,0.61,0.45))
    add_child(npc)
    npc.add_to_group("guide")

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(root)
    hud = Label.new()
    hud.position = Vector2(30,24)
    hud.add_theme_font_size_override("font_size",22)
    hud.add_theme_color_override("font_color",Color(0.96,0.88,0.68))
    root.add_child(hud)
    var panel := PanelContainer.new()
    panel.position = Vector2(26,690)
    panel.size = Vector2(1100,92)
    root.add_child(panel)
    message = Label.new()
    message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    message.add_theme_font_size_override("font_size",17)
    panel.add_child(message)
    var controls := Label.new()
    controls.text = "WASD mover  |  Shift correr  |  Espaço pular  |  Mouse câmera  |  J atacar  |  F descobrir  |  E falar"
    controls.position = Vector2(28,850)
    controls.add_theme_font_size_override("font_size",15)
    controls.add_theme_color_override("font_color",Color(0.95,0.91,0.80))
    root.add_child(controls)

func _process(_delta: float) -> void:
    if not is_instance_valid(player):
        return
    hud.text = "CAMINHOS DO VALE   |   MARCOS %d/4\n%s" % [discovered.size(),quest_text]
    if Input.is_action_just_pressed("interact"):
        if player.global_position.distance_to(Vector3(-6,_height(-6,17),17)) < 4.0:
            _show_message("Guia: As máquinas despertaram depois que a luz voltou ao santuário. Procure os quatro marcos.")
        else:
            _show_message("O vento atravessa o vale. Siga as lanternas e os cristais para encontrar os locais antigos.")
    if Input.is_action_just_pressed("explore"):
        _discover_nearest()

func _discover_nearest() -> void:
    var nearest: Dictionary = {}
    var nearest_distance := 99999.0
    for place in landmarks:
        var pos: Vector3 = place.pos
        pos.y = _height(pos.x,pos.z)
        var d := player.global_position.distance_to(pos)
        if d < nearest_distance:
            nearest_distance = d
            nearest = place
    if nearest.is_empty() or nearest_distance > 18.0:
        _show_message("Nenhum marco próximo. Procure os cristais brilhantes no horizonte.")
        return
    var key: String = nearest.id
    if discovered.has(key):
        _show_message(nearest.name + " — " + nearest.hint + " (já descoberto)")
        return
    discovered[key] = true
    _show_message("LOCAL DESCOBERTO — " + nearest.name + ". " + nearest.hint)
    if discovered.size() == 4:
        quest_text = "Todos os marcos foram descobertos. O vale está revelado!"
        _show_message("Você encontrou os quatro marcos. A trilha para o coração da máquina foi revelada.")

func _show_message(line: String) -> void:
    if is_instance_valid(message):
        message.text = line
