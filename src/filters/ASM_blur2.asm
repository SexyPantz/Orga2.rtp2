; ************************************************************************* ;
; Organizacion del Computador II                                            ;
;                                                                           ;
;   Implementacion de la funcion Blur 2                                     ;
;                                                                           ;
; ************************************************************************* ;
extern malloc
extern free

section .data
	align 16
	mascara: dq 0x000000ff000000ff,0x000000ff000000ff
	mascara_ultimo_pixel: dq 0x0000000000000000, 0xffffffff00000000	
	mascara_ultimos_pixel: dq 0x0000000000000000, 0xffffffffffffffff	
	mascara_primeros_pixeles: dq 0xffffffffffffffff,0x0000000000000000	
	constante_por_9: dq 0x00001c7200001c72,0x00001c7200001c72

section .text
; void ASM_blur2( uint32_t w, uint32_t h, uint8_t* data )
global ASM_blur2
ASM_blur2:

	push rbp
	mov rbp, rsp
	push rbx
	push r12
	push r13
	push r14
	push r15
	sub rbp, 8
  
	ASM_blur2.settings:	
 		;Seteamos estas variables y backupeamos los parametros
 		mov rbx, rdi			; rbx <- ancho de la imagen en bytes
 		mov r12, rsi			; r12 <- altura de la imagen en bytes
 		mov r13, rdx				; r13 <- puntero de la imagen
 		ASM_blur2.settings.backUpData:	
 			;Reservamos memoria para las tres filas que vamos a traer para cada paso
 			lea rdi, [rbx*4+4] 		; rdi <- tamaño de una fila
 			call malloc 			; rax <- puntero a memoria para fila
	 		mov r14, rax			; r14 <- puntero a memoria para fila (Va a ser para la primera fila)
	 		lea rdi, [rbx*4+4]		; rdi <- tamaño de una fila
	 		call malloc				; rax <- puntero a memoria para fila
	 		mov r15, rax			; r15 <- puntero a memoria para fila (Va a ser para la segunda fila)
	 		lea rdi, [rbx*4+4]		; rdi <- tamaño de una fila
	 		call malloc				; rax <- puntero a memoria para una fila (Va a ser para la tercera)
	 		;Copiamos la primera y segunda fila
	 		mov rdi, r13			;rdi <- puntero a la primer fila de la imagen
	 		mov rsi, r15			;rsi <-ASM_blur1.fin puntero a segunda memoria reservada
 			mov rdx, rbx
 			call copy_row			;Copio en r15 la primer fila de la imagen
 			lea rdi, [r13+rbx*4]	;rdi <- puntero a la segunda fila de la imagen
 			mov rsi, rax			;rsi <- puntero a memoria para tercer
 			mov rdx, rbx			;rax <- puntero a la tercer memoria reservada
 			call copy_row			;Copio en rax la segunda fila de la imagen
 		ASM_blur2.settings.variables:
 			mov rcx, 0 				;rcx <- contador de filas
	 		mov r10, rbx			;r10 <- tamaño de la fila
	 		sub r10, 4				;r10 <- ancho de la imagen - 2 (para no procesar la ultima columna)
 		 	dec r12					;r12 <- alto de la imagen - 1 (para no procesar la ultima fila)

ASM_blur2.rowLoop:
  		lea r13, [r13+rbx*4]		;r13 <- fila a procesar
 		inc rcx						;rcx <- rcx + 1
 		cmp rcx, r12				;si rcx == alto_imagen then
 		je ASM_blur1.fin 			;termino la funcion

 		;Muevo las columnas
 		mov r8, r14				; r8  <- primera fila
 		mov r14, r15			; r14 <- segunda fila
 		mov r15, rax			; r15 <- tercera fila
 		mov rax, r8				; rax <- primera fila
 		;Copio la fila que me falta para procesar la fila que queremos procesar
 		lea rdi, [r13+rbx*4]	; rdi <- la fila que le sigue a la que quiero procesar
 		mov rsi, rax			; rsi <- puntero a la tercer posicion de memoria reservada
 		mov rdx, rbx
 		call copy_row			; Copio en rax la nueva fila
 		
 		xor r9, r9  			;Seteo el contador de columnas a 0

 		ASM_blur2.colLoop:
 			movdqu xmm0, [r14+r9*4] ; xmm0 <- p00, p01, p02, p03
 			movdqu xmm1, [r15+r9*4]	; xmm1 <- p10, p11, p12, p13
 			movdqu xmm2, [rax+r9*4]	; xmm2 <- p20, p21, p22, p23
 			
 			cmp r9, r10
 			je ASM_blur2.process_two_pixels
 			;Traemos el bloque con los pixeles que vamos a procesar

 			movdqu xmm3, [r14+r9*4+8] ;xmm3 <- p02, p03, p04, p05
 			movdqu xmm4, [r15+r9*4+8] ;xmm4 <- p12, p13, p14, p15
 			movdqu xmm5, [rax+r9*4+8] ;xmm5 <- p22, p23, p24, p25

 			ASM_blur2.blue:
 				movdqu xmm6, xmm0
 				psrldq xmm6, 1
 				pand xmm6, [mascara] ;xmm6 <- primer fila

 				movdqu xmm7, xmm1
 				psrldq xmm7, 1
 				pand xmm7, [mascara]
 				paddd xmm6, xmm7 ;xmm6 <- primera fila mas segunda fila

 				movdqu xmm7, xmm2
 				psrldq xmm7, 1
 				pand xmm7, [mascara]
 				paddd xmm6, xmm7
 				;Hasta aca obtuve en xmm6 <- b00+b10+b20  b01+b11+b21  b02+b12+b22  b03+b13+b23
 				movdqu xmm7, xmm6
 				psrldq xmm7, 4
 				paddd xmm6, xmm7
 				;xmm6 <-  b00+b10+b20+b01+b11+b21 b01+b11+b21+b02+b12+b22 b02+b12+b22+b03+b13+b23 b03+b13+b23
 				movdqu xmm8, xmm3
 				psrldq xmm8, 1
 				pand xmm8, [mascara]
 				;xmm8 <- b02 b03 b04 b05
 				movdqu xmm7, xmm4
 				psrldq xmm7, 1
 				pand xmm7, [mascara]
 				paddd xmm8, xmm7
 				;xmm8 <- b02+b12 b03+b13 b04+b14 b05+b15
 				movdqu xmm7, xmm5
 				psrldq xmm7, 1
 				pand xmm7, [mascara]
 				paddd xmm8, xmm7
 				;xmm78 <- b02+b12+b22 b03+b13+b23 b04+b14+b24 b05+b15+b25
 				paddd xmm6, xmm8
 				;xmm6 <- b00+b10+b20+b01+b11+b21+b02+b12+b22  b01+b11+b21+b02+b12+b22+b03+b13+b23  b02+b12+b22+b03+b13+b23+b04+b14+b24  b03+b13+b23+b05+b15+b25
 				movdqu xmm7, xmm8
 				pslldq xmm7, 4
 				pand xmm7, [mascara_ultimo_pixel]
 				paddd xmm6, xmm7
 				;xmm6 <- b00+b10+b20+b01+b11+b21+b02+b12+b22  b01+b11+b21+b02+b12+b22+b03+b13+b23  b02+b12+b22+b03+b13+b23+b04+b14+b24  b03+b13+b23+b04+b14+b24+b05+b15+b25
 				;Divido por 9
		 		pmulld xmm6, [constante_por_9]
		 		psrld xmm6, 16	
		 		pslldq xmm6, 1

		 	ASM_blur2.green:
 				movdqu xmm7, xmm0
 				psrldq xmm7, 2
 				pand xmm7, [mascara] ;xmm7 <- primer fila

 				movdqu xmm8, xmm1
 				psrldq xmm8, 2
 				pand xmm8, [mascara]
 				paddd xmm7, xmm8 ;xmm7 <- primera fila mas segunda fila

 				movdqu xmm8, xmm2
 				psrldq xmm8, 2
 				pand xmm8, [mascara]
 				paddd xmm7, xmm8
 				;Hasta aca obtuve en xmm7 <- b00+b10+b20  b01+b11+b21  b02+b12+b22  b03+b13+b23
 				movdqu xmm8, xmm7
 				psrldq xmm8, 4
 				paddd xmm7, xmm8
 				;xmm7 <-  b00+b10+b20+b01+b11+b21 b01+b11+b21+b02+b12+b22 b02+b12+b22+b03+b13+b23 b03+b13+b23
 				movdqu xmm9, xmm3
 				psrldq xmm9, 2
 				pand xmm9, [mascara]
 				;xmm9 <- b02 b03 b04 b05
 				movdqu xmm8, xmm4
 				psrldq xmm8, 2
 				pand xmm8, [mascara]
 				paddd xmm9, xmm8
 				;xmm9 <- b02+b12 b03+b13 b04+b14 b05+b15
 				movdqu xmm8, xmm5
 				psrldq xmm8, 2
 				pand xmm8, [mascara]
 				paddd xmm9, xmm8
 				;xmm88 <- b02+b12+b22 b03+b13+b23 b04+b14+b24 b05+b15+b25
 				paddd xmm7, xmm9
 				;xmm7 <- b00+b10+b20+b01+b11+b21+b02+b12+b22  b01+b11+b21+b02+b12+b22+b03+b13+b23  b02+b12+b22+b03+b13+b23+b04+b14+b24  b03+b13+b23+b05+b15+b25
 				movdqu xmm8, xmm9
 				pslldq xmm8, 4
 				pand xmm8, [mascara_ultimo_pixel]
 				paddd xmm7, xmm8
 				;xmm7 <- b00+b10+b20+b01+b11+b21+b02+b12+b22  b01+b11+b21+b02+b12+b22+b03+b13+b23  b02+b12+b22+b03+b13+b23+b04+b14+b24  b03+b13+b23+b04+b14+b24+b05+b15+b25
 				;Divido por 9
		 		pmulld xmm7, [constante_por_9]
		 		psrld xmm7, 16	
		 		pslldq xmm7, 2

		 	ASM_blur2.red:
 				movdqu xmm8, xmm0
 				psrldq xmm8, 3
 				pand xmm8, [mascara] ;xmm8 <- primer fila

 				movdqu xmm9, xmm1
 				psrldq xmm9, 3
 				pand xmm9, [mascara]
 				paddd xmm8, xmm9 ;xmm8 <- primera fila mas segunda fila

 				movdqu xmm9, xmm2
 				psrldq xmm9, 3
 				pand xmm9, [mascara]
 				paddd xmm8, xmm9
 				;Hasta aca obtuve en xmm8 <- b00+b10+b20  b01+b11+b21  b02+b12+b22  b03+b13+b23
 				movdqu xmm9, xmm8
 				psrldq xmm9, 4
 				paddd xmm8, xmm9
 				;xmm8 <-  b00+b10+b20+b01+b11+b21 b01+b11+b21+b02+b12+b22 b02+b12+b22+b03+b13+b23 b03+b13+b23
 				movdqu xmm10, xmm3
 				psrldq xmm10, 3
 				pand xmm10, [mascara]
 				;xmm10 <- b02 b03 b04 b05
 				movdqu xmm9, xmm4
 				psrldq xmm9, 3
 				pand xmm9, [mascara]
 				paddd xmm10, xmm9
 				;xmm10 <- b02+b12 b03+b13 b04+b14 b05+b15
 				movdqu xmm9, xmm5
 				psrldq xmm9, 3
 				pand xmm9, [mascara]
 				paddd xmm10, xmm9
 				;xmm98 <- b02+b12+b22 b03+b13+b23 b04+b14+b24 b05+b15+b25
 				paddd xmm8, xmm10
 				;xmm8 <- b00+b10+b20+b01+b11+b21+b02+b12+b22  b01+b11+b21+b02+b12+b22+b03+b13+b23  b02+b12+b22+b03+b13+b23+b04+b14+b24  b03+b13+b23+b05+b15+b25
 				movdqu xmm9, xmm10
 				pslldq xmm9, 4
 				pand xmm9, [mascara_ultimo_pixel]
 				paddd xmm8, xmm9
 				;xmm8 <- b00+b10+b20+b01+b11+b21+b02+b12+b22  b01+b11+b21+b02+b12+b22+b03+b13+b23  b02+b12+b22+b03+b13+b23+b04+b14+b24  b03+b13+b23+b04+b14+b24+b05+b15+b25
 				;Divido por 9
		 		pmulld xmm8, [constante_por_9]
		 		psrld xmm8, 16	
		 		pslldq xmm8, 3

			 	movdqu xmm11, xmm6
			 	paddsb xmm11, xmm7
		 		paddsb xmm11, xmm8
			 	inc r9
			 	movdqu [r13+r9*4], xmm11
			 	add r9, 3
			 	jmp ASM_blur2.colLoop

		ASM_blur2.process_two_pixels:
		 		ASM_blur2.process_two_pixels.blue:
	 				movdqu xmm6, xmm0
	 				psrldq xmm6, 1
	 				pand xmm6, [mascara]

	 				movdqu xmm7, xmm1
	 				psrldq xmm7, 1
	 				pand xmm7, [mascara]
	 				paddd xmm6, xmm7

	 				movdqu xmm7, xmm2
	 				psrldq xmm7, 1
	 				pand xmm7, [mascara]
	 				paddd xmm6, xmm7
	 				;Hasta aca obtuve en xmm6 <- b00+b10+b20  b01+b11+b21  b02+b12+b22  b03+b13+b23
	 				
	 				movdqu xmm7, xmm6
	 				psrldq xmm7, 4
	 				;xmm7 <- b01+b11+b21  b02+b12+b22  b03+b13+b23
	 				movdqu xmm8, xmm7
	 				psrldq xmm8, 4
	 				;xmm8 <- b02+b12+b22  b03+b13+b23
	 				paddd xmm6, xmm7
	 				paddd xmm6, xmm8
	 				;xmm6 <- b00+b10+b20+b01+b11+b21+b02+b12+b22  b01+b11+b21+b02+b12+b22+b03+b13+b23  b02+b12+b22+b03+b13+b23  b03+b13+b23
	 				;Divido por 9
		 			pmulld xmm6, [constante_por_9]
		 			psrld xmm6, 16	
		 			pslldq xmm6, 1

		 		ASM_blur2.process_two_pixels.green:
	 				movdqu xmm7, xmm0
	 				psrldq xmm7, 2
	 				pand xmm7, [mascara]

	 				movdqu xmm8, xmm1
	 				psrldq xmm8, 2
	 				pand xmm8, [mascara]
	 				paddd xmm7, xmm8

	 				movdqu xmm8, xmm2
	 				psrldq xmm8, 2
	 				pand xmm8, [mascara]
	 				paddd xmm7, xmm8
	 				;Hasta aca obtuve en xmm7 <- b00+b10+b20  b01+b11+b21  b02+b12+b22  b03+b13+b23
	 				
	 				movdqu xmm8, xmm7
	 				psrldq xmm8, 4
	 				;xmm8 <- b01+b11+b21  b02+b12+b22  b03+b13+b23
	 				movdqu xmm9, xmm8
	 				psrldq xmm9, 4
	 				;xmm9 <- b02+b12+b22  b03+b13+b23
	 				paddd xmm7, xmm8
	 				paddd xmm7, xmm9
	 				;xmm7 <- b00+b10+b20+b01+b11+b21+b02+b12+b22  b01+b11+b21+b02+b12+b22+b03+b13+b23  b02+b12+b22+b03+b13+b23  b03+b13+b23
	 				;Divido por 9
		 			pmulld xmm7, [constante_por_9]
		 			psrld xmm7, 16	
		 			pslldq xmm7, 2

		 		ASM_blur2.process_two_pixels.red:
	 				movdqu xmm8, xmm0
	 				psrldq xmm8, 3
	 				pand xmm8, [mascara]

	 				movdqu xmm9, xmm1
	 				psrldq xmm9, 3
	 				pand xmm9, [mascara]
	 				paddd xmm8, xmm9

	 				movdqu xmm9, xmm2
	 				psrldq xmm9, 3
	 				pand xmm9, [mascara]
	 				paddd xmm8, xmm9
	 				;Hasta aca obtuve en xmm8 <- b00+b10+b20  b01+b11+b21  b02+b12+b22  b03+b13+b23
	 				
	 				movdqu xmm9, xmm8
	 				psrldq xmm9, 4
	 				;xmm9 <- b01+b11+b21  b02+b12+b22  b03+b13+b23
	 				movdqu xmm10, xmm9
	 				psrldq xmm10, 4
	 				;xmm10 <- b02+b12+b22  b03+b13+b23
	 				paddd xmm8, xmm9
	 				paddd xmm8, xmm10
	 				;xmm8 <- b00+b10+b20+b01+b11+b21+b02+b12+b22  b01+b11+b21+b02+b12+b22+b03+b13+b23  b02+b12+b22+b03+b13+b23  b03+b13+b23
	 				;Divido por 9
		 			pmulld xmm8, [constante_por_9]
		 			psrld xmm8, 16	
		 			pslldq xmm8, 3

		 			movdqu xmm11, xmm6
			 		paddsb xmm11, xmm7
		 			paddsb xmm11, xmm8
		 					
			 		inc r9
			 		movdqu xmm12, [r13+r9*4]
			 		pand xmm11, [mascara_primeros_pixeles]
			 		pand xmm12, [mascara_ultimos_pixel]
			 		paddsb xmm11, xmm12
			 		movdqu [r13+r9*4], xmm11
	 				jmp ASM_blur2.rowLoop	; termino el loop de la columnas y voy a procesar  la siguiente fila

 	ASM_blur1.fin:
 		mov rbx, rax
 		mov rdi, r14
 		call free
 		mov rdi, r15
 		call free
 		mov rdi, rbx
 		call free

  	add rbp, 8
	pop r15
	pop r14
	pop r13		
	pop r12
	pop rbx
	pop rbp
	ret


	copy_row:
	;rdi = puntero a la fila se quiere copiar
	;rsi = puntero a donde copiar
	;rdx = ancho de la imagen
	push rbp
	mov rbp,rsp
	push rbx
	sub rbp, 8

	mov rbx, 0
	imul rdx, 4
	copy_row.Loop:
		;Copio de a 16 bytes en la memoria de destino
		movdqu xmm0, [rdi+rbx]
		movdqu [rsi+rbx], xmm0
		;Avanzo en el loop
		add rbx, 16				; rbx <- rbx+1
		cmp rbx, rdx	; Si rbx == ancho_imagen
		je copy_row.fin 		; termino
		jmp copy_row.Loop 		; sino sigo con el loop

	copy_row.fin:
	mov [rsi+rbx], dword 0	
	add rbp, 8
	pop rbx
	pop rbp
	ret