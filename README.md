# Caminhos do Vale — Godot 4.7

Projeto original de aventura em terceira pessoa, com atmosfera cinematográfica inspirada em jogos de exploração de mundo aberto e identidade visual japonesa.

## Abrir no PC
1. No GitHub, use **Code > Download ZIP**.
2. Extraia a pasta.
3. Abra o Godot 4.7, importe `project.godot` e execute com F6/F5.

## Controles
- WASD: mover
- Mouse: câmera em terceira pessoa
- Shift: correr
- Espaço: pular
- J: pulso de energia (habilidade fantástica)
- E: conversar com o guia
- F: descobrir um marco
- Esc: liberar o cursor; botão direito captura novamente

## Estrutura de cenas
- `scenes/main.tscn`: raiz do jogo e organização dos sistemas.
- `scenes/samurai.tscn`: personagem controlável, colisão e câmera.
- `scenes/samurai_visual.tscn`: modelo visual 3D separado, com peças de armadura, tecido, materiais metálicos e detalhes luminosos.
- `scenes/machine_beast.tscn`: criatura mecânica com comportamento de patrulha.
- `scenes/machine_visual.tscn`: modelo visual 3D da criatura, com carcaça, pernas articuladas, sensores e núcleo luminoso.

## Mundo
- Vale com relevo, cadeia de montanhas, floresta e cerejeiras.
- Vila japonesa, torii, santuário, forja, lago e torre.
- Criaturas mecânicas patrulhando diferentes regiões.
- Quatro marcos de exploração, guia e HUD em português.
- Iluminação direcional, céu procedural, névoa e brilho.
- Shader de terreno com variação de grama, musgo e rocha; água com ondulação por shader.

## Estado desta versão
Os modelos do protagonista e da criatura agora são cenas 3D separadas, com malhas e materiais definidos nos próprios arquivos `.tscn`, em vez de serem montados inteiramente pelos scripts de controle. O terreno, vegetação, construções e parte dos efeitos do ambiente ainda são gerados pelo script do mundo.

A direção visual busca um resultado cinematográfico e detalhado, mas esta versão ainda é um protótipo: não equivale à qualidade técnica de um jogo AAA. Não foram importados pacotes externos nesta atualização; os modelos de personagem e criatura são originais e construídos com recursos nativos do Godot.

**Validação pendente:** abrir e executar no Godot 4.7 para conferir importação, renderização, controles e desempenho no PC.
