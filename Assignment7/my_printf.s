.data
string_pointer: .quad 0     # pointer to iterate over the format string passed in our printf
start_str_index: .quad 0    # index of the start (where we want to start printing)
end_str_index: .quad 0      # index of the end (where we want to end printing), when we encounter a valid format str ("%s")

.bss 
digits_array: .skip 20      # we will store the digits of a number in this separate "array" of max 20 elements
                            # as we need to pass chars to syscall CAN WE STORE INTS IN .TEXT
                            # why 20? 20 digits is the biggest possible number that could be passed by a 64 bit register 

.text
format_str: .asciz "Hello! This is created by %s and %s, by spending %d nights with only %u hours of sleep. %%"     # example format str
name1: .asciz "Moni"        # values to replace "%smth"
name2: .asciz "Shureto"
nights: .quad 361283761287 
hours: .quad 5                  
.global main

main:
    pushq %rbp              # prologue
    movq %rsp, %rbp
    
    movq $format_str, %rdi  # passing the format string
    movq $name1, %rsi       # passing the values to replace "%smth"
    movq $name2, %rdx
    movq $nights, %rcx
    movq $hours, %r8
                            # iff more than 6 parameters - the stack should be used
    call my_printf

    movq $0, %rax           # epilogue
    movq %rbp, %rsp
    popq %rbp
    call exit

my_printf:
    pushq %rbp              # prologue
    movq %rsp, %rbp
    
    # callee saved registers
    pushq %r12
    pushq %r13
    pushq %r14
    # function arguments
    pushq %r9               # in reverse order because stack is LIFO
    pushq %r8
    pushq %rcx
    pushq %rdx
    pushq %rsi
    
    movq %rdi, %r12         

    loop:
        movb string_pointer(%rdi), %al
        # check if current char is zero (zero terminated)
        cmpb $0, %al
        je end_my_printf

        # check for %
        cmpb $'%', %al
        jne handle_normal_char     # if not % -> normal character
        movb string_pointer(%rdi, $1), %al   

        cmpb $'s', %al
        leaq start_str_index(%r12), %rdi        # pass the address of the beginning of the string to print
        movq start_str_index, %r13
        movq end_str_index, %r14
        subq %r13, %r14                         # calculate the number of chars to print (needed in syscall)
        movq %r14, %rsi                         # pass the number to rsi
        call print_string
        # assigning new value to the start index (make it equal to end index) 

        cmpb $'u', %al
        # parameters
        call print_unsigned

        cmpb $'d', %al
        # parameters
        call print_signed

        cmpb $'%', %al
        # increase start_str_index by 1 so we can include the first %
        # after we are done with this comeback here to reset indexes
        
    # check for next char to determine if it is format char
            # jump to process it
            # elsee continue
        # print char
        handle_normal_char:
            incq end_str_index      # increase the interval of chars to be printed (between start and end index)
            jmp next
        next:
            incq string_pointer     # increment and back to loop
            jmp loop
    end_my_printf:
        # epilogue
        movq %rbp, %rsp
        popq %rbp
        ret

process_formats:
    # determine the type of the format
    # call the corresponding function

print_unsigned:
# prologue and epilogue

print_signed:


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