.bss
number: .quad               # number variable size(32 bits)

.text                       
numberPrompt: .asciz "Enter a non negative number: "            # number prompt text constant for printf
resultPrompt: .asciz "%ld\n"                                    # result prompt text constant for printf
format: .asciz "%ld"                                            # format string for getting long number from scanf

.global main

main:
                            # PROLOGUE
    push %rbp               # push the base pointer
    mov %rsp, %rbp          # copy stack pointer value to base pointer

    mov $0, %rax            # no vector registers in use for printf
    mov $numberPrompt, %rdi   # first parameter: basePrompt string
    call printf             # call printf to print the string

    mov $0, %rax            # no vector registers in use for scanf
    mov $format, %rdi       # first parameter: input format string
    mov $number, %rsi         # second parameter: address where to save input from scanf
    call scanf              # call scanf to get the base value
    
    mov $number, %rdi
    call factorial                # call factorial subroutine           
    mov %rax, %r10

    mov $resultPrompt, %rdi     # first parameter: resultPrompt string
    mov %r10, %rsi              # second paramter: copy the result value after the calculations from rax register
    mov $0, %rax                # no vector registers in use for scanf
    call printf                 # call printf to print the result

    mov %r10, %rax
                            # EPILOGUE
    mov %rbp, %rsp          # clear local variables from the stack
    pop %rbp                # restore base pointer location

    mov $0, %rdi            # setting zero status code as first parameter for exit
    call exit               # call exit to stop execution

factorial:
    push %rbp
    mov %rsp, %rbp

    subq $8, %rsp
    movq %rdi, %rsp

    condition:
        cmpq $1, %rdi
        jne recur
        mov $1, %rax
        jmp return

    

    recur:
        mov %rsp, %rdi
        dec %rdi
        call factorial
        # return n * factorial(n-1
    return:
        mulq %rsp
        
        mov %rbp, %rsp
        pop %rbp
        ret