# PCAP HTTP File Extraction Lab

https://github.com/jamieduk/extract-file-from-pcap-example

**Example: Extracting a file from a captured PCAP network traffic file using TShark.**

This project demonstrates how to capture HTTP traffic, inspect a PCAP file, extract transferred files and verify that the recovered files match the originals.

<img width="975" height="506" alt="Screenshot From 2026-11-20 21-35-32" src="https://github.com/user-attachments/assets/206cd756-38db-4300-8d96-85d3e73efbaa" />


The example uses a local Python HTTP server and a fictional test file (`case20.txt`) to demonstrate the process.

## Requirements

- Linux
- Python 3
- TShark (Wireshark command-line tools)
- curl

Install the required packages on Ubuntu/Debian:

```bash
sudo apt update
sudo apt install -y tshark python3 curl
```

## Getting Started

Make the scripts executable:

```bash
chmod +x *.sh
```

## Running the Example

Follow these steps in order.

### 1. Start the HTTP Server

```bash
./start-server.sh
```

Creates the fictional test file and starts the local Python HTTP server.

The server listens on:

```text
http://127.0.0.1:8870/
```

### 2. Capture HTTP Traffic

```bash
./capture.sh
```

Captures HTTP network traffic on the local loopback interface.

Generates:

```text
evidence.pcapng
```

The script automatically requests the test file so that HTTP traffic is recorded in the capture.

### 3. Read and Extract Captured Traffic

```bash
./read.sh
```

Reads the captured PCAP file and displays HTTP requests and response status codes.

It also extracts HTTP objects from the capture into the `export/` directory.

The extraction uses:

```bash
tshark -r evidence.pcapng -d tcp.port==8870,http --export-objects http,export -q
```

### 4. Stop the HTTP Server

```bash
./stop-server.sh
```

Stops the local HTTP server and removes its PID file.

## File Verification

The `read.sh` script automatically compares the original test file against the extracted copy.

It uses SHA-256 checksums:

```bash
sha256sum www/case20.txt export/case20.txt
```

And binary file comparison:

```bash
cmp www/case20.txt export/case20.txt
```

If the SHA-256 hashes match and `cmp` produces no output, the extracted file is byte-for-byte identical to the original.

## Project Structure

```text
PCAP-HTTP-Extraction/
├── start-server.sh
├── capture.sh
├── read.sh
├── stop-server.sh
├── server.log              (generated)
├── server.pid              (generated)
├── evidence.pcapng         (generated)
├── www/
│   └── case20.txt          (generated)
└── export/
    └── case20.txt          (extracted)
```

### Script Overview

| File | Description |
|---|---|
| `start-server.sh` | Creates the test file and starts the HTTP server |
| `capture.sh` | Captures HTTP traffic and generates the PCAP file |
| `read.sh` | Reads the capture, extracts HTTP objects and verifies files |
| `stop-server.sh` | Stops the HTTP server and removes its PID file |

## Important Notes

- The HTTP server is bound to `127.0.0.1`, so it is only accessible locally.
- The capture uses the loopback network interface (`lo`).
- The example uses HTTP rather than HTTPS so that the transferred objects can be inspected and extracted directly.
- The test file contains fictional data and is intended for demonstration purposes.
- Capturing packets may require appropriate permissions to access the network interface.

**This is a demonstration of extracting transferred files from captured HTTP network traffic using TShark.**

## Reference

Video reference:

https://www.youtube.com/watch?v=9VZb7AEin-8

---

**PCAP HTTP File Extraction Lab**

**(c) J~Net 2026**
