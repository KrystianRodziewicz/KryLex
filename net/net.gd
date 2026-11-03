extends Node
## Autoload [code]Net[/code]: zestawianie połączenia. Właściciel: Krystian.
##
## Krok 1 M0 nie używa sieci, ten plik to szkielet pod krok 2. Zgodnie
## z docs/technika.md tylko tutaj dotykamy ENet, żeby ewentualna zmiana
## transportu (np. GodotSteam) nie ruszała kodu rozgrywki. Host, czyli
## prowadzący gracz, decyduje o wszystkim (opcja A); klient wysyła
## tylko [InputFrame] i prośby.
##
## Uwaga: skrypt autoloadu nie ma [code]class_name[/code], bo nazwa klasy
## nie może pokrywać się z nazwą singletona.

signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)
signal joined_host
signal join_failed
signal host_lost

enum Role { OFFLINE, HOST, CLIENT }

## Podbijać ręcznie przy każdej zmianie RPC. Przy łączeniu sprawdzamy,
## czy oboje mamy tę samą wartość (docs/technika.md: "Rozłączenie i łączenie").
## Do ustalenia: stała czy commit gita (README, sekcja 7).
const PROTOCOL: int = 1
const DEFAULT_PORT: int = 24565
const MAX_CLIENTS: int = 1

var role: Role = Role.OFFLINE


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func start_host(port: int = DEFAULT_PORT) -> Error:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var err: Error = peer.create_server(port, MAX_CLIENTS)
	if err != OK:
		push_error("Net: nie udało się otworzyć hosta na porcie %d (%s)" % [port, error_string(err)])
		return err
	multiplayer.multiplayer_peer = peer
	role = Role.HOST
	print("[Net] host na porcie %d, protokół %d" % [port, PROTOCOL])
	return OK


func join(address: String, port: int = DEFAULT_PORT) -> Error:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var err: Error = peer.create_client(address, port)
	if err != OK:
		push_error("Net: nie udało się połączyć z %s:%d (%s)" % [address, port, error_string(err)])
		return err
	multiplayer.multiplayer_peer = peer
	role = Role.CLIENT
	print("[Net] łączę z %s:%d, protokół %d" % [address, port, PROTOCOL])
	return OK


func leave() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	role = Role.OFFLINE


func is_host() -> bool:
	return role == Role.HOST


func is_online() -> bool:
	return role != Role.OFFLINE


func _on_peer_connected(peer_id: int) -> void:
	print("[Net] dołączył peer %d" % peer_id)
	peer_joined.emit(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	## Rozłączenie to nie śmierć: osobne zdarzenie, nigdy player_death.
	print("[Net] odszedł peer %d" % peer_id)
	peer_left.emit(peer_id)


func _on_connected_to_server() -> void:
	print("[Net] połączono z hostem")
	joined_host.emit()


func _on_connection_failed() -> void:
	push_warning("Net: połączenie nie powiodło się")
	role = Role.OFFLINE
	join_failed.emit()


func _on_server_disconnected() -> void:
	push_warning("Net: host się rozłączył")
	role = Role.OFFLINE
	host_lost.emit()
