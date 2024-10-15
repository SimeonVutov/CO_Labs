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
    
    pushq %r9
    pushq %r8
    pushq %rcx
    pushq %rdx
    pushq %rsi
    pushq %rdi

    # Loop over each char
        # check if we are at the end
        # check for %
            # check for next char to determine if it is format char
            # jump to process it
            # else continue
        # print char
    movq %rbp, %rsp
    popq %rbp
    ret

process_formats:
    # determine the type of the format
    # call the corresponding function

print_unsigned:
print_signed:
print_string:
print_char:
