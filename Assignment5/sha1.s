.global sha1_chunk

# two parameters: %rdi - the address of h0 (ho is 32 bits - 4 bytes and h1, h2, etc. are stored directly after each other)
# %rsi - the address of the first 32-bit word of an array of 80 32-bit word (in Wikipedia the array is denoted as w[index])
# i will need a counter for the first loop starting at 16 until 79 (coz 80 elements in the array)
# then we will use the same counter for the second array starting 0 until 79
# variables we will need - a, b, c, d, e, f, k, w[i], and two shifted values 
# (caller-saved: %r8, %r9, %r10, %r11, %rdx, %rcx), (callee-saved: %r12, %13, %14, %r15)
# temp - will push and pop from stack
# flow - loop1, initializing values, main loop, add results, produce final hash value (i think this is not required)

sha1_chunk:								# rsi - address of w[0]
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15

	movq $16, %rax						# counter for first loop (16 - 79) 
	loop_extend_to_eighty_32_bit_words:
		cmpq $80, %rax					# compare with 80 (if it is 80 - break)
		je initialize_hash_values		# break loop

		movq %rax, %rcx					# rcx - used for every index of the previous elemnts in the expression
		subq $3, %rcx
		movl (%rsi, %rcx, 4), %r8d

		subq $5, %rcx
		movl (%rsi, %rcx, 4), %r9d

		xorl %r8d, %r9d								# xor operation (xor is associative operator, btw)

		subq $6, %rcx
		movl (%rsi, %rcx, 4), %r10d

		subq $2, %rcx
		movl (%rsi, %rcx, 4), %r11d

		xorl %r10d, %r11d

		xorl %r9d, %r11d								# result after big xor expression

		movl %r11d, %r8d		# left rotating by one bit
		shll $1, %r11d
		shrl $31, %r8d
		orl %r8d, %r11d

		movl %r11d, (%rsi, %rax, 4)								# assigning value 

		incq %rax						# increment counter
		jmp loop_extend_to_eighty_32_bit_words		# back to function

	initialize_hash_values:
		movl (%rdi), %r8d				# a
		movl 4(%rdi), %r9d				# b
		movl 8(%rdi), %r10d				# c
		movl 12(%rdi), %r11d			# d
		movl 16(%rdi), %ecx				# e
		
		movq $0, %rax					# counter for second loop (0 - 79)
	main_loop:
		cmpq $80, %rax					# compare with 80 (if it is 80 - break)
		je add_this_chunks_hash_to_results	# break loop

		check_1:
		cmpq $19, %rax
		jle case_1

		check_2:
		cmpq $39, %rax
		jle case_2

		check_3:
		cmpq $59, %rax
		jle case_3

		jmp case_4
		# a - r8d b - r9d c - r10d d - r11d e - ecx k - edx f - r13d
		case_1:
		movl $0x5A827999, %edx

		movl %r9d, %r12d
		andl %r10d, %r12d

		movl %r9d, %r13d
		notl %r13d
		andl %r11d, %r13d

		orl %r12d, %r13d

		jmp update_and_return_to_loop

		case_2:
		movl $0x6ED9EBA1, %edx

		movl %r10d, %r13d			# push r13d and pop cuz callee saved
		xorl %r9d, %r13d
		xorl %r11d, %r13d

		jmp update_and_return_to_loop

		case_3:
		movl $0x8F1BBCDC, %edx

		movl %r9d, %r12d
		andl %r10d, %r12d

		movl %r9d, %r13d
		andl %r11d, %r13d

		orl %r12d, %r13d

		movl %r10d, %r12d
		andl %r11d, %r12d	

		orl %r12d, %r13d	

		jmp update_and_return_to_loop

		case_4:
		movl $0xCA62C1D6, %edx
	
		movl %r10d, %r13d			# push r13d and pop cuz callee saved
		xorl %r9d, %r13d
		xorl %r11d, %r13d


		update_and_return_to_loop:
		# a - r8d b - r9d c - r10d d - r11d e - ecx k - edx f - r13d temp - r12d

		# temp
		movl %r8d, %r12d
		movl %r8d, %r15d
		shll $5, %r15d
		shrl $27, %r12d
		orl %r15d, %r12d

		addl %r13d, %r12d
		addl %ecx, %r12d
		addl %edx, %r12d
		addl (%rsi, %rax, 4), %r12d

		movl %r11d, %ecx  		# e = d
		movl %r10d, %r11d		# d = c

		movl %r9d, %r14d
		movl %r9d, %r15d
		shll $30, %r15d
		shrl $2, %r14d
		orl %r15d, %r14d
		# roll instruction

		movl %r14d, %r10d		# c = b left rotate 30

		movl %r8d, %r9d			# b = a

		movl %r12d, %r8d

		incq %rax
		jmp main_loop

	add_this_chunks_hash_to_results:
		addl %r8d, (%rdi)
		addl %r9d, 4(%rdi)
		addl %r10d, 8(%rdi)
		addl %r11d, 12(%rdi)
		addl %ecx, 16(%rdi)

		popq %r15
		popq %r14
		popq %r13
		popq %r12

	ret
