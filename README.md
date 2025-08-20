# Challenge Tcp Server

![Erlang](https://img.shields.io/badge/Language-Erlang-4B0082)

A minimal Erlang TCP server implementing a **challenge-response protocol**.  
Clients can submit multi-line data, receive a cryptographic challenge, and respond with a hash to validate their submission. Upon success, the server returns a unique ID.

---

## Features

- Accepts `POST` submissions over TCP.
- Generates a **random challenge** for each session.
- Verifies submissions using **SHA-256 hashing**.
- Returns a unique ID upon successful verification.
- Supports `GET` requests for retrieving submitted data (feature in progress).
- Minimal dependencies—just Erlang/OTP.

---

## Protocol Overview

The server uses a simple TCP protocol:

1. **POST** multiple lines of data.
2. Send `SUBMIT` to indicate end of post.
3. Server responds with `CHALLENGE <challenge>` (random 32-byte hex).
4. Client sends `ACCEPTED <hash>` — a SHA-256 hash of `[lines, challenge, "\r\n", suffix]`.
5. On success, server returns a unique ID.

Example session:
```
Client: POST
Client: Hello world
Client: Another line
Client: SUBMIT
Server: CHALLENGE 0123abcd...
Client: ACCEPTED <hash>
Server: <unique_id>
```
Invalid commands or failed challenges terminate the session.

---

## Installation

Clone the repository:

```bash
git clone https://github.com/Gappylul/challenge-tcp-server.git
cd challenge-tcp-server
```

Compile in Erlang shell:
```erlang
c(main).
```

Start the server:
```erlang
main:start().
```

The server listens on TCP port 8888 by default.

Example Usage

```bash
telnet localhost 8888
```
