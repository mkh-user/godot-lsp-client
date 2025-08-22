class_name LSPClient
extends Node

signal connection_failed(err: Error)
signal connecting(host: String, port: int)
signal connected
signal response(response: String)

var connection := StreamPeerTCP.new()
var message_id := 1

func _process(_delta):
	connection.poll()
	if connection.get_available_bytes() > 0:
		var resp = connection.get_utf8_string(connection.get_available_bytes())
		response.emit(resp)


func connect_to_server(host: String, port: int) -> void:
	var err = connection.connect_to_host(host, port)
	if err:
		connection_failed.emit(err)
	else:
		connecting.emit(host, port)
		while connection.get_status() == StreamPeerTCP.STATUS_CONNECTING:
			await get_tree().create_timer(0.1).timeout
		connected.emit()


func send_initialize() -> void:
	var msg := {
		"jsonrpc": "2.0",
		"id": message_id,
		"method": "initialize",
		"params": {
			"processId": null,
			"rootUri": "file:///" + OS.get_cache_dir().uri_encode(),
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
	#print("Send message to LSP: " + header + json)
	var ful_msg := header.to_ascii_buffer() + json.to_utf8_buffer()
	connection.put_data(ful_msg)
