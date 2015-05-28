
; ************************************************************************* ;
; Organizacion del Computador II                                            ;
;                                                                           ;
;   Implementacion de la funcion Merge 1                                    ;
;                                                                           ;
; ************************************************************************* ;

; void ASM_merge1(uint32_t w, uint32_t h, uint8_t* data1, uint8_t* data2, float value)

global ASM_merge1

extern malloc

section .data

section .rodata

	mask_PixelByte: DD 0x000000ff,0x000000ff,0x000000ff,0x000000ff		; para analizar el ultimo byte del pixel
	mask_FloatOne: DD 0x3f800000,0x3f800000,0x3f800000,0x3f800000 		; todos 1 en punto flotante

section .text

ASM_merge1:

push rbp
mov rbp, rsp
push rbx
push r12
push r13
push r14
push r15
sub rbp, 8

 ; void ASM_merge1(uint32_t w, uint32_t h, uint8_t* data1, uint8_t* data2, float value)
 ; RDI <-uint32_t w (ancho de destino)
 ; RSI <-uint32_t h (altura de destino)
 ; RDX <-uint8_t* data1 (destino)
 ; RCX <-uint8_t* data2 (imagen input)
 ;
 ; XMM0 <- float value (value float )
 ;=====================MERGE 01 =====================
 ;ALGORITMO CATEDRA
 ;Forall j,i de imagen m1, m2 
 ;m1[j][i][k] = value * m1[j][i][k] + (1-value) * m2[j][i][k]


	 mov rbx, rdx 	;<-- backup de puntero a img. destino
	 mov r12, rcx 	;<-- backup de puntero a img. input
	 mov r13, rdi 	;<-- r13 contador

	 imul r13, rsi	;r13 = cantidad de pixeles
	 shl r13, 2 	;<-- tamaño en Bytes de la imagen (lo mismo que multiplicar por 4)
	 
	ASM_merge1.settings: 	; Prepara XMM1, XMM2 y XMM3 para usar a lo largo del ciclo
		movdqu xmm1, xmm0
		pslldq xmm1, 4
		addps xmm1, xmm0 
		pslldq xmm1, 4	
		addps xmm1, xmm0 
		pslldq xmm1, 4
		addps xmm1, xmm0 

		movdqu xmm2, [mask_FloatOne]
		subps xmm2, xmm1

		movdqu xmm3, [mask_PixelByte]

		;XMM1 = valor del merge para la 1ra img empaquetado 4 veces
		;XMM2 = 1 - XMM1, valor del merge para la 2da img
		;XMM3 = mascara para agarrar de a un byte de cada pixel

	 	 ASM_merge1.loopLoco:
			 	 cmp r13, 16
				 jl  ASM_merge1.END
			 	 sub r13, 16

			 	 movdqu xmm4, [rbx+r13] 	; XMM4 = pixeles de img destino a procesar para cada color
			 	 movdqu xmm5, [r12+r13] 	; XMM5 = pixeles de img input a procesar para cada color

			ASM_merge1.TRANS:				; Guardo la transparecia de la img destino original
			 	movdqu xmm6, xmm4 			; XMM6 = XMM4
			 	pand xmm6, xmm3				; Aplico la mascara para quedarme con las transaparencias de los cuatro pixeles
			 	movdqu xmm13, xmm6			; XMM13 = A de cada pixel

			ASM_merge1.BLUE:
			 	movdqu xmm6, xmm4			; XMM6 = XMM4
			 	movdqu xmm7, xmm5			; XMM7 = XMM5
				psrldq xmm6, 1				; Shifteamos ambos para dejar el Azul en el ultimo byte
				psrldq xmm7, 1

			 	pand xmm6, xmm3				; Aplicamos la mascara para quedarnos solo con el Azul
			 	pand xmm7, xmm3
			 	 
			 	cvtdq2ps xmm8, xmm6			; Transformamos a float cada valor para multiplicar
			 	cvtdq2ps xmm9, xmm7

			 	mulps xmm8, xmm1			; XMM8 = XMM8 * XMM1 (multiplico por el factor)
     		 	mulps xmm9, xmm2			; XMM9 = XMM9 * XMM2
			 	addps xmm8, xmm9			; XMM8 = XMM8 + XMM9 (merge de los pixeles por su factor)
			 	cvtps2dq xmm10, xmm8		; XMM10 = paso a los cuatro enteros empaquetados
			 	pslldq xmm10, 1				; Vuelvo a colocar los pixeles en sus posiciones originales, para que me quede el color que acabo de procesar en su lugar

			ASM_merge1.GREEN:
				movdqu xmm6, xmm4
			 	movdqu xmm7, xmm5
				psrldq xmm6, 2
				psrldq xmm7, 2

				pand xmm6, xmm3
			 	pand xmm7, xmm3	 	 

			 	cvtdq2ps xmm8, xmm6
			 	cvtdq2ps xmm9, xmm7

			 	mulps xmm8, xmm1
     		 	mulps xmm9, xmm2
			 	addps xmm8, xmm9
				cvtps2dq xmm11, xmm8	
				pslldq xmm11, 2

			ASM_merge1.RED:
				movdqu xmm6, xmm4
			 	movdqu xmm7, xmm5
				psrldq xmm6, 3
				psrldq xmm7, 3

     		 	pand xmm6, xmm3
			 	pand xmm7, xmm3

			 	cvtdq2ps xmm8, xmm6
			 	cvtdq2ps xmm9, xmm7

			 	mulps xmm8, xmm1
     		 	mulps xmm9, xmm2
			 	addps xmm8, xmm9
				cvtps2dq xmm12, xmm8
				pslldq xmm12, 3

				paddb xmm10, xmm11			; Sumo los XMM10, XMM11, XMM12 y XMM13 para tener cada pixel procesado, ya que cada uno tiene valor donde los otros tienen ceros
				paddb xmm10, xmm12
				paddb xmm10, xmm13
			 	movdqu [rbx+r13], xmm10		; Pongo el resultado en la img destino
			 	jmp  ASM_merge1.loopLoco

	ASM_merge1.END: 

				
add rbp, 8
pop r15
pop r14
pop r13
pop r12
pop rbx
pop rbp
ret

  ret












