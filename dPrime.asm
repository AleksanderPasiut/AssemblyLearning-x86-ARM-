format PE64 console
entry start

include '..\..\include\win64ax.inc'

section '.text' code executable
start:
        ; Introduction text
        mov     rcx,welcome
        call    [printf]

        ; rbx - (N-1)
        ; rsi - array for sieve of Eratosthenes
        ; r12 - prime numbers' amount
        ; rdi - array for differences' counting
        ; r13 - differences' amount
        ; r14 - output file

        ; Enter range (N)
enter_range:
        mov     rcx,txt_range_end
        call    [printf]

        mov     rcx,format_lu
        mov     rdx,N
        call    [scanf]
        call    [getchar]
        mov     rbx,[N]

        cmp     rbx,2     ; Require range reenter if value is not above 2
        jna     enter_range

        dec     rbx     ; The range is [2;N]

        mov     rax,0x1fffffffffffffff ; and if value is bigger than (2^64-1) / 8
        cmp     rbx,rax
        ja      enter_range

        ; Enter output file name
        mov     rcx,txt_output_file_name
        call    [printf]

        mov     rcx,format_32s
        mov     rdx,output_file_name
        call    [scanf]
        call    [getchar]

        ; Array allocation
        mov     rcx,[N]
        shl     rcx,3
        call    [malloc]
        cmp     rax,0
        je      alloc_failed
        mov     rsi,rax

        ; Init values in array
        mov     rax,[N]
loop_init:
        mov     [rsi+rax*8-16],rax
        dec     rax
        cmp     rax,2
        jnb     loop_init

        ; Essential algorithm loops
        xor     r12,r12
        xor     rcx,rcx
loop1:
        mov     rdx,rcx
loop2:
        add     rdx,[rsi+rcx*8]
        cmp     rdx,rbx
        ja      loop2end
        mov     qword [rsi+rdx*8],0
        jmp     loop2
loop2end:

        mov     rax,[rsi+rcx*8]
        mov     [rsi+r12*8],rax
        inc     r12
loop3:
        inc     rcx
        cmp     rcx,rbx
        ja      loops_end
        cmp     qword [rsi+rcx*8],0
        je      loop3
        jmp     loop1
loops_end:

        ; Conversion from primes to differences ...
        ; ... and finding the biggest difference
        xor     r13,r13
        mov     rcx,r12
loop4:
        mov     rax,[rsi+rcx*8-16]
        sub     [rsi+rcx*8-8],rax

        cmp     [rsi+rcx*8-8],r13
        cmova   r13,[rsi+rcx*8-8]

        dec     rcx
        cmp     rcx,3
        jnb     loop4

        ; Allocate output array
        mov     rcx,r13
        shl     rcx,2
        shr     r13,1
        call    [malloc]
        cmp     rax,0
        je      alloc_failed_2
        mov     rdi,rax

        ; Init output array
        mov     rcx,r13
loop5:
        mov     qword [rdi+rcx*8-8],0
        dec     rcx
        cmp     rcx,0
        ja      loop5

        ; Count specified values
        mov     rcx,r12
loop6:
        mov     rax,[rsi+rcx*8-8]
        shr     rax,1
        inc     qword [rdi+rax*8-8]
        dec     rcx
        cmp     rcx,2
        ja      loop6

        ; Deallocate first array
        mov     rcx,rsi
        call    [free]

        ; Output file creation
        mov     rcx,output_file_name
        mov     rdx,format_wb
        call    [fopen]
        cmp     rax,0
        je      file_creation_failed
        mov     r14,rax

        ; Writing data to output file
        mov     rcx,rdi
        mov     rdx,8
        mov     r8,r13
        mov     r9,r14
        call    [fwrite]

        ; Closing output file
        mov     rcx,r14
        call    [fclose]

        ; Array deallocation
        mov     rcx,rdi
        call    [free]

finish:
        xor     rcx,rcx
        call    [ExitProcess]

alloc_failed_2:
        mov     rcx,rsi
        call    [free]
alloc_failed:
        mov     rcx,txt_allocation_failed
        call    [printf]
        call    [getchar]
        jmp     finish

file_creation_failed:
        mov     rcx,txt_file_creation_failed
        call    [printf]
        call    [getchar]

        mov     rcx,rsi
        call    [free]
        jmp     finish

section '.rdata' data readable writeable
        welcome db 'dPrime by Aleksander Pasiut', 10, 10, 0
        txt_range_end db 'Enter range end (N): ', 0
        txt_output_file_name db 'Enter output file name (max. 32 characters): ', 0
        txt_primes_amount db 'Primes amount: %lu', 10, 0
        txt_allocation_failed db 'Failed allocation error.', 10, 0
        txt_file_creation_failed db 'Failed file creation error.', 10, 0
        format_lu db '%lu', 0
        format_lun db '%lu', 10, 0
        format_32s db '%32s', 0
        format_wb db 'wb', 0
        N dq 0
        output_file_name: TIMES 33 db 0

section '.idata' data readable import
        library kernel32, 'kernel32.dll', \
                msvcrt,   'msvcrt.dll'

        import kernel32,\
               ExitProcess, 'ExitProcess'

        import msvcrt,\
               printf, 'printf',\
               scanf, 'scanf',\
               getchar, 'getchar',\
               malloc, 'malloc',\
               free, 'free',\
               fopen,'fopen',\
               fwrite,'fwrite',\
               fclose,'fclose'
