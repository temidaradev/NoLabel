extends Node3D

@onready var main_menu: PanelContainer = $CanvasLayer/MainMenu
@onready var address_entry: LineEdit = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry
@onready var hud: Control = $CanvasLayer/HUD
@onready var health_bar: ProgressBar = $CanvasLayer/HUD/Health

const Player = preload("res://main/player.tscn")
const PORT = 9999
var enet_peers =  ENetMultiplayerPeer.new()

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("esc"):
		get_tree().quit()

func _on_host_button_pressed() -> void:
	main_menu.hide()
	hud.show()
	
	enet_peers.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peers 
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.disconnect(remove_player)
	
	add_player(multiplayer.get_unique_id())
	#upnp_setup()

func _on_join_button_pressed() -> void:
	main_menu.hide()
	hud.show()
	
	enet_peers.create_client("localhost", PORT)
	
	multiplayer.multiplayer_peer = enet_peers

func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health)

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if not player:
		player.queue_free()

func update_health(health_value):
	health_bar.value = health_value
	
func _on_multiplayer_spawner_spawned(node: Node) -> void:
	if node.is_multiplayer_authority():
		node.health_changed.connect(update_health)

func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed!! Error %s" % discover_result)

	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway!!")
	
	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port MApping Failed!! Error %s" & map_result)
		
	print("Success! Join Adress %s" % upnp.query_external_address())
