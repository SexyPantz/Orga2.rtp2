; ************************************************************************* ;
; Organizacion del Computador II                                            ;
;                                                                           ;
;   Implementacion de la funcion Merge 2                                    ;
;                                                                           ;
; ************************************************************************* ;

; void ASM_merge2(uint32_t w, uint32_t h, uint8_t* data1, uint8_t* data2, float value)


; 0x3B9ACA00 

global ASM_merge2

extern malloc

section .data
	;10ala9: DD 0x3B9ACA00
	;2ala30: DD 0x40000000
	;2ala30: DD 0x4e800000,

section .rodata
	; 10ala9: DD 0x3B9ACA00
	; 2ala30: DD 0x40000000
	; 2ala30: DD 0x4e800000
	; menos1: DD 0x3f800000
	mask_PixelByte: DD 0x000000ff,0x000000ff,0x000000ff,0x000000ff

	mask_2ala30SF: DD 0x4b800000,0x00000000,0x00000000,0x00000000; {2^24,0,0,0} en Single P Float
					  
	mask_1enSFlot: DD 0x3f800000,0x00000000,0x00000000,0x00000000; {1,0,0,0} en Sinle P Flaot

	mask_Clean1n3: DD 0xffffffff,0xffffffff,0x00000000,0x00000000


section .text


ASM_merge2:

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
 ;===================== MERGE 02 =====================
 ;ALGORITMO CATEDRA
 ;Forall j,i de imagen m1, m2 
 ;m1[j][i][k] = value * m1[j][i][k] + (1-value) * m2[j][i][k]

 	ASM_merge2.Settings:

	 mov rbx, rdx 	;<-- backup de puntero a img. destino
	 mov r12, rcx 	;<-- backup de puntero a img. input
	 mov r13, rdi 	;<-- r13 contador

	 imul r13, rsi	;r13 = cantidad de pixeles
	 shl r13, 2 	;<-- tamaño en Bytes de la imagen (lo mismo que multiplicar por 4)
	 
	 movdqu xmm3, [mask_PixelByte]
	 movdqu xmm13, [mask_Clean1n3]
	 pxor xmm10, xmm10

		 	ASM_merge2.ValueAUnsigInt:

		 		ASM_merge2.VmenosUnoPorK:

			 		movdqu xmm2, [mask_1enSFlot]
			 		subps xmm2, xmm0 
			 		

			 		movdqu xmm1, [mask_2ala30SF]
			 		mulps xmm1, xmm2
			 		
			 		movdqu xmm2, xmm1
			 		pslldq xmm1, 4
					addps xmm1, xmm2 
					pslldq xmm1, 4	
					addps xmm1, xmm2 
					pslldq xmm1, 4
					addps xmm1, xmm2 

					cvtps2dq xmm9, xmm1 ;tengo los cuatro valores de V pasados a unsing Int
					movdqu  xmm2, xmm9 ;


				ASM_merge2.VporK:

					movdqu xmm1, [mask_2ala30SF]
			 		mulps xmm1, xmm0

			 		movdqu xmm0, xmm1
			 		pslldq xmm1, 4
					addps xmm1, xmm0 
					pslldq xmm1, 4	
					addps xmm1, xmm0 
					pslldq xmm1, 4
					addps xmm1, xmm0 

					cvtps2dq xmm8, xmm1
					movdqu xmm1, xmm8


	ASM_merge2.loopLoco:


	 cmp r13, 16
	 jl  ASM_merge2.END
	 sub r13, 16
 	 movdqu xmm4, [rbx+r13] 
 	 movdqu xmm5, [r12+r13] 

		 ASM_merge2.TRANS:
			 	movdqu xmm6, xmm4 			; XMM6 = XMM4
			 	pand xmm6, xmm3				; Aplico la mascara para quedarme con las transaparencias de los cuatro pixeles
			 	movdqa xmm15, xmm6			; XMM13 = A de cada pixel


	 			ASM_merge2.BLUE:

			 		movdqu xmm6, xmm4
					movdqu xmm7, xmm5


					psrldq xmm6, 1
					psrldq xmm7, 1
					pand xmm6, xmm3
					pand xmm7, xmm3 


					; PMULUDQ xmm6, xmm8
					pmulld xmm6, xmm8
					pmulld xmm7, xmm9

					; PADDSW xmm6, xmm7
					paddd xmm6, xmm7
					psrld xmm6, 24
					pslldq xmm6, 1
					movdqu xmm10, xmm6	
	 		
			  	ASM_merge2.GREEN:

			 		movdqu xmm6, xmm4
					movdqu xmm7, xmm5


					psrldq xmm6, 2
					psrldq xmm7, 2
					pand xmm6, xmm3
					pand xmm7, xmm3 


					pmulld xmm6, xmm8
					pmulld xmm7, xmm9

					PADDD xmm6, xmm7
					psrld xmm6, 24
					pslldq xmm6, 2
					movdqu xmm11, xmm6

				ASM_merge2.RED:

			 		movdqu xmm6, xmm4
					movdqu xmm7, xmm5


					psrldq xmm6, 3
					psrldq xmm7, 3
					pand xmm6, xmm3
					pand xmm7, xmm3 

					pmulld xmm6, xmm8
					pmulld xmm7, xmm9

					PADDD xmm6, xmm7
					psrld xmm6, 24
					pslldq xmm6, 3
					movdqu xmm12, xmm6
	



				paddd xmm10, xmm11			; Sumo los XMM10, XMM11, XMM12 y XMM13 para tener cada pixel procesado, ya que cada uno tiene valor donde los otros tienen ceros
				paddd xmm10, xmm12
				paddd xmm10, xmm15	
			 	movdqu [rbx+r13], xmm10		; Pongo el resultado en la img destino
				jmp  ASM_merge2.loopLoco
 		
	ASM_merge2.END: 
	 	
add rbp, 8
pop r15
pop r14
pop r13
pop r12
pop rbx
pop rbp
ret

