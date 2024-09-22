.bss
number: .quad               # number variable size(64 bit)

.text                       
numberPrompt: .asciz "Enter a non negative number: "            # number prompt text constant for printf
resultPrompt: .asciz "%ld\n"                                    # result prompt text constant for printf
format: .asciz "%ld"                                            # format string for getting long number from scanf

.global main

main:
                            # PROLOGUE
    push %rbp               # push the base pointer
    movq %rsp, %rbp         # copy stack pointer value to base pointer

    movq $0, %rax              # no vector registers in use for printf
    movq $numberPrompt, %rdi   # first parameter: basePrompt string
    call printf                # call printf to print the string

    movq $0, %rax            # no vector registers in use for scanf
    movq $format, %rdi       # first parameter: input format string
    movq $number, %rsi       # second parameter: address where to save input from scanf
    call scanf               # call scanf to get the base value
    
    movq number, %rdi           # set first parameter of factorial to number variable's value
    call factorial              # call factorial subroutine           
    movq %rax, %r10             # copy result of factorial execution to r10(for temporary)

    movq $resultPrompt, %rdi     # first parameter: resultPrompt string
    movq %r10, %rsi              # second parameter: the return value of factorial execution
    movq $0, %rax                # no vector registers in use for scanf
    call printf                 # call printf to print the result

    movq %r10, %rax         # copy again the return value of factorial to rax
                            
                            # EPILOGUE
    movq %rbp, %rsp         # clear local variables from the stack
    pop %rbp                # restore base pointer location

    movq $0, %rdi            # setting zero status code as first parameter for exit
    call exit               # call exit to stop execution

factorial:
                            #PROLOGUE
    push %rbp               # push the base pointer
    movq %rsp, %rbp         # copy stack pointer value to base pointer

    baseCasesCheck:         # this is the bottom of the recursion 
        cmpq $2, %rdi       # compare if the rdi to 2
        jl baseCase         # jump to base Case if rdi is less than 2(1 or 0) then we have reached the the bottom of the recursion or
                            # we have 0 as input

    subq $16, %rsp          # reserve 16 bytes on the stack for local variables
    movq %rdi, -8(%rbp)     # use first 8 bytes to store the variable number there

    jg recur                # jump to recursion part if rdi is greater than 1

    baseCase:                # bottom of recursion
        movq $1, %rax        # store 1 in rax for return value of the subroutine
        jmp return           # jump to return section to exit the subroutine
    
    recur:                      # recursion part
        movq -8(%rbp), %rdi     # get number variable value from stack and store it in rdi
        dec %rdi                # decrease rdi value
        call factorial          # call factorial but as first parameter number - 1
                                
                                # part will be executed after we reach bottom of recursion and start
                                # returning from it
        mulq -8(%rbp)           # multiply the variable nuber on the stack with the result of factorial return value in rax 
    
    return:                 # return section which contains EPILOGUE
        movq %rbp, %rsp     # clear local variables from the stack
        pop %rbp            # restore base pointer location
        ret                 # return from factorial subroutine

