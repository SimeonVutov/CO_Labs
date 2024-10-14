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
	# prologue
	pushq %rbp
	movq %rsp, %rbp

	pushq %r12
	pushq %r13							# push callee-saved registers
	pushq %r14
	pushq %r15

	movq $16, %rax						# counter for first loop (16 - 79) , i
	loop_extend_to_eighty_32_bit_words:	# EXPRESSION: w[i] = (w[i-3] xor w[i-8] xor w[i-14] xor w[i-16]) leftrotate 1
		cmpq $80, %rax					# compare with 80 (if it is 80 - break)
		je initialize_hash_values		# break loop

		movq %rax, %rcx					# rcx - used as index for getting the elements in the expression (i - smth), REFER TO EXPRESSION
		subq $3, %rcx					# subtract 3 for the index of the first element 
		movl (%rsi, %rcx, 4), %r8d		# get the value of that element, rsi - start address of array, rcx - index, scale 4 - 4 bytes

		subq $5, %rcx					# subtract 5 more for the index of the second element
		movl (%rsi, %rcx, 4), %r9d		# get the value of that element, rsi - start address of array

		xorl %r8d, %r9d					# xor operation of the first two elements(xor is associative operator, btw)
											# store result in %r9d
		subq $6, %rcx					# subtract 6 more for the index of the third element 
		movl (%rsi, %rcx, 4), %r10d		# get the value of that element, rsi - start address of array

		subq $2, %rcx					# subtract 2 more for the index of the fourth element 
		movl (%rsi, %rcx, 4), %r11d		# get the value of that element, rsi - start address of array

		xorl %r10d, %r11d				# xor the last two elements and store result in %r11d

		xorl %r9d, %r11d				# result after main connective xor (r9d - result of first two elements)
											# r11d - result of last two elements
		movl %r11d, %r8d		# store in r8d, because we need two copies of the original value
		shll $1, %r11d			# shift left once		
		shrl $31, %r8d			# get the first digit in last position 
		orl %r8d, %r11d			# bitwise or to complete the left rotation (rotation != bit shifting)

		movl %r11d, (%rsi, %rax, 4)				# assigning value to current element (w[i]), rsi - start address of array, rax - index

		incq %rax						# increment counter (i)
		jmp loop_extend_to_eighty_32_bit_words		# back to loop

	initialize_hash_values:
		# rdi - stores the memory location where h0 is stored
		# h1,h2,h3,h4 stored consecutively after h0
		# 4 bytes each
		movl (%rdi), %r8d				# a = h0
		movl 4(%rdi), %r9d				# b = h1
		movl 8(%rdi), %r10d				# c = h2
		movl 12(%rdi), %r11d			# d = h3
		movl 16(%rdi), %ecx				# e = h4
		
		movq $0, %rax					# counter for second loop (0 - 79)
	main_loop:
		cmpq $80, %rax					# compare with 80 (if it is 80 - break)
		je add_this_chunks_hash_to_results	# break loop

		check_1:						# checks in which interval is the counter
		cmpq $19, %rax
		jle case_1

		check_2:
		cmpq $39, %rax
		jle case_2

		check_3:
		cmpq $59, %rax
		jle case_3

		jmp case_4						# if not in the first three cases - then it's in the last case
		# a - r8d b - r9d c - r10d d - r11d e - ecx k - edx f - r13d
		case_1:
			# f(R13d) = (b and c) or ((not b) and d)
			# k(EDX) = 0x5A827999
			movl $0x5A827999, %edx 		# set k to specific value		

			movl %r9d, %r12d		# copy value of b to register r12d (TEMP register) - so we don't overwrite the values in a,b,c,d,e
			andl %r10d, %r12d		# bitwise and (b and c)

			movl %r9d, %r13d		# copy value to r13d (we store f in r13)
			notl %r13d				# (not (b))
			andl %r11d, %r13d		# (not b) and d

			orl %r12d, %r13d		# main connective and store value in r13d (f value stored there)

			jmp update_and_return_to_loop		# return to loop

		case_2:
			# f = b xor c xor d
			# k = 0x6ED9EBA1
			movl $0x6ED9EBA1, %edx

			movl %r10d, %r13d			# copy c value to r13d
			xorl %r9d, %r13d			# b xor c - store in r13d
			xorl %r11d, %r13d			# d xor (b xor c) and store in r13d (f value)

			jmp update_and_return_to_loop		# return to loop

		case_3:
			# f = (b and c) or (b and d) or (c and d) 
			# k = 0x8F1BBCDC
			movl $0x8F1BBCDC, %edx

			movl %r9d, %r12d			# copy to r12d (TEMP register)
			andl %r10d, %r12d			# b and c - stored in r12d

			movl %r9d, %r13d			# copy value
			andl %r11d, %r13d			# b and d - stored in r13d

			orl %r12d, %r13d			# (b and c) or (b and d) - stored in r13d

			movl %r10d, %r12d			# overwrite r12d as we don't need the previous value		
			andl %r11d, %r12d			# c and d - store in r12d		

			orl %r12d, %r13d			# (c and d) OR (b and c) or (b and d) - store in r13d(f value)

			jmp update_and_return_to_loop		# return to loop

		case_4:
			# f = b xor c xor d
			# k = 0xCA62C1D6
			movl $0xCA62C1D6, %edx
		
			movl %r10d, %r13d			# copy value to r13d
			xorl %r9d, %r13d			# b xor c - stored in r13d
			xorl %r11d, %r13d			# d xor (b xor c) and store in r13d (f value)


		update_and_return_to_loop:			# return to loop
			# a - r8d; b - r9d; c - r10d; d - r11d; e - ecx; k - edx; f - r13d; temp - r12d

			# temp = (a leftrotate 5) + f + e + k + w[i]
			# (a leftrotate 5)
			movl %r8d, %r12d
			movl %r8d, %r15d
			shll $5, %r15d
			shrl $27, %r12d
			orl %r15d, %r12d
			# all for (a leftrotate 5)


			# + f + e + k + w[i]
			addl %r13d, %r12d
			addl %ecx, %r12d
			addl %edx, %r12d
			addl (%rsi, %rax, 4), %r12d		# add w[i] - rsi start memory address of array, rax - index, scale coz 4 byte values
			# adding to (a leftrotate5)


			movl %r11d, %ecx  		# e = d (specific operation refer to Wikipedia)
			movl %r10d, %r11d		# d = c (specific operation refer to Wikipedia)

			# c = b leftrotate 30
			movl %r9d, %r14d		# r14d (TEMP register)
			movl %r9d, %r15d		# r15d (TEMP register)
			shll $30, %r15d
			shrl $2, %r14d
			orl %r15d, %r14d
			movl %r14d, %r10d		# assign to c

			movl %r8d, %r9d			# b = a (specific operation)

			movl %r12d, %r8d		# a = temp value we calculated (refer to WIKIPEDIA)

			incq %rax				# increment loop counter
			jmp main_loop			# back to loop

	add_this_chunks_hash_to_results:
		# rdi - address of h0 (h1,h2,h3,h4 - stored after each other, consecutively) 
		# each is 4 bytes, that's why the offset is a factor of 4
		addl %r8d, (%rdi)		# h0 = h0 + a
		addl %r9d, 4(%rdi)		# h1 = h1 + b
		addl %r10d, 8(%rdi)		# h2 = h2 + c
		addl %r11d, 12(%rdi)	# h3 = h3 + d
		addl %ecx, 16(%rdi)		# h4 = h4 + e

		popq %r15				# pop callee-saved registers
		popq %r14
		popq %r13
		popq %r12

		# epilogue
		movq %rbp, %rsp
		popq %rbp

	ret
