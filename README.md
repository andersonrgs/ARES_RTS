# A.R.E.S. (Allied Response & Engagement System)

Um jogo de estratégia em tempo real (RTS) moderno inspirado nas mecânicas clássicas de *Command & Conquer: Generals*, desenvolvido em **Godot Engine 4 (Forward+)**.

![Godot 4](https://img.shields.io/badge/Engine-Godot%204.7-blue.svg)
![Multiplatform](https://img.shields.io/badge/Plataforma-Linux%20%7C%20Windows-brightgreen.svg)
![Status](https://img.shields.io/badge/Status-Protótipo%20Jogável%20v0.6-green.svg)

---

## 🎮 Funcionalidades Implementadas

### 1. Câmera & Controles RTS
- **Câmera Tática:** Pan com WASD/Setas, rotação com Q/E e zoom suave com scroll do mouse.
- **Seleção & Ordens:**
  - Caixa de seleção verde (*Box Selection*).
  - Seleção individual e com Shift.
  - Ordem de movimentação em formação tática com o botão direito.
  - Foco de ataque prioritário ao clicar diretamente sobre unidades inimigas.

### 2. Combate & Balística
- **Torres com Rotação Independente:** Tanques e veículos miram e atiram independentemente da direção de locomoção do chassi.
- **Projéteis Balísticos:** Rastreamento dinâmico, física de projétil, clarão de boca de canhão (*muzzle flash*) e explosões com dispersão de dano.
- **Barras de Vida Flutuantes:** Indicadores em modo Billboard acima de tropas e prédios.

### 3. Facções & Unidades
- **Forças Aliadas (Jogador):**
  - **Crusader Heavy Tank:** Tanque pesado com blindagem reforçada, esteiras, quebra-chamas e antenas.
  - **Humvee .50 Cal:** Veículo de patrulha e reconhecimento de alta velocidade com metralhadora giratória em rajadas de 3 tiros.
  - **Ranger da Infantaria:** Soldados táticos com fuzil de assalto, capacete balístico e animação procedural de marcha.
  - **Caminhão de Suprimentos:** Veículo autônomo de coleta e logística de recursos.
- **Forças Hostis:**
  - **Scorpion Tank:** Tanque veloz inimigo com camuflagem avermelhada e alta cadência de tiro.

### 4. Economia & Construção de Base
- **Sistema de Holograma / Blueprint:** Pré-visualização verde (terreno válido) e vermelho (obstruído) para posicionar edifícios.
- **Gerenciamento de Energia:** Balanço entre geração e consumo elétrico em tempo real.
- **Estruturas:**
  - **Usina Elétrica (+20 MW):** Fornece energia para a base.
  - **Fábrica Bélica:** Linha de produção para tanques, Humvees e recrutamento de Rangers.
  - **Centro de Suprimentos:** Galpão de depósito que financia o exército conforme caminhões entregam caixas de suprimentos.
  - **Doca de Suprimentos (Neutra):** Ponto de extração de recursos no mapa.

### 5. Doutrinas Gerais & Poderes Táticos
- **🛰️ Varredura de Satélite Orbital:** Revela permanentemente qualquer área encoberta pela névoa de guerra.
- **✈️ Ataque Aéreo A-10 Thunderbolt:** Caça a jato que sobrevoa a área em alta velocidade e lança bombas de fragmentação em cadeia.

### 6. Névoa de Guerra (Fog of War)
- Mapa coberto por escuridão inicial (*Shroud*).
- Visão ativa em tempo real revelada pelo raio de visão das tropas e prédios aliados.
- Inimigos ocultos na névoa até serem detectados.

### 7. Radar / Minimapa Interativo
- Exibição de tropas aliadas (verde), inimigos revelados (vermelho) e prédios (azul).
- Clique ou arraste no radar para navegar a câmera pelo campo de batalha.

### 8. Áudio Procedural Militar
- Sistema de som 100% nativo em GDScript (tiros de canhão, explosões, bipes de rádio e turbina a jato), sem necessidade de arquivos externos de áudio.

### 9. Cenografia & Pós-Processamento PBR
- **Iluminação Cinematográfica:** Tonemapping ACES, SSAO (sombras de contato), SSIL, SDFGI e névoa volumétrica atmosférica.
- **Cenário:** Rodovia asfaltada com faixas de tráfego, palmeiras do deserto, arbustos áridos e complexo residencial árabe fortificado.

---

## 💻 Compatibilidade e Como Executar

O projeto foi estruturado em **GDScript puro e shaders universais**, sendo **100% compatível entre Linux e Windows** sem necessidade de conversão.

### 🪟 No Windows:

1. **Baixar o Godot 4:**
   - Baixe o **Godot 4** para Windows (Standard 64-bit) em [godotengine.org/download/windows](https://godotengine.org/download/windows/).
   - O Godot é um executável portátil (`.exe`), dispensando instalação.
2. **Obter o Código:**
   - Clone o repositório ou baixe o arquivo ZIP pelo GitHub:
     ```powershell
     git clone https://github.com/andersonrgs/ARES_RTS.git
     ```
3. **Executar:**
   - **Pela Interface Gráfica:** Abra o Godot, clique no botão **Import** (Importar), selecione o arquivo `project.godot` da pasta do jogo e clique em **Run** (ou pressione `F5`).
   - **Pelo Terminal (PowerShell / CMD):**
     ```powershell
     .\Godot_v4.*_win64.exe scenes/core/main.tscn
     ```

### 🐧 No Linux:

1. **Baixar o Godot 4:**
   - Baixe o binário para Linux (x86_64) pelo site oficial ou utilize o binário portátil.
2. **Obter o Código & Executar:**
   ```bash
   git clone https://github.com/andersonrgs/ARES_RTS.git
   cd ARES_RTS
   godot scenes/core/main.tscn
   ```

---

## ⚙️ Requisitos de Sistema Recomendados
- **GPU:** Placa de vídeo com suporte a **Vulkan 1.2+** (NVIDIA GTX 900+ / AMD RX 400+ / Intel Iris Xe ou gráficos integrados modernos).
- **RAM:** 4 GB de memória RAM.
- **Armazenamento:** Menos de 100 MB (projeto super otimizado e procedural).
