extends Control

func _ready() -> void:
	var client = LSPClient.new()
	add_child(client)
	client.connecting.connect(print)
	client.connected.connect(client.send_initialize)
	client.response.connect(print)
	client.connect_to_server("127.0.0.1", 6005)
