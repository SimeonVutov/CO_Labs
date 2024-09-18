.text
format: .asciz "%d"
formatChar: .asciz "%c"

.include "helloWorld.s"

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
        leaq (%r13), %rdi       # get letter ascii representation
        leaq +1(%r13), %rsi     # get number of times to print the letter
        movzbq (%rdi), %rdi     # get actual character byte and extend it to quad
        movzbq (%rsi), %rsi     # get amount byte and extend it to quad
        call print              # first param - character, second param - amount
        
        leaq +2(%r13), %rdi     # calculate the address of first byte of index
        movzbq (%rdi), %rax     # Store index value(4 bytes) in rax(rezo extended to quad)
        
        exitCaseCheck:
            cmpq $0, %rax       # check if next index is 0 
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

main:
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	movq	$MESSAGE, %rdi	# first parameter: address of the message
	call	decode			# call decode

	popq	%rbp			# restore base pointer location 
	movq	$0, %rdi		# load program exit code
	call	exit			# exit the program

