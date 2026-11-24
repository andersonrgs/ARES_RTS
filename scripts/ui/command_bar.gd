extends PanelContainer
class_name CommandBar

const PowerPlantScene = preload("res://scenes/buildings/power_plant.tscn")
const WarFactoryScene = preload("res://scenes/buildings/war_factory.tscn")
const SupplyCenterScene = preload("res://scenes/buildings/supply_center.tscn")
const TankCrusaderScene = preload("res://scenes/units/tank_crusader.tscn")
const JeepHumveeScene = preload("res://scenes/units/jeep_humvee.tscn")
const SoldierRangerScene = preload("res://scenes/units/soldier_ranger.tscn")

const GameEconomy = preload("res://scripts/systems/game_economy.gd")
const BuildingPlacementManager = preload("res://scripts/systems/building_placement_manager.gd")
const BuildingBase = preload("res://scripts/buildings/building_base.gd")
const SelectionManager = preload("res://scripts/core/selection_manager.gd")
const GeneralsPowers = preload("res://scripts/systems/generals_powers.gd")

@export var economy: GameEconomy
@export var placement_mgr: BuildingPlacementManager
@export var selection_mgr: SelectionManager
@export var powers_mgr: GeneralsPowers

@onready var credits_label: Label = $Margin/HBox/RightCol/StatsRow/CreditsLabel
@onready var power_label: Label = $Margin/HBox/RightCol/StatsRow/PowerLabel
@onready var btn_power_plant: Button = $Margin/HBox/RightCol/BuildButtons/BtnPowerPlant
@onready var btn_war_factory: Button = $Margin/HBox/RightCol/BuildButtons/BtnWarFactory
@onready var btn_supply_center: Button = $Margin/HBox/RightCol/BuildButtons/BtnSupplyCenter
@onready var selection_info_label: Label = $Margin/HBox/CenterCol/SelectionInfo

@onready var unit_production_row: HBoxContainer = $Margin/HBox/CenterCol/UnitProductionRow
@onready var btn_build_tank: Button = $Margin/HBox/CenterCol/UnitProductionRow/BtnBuildTank
@onready var btn_build_humvee: Button = $Margin/HBox/CenterCol/UnitProductionRow/BtnBuildHumvee
@onready var btn_build_ranger: Button = $Margin/HBox/CenterCol/UnitProductionRow/BtnBuildRanger

@onready var btn_satellite: Button = $Margin/HBox/CenterCol/PowersRow/BtnSatellite
@onready var btn_airstrike: Button = $Margin/HBox/CenterCol/PowersRow/BtnAirstrike

var selected_factory: BuildingBase = null

func _ready() -> void:
	if not economy:
		economy = get_tree().root.find_child("GameEconomy", true, false)
	if not placement_mgr:
		placement_mgr = get_tree().root.find_child("BuildingPlacementManager", true, false)
	if not selection_mgr:
		selection_mgr = get_tree().root.find_child("SelectionManager", true, false)
	if not powers_mgr:
		powers_mgr = get_tree().root.find_child("GeneralsPowers", true, false)

	if economy:
		economy.credits_changed.connect(_on_credits_changed)
		economy.power_changed.connect(_on_power_changed)
		_on_credits_changed(economy.credits)
		_on_power_changed(economy.power_produced, economy.power_consumed)
		
	if powers_mgr:
		powers_mgr.powers_cooldown_updated.connect(_on_powers_cooldown_updated)
		
	btn_power_plant.pressed.connect(_on_build_power_plant_pressed)
	btn_war_factory.pressed.connect(_on_build_war_factory_pressed)
	btn_supply_center.pressed.connect(_on_build_supply_center_pressed)
	
	btn_build_tank.pressed.connect(_on_build_tank_pressed)
	btn_build_humvee.pressed.connect(_on_build_humvee_pressed)
	btn_build_ranger.pressed.connect(_on_build_ranger_pressed)
	unit_production_row.visible = false
	
	btn_satellite.pressed.connect(func(): if powers_mgr: powers_mgr.trigger_satellite_scan_targeting())
	btn_airstrike.pressed.connect(func(): if powers_mgr: powers_mgr.trigger_airstrike_targeting())

func _process(_delta: float) -> void:
	_update_selection_display()

func _on_credits_changed(new_credits: int) -> void:
	if credits_label:
		credits_label.text = "$ " + str(new_credits)

func _on_power_changed(produced: int, consumed: int) -> void:
	if power_label:
		var status := "Estavel" if produced >= consumed else "BAIXA ENERGIA!"
		power_label.text = "Energia: %d / %d MW (%s)" % [produced, consumed, status]
		if produced >= consumed:
			power_label.modulate = Color(0.2, 0.9, 0.3)
		else:
			power_label.modulate = Color(1.0, 0.2, 0.2)

func _on_powers_cooldown_updated(scan_cd: float, strike_cd: float) -> void:
	if btn_satellite:
		if scan_cd > 0.0:
			btn_satellite.text = "Satélite (%.0fs)" % scan_cd
			btn_satellite.disabled = true
		else:
			btn_satellite.text = "🛰️ Satélite (Pronto)"
			btn_satellite.disabled = false
			
	if btn_airstrike:
		if strike_cd > 0.0:
			btn_airstrike.text = "Ataque Aéreo (%.0fs)" % strike_cd
			btn_airstrike.disabled = true
		else:
			btn_airstrike.text = "✈️ Ataque Aéreo (Pronto)"
			btn_airstrike.disabled = false

func _on_build_power_plant_pressed() -> void:
	if placement_mgr:
		placement_mgr.start_placement(PowerPlantScene, 800, Vector3(5, 3.5, 5))

func _on_build_war_factory_pressed() -> void:
	if placement_mgr:
		placement_mgr.start_placement(WarFactoryScene, 2000, Vector3(8, 4, 7))

func _on_build_supply_center_pressed() -> void:
	if placement_mgr:
		placement_mgr.start_placement(SupplyCenterScene, 1500, Vector3(7, 3.5, 6))

func _on_build_tank_pressed() -> void:
	if selected_factory and economy and economy.spend_credits(700):
		selected_factory.spawn_unit(TankCrusaderScene)

func _on_build_humvee_pressed() -> void:
	if selected_factory and economy and economy.spend_credits(500):
		selected_factory.spawn_unit(JeepHumveeScene)

func _on_build_ranger_pressed() -> void:
	if selected_factory and economy and economy.spend_credits(150):
		selected_factory.spawn_unit(SoldierRangerScene)

func _update_selection_display() -> void:
	if not selection_mgr:
		return
		
	var sel = selection_mgr.selected_units
	if not sel.is_empty():
		var first = sel[0]
		if is_instance_valid(first):
			selection_info_label.text = "%s (%d sel.) | HP: %.0f/%.0f" % [first.unit_name, sel.size(), first.current_health, first.max_health]
			unit_production_row.visible = false
			selected_factory = null
			return

	var clicked_building = _get_clicked_building()
	if clicked_building:
		selection_info_label.text = "%s | HP: %.0f/%.0f" % [clicked_building.building_name, clicked_building.current_health, clicked_building.max_health]
		if clicked_building.building_name == "Fabrica Belica":
			selected_factory = clicked_building
			unit_production_row.visible = true
		else:
			selected_factory = null
			unit_production_row.visible = false
		return

	if not selected_factory:
		selection_info_label.text = "A.R.E.S. Comando Geral | Doutrinas Ativas"
		unit_production_row.visible = false

func _get_clicked_building() -> BuildingBase:
	if not selection_mgr or not selection_mgr.camera:
		return null
	var mouse_pos := get_viewport().get_mouse_position()
	if mouse_pos.y > get_viewport_rect().size.y - 140:
		return selected_factory
		
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var from := selection_mgr.camera.project_ray_origin(mouse_pos)
		var to := from + selection_mgr.camera.project_ray_normal(mouse_pos) * 1000.0
		var space_state := selection_mgr.camera.get_world_3d().direct_space_state
		var query := PhysicsRayQueryParameters3D.create(from, to)
		var result := space_state.intersect_ray(query)
		if result and result.collider is BuildingBase:
			return result.collider
	return selected_factory
