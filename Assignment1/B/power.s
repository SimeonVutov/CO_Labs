.data
base: .quad 0               # base variable size(64 bits)
exp:  .quad 0               # exp - exponent variable size(64 bits)

.text                       
basePrompt: .asciz "Enter a non negative base number: "            # base prompt text constant for printf
expPrompt: .asciz "Enter a non negative exponent number: "         # exp prompt text constant for printf 
resultPrompt: .asciz "%ld"                                       # result prompt text constant for printf
format: .asciz "%d"                                                # format string for getting long number from scanf

.global main

main:
                            # PROLOGUE
    pushq %rbp               # push the base pointer
    movq %rsp, %rbp          # copy stack pointer value to base pointer

    movq $0, %rax            # no vector registers in use for printf
    movq $basePrompt, %rdi   # first parameter: basePrompt string
    call printf             # call printf to print the string

    movq $0, %rax            # no vector registers in use for scanf
    movq $format, %rdi       # first parameter: input format string
    movq $base, %rsi         # second parameter: address where to save input from scanf
    call scanf              # call scanf to get the base value

    movq $0, %rax            # no vector registers in use for printf 
    movq $expPrompt, %rdi    # first parameter: expPrompt string
    call printf             # call printf to print the string

    movq $0, %rax            # no vector registers in use for scanf
    movq $format, %rdi       # first parameter: input format string
    movq $exp, %rsi          # second parameter: address where to save input from scanf
    call scanf              # call scanf to get the base value

    movq base, %rdi          # first parameter: base variable value
    movq exp, %rsi           # second parameter: exp variable value
    call pow                # call pow subroutine           

    movq %rax, %r10          # copy result of pow from rax to r11(storing temporary)
    movq $resultPrompt, %rdi # first parameter: input format string
    movq %rax, %rsi          # second parameter: result from the pow subroutine
    movq $0, %rax
    call printf             # call printf to print the result
                            
    movq %r10, %rax          # return result from pow from r11 back to rax
                            # EPILOGUE
    movq %rbp, %rsp          # clear local variables from the stack
    popq %rbp                # restore base pointer location

    movq $0, %rdi            # setting zero status code as first parameter for exit
    call exit               # call exit to stop execution

pow:                        # subroutine for calculating the result of param1 to the power of param2
                            # PROLOGUE
    pushq %rbp               # push the base pointer
    movq %rsp, %rbp          # copy stack pointer value to base pointer

    subq $8, %rsp            # reserve space on the stack for local variable: total(64 bits)
    movq $1, -8(%rbp)           # setting local variable total to 1

    condition:              # checks if exp > 0
        cmpq $0, %rsi        # compare EXP to 0
        jg loop             # jump to loop if greater than 0 
    
    movq -8(%rbp), %rax          # store final value of total to rax
                            # EPILOGUE
    movq %rbp, %rsp          # clear local variables from the stack
    popq %rbp                # restore base pointer location
    
    ret                     # exit pow subroutine

    loop:
                            # total = total * base
        movq -8(%rbp), %rax     # copy the address of local variable total to RAX
        mulq %rdi           # multiply RAX with base value and result is stored again in RAX
        
        movq %rax, -8(%rbp)      # storing the value of total in RSP(location of local variable total)
        subq $1, %rsi        # decrementing exponent after the multiplication
        jmp condition       # jump to condition

