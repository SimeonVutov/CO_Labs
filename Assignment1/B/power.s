.data
base: .long 0               # base variable
exp:  .long 0

.text
basePrompt: .asciz "Enter a non negative base number: "
expPrompt: .asciz "Enter a non negative exponent number: "
resultPrompt: .asciz "The result is: %ld\n"
format: .asciz "%d"

.global main

main:
    push %rbp               # prologue
    mov %rsp, %rbp

    mov $0, %rax            #no vector
    mov $basePrompt, %rdi
    call printf

    mov $0, %rax
    mov $format, %rdi
    mov $base, %rsi
    call scanf

    mov $0, %rax
    mov $expPrompt, %rdi
    call printf

    mov $0, %rax
    mov $format, %rdi
    mov $exp, %rsi
    call scanf
    
    call pow

    mov $resultPrompt, %rdi
    mov %rax, %rsi
    mov $0, %rax
    call printf

    mov %rbp, %rsp          # epilogue
    pop %rbp

    mov $0, %rdi
    call exit

pow:
    push %rbp               # prologue
    mov %rsp, %rbp

    sub $8, %rsp            # Reserve space on the stack for local variable: total
    movq $1, %rsp       # Setting local variable total to 1

    condition:
        cmpl $0, exp
        jg loop
    

    mov %rbp, %rsp          # epilogue
    pop %rbp
    
    ret

    loop:
        # total = total * base
        mov %rsp, %rax
        mull base
        mov %rax, %rsp  # Update total to the result of total * %rax
        subl $1, exp
        jmp condition

