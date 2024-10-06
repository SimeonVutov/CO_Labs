.text
valid: .string "valid"
invalid: .string "invalid"

.data              # Data section for initialized variables
valid_msg: .ascii "valid\0"      # Define a null-terminated string for "valid"
invalid_msg: .ascii "invalid\0"  # Define a null-terminated string for "invalid"

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

	movq $0, %r11			# counter (which char are we at, "i" in for loop)

		iterating_string:
		movb    (%rdi, %r11), %al  # Load the current character into %al
    	testb   %al, %al           # Check if it's the null terminator
    	je      end_count          # If yes, jump to end_count

			check_whether_count_of_open_brackets_is_zero:
			cmpq $0, %rdx
			je reset_steps_back

			base_false_check_if_first_bracket_is_closed:
			cmpq $0, %rdx  						# check if open bracktes are zero
			jne check_if_next_bracket_is_open   # skip checks if not equal

			# check for closed bracket, and go to invalid if so
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
			je increment_open_bracket_counter_and_back_to_loop
			cmpb $'[', %al
			je increment_open_bracket_counter_and_back_to_loop
			cmpb $'{', %al
			je increment_open_bracket_counter_and_back_to_loop
			cmpb $'<', %al
			je increment_open_bracket_counter_and_back_to_loop

			check_if_current_closed_bracket_corresponds_to_an_open:
			# calculating the open bracket (tracking back)
			# r11(current) - rcx(steps back)
			# r10 - calculated offset
			movq %r11, %r10
			subq %rcx, %r10
			movb    (%rdi, %r10), %r8b  # Load the current character into %r11b

			check_bracket_2_0:
			cmpb $')', %al
			jne check_bracket_2_1
			cmpb $'(', %r8b  		# check if calculated open bracket is the same as closed
			je closed_bracket_corresponds_to_open_so_we_update

			check_bracket_2_1:
			cmpb $']', %al
			jne check_bracket_2_2
			cmpb $'[', %r8b		# check if calculated open bracket is the same as closed
			je closed_bracket_corresponds_to_open_so_we_update

			check_bracket_2_2:
			cmpb $'}', %al
			jne check_bracket_2_3
			cmpb $'{', %r8b		# check if calculated open bracket is the same as closed
			je closed_bracket_corresponds_to_open_so_we_update

			check_bracket_2_3:
			cmpb $'>', %al
			cmpb $'<', %r8b		# check if calculated open bracket is the same as closed
			je closed_bracket_corresponds_to_open_so_we_update

			# iff closed bracket doesn't correspond to open
			jmp set_invalid

			increment_open_bracket_counter_and_back_to_loop:
			incq %rdx 		# open bracket counter
			jmp next_cycle

			closed_bracket_corresponds_to_open_so_we_update:
			decq %rdx		# open bracket counter
			addq $2, %rcx	# steps back
			jmp next_cycle

		next_cycle:
    	incq    %r11               # Increment the character count
    	jmp     iterating_string         # Repeat the loop
		
		set_invalid:
		# break, and set to invalid
			movq $0, %rsi
			jmp end_count

			reset_steps_back:
				movq $1, %rcx
				jmp base_false_check_if_first_bracket_is_closed

	end_count:

	# check if there are left open brackets	
	cmpq $0, %rdx
	jne print_invalid

	# print based on value in rsi

	cmpq $0, %rsi
	je print_invalid

	# print valid
	movq $valid_msg, %rax
	jmp epilogue_

	print_invalid:
	movq $invalid_msg, %rax

	epilogue_:
	# epilogue
	movq	%rbp, %rsp		# clear local variables from stack
	popq	%rbp			# restore base pointer location 
	ret

main:
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

#	movq $1, %rax			# boolean (0 - false, 1 - true) validator
#	movq $0, %r8			# count of open brackets
#	movq $1, %r9			# number of stepsToGoBackToCheckForMatching

	movq	$MESSAGE, %rdi		# first parameter: address of the message
	movq $1, %rsi
	movq $0, %rdx
	movq $1, %rcx
	call	check_validity		# call check_validity

	movq %rax, %rdi
	call printf

	popq	%rbp			# restore base pointer location 
	movq	$0, %rdi		# load program exit code
	call	exit			# exit the program

