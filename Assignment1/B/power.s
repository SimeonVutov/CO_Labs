.bss
base: .skip 8               # base variable size(64 bits)
exp:  .skip 8               # exp - exponent variable size(64 bits)

.text                       
basePrompt: .asciz "Enter a non negative base number: "            # base prompt text constant for printf
expPrompt: .asciz "Enter a non negative exponent number: "         # exp prompt text constant for printf 
resultPrompt: .asciz "%ld"                                         # result prompt text constant for printf
format: .asciz "%ld"                                               # format string for getting long number from scanf

.global main

main:
                             # PROLOGUE
    pushq %rbp               # push the base pointer
    movq %rsp, %rbp          # copy stack pointer value to base pointer

    movq $0, %rax            # no vector registers in use for printf
    movq $basePrompt, %rdi   # first parameter: basePrompt string
    call printf              # call printf to print the string

    movq $0, %rax            # no vector registers in use for scanf
    movq $format, %rdi       # first parameter: input format string
    movq $base, %rsi         # second parameter: address where to save input from scanf
    call scanf               # call scanf to get the base value

    movq $0, %rax            # no vector registers in use for printf 
    movq $expPrompt, %rdi    # first parameter: expPrompt string
    call printf              # call printf to print the string

    movq $0, %rax            # no vector registers in use for scanf
    movq $format, %rdi       # first parameter: input format string
    movq $exp, %rsi          # second parameter: address where to save input from scanf
    call scanf               # call scanf to get the base value

    movq base, %rdi          # first parameter: base variable value
    movq exp, %rsi           # second parameter: exp variable value
    call pow                 # call pow subroutine           

    movq $resultPrompt, %rdi # first parameter: input format string
    movq %rax, %rsi          # second parameter: result from the pow subroutine
    movq $0, %rax            # no vector registers in use for scanf   
    call printf              # call printf to print the result
                            
                             # EPILOGUE
    movq %rbp, %rsp          # clear local variables from the stack
    popq %rbp                # restore base pointer location

    movq $0, %rdi            # setting zero status code as first parameter for exit
    call exit                # call exit to stop execution

pow:                         # subroutine for calculating the result of param1 to the power of param2
                             # PROLOGUE
    pushq %rbp               # push the base pointer
    movq %rsp, %rbp          # copy stack pointer value to base pointer
    movq $1, %rax

    condition:              # checks if exp > 0
        cmpq $0, %rsi       # compare EXP to 0
        jg loop             # jump to loop if greater than 0 

                              # EPILOGUE
    movq %rbp, %rsp           # clear local variables from the stack
    popq %rbp                # restore base pointer location
    
    ret                     # exit pow subroutine

    loop:
                                # total = total * base
        mulq %rdi               # multiply RAX with base value and result is stored again in RAX
        
        subq $1, %rsi           # decrementing exponent after the multiplication
        jmp condition           # jump to condition

