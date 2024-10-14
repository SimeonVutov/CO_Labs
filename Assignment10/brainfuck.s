.data
skip_loop: .byte 0              # boolean variable for storing of current loop must be skipped

.bss
memory_cells: .skip 30000       # array of 30 000 bytes for the brainfuck to use as memory

.text
format_str: .asciz "We should be executing the following code:\n%s"

.global brainfuck

# Your brainfuck subroutine will receive one argument:
# a zero termianted string containing the code to execute
# r12 -> address of the code string in memory
# r13 -> instruction pointer in the code string
# r14 -> current memory cell index pointer
# rbx -> store the opened brackets inside a skip loop
brainfuck:
                                        # Prologue
	pushq %rbp                          # Push base pointer to the stack
	movq %rsp, %rbp                     # Set the stack pointer to point to the base pointer
	
    movq %rdi, %r12                     # Copy the address of the brainfuck string to r12
    movq $0, %r13                       # Set the instruction pointer to 0
    movq $0, %r14                       # Set the current memory cell index to 0
    movq $0, %rbx                       # Set opened brackets inside a skip loop to 0
    loop:
        movb (%r12, %r13), %al          # Get current brainfuck char and store it in al

        cmpb $0, %al                    # compare char with 0, brainfuck code is null-terminated
        je end_brainfuck                # if we encounter the null char we end the program
        cmpb $1, skip_loop              # compare if skip_loop boolean is true
        je loop_check                   # if it is true we skip the standart_checks

        standart_checks:
            cmpb $'+', %al              # compare current brainfuck char to "+"
            je increaseMemoryCell       # jump to increaseMemoryCell to increment the current memory cell

            cmpb $'-', %al              # compare current brainfuck char to "-"
            je decreaseMemoryCell       # jump to decreaseMemoryCell to decrement the current memory cell
            
            cmpb $'.', %al              # compare current brainfuck char to "."
            je print                    # jump to print, to print the current memory cell
            
            cmpb $',', %al              # compare current brainfuck char to ","
            je read                     # jump to read, to read input and store it in current memory cell
            
            cmpb $'>', %al              # compare current brainfuck char to ">"
            je moveRightPointer         # jump to moveRightPointer to move the memoryCell pointer to the right
            
            cmpb $'<', %al              # compare current brainfuck char to "<"
            je moveLeftPointer          # jump to moveLeftPointer to move the memoryCell pointer to the left
        
        loop_check:
            cmpb $'[', %al              # compare current brainfuck char to "["
            je handle_start_loop        # jump to handle_start_loop
            cmpb $']', %al              # compare current brainfuck char to "]"
            je handle_end_loop          # jump to handle_end_loop
        next:
            incq %r13                   # increment instruction pointer
            jmp loop                    # restart the loop
        
        increaseMemoryCell:
            leaq memory_cells(,%r14), %rax      # calculate the address of the current memoryCell and copy to rax
            incb (%rax)                         # increment the value located in the address stored in rax
            jmp next                            # jump to next to prepare for restart of loop

        decreaseMemoryCell:
            leaq memory_cells(,%r14), %rax      # calculate the address of the current memoryCell and copy to rax
            decb (%rax)                         # decrement the value located in the address stored in rax
            jmp next                            # jump to next to prepare for restart of loop

        print:
            leaq memory_cells(,%r14), %rdi      # calculate the address of the current memoryCell and copy to rdi
            movb (%rdi), %dil                   # copy 1 byte from the value located in the address stored in rdi to dil
            call putchar                        # call putchar which will print the char in dil
            jmp next                            # jump to next to prepare for the restart of loop

        read:
            call getchar                        # call getchar which will store input in al
            leaq memory_cells(,%r14), %rsi      # calculate the address of the current memoryCell and copy to rsi
            movb %al, (%rsi)                    # copy the input from al to the address stored in rsi
            jmp next                            # jump to next to prepare for the restart of loop
        moveLeftPointer:
            cmpq $0, %r14                       # compare the current memoryCell index to 0
            je end_brainfuck                    # if it is 0, we cannot move left
            decq %r14                           # if it is not 0, we decrement the memoryCell index
            jmp next                            # jump to next to prepare for the restart of loop 
        moveRightPointer:
            cmpq $29999, %r14                   # compare the current memoryCell index to 29999
            je end_brainfuck                    # if it is 29999 we cannot move right of it
            incq %r14                           # if it is not 29999, we can safely increment
            jmp next                            # jump to next to prepare for the restart of loop
        handle_start_loop:
            cmpb $1, skip_loop                  # compare if skip_loop is true
            je skip_start_loop_case             # if it is true, we skip the start of the loop(more info in skip_start_loop_case)
            leaq memory_cells(, %r14), %rax     # if it is not true, calculate the address of the current memoryCell and copy to rax
            cmpb $0, (%rax)                     # comapre if the value in the current memoryCell is 0
            je skip_loop_logic                  # if the value in the current memoryCell is 0, we need to skip the loop
            pushq %r13                          # if the value in the current memoryCell is not 0, we need to execute the loop
                                                # save the instruction pointer of the start of the loop to the stack
            subq $8, %rsp                       # align stack
            jmp next                            # jump to next to prepare for the restart of loop
           
            # If we enter this code it means we are inside of a skip loop, which means we do not care about the nested loops inside
            # we only need to know how many nested loops are there, so we can find the close bracket of the initial skip loop
            skip_start_loop_case:
                incq %rbx                           # increment opened brackets inside skip_loop
                jmp next                            # jump to next to prepare for the restart of loop
            
            skip_loop_logic:
                movb $1, skip_loop              # set skip_loop to true
                incq %rbx                       # increment the opened brackets inside of skip loop
                jmp next                        # jump to next to prepare for the restart of loop
        handle_end_loop:
            cmpb $1, skip_loop                  # compare if skip loop is set to true
            jne continue_end_loop               # if it is not true(it is false), we continue the end loop process
            decq %rbx                           # decrement the opened brackets inside skip loop
            cmpq $0, %rbx                       # compare opened brackets inside skip loop is 0
            je reset_skip_loop                  # if it is 0, then we have reached the end of the skip loop and need to reset the variable related to it
            jmp next                            # jump to next to prepare for the restart of loop
        continue_end_loop:
            leaq memory_cells(, %r14), %rax     # calculate the address of the current memory cell
            cmpb $0, (%rax)                     # comapre the value in the current memery cell with 0
            jne return_to_start_of_loop         # if it is not 0, then we restart the brainfuck loop
            addq $16, %rsp                      # if it is 0, then we need to exit the loop
                                                # we add 16 to rsp to align the stack and remove the instruction pointer(8 bytes) from the stack
            jmp next                            # jump to next to prepare for the restart of loop
        return_to_start_of_loop:
            addq $8, %rsp                       # add 8 to rsp to align stack
            popq %r13                           # pop the index of the start of the loop we are in, and set instruction pointer to it
            jmp loop                            # directly restart the loop without going to next
        reset_skip_loop:
            movq $0, %rbx                       # reset opened brackets inside skip loop
            movb $0, skip_loop                  # set skip_loop to false
            jmp next                            # jump to next to prepare for the restart of loop
    
    end_brainfuck:                              # Epilogue
        movq %rbp, %rsp                         # Remove the local variables on the stack, by reseting the rsp
        popq %rbp                               # remove the base pointer from the stack
        ret                                     # return from the subroutine
