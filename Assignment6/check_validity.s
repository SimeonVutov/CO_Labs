.text             
valid_msg: .asciz "valid"      # Define a null-terminated string for "valid"
invalid_msg: .asciz "invalid"  # Define a null-terminated string for "invalid"

.include "basic.s"

.global main

# *******************************************************************************************
# Subroutine: check_validity                                                                *
# Description: checks the validity of a string of parentheses as defined in Assignment 6.   *
# Parameters:                                                                               *
#   first: the string that should be check_validity                                         *
#   return: the result of the check, either "valid" or "invalid"                            *
# *******************************************************************************************
check_validity:
	# prologue
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	movq $1, %rsi			# boolean variable whether parantheses are valid
	movq $0, %rdx			# amount of open brackets that are not "closed" 
	
	movq $0, %r11			# counter (which char are we at, "i" in for loop)

		iterating_string:   # loop
		# base with index addressing - rdi is the start address of the message 
		movb    (%rdi, %r11), %al  # load the current character into %al - rdi(starting address), r11 - counter
    	cmpb    $0, %al            # check if it's the null terminator
    	je      end_count          # if yes, jump to end_count

			check_1:
			# check for closed bracket after open brackets becomes zero

			cmpq $0, %rdx  						# check if open bracktes are zero
			jne check_if_next_bracket_is_open   # skip below checks, if not equal to 0

			# check for closed bracket, and go to invalid, if so
			cmpb $')', %al 	
			je set_invalid
			cmpb $']', %al
			je set_invalid
			cmpb $'}', %al
			je set_invalid
			cmpb $'>', %al
			je set_invalid

			check_if_next_bracket_is_open:
			cmpb $'(', %al
			je push_open_bracket
			cmpb $'[', %al
			je push_open_bracket
			cmpb $'{', %al
			je push_open_bracket
			cmpb $'<', %al
			je push_open_bracket

			check_if_brackets_match:	# if current bracket is not open, we go here
			
				check_bracket_2_0:
				cmpb $')', %al			# check if current closing bracket is ')'
				jne check_bracket_2_1	# if not, go check for next type of parenthesis
				addq $8, %rsp			# prepare stack for pop (aligning stack)
				popq %r8				# finally we pop the opening bracket
				cmpb $'(', %r8b  		# check if calculated open bracket is the same as closed
				je update_after_brackets_match
				jmp set_invalid			# if closed bracket doesn't correspond to open

				check_bracket_2_1:
				cmpb $']', %al			# check if current closing bracket is ']'
				jne check_bracket_2_2	# if not, go check for next type of parenthesis
				addq $8, %rsp			# prepare stack for pop (aligning stack)
				popq %r8           		# finally we pop the opening bracket
				cmpb $'[', %r8b			# check if calculated open bracket is the same as closed
				je update_after_brackets_match
				jmp set_invalid   		# if closed bracket doesn't correspond to open


				check_bracket_2_2:
				cmpb $'}', %al			# check if current closing bracket is '}'
				jne check_bracket_2_3	# if not, go check for next type of parenthesis
				addq $8, %rsp			# prepare stack for pop (aligning stack)
				popq %r8				# finally we pop the opening bracket
				cmpb $'{', %r8b			# check if calculated open bracket is the same as closed
				je update_after_brackets_match
				jmp set_invalid   		# if closed bracket doesn't correspond to open


				check_bracket_2_3:
				cmpb $'>', %al			# check if current closing bracket is '>'
				addq $8, %rsp			# prepare stack for pop (aligning stack)
				popq %r8				# finally we pop the opening bracket
				cmpb $'<', %r8b			# check if calculated open bracket is the same as closed
				je update_after_brackets_match
				jmp set_invalid   		# iff closed bracket doesn't correspond to open

			push_open_bracket:
			movzbq %al, %rax    # zero-extend %al to %rax (64-bit)
			pushq %rax          # push the 64-bit %rax onto the stack
			subq $8, %rsp 		# aligning stack
			incq %rdx			# incrementing open bracket counter
			jmp next_cycle      # continue iterating

			update_after_brackets_match:
			decq %rdx			# open bracket counter decremented by one, because we "closed"
			jmp next_cycle		# continue iterating

		next_cycle:
    	incq    %r11               		 # increment the character counter
    	jmp     iterating_string         # repeat the loop
		
		set_invalid:
		# break, and set to invalid
			movq $0, %rsi 			# rsi - false
			jmp end_count			# break from loop

	end_count:
	# check if there are left open brackets

	cmpq $0, %rdx
	jne return_invalid

	cmpq $0, %rsi				# rsi - boolean validator
	je return_invalid

	movq $valid_msg, %rax		# valid
	movq $valid_msg, %rdi
	call printf
	jmp epilogue_

	return_invalid:
	movq $invalid_msg, %rax		# invalid
	movq $invalid_msg, %rdi
	call printf

	epilogue_:
	movq	%rbp, %rsp		# clear local variables from stack
	popq	%rbp			# restore base pointer location 
	ret

main:
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	movq	$MESSAGE, %rdi		# first parameter: address of the message
	call	check_validity		# call check_validity

	popq	%rbp			# restore base pointer location 
	movq	$0, %rdi		# load program exit code
	call	exit			# exit the program

