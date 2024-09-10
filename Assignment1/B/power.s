.data
base: .long 0               # base variable size(32 bits)
exp:  .long 0               # exp - exponent variable size(32 bits)

.text                       
basePrompt: .asciz "Enter a non negative base number: "            # base prompt text constant for printf
expPrompt: .asciz "Enter a non negative exponent number: "         # exp prompt text constant for printf 
resultPrompt: .asciz "The result is: %ld\n"                        # result prompt text constant for printf
format: .asciz "%d"                                                # format string for getting long number from scanf

.global main

main:
                            # PROLOGUE
    push %rbp               # push the base pointer
    mov %rsp, %rbp          # copy stack pointer value to base pointer

    mov $0, %rax            # no vector registers in use for printf
    mov $basePrompt, %rdi   # first parameter: basePrompt string
    call printf             # call printf to print the string

    mov $0, %rax            # no vector registers in use for scanf
    mov $format, %rdi       # first parameter: input format string
    mov $base, %rsi         # second parameter: address where to save input from scanf
    call scanf              # call scanf to get the base value

    mov $0, %rax            # no vector registers in use for printf 
    mov $expPrompt, %rdi    # first parameter: expPrompt string
    call printf             # call printf to print the string

    mov $0, %rax            # no vector registers in use for scanf
    mov $format, %rdi       # first parameter: input format string
    mov $exp, %rsi          # second parameter: address where to save input from scanf
    call scanf              # call scanf to get the base value

    mov base, %edi
    mov exp, %esi
    call pow                # call pow subroutine           

    mov $resultPrompt, %rdi     # first parameter: resultPrompt string
    mov %rax, %rsi              # second paramter: copy the result value after the calculations from rax register
    mov $0, %rax                # no vector registers in use for scanf
    call printf                 # call printf to print the result

                            # EPILOGUE
    mov %rbp, %rsp          # clear local variables from the stack
    pop %rbp                # restore base pointer location

    mov $0, %rdi            # setting zero status code as first parameter for exit
    call exit               # call exit to stop execution

pow:                        # subroutine for calculating the result of param1 to the power of param2
                            # PROLOGUE
    push %rbp               # push the base pointer
    mov %rsp, %rbp          # copy stack pointer value to base pointer

    sub $8, %rsp            # reserve space on the stack for local variable: total(64 bits)
    movq $1, %rsp           # setting local variable total to 1

    condition:              # checks if exp > 0
        cmpl $0, %esi        # compare EXP to 0
        jg loop             # jump to loop if greater than 0 
    
                            # EPILOGUE
    mov %rbp, %rsp          # clear local variables from the stack
    pop %rbp                # restore base pointer location
    
    ret                     # exit pow subroutine

    loop:
                            # total = total * base
        movq %rsp, %rax     # copy the address of local variable total to RAX
        mull %edi           # multiply RAX with base value and result is stored again in RAX
        
        mov %rax, %rsp      # storing the value of total in RSP(location of local variable total)
        subl $1, %esi        # decrementing exponent after the multiplication
        jmp condition       # jump to condition

