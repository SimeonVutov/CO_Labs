.data
skip_loop: .byte 0

.bss
memory_cells: .skip 30000

.text
format_str: .asciz "We should be executing the following code:\n%s"
input_format_str: .asciz "%c"
output_format_str: .asciz "%d"

.global brainfuck

# Your brainfuck subroutine will receive one argument:
# a zero termianted string containing the code to execute
# r12 -> address of the code string in memory
# r13 -> instruction pointer in the code string
# r14 -> current memory cell index pointer
# r15 -> number of opened square brackets
# rbx -> store the opened brackets inside a skip loop
brainfuck:
	pushq %rbp
	movq %rsp, %rbp
	
    movq %rdi, %r12
    movq $0, %r13
    movq $0, %r14
    movq $0, %r15
    movq $0, %rbx
    loop:
        movb (%r12, %r13), %al
        movzbq %al, %rdi

        cmpb $0, %al
        je end_brainfuck
        cmpb $1, skip_loop 
        je loop_check

        standart_checks:
            cmpb $'+', %al
            je increaseMemoryCell

            cmpb $'-', %al
            je decreaseMemoryCell
            
            cmpb $'.', %al
            je print
            
            cmpb $',', %al
            je read
            
            cmpb $'>', %al 
            je moveLeftPointer
            
            cmpb $'<', %al
            je moveRightPointer
        
        loop_check:
            cmpb $'[', %al
            je handle_start_loop
            cmpb $']', %al
            je handle_end_loop
        next:
            incq %r13
            jmp loop
        
        increaseMemoryCell:
            leaq memory_cells(,%r14,8), %rax 
            incq (%rax)
            jmp next
        decreaseMemoryCell:
            leaq memory_cells(,%r14, 8), %rax
            decq (%rax)
            jmp next
        moveLeftPointer:
            cmpq $1, %r14
            je end_brainfuck
            decq %r14
            jmp next
        moveRightPointer:
            cmpq $29999, %r14
            je  end_brainfuck
            incq %r14
            jmp next
        print:
            leaq memory_cells(,%r14,8), %rax
            movq $output_format_str, %rdi
            movzbq (%rax), %rsi
            movq $0, %rax # no-vector arguments
            call printf
            jmp next
        read:
            leaq memory_cells(,%r14, 8), %rsi
            movq $input_format_str, %rdi
            call scanf
            jmp next
        handle_start_loop:
            cmpb $1, skip_loop                 # if skip loop is true we do not execute regularly
            je skip_start_loop_case
            leaq memory_cells(, %r14,8), %rax
            cmpq $0, (%rax)
            je skip_loop_logic
            pushq %r13                          # save address of beginning of the loop
            subq $8, %rsp                       # align stack
            incq %r15        
            jmp next
           
            skip_start_loop_case:
                incq %rbx                           # increment temp opened brackets
                jmp next
            
            skip_loop_logic:
                movq $1, skip_loop
                incq %rbx
            jmp next 
        handle_end_loop:
            cmpb $1, skip_loop
            jne continue_end_loop
            decq %rbx
            cmpq $0, %rbx
            je reset_skip_loop
            jmp next
        continue_end_loop:
            leaq memory_cells(, %r14, 8), %rax
            cmpq $0, (%rax)
            jne return_to_start_of_loop
            addq $16, %rsp                      # remove the bracket address because we need to exit the loop
            decq %r15
            jmp next
            #PROBLEM
        return_to_start_of_loop:
            addq $8, %rsp
            popq %r13                            # pop the address of start of loop
            jmp loop
        reset_skip_loop:
            movq $0, %rbx
            movq $0, skip_loop
            jmp next
    end_brainfuck:
        movq %rbp, %rsp
        popq %rbp
        ret
