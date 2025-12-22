# Godot LSP Client
LSP client written in GDScript

---

This repo is a **work in progress** LSP client written in pure GDScript. Supports JSONRPC 2.0 and TCP connection (`stdio` is not supported for now). Current implementation connects to Godot's LSP server in localhost and sends `initialize` message.

> [!Note]
> This repository is a development platform for text-forge/text-forge#88.

> [!Caution]
> Currently is experimental, a lot of features are missing and some features may not work correctly. Please use with caution. Contributions welcome.

---

## Known Issues
- Doesn't support `stdio`:  
  This client doesn't support `stdio` for now because of limited features of Godot's process API. (Breaking changes from 3.x to 4.x)
- Can't get very large responses:  
  Work in progress: [tree/safe-buffer](https://github.com/mkh-user/godot-lsp-client/tree/safe-buffer)  
  When connected to `pylsp` (with `stdio` to `TCP` wrapper) failed to receive complete initialize response (very large message).
