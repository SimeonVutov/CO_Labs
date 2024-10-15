.data
string_pointer: .quad 0
start_str_index: .quad 0
end_str_index: .quad 0
.text
format_str: .asciz "Hello! This is created by %s and %s, by spending %d nights with only %u hours of sleep. %%"
name1: .asciz "Moni"
name2: .asciz "Shureto"
nights: .quad 361283761287
hours: .quad 5
.global main

main:
    pushq %rbp
    movq %rsp, %rbp
    
    movq $format_str, %rdi
    movq $name1, %rsi
    movq $name2, %rdx
    movq $nights, %rcx
    movq $hours, %r8
    pushq $11
    call my_printf

    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    call exit

my_printf:
    pushq %rbp
    movq %rsp, %rbp
    
    # calle saved registers
    pushq %r12
    pushq %r13
    pushq %r14
    # function arguments
    pushq %r9
    pushq %r8
    pushq %rcx
    pushq %rdx
    pushq %rsi
    
    movq %rdi, %r12

    loop:
        movb string_pointer(%rdi), %al
        # check if we are at the end
        cmpb $0, %al
        je end_my_printf

        # check for %
        cmpb $'%', %al
        jne handle_normal_char
        movb string_pointer(%rdi, 1), %al
        cmpb $'s', %al
        je process_strings
        cmpb $'u', %al
        je process_unsigned
        cmpb $'d', %al
        je process_signed
        cmpb $'%', %al
        # increase start_str_index by 1 so we can include the first %
        # after we are done with this comeback here to reset indexes
        
    # check for next char to determine if it is format char
            # jump to process it
            # else continue
        # print char
        handle_normal_char:
            incq end_str_index
            jmp next
        next:
            incq string_pointer
            jmp loop
    end_my_printf:
        movq %rbp, %rsp
        popq %rbp
        ret

process_formats:
    # determine the type of the format
    # call the corresponding function

print_unsigned:
print_signed:

# first parameter string address
# second parameter string size to print
print_string:
    pushq %rbp
    movq %rsp, %rbp
    movq %rdi, rax

    movq $1, %rdi           # set sys_write to use stdout
    movq %rsi, %rdx         # set the size of the string which will be printed
    movq %rax, %rsi         # put the address of the string which will be printed
    movq $1, %rax           # set sys_call to use sys_write
    syscall 

    movq %rbp, %rsp
    popq %rbp
    ret
    

