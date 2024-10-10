.bss
memory_cells: .skip 30000

.text
format_str: .asciz "We should be executing the following code:\n%s"
input_format_str: .asciz "%c"
output_format_str: .asciz "%d"
.data
skip_loop: .byte 0
.global brainfuck

# Your brainfuck subroutine will receive one argument:
# a zero termianted string containing the code to execute
# r11 -> address of the code string in memory
# r12 -> instruction pointer in the code string
# r13 -> current memory cell index pointer
# r14 -> number of opened square brackets
# r15 -> store the opened brackets inside a skip loop
brainfuck:
	pushq %rbp
	movq %rsp, %rbp
	
    movq %rdi, %r11
    movq $0, %r12
    movq $0, %r13
    movq $0, %r14

    loop:
        movb (%r11, %r12), %al
        movzbq %al, %rdi

        cmpb $0, %al
        je end_brainfuck
        
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
            incq %r12
            jmp loop
        
        increaseMemoryCell:
            leaq memory_cells(,%r13,8), %rax 
            incq (%rax)
            jmp next
        decreaseMemoryCell:
            leaq memory_cells(,%r13, 8), %rax
            decq (%rax)
            jmp next
        moveLeftPointer:
            cmpq $1, %r13
            je end_brainfuck
            decq %r13
            jmp next
        moveRightPointer:
            cmpq $29999, %r13
            je  end_brainfuck
            incq %r13
            jmp next
        print:
            leaq memory_cells(,%r13,8), %rax
            movq $output_format_str, %rdi
            movzbq (%rax), %rsi
            movq $0, %rax # no-vector arguments
            call printf
            jmp next
        read:
            leaq memory_cells(,%r13, 8), %rsi
            movq $input_format_str, %rdi
            call scanf
            jmp next
        handle_start_loop:
            cmpb $1, skip_loop                 # if skip loop is true we do not execute regularly
            je skip_start_loop_case
            leaq memory_cells(, %r13,8), %rax
            cmpq $0, (%rax)
            je skip_loop_logic
            pushq %rax                          # save address of beginning of the loop
            subq $8, %rsp                       # align stack
            incq %r14        
            jmp next
           
            skip_start_loop_case:
                incq %r15                           # increment temp opened brackets
                jmp next
            
            skip_loop_logic:
                movq $1, skip_loop
                incq %r15
            jmp next 
        handle_end_loop:
            cmpb $1, skip_loop
            jne continue_end_loop
            decq %r15
            cmpq $0, %r15
            je reset_skip_loop
            jmp next
        continue_end_loop:
            leaq memory_cells(, %r13, 8), %rax
            cmpq $0, (%rax)
            jne return_to_start_of_loop
            addq $16, %rsp                      # remove the bracket address because we need to exit the loop
            decq %r14
        return_to_start_of_loop:
            addq $8, %rsp
            popq %r12                            # pop the address of start of loop
            jmp next 
        reset_skip_loop:
            movq $0, %r15
            movq $0, skip_loop
            jmp next
    end_brainfuck:
        movq %rbp, %rsp
        popq %rbp
        ret
