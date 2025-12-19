class_name LSPClient
extends Node

signal connection_failed(err: Error)
signal connecting(host: String, port: int)
signal connected
signal response(resp: String)
signal message_sent(msg: String)

var connection := StreamPeerTCP.new()
var message_id := 1
var buffer := PackedByteArray()
var is_connected_to_server := false

func _process(_delta) -> void:
	connection.poll()
	if connection.get_status() in [StreamPeerTCP.STATUS_ERROR, StreamPeerTCP.STATUS_NONE]:
		return
	if connection.get_available_bytes() > 0:
		buffer.append_array(connection.get_data(connection.get_available_bytes()))
		print_rich("[color=webgray]Process buffer (size: %d)...[/color]" % buffer.size())
		_process_buffer()


func _process_buffer() -> void:
	var header_end := -1
	for i in range(buffer.size() - 3):
		if buffer[i] == 13 and buffer[i + 1] == 10 and buffer[i + 2] == 13 and buffer[i + 3] == 10:
			header_end = i
			break

	if header_end == -1:
		return
	var header := buffer.slice(0, header_end).get_string_from_ascii()

	var content_length := 0
	for line in header.split("\r\n", false):
		if line.begins_with("Content-Length:"):
			content_length = int(line.replace("Content-Length:", "").strip_edges())
			break

	if content_length == 0:
		print("[LSPClient] Invalid Content-Length")
		buffer = buffer.slice(header_end + 4, buffer.size())
		return

	if buffer.size() < header_end + 4 + content_length:
		return

	var msg_data := buffer.slice(header_end + 4, header_end + 4 + content_length)
	var msg_text := msg_data.get_string_from_utf8()

	response.emit(msg_text)

	buffer = buffer.slice(header_end + 4 + content_length, buffer.size())


func connect_to_server(host: String, port: int) -> void:
	connected.connect(func(): is_connected_to_server = true)
	print("[LSPClient] Connection requested: " + host + ":" + str(port))
	var err = connection.connect_to_host(host, port)
	if err:
		connection_failed.emit(err)
		print("[LSPClient] Connection failed: " + error_string(err))
	else:
		connecting.emit(host, port)
		var timeout := get_tree().create_timer(10)
		while connection.get_status() == StreamPeerTCP.STATUS_CONNECTING:
			await get_tree().create_timer(0.1).timeout
			if timeout.time_left == 0.0:
				connection_failed.emit(ERR_TIMEOUT)
				print("[LSPClient] Connection timeout")
				return
		connected.emit()
		print("[LSPClient] Connected to host")


func send_initialize(root_uri: String) -> void:
	var msg := {
		"jsonrpc": "2.0",
		"id": message_id,
		"method": "initialize",
		"params": {
			"processId": null,
			"rootUri": "file:///" + root_uri,
			"capabilities": {}
		}
	}
	send_message(msg)
	message_id += 1


func send_did_open(uri: String, language_id: String, text: String) -> void:
	var msg := {
		"jsonrpc": "2.0",
		"method": "textDocument/didOpen",
		"params": {
			"textDocument": {
				"uri": uri,
				"languageId": language_id,
				"version": 1,
				"text": text
			}
		}
	}
	send_message(msg)


func send_message(msg: Dictionary) -> void:
	while not is_connected_to_server:
		await get_tree().create_timer(0.1).timeout
	var json := JSON.stringify(msg)
	var header := "Content-Length: %d\r\n\r\n" % json.to_utf8_buffer().size()
	print("[LSPClient] Send message to server: " + msg["method"])
	var ful_msg := header.to_ascii_buffer() + json.to_utf8_buffer()
	connection.put_data(ful_msg)
	message_sent.emit(header + json)
