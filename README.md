# README: Assembly Web Server Implementation

## Overview
This program is an HTTP server written in x86-64 assembly. It listens for incoming connections, handles both `GET` and `POST` HTTP requests, and serves requested files over a TCP connection. The server uses Linux system calls directly and supports concurrent client handling via `fork()`.

## Features
1. **Handles HTTP GET Requests**: Serves files requested by clients.
2. **Handles HTTP POST Requests**: Extracts and processes the content submitted by clients.
3. **Concurrent Client Support**: Forks a child process for each incoming client connection.
4. **Error Handling**: Manages invalid file paths and unexpected requests.

## Program Flow
The following is a detailed walkthrough of the program logic:

### 1. **Socket Creation**
- The server starts by creating a socket using `socket()` with:
  - `AF_INET`: IPv4
  - `SOCK_STREAM`: TCP
  - `IPPROTO_IP`: Default protocol (TCP).
- The socket file descriptor is stored in `r13`.

### 2. **Binding to Address**
- The server binds the socket to the address `0.0.0.0` (accepts connections from any interface) and port `80` using `bind()`.
- A pre-defined structure `big_one` is used to specify the family (`AF_INET`), port (`0x5000` for port 80 in big-endian), and address.

### 3. **Listening for Connections**
- The server sets the socket to listen mode using `listen()`, enabling it to accept incoming connections.

### 4. **Accepting Connections**
- In a loop:
  - The server waits for a client to connect using `accept()`.
  - If a client connects, the socket file descriptor for the client is stored in `r12`.

### 5. **Forking for Concurrent Handling**
- The server forks a new process using `fork()`:
  - **Parent Process**:
    - Closes the client connection socket (`r12`) and continues to wait for new connections.
  - **Child Process**:
    - Handles the current client's request.

### 6. **Handling HTTP Requests**
#### **General Steps in the Child Process**:
- **Close the server's listening socket**: The child process does not need it.
- **Read the Request**:
  - Reads up to 1024 bytes from the client socket into the `buffer`.
  - Determines whether the request is `GET` or `POST` based on the first character in the request:
    - `G` (ASCII 0x47): `GET` request.
    - `P` (ASCII 0x50): `POST` request.

#### **GET Request Flow**:
1. **Extract File Path**:
   - Locates the requested file path in the HTTP request (delimited by `/` and a space).
   - Null-terminates the extracted path.
2. **Open and Read File**:
   - Opens the file using `open()`.
   - Reads the file contents into `r_buf` using `read()`.
3. **Send Response**:
   - Writes the HTTP response header (`HTTP/1.0 200 OK`) to the client.
   - Writes the file contents from `r_buf` to the client.
4. **Clean Up**:
   - Closes the file descriptor.
   - Exits the child process.

#### **POST Request Flow**:
1. **Extract Content**:
   - Identifies the start of the content in the request body by locating the last newline (`\n`).
   - Determines the content length and extracts the data from `buffer`.
2. **Save or Process Content**:
   - This example doesn't process POST data further but sets up the logic for handling it.
3. **Respond**:
   - Writes the HTTP response header (`HTTP/1.0 200 OK`) to the client.

### 7. **Closing Connections**
- Both parent and child processes close their respective client file descriptors once done.

### 8. **Restarting Accept Loop**
- The parent process resumes listening for new client connections.

---

## System Calls Used
- `socket()`: Creates a TCP socket.
- `bind()`: Binds the socket to an IP address and port.
- `listen()`: Prepares the socket to accept connections.
- `accept()`: Accepts an incoming client connection.
- `fork()`: Creates a new process for concurrent client handling.
- `read()`: Reads data from a socket or file.
- `write()`: Sends data to a socket.
- `open()`: Opens a file.
- `close()`: Closes a file descriptor.
- `exit()`: Exits a process.

---

This code illustrates the basics of server implementation while showcasing practical assembly skills, network programming, and system-level resource management.
