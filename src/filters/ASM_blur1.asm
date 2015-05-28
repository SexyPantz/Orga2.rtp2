; ************************************************************************* ;
; Organizacion del Computador II                                            ;
;                                                                           ;
;   Implementacion de la funcion Blur 1                                     ;
;                                                                           ;
; ************************************************************************* ;
extern malloc
extern free

section .data	
	mascara: dq 0x000000ff000000ff,0x00000000000000ff
	mascara_pixel: dq 0x00000000ffffffff, 0x0000000000000000
	constante_por_9: dq 0x00001c7200001c72,0x00001c7200001c72
	mascara_agregar_pixel: dq 0xffffffff00000000, 0x0000000000000000
	mascara_ultimo_pixel: dq 0x0000000000000000, 0xffffffffffffffff

section .text

; void ASM_blur1( uint32_t w, uint32_t h, uint8_t* data )
global ASM_blur1
ASM_blur1:
	;rdi = ancho de la imagen
	;rsi = altura de la imagen
	;rdx = puntero a la imagen
	
	push rbp
	mov rbp, rsp
	push rbx
	push r12
	push r13
	push r14
	push r15
	sub rbp, 8

 	ASM_blur1.settings:	
 		;Seteamos estas variables y backupeamos los parametros
 		mov rbx, rdi			; rbx <- ancho de la imagen en bytes
 		mov r12, rsi			; r12 <- altura de la imagen en bytes
 		mov r13, rdx				; r13 <- puntero de la imagen
 		ASM_blur1.settings.backUpData:	
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
 		ASM_blur1.settings.variables:
 			mov rcx, 0 				;rcx <- contador de filas
	 		mov r10, rbx			;r10 <- tamaño de la fila
	 		movdqu xmm8, [mascara]
	 		movdqu xmm9, [mascara_pixel]
	 		movdqu xmm10, [constante_por_9]
	 		movdqu xmm15, [mascara_agregar_pixel]
	 		movdqu xmm14, [mascara_ultimo_pixel]
	 		sub r10, 2				;r10 <- ancho de la imagen - 2 (para no procesar la ultima columna)
 		 	dec r12					;r12 <- alto de la imagen - 1 (para no procesar la ultima fila)

  	ASM_blur1.rowLoop:
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
 		
 		ASM_blur1.colLoop:
 			;Traemos el bloque con el pixel que vamos a procesar
 			movdqu xmm0, [r14+r9*4] ; xmm0 <- fila sobre el pixel a procesar
 			movdqu xmm1, [r15+r9*4]	; xmm1 <- fila del pixel a procesar
 			movdqu xmm2, [rax+r9*4]	; xmm2 <- fila debajo del pixel a procesar

	 	 	ASM_blur1.blue:

	 	 		movdqu xmm3, xmm0	; xmm3 <- fila anterior
 				movdqu xmm4, xmm1	; xmm4 <- fila a procesar
 				movdqu xmm5, xmm2	; xmm5 <- fila siguiente

				;Shifteo a la derecha 1 bit cada registro para quedarme con los primeros tres canales y elimino transparencias	 	 		
	 	 		psrldq xmm3, 1
	 	 		psrldq xmm4, 1
				psrldq xmm5, 1
		

 				;Me quedo con la parte azul de los pixeles del bloque
 				pand xmm3, xmm8
	  			pand xmm4, xmm8
 				pand xmm5, xmm8

		 		ASM_blur1.blue.average:
		 					;Sumo todos los pixeles
		 			paddd xmm3, xmm4 ; xmm3 <- xmm3 + xmm4  (x,y,z,w) <- (0,a1,a2,a3) + (0,b1,b2,b3)
		 			paddd xmm3, xmm5 ; xmm3 <- xmm3 + xmm5 (x,y,z,w) <- (0,a1+b1,a2+b2,a3+b3) + (0,c1,c2,c3)

		 			movdqu xmm4, xmm3	; xmm4 <- xmm3 : xmm4 <- (0,a1+b1+c1,a2+b2+c2,a3+b3+c3)
		 			psrldq xmm4, 4		; xmm4 <- (0,0,a1+b1+c1,a2+b2+c2)
		 			paddd xmm3, xmm4	; xmm3 <- xmm3 + xmm4 	(x,y,z,w) <- (0,a1+b1+c1,a2+b2+c2,a3+b3+c3) + (0,0,a1+b1+c1,a2+b2+c2)
		 			psrldq xmm4, 4		; xmm4 <- (0,0,0,a1+b1+c1)
		 			paddd xmm3, xmm4	; xmm3 <- xmm3 + xmm4	(x,y,z,w) <- (0,a1+b1+c1,a2+b2+c2,a3+b3+c3+a2+b2+c2) + (0,0,0,a1+b1+c1)
		 			;xmm3 <- (0,a1+b1+c1,a2+b2+c2,a3+b3+c3+a2+b2+c2+a1+b1+c1) : En xmm3[3] tengo la suma de todos los pixeles
		 			;Divido por 9
		 			pand xmm3, xmm9	
		 			pmuldq xmm3,xmm10
		 			psrldq xmm3, 2	
		 			pslldq xmm3, 1	
		 
		 	 ASM_blur1.green:
 			 	movdqu xmm4, xmm0	; xmm4 <- fila antrior
 			 	movdqu xmm5, xmm1	; xmm5 <- fila a procesar
 			 	movdqu xmm6, xmm2	; xmm6 <- fila siguiente

 				;Shifteo 2 byte para eliminar la parte azul y transparencia
 			 	psrldq xmm4, 2
 			 	psrldq xmm5, 2
 			 	psrldq xmm6, 2

 				;Me quedo con la parte verde de los pixeles del bloque
 			 	pand xmm4, xmm8
 			 	pand xmm5, xmm8
 			 	pand xmm6, xmm8

		 	 	ASM_blur1.green.average:
		 	 		;Sumo todos los pixeles
		 	 		paddd xmm4, xmm5 ; xmm4 <- xmm4 + xmm5  (x,y,z,w) <- (0,a1,a2,a3) + (0,b1,b2,b3)
		 	 		paddd xmm4, xmm6 ; xmm4 <- xmm4 + xmm5 (x,y,z,w) <- (0,a1+b1,a2+b2,a3+b3) + (0,c1,c2,c3)

		 	 		movdqu xmm5, xmm4	; xmm5 <- xmm4 : xmm5 <- (0,a1+b1+c1,a2+b2+c2,a3+b3+c3)
		 	 		psrldq xmm5, 4		; xmm5 <- (0,0,a1+b1+c1,a2+b2+c2)
		 	 		paddd xmm4, xmm5	; xmm4 <- xmm4 + xmm5 	(x,y,z,w) <- (0,a1+b1+c1,a2+b2+c2,a3+b3+c3) + (0,0,a1+b1+c1,a2+b2+c2)
		 	 		psrldq xmm5, 4		; xmm5 <- (0,0,0,a1+b1+c1)
		 	 		paddd xmm4, xmm5	; xmm4 <- xmm4 + xmm5	(x,y,z,w) <- (0,a1+b1+c1,a2+b2+c2,a3+b3+c3+a2+b2+c2) + (0,0,0,a1+b1+c1)
		 	 		;xmm4 <- (0,a1+b1+c1,a2+b2+c2,a3+b3+c3+a2+b2+c2+a1+b1+c1) : En xmm4[3] tengo la suma de todos los pixeles
		 	 		;Divido por 9
		 	 		pand xmm4, xmm9	
		 	 		pmuldq xmm4,xmm10
		 	 		psrldq xmm4, 2
		 	 		pslldq xmm4, 2
		 	
		 	 ASM_blur1.red:
 				movdqu xmm5, xmm0	; xmm5 <- fila antrior
 			 	movdqu xmm6, xmm1	; xmm6 <- fila a procesar
 			 	movdqu xmm7, xmm2	; xmm7 <- fila siguiente

 			 	;Shifteo 3 byte para eliminar la parte azul y la parte verde
 			 	psrldq xmm5, 3
 			 	psrldq xmm6, 3
 			 	psrldq xmm7, 3
 				
 			 	;Me quedo con la parte roja de los pixeles del bloque
 			 	pand xmm5, xmm8
 			 	pand xmm6, xmm8
 			 	pand xmm7, xmm8

		 	 	ASM_blur1.red.average:
		 	 		;Sumo todos los pixeles
		 	 		paddd xmm5, xmm6 ; xmm5 <- xmm5 + xmm6  (x,y,z,w) <- (0,a1,a2,a3) + (0,b1,b2,b3)
		 	 		paddd xmm5, xmm7 ; xmm5 <- xmm5 + xmm7 (x,y,z,w) <- (0,a1+b1,a2+b2,a3+b3) + (0,c1,c2,c3)

		 	 		movdqu xmm6, xmm5	; xmm 6 <- xmm5 : xmm6 <- (0,a1+b1+c1,a2+b2+c2,a3+b3+c3)
		 	 		psrldq xmm6, 4		; xmm6 <- (0,0,a1+b1+c1,a2+b2+c2)
		 	 		paddd xmm5, xmm6	; xmm5 <- xmm5 + xmm6 	(x,y,z,w) <- (0,a1+b1+c1,a2+b2+c2,a3+b3+c3) + (0,0,a1+b1+c1,a2+b2+c2)
		 	 		psrldq xmm6, 4		; xmm6 <- (0,0,0,a1+b1+c1)
		 	 		paddd xmm5, xmm6	; xmm5 <- xmm5 + xmm6	(x,y,z,w) <- (0,a1+b1+c1,a2+b2+c2,a3+b3+c3+a2+b2+c2) + (0,0,0,a1+b1+c1)
		 	 		;xmm5 <- (0,a1+b1+c1,a2+b2+c2,a3+b3+c3+a2+b2+c2+a1+b1+c1) : En xmm5[3] tengo la suma de todos los pixeles
		 	 		;Divido por 9
		 	 		pand xmm5, xmm9	
		 	 		pmuldq xmm5,xmm10
		 	 		psrldq xmm5, 2
		 	 		pslldq xmm5, 3

		 	movdqu xmm11, xmm1
		 	psrldq xmm11,4
		 	pand xmm11, xmm15
		 	paddsb xmm11, xmm3
		 	paddsb xmm11, xmm4
		 	paddsb xmm11, xmm5
		 	inc r9
		 	movdqu xmm12, [r13+r9*4]
		 	pand xmm12, xmm14
		 	paddsb xmm11, xmm12
		 	movdqu [r13+r9*4], xmm11
 			cmp r9, r10
 			je ASM_blur1.rowLoop	; termino el loop de la columnas y voy a procesar  la siguiente fila
		 	jmp ASM_blur1.colLoop

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