.text
format: .asciz "%d"
formatChar: .asciz "%c"
foregroundColorEffectFormat: .asciz "\033[38;5;%dm"
backgroundColorEffectFormat: .asciz "\033[48;5;%dm"


# Special Effects' codes
resetEffects: .asciz "\033[0m"
stopBlinkingEffect: .asciz "\033[25m"
boldEffect: .asciz "\033[1m"
faintEffect: .asciz "\033[2m"
concealEffect: .asciz "\033[8m"
revealEffect: .asciz "\033[28m"
blinkEffect: .asciz "\033[5m"

.include "final.s"

specialEffects:
    .quad 0, resetEffects      # Reset to normal
    .quad 37, stopBlinkingEffect   # Stop blinking
    .quad 42, boldEffect           # Bold
    .quad 66, faintEffect          # Faint
    .quad 105, concealEffect       # Conceal
    .quad 153, revealEffect        # Reveal
    .quad 182, blinkEffect         # Blink

.global main

# ************************************************************
# Subroutine: decode                                         *
# Description: decodes message as defined in Assignment 3    *
#   - 2 byte unknown                                         *
#   - 4 byte index                                           *
#   - 1 byte amount                                          *
#   - 1 byte character                                       *
# Parameters:                                                *
#   first: the address of the message to read                *
#   return: no return value                                  *
# ************************************************************

# Using these registers:
# r12 -> start address of Message
# r13 -> address of first bit on current element in Message
decode:
	# prologue
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

    pushq %r12              # Store previous value of r12 calle saved register
    pushq %r13              # Store previous value of r13 calle saved register

    movq %rdi, %r12         # store the start address of Message in r12
    movq %r12, %r13         # set current element to be the first one

    loop1:
        movzbq 6(%r13), %rdi    # get foreground color
        movzbq 7(%r13), %rsi    # get background color
        
    # Set background and foreground
        call set_effects
        
        movzbq (%r13), %rdi     # get actual character byte and extend it to quad
        movzbq 1(%r13), %rsi    # get number of times to print and extend it to quad

        call print              # first param - character, second param - amount
        
        movl 2(%r13), %eax       # Store index value(4 bytes) in eax
        
        exitCaseCheck:
            cmpl $0, %eax       # check if next index is 0 
            je endDecode        # if next index is 0 we exit decode
 
        movq $8, %rdx           # Copy 8 in rdx
        mulq %rdx               # Multiply index of element(in rax) with value 8 (rdx)
        movq %r12, %r13         # Set current element address to first element
        addq %rax, %r13         # Add calculated offset to current element address
                                # r13 = r12 + 8 * index
        
        jmp loop1               # restart loop
         

    endDecode:
        popq %r13              # Restore previous value of r13 calle saved register
        popq %r12              # Restore previous value of r12 calle saved register
        
        # epilogue
        movq	%rbp, %rsp		# clear local variables from stack
	    popq	%rbp			# restore base pointer location 
	    ret


# first parameter - character
# second parameter - number of times to print
print:
    # prologue
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

    pushq %r14              # save previous value of r14 to stack (calle-saved)
    pushq %r15              # save previous value of r15 to stack (calle-saved)

    movq %rdi, %r14         # Save first parameter in r14 to free rdi
    movq %rsi, %r15         # Save second parameter in r15 to free rsi
    
    loop:
        cmpq $0, %r15       # compare printTimes with 0
        jle endPrint        # if printTimes is less or equal to 0 we stop printing

        movq $0, %rax       # no vector arguments
        movq $formatChar, %rdi      # first parameter - format for printing char
        movq %r14, %rsi             # second parameter - actual character to print
        
        call printf                 # call printf
        
        decq %r15           # decrement printTimes by 1
        jmp loop            # restart the loop
    endPrint:        
        popq %r15           # restore previous value of r15
        popq %r14           # restore previous value of r14
        
                            # epilogue
        movq %rbp, %rsp     # clear local variables from stack
        popq %rbp           # restore base pointer
        ret                 # return from print Subroutine

# first param(rdi): foreground color number
# second param(rsi): background color number
set_effects:
    pushq %rbp              # push the base pointer (and align the stack)
    movq %rsp, %rbp         # copy stack pointer value to base pointer
    
    cmpq %rdi, %rsi         # compare foreground and background color values
    jne colorEffects        # if they are different we set the specific colors
    
    otherEffects:
        movq $0, %rcx               # Set loop counter to 0
    
        loop_effects:
                                            # Formula to calculate -> specialEffects + counter * 16
            movq %rcx, %rax                 # Copy value of counter to rax
            shlq $4, %rax                   # shift left 4 times rax (counter * 16)
            addq $specialEffects, %rax      # add start address of specialEffects table
            movq (%rax), %r8                # copy value of first part of the pair from specialEffects table from calculated address

            cmpq %rdi, %r8                  # compare foreground number to 
            je applyEffect                  # apply the effect we want
            
            addq $1, %rcx                   # increase the loop counter by 1
            cmpq $7, %rcx                   # compare the counter to 7, because we have only 7 special effects
            jl loop_effects                 # if counter < 7, then we can continue looping
    
        jmp endSetEffects                   # jump to epilogue to return from the set_effects Subroutine

    applyEffect:
        addq $8, %rax               # add 8 to the address stored in rax (specialEffects + counter * 16 + 8)
        movq (%rax), %rdi           # copy the value stored in the address in rax to rdi(first param)
        call printf                 # print the value in rdi
        jmp endSetEffects           # jump to epilogue to return from set_effects Subroutine
    
    colorEffects:
        movq %rdi, %r8                              # Copy value of foreground to r8
        movq %rsi, %r9                              # Copy value of background to r9
        movq $0, %rax                               # no vector arguments
        movq $foregroundColorEffectFormat, %rdi     # first param: the ansi code format string for foreground
        movq %r8, %rsi                              # second param: the value of foreground color
        call printf                                 # call printf Subroutine
        
        movq $backgroundColorEffectFormat, %rdi     # first param: the ansi code format string for background
        movq %r9, %rsi                              # second param: the value of background color
        call printf                                 # call printf Subroutine
        
    endSetEffects:
        # Restore stack frame
        movq %rbp, %rsp             # clear local variables from stack 
        popq %rbp                   # restore base pointer location 
        ret

main:
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	movq	$MESSAGE, %rdi	# first parameter: address of the message
	call	decode			# call decode

	popq	%rbp			# restore base pointer location 
	movq	$0, %rdi		# load program exit code
	call	exit			# exit the program

