extends Node
class_name SoundManager

static var instance: SoundManager

var players_pool: Array[AudioStreamPlayer] = []
var max_players: int = 12

func _ready() -> void:
	instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(max_players):
		var p := AudioStreamPlayer.new()
		add_child(p)
		players_pool.append(p)

func _get_free_player() -> AudioStreamPlayer:
	for p in players_pool:
		if not p.playing:
			return p
	return players_pool[0]

# 1. Som de Disparo de Canhão (Thud grave + ruído de pressão)
func play_cannon_shot() -> void:
	var stream := _generate_noise_shot(0.35, 90.0, 0.7)
	_play_stream(stream, -2.0)

# 2. Som de Explosão (Rumble de baixa frequência com caimento)
func play_explosion() -> void:
	var stream := _generate_noise_shot(0.65, 55.0, 1.0)
	_play_stream(stream, 0.0)

# 3. Bipe tático de rádio (Confirmação de seleção / ordem estilo walkie-talkie)
func play_radio_ack() -> void:
	var stream := _generate_radio_chirp()
	_play_stream(stream, -8.0)

# 4. Som de Construção / Maquinário completo
func play_construction_complete() -> void:
	var stream := _generate_construction_fanfare()
	_play_stream(stream, -6.0)

# 5. Rasante de Caça a Jato / Ataque Aéreo (Whoosh de turbina a jato)
func play_jet_flyby() -> void:
	var stream := _generate_jet_sound(2.0)
	_play_stream(stream, -1.0)

func _play_stream(stream: AudioStreamWAV, volume_db: float = 0.0) -> void:
	if not stream:
		return
	var p := _get_free_player()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = randf_range(0.95, 1.05)
	p.play()

# --- Geradores Procedurais de Áudio PCM (16-bit Mono, 22050 Hz) ---

func _generate_noise_shot(duration: float, freq: float, punch: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var total_frames := int(sample_rate * duration)
	var buffer := PackedByteArray()
	buffer.resize(total_frames * 2) # 16-bit = 2 bytes por sample
	
	for i in range(total_frames):
		var t := float(i) / float(sample_rate)
		var env := exp(-t * 12.0) # Envelope de decaimento rápido
		var sine_val := sin(2.0 * PI * (freq * (1.0 - t * 2.0)) * t)
		var noise_val := randf_range(-1.0, 1.0)
		var sample := (sine_val * 0.6 + noise_val * 0.4 * punch) * env
		sample = clampf(sample, -1.0, 1.0)
		var val_16 := int(sample * 32767.0)
		buffer.encode_s16(i * 2, val_16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = buffer
	return wav

func _generate_radio_chirp() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.12
	var total_frames := int(sample_rate * duration)
	var buffer := PackedByteArray()
	buffer.resize(total_frames * 2)
	
	for i in range(total_frames):
		var t := float(i) / float(sample_rate)
		var freq := 880.0 if t < 0.06 else 1320.0 # Bip duplo tático
		var env := sin((t / duration) * PI)
		var sample := sin(2.0 * PI * freq * t) * env * 0.5
		var val_16 := int(clampf(sample, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, val_16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = buffer
	return wav

func _generate_construction_fanfare() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.25
	var total_frames := int(sample_rate * duration)
	var buffer := PackedByteArray()
	buffer.resize(total_frames * 2)
	
	for i in range(total_frames):
		var t := float(i) / float(sample_rate)
		var env := exp(-t * 6.0)
		var freq := 523.25 if t < 0.12 else 659.25
		var sample := sin(2.0 * PI * freq * t) * env * 0.5
		var val_16 := int(clampf(sample, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, val_16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = buffer
	return wav

func _generate_jet_sound(duration: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var total_frames := int(sample_rate * duration)
	var buffer := PackedByteArray()
	buffer.resize(total_frames * 2)
	
	for i in range(total_frames):
		var t := float(i) / float(sample_rate)
		# Efeito doppler e aumento de volume da turbina
		var progress := t / duration
		var env := sin(progress * PI)
		var noise := randf_range(-1.0, 1.0) * 0.7
		var low_hum := sin(2.0 * PI * (120.0 + progress * 80.0) * t) * 0.3
		var sample := (noise + low_hum) * env
		var val_16 := int(clampf(sample, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, val_16)
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = buffer
	return wav
