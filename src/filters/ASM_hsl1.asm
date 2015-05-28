; ************************************************************************* ;
; Organizacion del Computador II                                            ;
;                                                                           ;
;   Implementacion de la funcion HSL 1                                      ;
;                                                                           ;
; ************************************************************************* ;

global ASM_hsl1

extern rgbTOhsl
extern hslTOrgb
extern malloc
extern free

section .rodata
	align 16
	mask_1_1_360_0: dd 0, 360.0, 1.0, 1.0
	mask_0_0_360_0: dd 0, 360.0, 0,0
	mask_1_1_m360_0: dd 0, -360.0, 1.0, 1.0
	mask_ceros: dd 0, 0, 0, 0
	mask_h: dd 0, 0xFFFFFFFF,  0, 0
	mask_lastDouble: dd 0xFFFFFFFF, 0, 0, 0 
	full_mask: dd 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF

section .text


ASM_hsl1:
	push rbp
	mov rbp, rsp
	push rbx
	push r12
	push r13
	push r14
	push r15
	sub rbp, 8

	mov rbx, rdi 	; backup del ancho
	mov r12, rsi	; backup de la altura
	mov r13, rdx	; backup del puntero a la imagen

	imul rbx, r12	; rbx = tamaño de la imagen en pixeles
	
	movdqu xmm15, [mask_lastDouble]
	pand xmm0, xmm15
	pand xmm1, xmm15
	pand xmm2, xmm15
	
	pslldq xmm0, 4	; xmm0 <- 0 0 H 0
	pslldq xmm1, 8
	pslldq xmm2, 12
	addps xmm0, xmm1 ; xmm0 <- L 0 H 0 
	addps xmm0, xmm2 ; XMM0 = L S H 0

	mov rdi, 16		; Reservo memoria para los pixeles convertidos
	call malloc
	mov r14, rax	; backup del puntero a los floats

	xor r12, r12	; r12 = contador para recorrer la imagen


	ASM_hsl1.LoopLoco:
		ASM_65hsl1.rgbTOhsl:
		;void rgbTOhsl(uint8_t *src, float *dst)
		; RDI <--- puntero a la imagen
		; RSI <--- puntero a los tres floats HSL del pixel convertido

		sub rsp, 16	
		movdqu [rsp], xmm0	; "meto en la pila a xmm0"

		lea rdi, [r13]	; RDI == puntero a la imagen
		mov rsi, r14			; RSI == puntero a los floats
		call rgbTOhsl			; Convierto el pixel a hsl y lo guardo en [r14]
		
		movdqu xmm0, [rsp]
		add rsp, 16			;"Saco de la pila a xmm0"


	ASM_hsl1.transformacion:	
		movdqu xmm1, [r14]		; xmm1 <- pixel convertido L S H A
		addps xmm1, xmm0		; XMM1 <- l+LL, s+SS, h+HH, A
		
		vcmpps xmm2, xmm1, [mask_1_1_360_0], 5	  	; Me fijo si esto es mayor al maximo
		vcmpps xmm3, xmm1, [mask_ceros], 2		; Me fijo si esto es menor al minimo
		vpxor xmm4, xmm2,xmm3					; "Sumo xmm2 y xmm3"
		pxor xmm4, [full_mask]
		; Me fijo que cosas entraron en el ultimo caso
		movdqu  xmm5, [mask_h]
		pand xmm5, xmm1	
		movdqu xmm6, xmm5						; xmm6 <- 0,0,h+HH,0
		addps xmm5,	[mask_1_1_m360_0] 			;xmm5 <- 1,1,h+HH-360,0	 (Caso maximo)
		addps xmm6, [mask_0_0_360_0]			;xmm6 <- 0,0,h+hh+360,0  (Caso minimo)

	;Hasta acá tengo en xmm0 <- (l+LL, s+SS, h+HH, 0) ultimo caso; xmm5 <- (1,1,h+HH-360,0) primer caso; xmm6 <-(0,0,h+HH+360,0) segundo caso
		pand xmm5, xmm2		;Me quedo en xmm5 con los que cumplen la primer condicion
		pand xmm6, xmm3		;Me quedo en xmm6 con los que cumplen la segunda condicion
		pand xmm1, xmm4		;Me quedo en xmm0 con los que no cumplen ninguna condicion

		paddd xmm5, xmm6
		paddd xmm5, xmm1	;Tengo los valores del pixel
		movdqu [r14], xmm5

		ASM_hsl1.hslTOrgb:
			; void hslTOrgb(float *src, uint8_t *dst)
			sub rsp, 16	
			movdqu [rsp], xmm0	; "meto en la pila a xmm0"

			mov rdi, r14
			lea rsi, [r13]
			call hslTOrgb

			movdqu xmm0, [rsp]	
			add rsp, 16			;"Saco de la pila a xmm0"

			inc r12
			cmp r12, rbx
			je ASM_hsl1.END	

			add r13, 4
			jmp ASM_hsl1.LoopLoco




	ASM_hsl1.END:

	mov rdi, r14
	call free

	add rbp, 8
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
	ret