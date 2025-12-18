extends Control

@export var client_masseges: RichTextLabel
@export var server_messages: RichTextLabel

func _ready() -> void:
	var client = LSPClient.new()
	add_child(client)
	client.connected.connect(_append_cm.bind("Connected"))
	client.connecting.connect(_append_cm.bind("Connecting...").unbind(2))
	client.connection_failed.connect(_append_cm.bind("Connection failed!").unbind(1))
	client.message_sent.connect(_append_cm)
	client.response.connect(_append_sm)
	client.response.connect(print)
	client.connected.connect(client.send_initialize.bind(ProjectSettings.globalize_path("res://")))
	client.connect_to_server("127.0.0.1", 6005)


func _append_cm(text: String) -> void:
	client_masseges.text += "\n\nClient: \n" + text


func _append_sm(text: String) -> void:
	server_messages.text += "\n\nServer: \n" + text
