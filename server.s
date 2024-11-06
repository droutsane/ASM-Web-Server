.intel_syntax noprefix
.globl _start

.section .bss
buffer:
    .space 1024       # Reserve 1024 bytes for read buffer

r_buf:
    .space 1024

.section .data
response:
    .asciz "HTTP/1.0 200 OK\r\n\r\n"  # HTTP response

.section .text

_start:
    #socket(AF_INET, SOCK_STREAM, IPPROTO_IP) = 3
    mov rax, 41
    mov rdi, 2
    mov rsi, 1
    mov rdx, 0
    syscall
    mov r13, rax
    
    #bind(3, {sa_family=AF_INET, sin_port=htons(<bind_port>), sin_addr=inet_addr("<bind_address>")}, 16) = 0jj
    mov rdi, rax
    mov rax, 49
    mov rsi, OFFSET big_one  #struct
    mov rdx, 16
    syscall

    #listen
    mov rax, 50
    mov rdi, r13
    mov rsi, 0
    syscall

    start_accept:
    #accepts
    mov rax, 43
    mov rdi, r13
    mov rsi, 0
    mov rdx, 0
    syscall
    mov r12, rax
    mov r8, rax

    #fork
    mov rax, 57
    syscall

    cmp rax, 0
    je child
    jmp parent
    
    parent:
    #close the opened file
    mov rax, 3
    mov rdi, r12
    syscall

    jmp start_accept

    child:
    # rax now holds the new client file descriptor
    
    #close the opened file
    mov rax, 3
    mov rdi, r13
    syscall

    # read(client_fd, buffer, 1024) = bytes_read
    mov rdi, r12         # client file descriptor
    mov rsi, OFFSET buffer        # buffer to read into
    mov rdx, 1024          # read 1024 bytes
    mov rax, 0             # syscall number for read
    syscall
    mov r15, rax  #length of read

    #find if we need to do get or post
    mov r13, OFFSET buffer
    mov al, [r13]
    cmp al, 0x47
    je nine_code
    jmp ten_code

    ten_code:
    # Start searching from the end of the buffer (r13 = buffer)
    mov r13, OFFSET buffer     # start of the buffer
    mov rbx, r15               # rbx = length of data read
    dec rbx                    # rbx = index of the last byte in the buffer (r15-1)

    # Loop to find the newline (\n, 0x0A) starting from the end
    start_content_find:
    mov al, [r13 + rbx]    # load the byte at buffer[rbx]
    cmp al, 0x0A           # check if it's a newline
    je content_found       # if found, jump to content_found
    dec rbx   
    mov r12, rbx              # decrement index to move backwards
    cmp rbx, 0             # if rbx becomes 0, stop (no newline found)
    jge start_content_find # continue loop if rbx >= 0
    

    content_found:
    # rbx now holds the index of the newline in the buffer
    # You can calculate the content length as (r15 - rbx - 1)
    # because r15 is the total length and rbx is the index of \n.
    mov rdx, r15           # total bytes read
    sub rdx, rbx           # rdx = content length (total - index of \n)
    dec rdx                # adjust by -1 to get the true content length
    # rdx now holds the content length
    mov r15, rdx
    inc r12
    #extract the file name from buffer
    mov r13, OFFSET buffer
    start_find:
    mov al, [r13]
    cmp al, 0x2f
    je found
    inc r13
    jmp start_find
    found:
    mov r14, r13

    find_end_of_path:
    mov al, [r13]
    cmp al, 0x20
    je end_of_path 
    inc r13
    jmp find_end_of_path

    end_of_path:
    mov BYTE PTR [r13], 0


    #open("<open_path>", O_RDONLY) = 5
    #open the extracted file
    #2	sys_open	const char *filename	int flags	int mode
    mov rax, 2
    mov rdi, r14
    mov rsi, 0x41
    mov rdx, 0x1ff
    syscall
    mov r14, rax


    #write(4, <write_file>, <write_file_count>) = <write_file_result>
    #this is writing the contents of file to screen
    mov rdi, r14     
    mov rsi, OFFSET buffer      # client file descriptor
    add rsi, r12      # HTTP response
    mov rdx, r15          # response length
    mov rax, 1             # syscall number for write
    syscall

    #close(5) = 0
    #close the opened file
    mov rax, 3
    mov rdi, r14
    syscall

    # write
    mov rdi, r8           # client file descriptor
    mov rsi, OFFSET response      # HTTP response
    mov rdx, 19            # response length
    mov rax, 1             # syscall number for write
    syscall

    # SYS_exit
    mov rdi, 0
    mov rax, 60     
    syscall

    jmp end

    nine_code:

    #extract the file name from buffer
    mov r13, OFFSET buffer
    start_fin:
    mov al, [r13]
    cmp al, 0x2f
    je foun
    inc r13
    jmp start_fin
    foun:
    mov r14, r13

    find_end_of_pat:
    mov al, [r13]
    cmp al, 0x20
    je end_of_pat 
    inc r13
    jmp find_end_of_pat

    end_of_pat:
    mov BYTE PTR [r13], 0


    #open("<open_path>", O_RDONLY) = 5
    #open the extracted file
    #2	sys_open	const char *filename	int flags	int mode
    mov rax, 2
    mov rdi, r14
    mov rsi, 0
    syscall
    mov r9, rax

    #read(5, <read_file>, <read_file_count>) = <read_file_result>
    #read the opened file, coz the fd is same
    #0	sys_read	unsigned int fd	char *buf	size_t count
    mov rdi, rax
    mov rax, 0
    mov rsi, OFFSET r_buf
    mov rdx, 1024
    syscall
    mov r13, rax

    #close(5) = 0
    #close the opened file
    mov rax, 3
    mov rdi, r9
    syscall


    # write
    mov rdi, r8           # client file descriptor
    mov rsi, OFFSET response      # HTTP response
    mov rdx, 19            # response length
    mov rax, 1             # syscall number for write
    syscall

    #write(4, <write_file>, <write_file_count>) = <write_file_result>
    #this is writing the contents of file to screen
    mov rdi, r8           # client file descriptor
    mov rsi, OFFSET r_buf      # HTTP response
    mov rdx, r13           # response length
    mov rax, 1             # syscall number for write
    syscall

    # SYS_exit
    mov rdi, 0
    mov rax, 60     
    syscall

    jmp end
    end:
    jmp start_accept


.section .data
big_one:
    .short 2
    .short 0x5000
    .space 4, 0

