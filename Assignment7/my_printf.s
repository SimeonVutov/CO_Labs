.data
# r13: .quad 0     # pointer to iterate over the format string passed in our printf
start_str_index: .quad 0    # index of the start (where we want to start printing)
end_str_index: .quad 0      # index of the end (where we want to end printing), when we encounter a valid format str ("%s")
normal_string_after_formatter: .byte 1      # print string after last formatter (%) 
arguments_counter: .quad 0  # Initial value is 1, because we always have format string

.bss 
digits_array: .skip 20      # we will store the digits of a number in this separate "array" of max 20 elements
                            # as we need to pass chars to syscall CAN WE STORE INTS IN .TEXT
                            # why 20? 20 digits is the biggest possible number that could be passed by a 64 bit register 

.text
# format_str: .asciz "Hello! This is created by %s and %s, by spending %d nights with only %u hours of sleep. %%"     # example format str
format_str: .asciz "%d %d %d %d %d"
minus_symbol: .asciz "-"
name1: .asciz "The quick brown fox quickly jumps over the lazy dog!"        # values to replace "%smth"
# name2: .asciz "Shureto"

# nights: .quad 123 
# hours: .quad 5
n1: .quad 1
n2: .quad 2
n3: .quad 3
n4: .quad 4
n5: .quad 5
n6: .quad 6
.global main

main:
    pushq %rbp              # prologue
    movq %rsp, %rbp
    
    movq $format_str, %rdi  # passing the format string
    movq $n1, %rsi
    movq $n2, %rdx
    movq $n3, %rcx
    movq $n4, %r8
    movq $n5, %r9
                            # iff more than 6 parameters - the stack should be used
    call my_printf

    movq %rbp, %rsp
    popq %rbp

    movq $60, %rax    # syscall number for exit
    movq $0, %rdi   # exit code 0 (success)
    syscall           # invoke syscall to exit

my_printf:
    pushq %rbp              # prologue
    movq %rsp, %rbp
    subq $8, %rsp
    # callee saved registers (pop them afterwards)
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %rbx
    # function arguments
    pushq %r9               # in reverse order because stack is LIFO
    pushq %r8
    pushq %rcx
    pushq %rdx
    pushq %rsi

    movq %rdi, %r12
    movq $0, %r13
    loop:
        movb (%r12, %r13), %al
        # check if current char is zero (zero terminated)
        cmpb $0, %al
        je end_my_printf

        # check for %
        cmpb $'%', %al
        jne handle_normal_char       # if not % -> normal character
        movb 1(%r12, %r13), %al      # check the next symbol after '%'

        case1:
            cmpb $'s', %al
            jne case2
            cmpb $5, arguments_counter
            jl continue_case1
            je configure_stack_for_more_arguments1
            jmp continue_case1

            configure_stack_for_more_arguments1:
                movq %rbp, %rsp                 
                addq $16, %rsp
                                            # else use stack -> set rsp before the my_printf subroutine
            
            continue_case1:
                call pre_printing_string    # subroutine because we want to return and we use it in several places

                popq %r14                   # pop from stack to get the next argument
                movq %r14, %rdi
                call get_size_of_string
                # result is in rax
                movq %r14, %rdi
                movq %rax, %rsi
                call print_string

                addq $2, end_str_index
                movq end_str_index, %rax
                movq %rax, start_str_index
                incq %r13

                movb $0, normal_string_after_formatter
                incq arguments_counter      # we have used one more argument
                jmp next
        case2: # convert_digits_to_chars
            cmpb $'u', %al
            jne case3
            cmpb $5, arguments_counter
            jl continue_case2
            je configure_stack_for_more_arguments2
            jmp continue_case2
            
            configure_stack_for_more_arguments2:
                movq %rbp, %rsp                 
                addq $16, %rsp
            
            continue_case2:
                call pre_printing_string
                popq %r14                   # pop from stack to get the next argument

                cmpq $0, (%r14)
                movq (%r14), %r14
                jl remove_minus_for_unsigned

                logic_for_unsigned_numbers:
                    movq %r14, %rdi
                    # other things
                    # set number to convert_digits_to_chars as first param
                    call convert_digits_to_chars
                    # result will be in rax which will be the index of the first digit in the array
                    # calculate the address of this element using the address of the array
                    # first array element address = array address + n(from rax)
                    leaq digits_array(, %rax), %rdi
                    subq $20, %rax
                    negq %rax
                    movq %rax, %rsi
                    call print_string
                    # pass this to the print_string and the size of the number(20 - n) Think how really we need to get the size of the number
                    # . . . . 1 2 3 4 5 -> n = 4

                addq $2, end_str_index
                movq end_str_index, %rax
                movq %rax, start_str_index
                incq %r13

                movb $0, normal_string_after_formatter
                incq arguments_counter      # we have used one more argument
                jmp next

            remove_minus_for_unsigned:
                negq %r14
                jmp logic_for_unsigned_numbers

        case3: # convert_digits_to_chars
            cmpb $'d', %al
            jne case4
            
            cmpb $5, arguments_counter
            jl continue_case3
            je configure_stack_for_more_arguments3
            jmp continue_case3
            
            configure_stack_for_more_arguments3:
                movq %rbp, %rsp                 
                addq $16, %rsp
            
            continue_case3:
                call pre_printing_string
                popq %r14                   # pop from stack to get the next argument

                cmpq $0, (%r14)
                movq (%r14), %r14
                jl add_minus
                jmp logic_for_unsigned_numbers

                add_minus:
                    negq %r14
                    # print minus sign
                    movq $1, %rdi
                    movq $minus_symbol, %rsi
                    movq $1, %rdx
                    movq $1, %rax
                    syscall

                jmp logic_for_unsigned_numbers
            # we do not need the jmp next since we use case2
            # We REUSE THE END LOGIC FROM CASE2
        case4:
            cmpb $'%', %al
            jne case5
            incq end_str_index
            call pre_printing_string
            incq end_str_index
            movq end_str_index, %rax 
            movq %rax, start_str_index              # update start index
            incq %r13                               # skip the second %
            movb $0, normal_string_after_formatter
            jmp next
        case5:
            # handle the print of % 
            jmp handle_normal_char
        
        
    # check for next char to determine if it is format char
            # jump to process it
            # elsee continue
        # print char
        handle_normal_char:
            incq end_str_index      # increase the interval of chars to be printed (between start and end index)
            movb $1, normal_string_after_formatter
            jmp next
        next:
            incq %r13     # increment and back to loop
            jmp loop
    end_my_printf:
        cmpb $1, normal_string_after_formatter
        jne end
        call pre_printing_string
        
        movq $5, %rcx
        subq arguments_counter, %rcx
        loop1:
            cmpq $0, %rcx
            jle end_loop1

            addq $8, %rsp
            jmp loop1
        end_loop1:
        popq %rbx
        popq %r14
        popq %r13
        popq %r12
        # epilogue
        end:
            movq %rbp, %rsp
            popq %rbp
            ret

# rdi = number to convert
convert_digits_to_chars:
    # prologue
    pushq %rbp
    movq %rsp, %rbp

    movq $19, %rcx              # set the counter to the last element of the array
    movq %rdi, %rax
    movq $10, %rbx              # we need to devide by 10
    movq $0, %rdx               # reset register to 0
    loop_number:
        cmpq $0, %rax
        jle out_of_loop_number
        divq %rbx               # rax = rax / 10
                                # rdx = rax % 10
        addq $48, %rdx          # add 40 to rax % 10 to convert it to ascii code
        movb %dl, digits_array(, %rcx)      # dl is rdx for 1 byte
        decq %rcx
        movq $0, %rdx
        jmp loop_number


    out_of_loop_number:
        movq %rcx, %rax
        incq %rax               # because of how we handle the rcx, we will have at the end the index of the next element(but it is outside of our number)

    # epilogue
    movq %rbp, %rsp
    popq %rbp
    ret

pre_printing_string:
    # prologue
    pushq %rbp
    movq %rsp, %rbp
    
    movq start_str_index, %rax
    leaq (%r12, %rax), %rdi        # pass the address of the beginning of the string to print
    movq start_str_index, %r8
    movq end_str_index, %r9
    subq %r8, %r9                         # calculate the number of chars to print (needed in syscall)
    movq %r9, %rsi
    call print_string

    # epilogue
    movq %rbp, %rsp
    popq %rbp
    ret

# address of the string in rdi
get_size_of_string:
    # prologue
    pushq %rbp
    movq %rsp, %rbp

    movq $0, %rcx
    loop_string:
        movb (%rdi, %rcx), %al
        cmpb $0, %al
        je end_loop
        incq %rcx
        jmp loop_string


    end_loop:
        # return size
        movq %rcx, %rax

        # epilogue
        movq %rbp, %rsp
        popq %rbp
        ret

# first parameter string address
# second parameter string size to print
print_string:
    pushq %rbp              # prologue (is it a subroutine or a label?)
    movq %rsp, %rbp
    movq %rdi, %rax          # we need rdi, that's why we copy

    movq $1, %rdi           # set sys_write to use stdout (print in terminal)
    movq %rsi, %rdx         # set the size of the string which will be printed
    movq %rax, %rsi         # put the start address of the string which will be printed
    movq $1, %rax           # set sys_call to use sys_write
    syscall 

    # epilogue
    movq %rbp, %rsp
    popq %rbp
    ret
