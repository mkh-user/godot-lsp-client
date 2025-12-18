class_name LSPClient
extends Node

signal connection_failed(err: Error)
signal connecting(host: String, port: int)
signal connected
signal response(resp: String)
signal message_sent(msg: String)

var connection := StreamPeerTCP.new()
var message_id := 1

func _process(_delta):
	if connection.get_status() in [StreamPeerTCP.STATUS_ERROR, StreamPeerTCP.STATUS_NONE]:
		return
	connection.poll()
	if connection.get_available_bytes() > 0:
		var resp = connection.get_utf8_string(connection.get_available_bytes())
		print("[LSPClient] Response passed to client")
		var resps := resp.split("Content-Length:", false)
		for r in resps:
			response.emit("Content-Length:" + r)


func connect_to_server(host: String, port: int) -> void:
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
	var json := JSON.stringify(msg)
	var header := "Content-Length: %d\r\n\r\n" % json.to_utf8_buffer().size()
	print("[LSPClient] Send message to server: " + msg["method"])
	#print("Send message to LSP: " + header + json)
	var ful_msg := header.to_ascii_buffer() + json.to_utf8_buffer()
	connection.put_data(ful_msg)
	message_sent.emit(header + json)
