segment code
..start:
	; iniciar os registros de segmento DS e SS e o ponteiro de pilha SP
	mov 	ax,data
	mov 	ds,ax
	mov 	ax,stack
	mov 	ss,ax
	mov 	sp,stacktop
    call 	video_setup

    mov		byte[cor],branco_intenso
	call	draw_menu_lines
	call	write_menu_names
	call	initialize_mouse
	jmp 	main

sair:
	call 	video_close
    mov 	ah, 4ch
	int 	21h

main:
	call	delay
	; mov		ah, 01h
    ; int		16h
    ; jnz 	sair
	mov		ax, 03h
	int		33h
	test	bx, 01h
	jz		main
	cmp		cx, 65
	jg		main
	sub		dx, 80
	jle		click_abrir
	sub		dx, 80
	jle		click_fir1
	sub		dx, 80
	jle		click_fir2
	sub		dx, 80
	jle		click_fir3
	sub		dx, 80
	jle		click_histograma
	sub		dx, 80
	jmp		sair

write_menu_names:
	call	write_abrir
	call	write_fir1
	call	write_fir2
	call	write_fir3
	call	write_histograma
	call	write_sair
	call	write_nome
	ret

click_abrir:
	mov		byte[cor], branco_intenso
	call	write_menu_names
	mov		byte[cor], amarelo
	call	abrir_function
	jmp 	main

click_fir1:
	mov		byte[cor], branco_intenso
	call	write_menu_names
	mov		byte[cor], amarelo
	call	fir1_function
	jmp		main

click_fir2:
	mov		byte[cor], branco_intenso
	call	write_menu_names
	mov		byte[cor], amarelo
	call	fir2_function
	jmp		main

click_fir3:
	mov		byte[cor], branco_intenso
	call	write_menu_names
	mov		byte[cor], amarelo
	call	fir3_function
	jmp		main

click_histograma:
	mov		byte[cor], branco_intenso
	call	write_menu_names
	mov		byte[cor], amarelo
	call	histograma_function
	jmp		main

initialize_mouse:
	mov 	ax, 0001h
    int 	33h
	ret

abrir_function:
	call	write_abrir
	cmp		byte[aberto], 1
	je		fechar
	call	read_txt
	call	convert_vector_to_int
	call	plot_sinal_original
	call	plot_histograma_original
	mov		byte[aberto], 1
	ret
fechar:
	mov		byte[cor], preto
	call	plot_sinal_original
	call	plot_sinal_filtrado
	call	zero_sinais
	mov		byte[aberto], 0
	ret

zero_sinais:
	mov		si, 0
	mov		cx, 2048
.loop
	mov		byte[int_sinal_array+si], 0
	mov		byte[sinal_array+si], 0
	mov		byte[sinal_filtrado+si], 0
	inc		si
	loop	.loop
	mov		byte[sinal_array], '$'
	mov		word[sinal_size], 0
	ret

fir1_function:
	call	write_fir1
	cmp 	byte[aberto], 0
	je		fechar_fir1
	mov		byte[cor], preto
	call	plot_sinal_filtrado
	mov		byte[cor], verde
	mov		word[filter_width], 6
	call	calculate_convolution
	call	plot_sinal_filtrado
fechar_fir1
	ret

fir2_function:
	call	write_fir2
	cmp 	byte[aberto], 0
	je		fechar_fir2
	mov		byte[cor], preto
	call	plot_sinal_filtrado
	mov		byte[cor], verde
	mov		word[filter_width], 11
	call	calculate_convolution
	call	plot_sinal_filtrado
fechar_fir2:
	ret

fir3_function:
	call	write_fir3
	cmp 	byte[aberto], 0
	je		fechar_fir3
	mov		byte[cor], preto
	call	plot_sinal_filtrado
	mov		byte[cor], verde
	mov		word[filter_width], 18
	call	calculate_convolution
	call	plot_sinal_filtrado
fechar_fir3:
	ret

histograma_function:
	call	write_histograma
	ret

read_txt:
	; Open file
    mov 	ah, 3dh
    mov 	al, 0
    mov 	dx, filename
    int 	21h
	mov		[handle], ax

	; Read 2048 byte from file (read all at once)
	mov 	ah, 3fh
	mov 	bx, [handle]
	mov 	cx, 2048
	mov 	dx, sinal_array
	int 	21h

	mov		bx, ax
	mov		byte[sinal_array+bx], '$'

	; Close file
	mov 	ah, 3eh
	mov 	bx, [handle]
	int 	21h
	ret

convert_vector_to_int:
    mov 	di, 0
    mov 	si, 0
	mov 	word[sinal_size], 0
	mov 	ch, 0
	mov 	ax, 0

.convert_number:
    mov 	cl, byte[sinal_array+si]
    inc 	si
    cmp 	cl, '$'
    je 		.end

    ; Check for sign
    mov 	ax, 0
    cmp 	cl, '-'
    je 		.convert_negative
	jmp 	.convert_positive

.convert_negative:
	mov 	cl, byte[sinal_array+si]
	inc 	si
	cmp 	cl, 10
	je 		.store_number
	sub 	cl, '0'
	mov 	ch, 0
	imul 	ax, 10
	sub 	ax, cx
	jmp 	.convert_negative

.convert_positive:
	sub 	cl, '0'
	mov 	ch, 0
	add 	ax, cx
.next_positive_digit:
	mov 	cl, byte[sinal_array+si]
	inc 	si
	cmp 	cl, 10
	je 		.store_number
	sub 	cl, '0'
	mov 	ch, 0
	imul 	ax, 10
	add 	ax, cx
	jmp 	.next_positive_digit

.store_number:
	mov 	[int_sinal_array+di], al
	inc 	di
	jmp 	.convert_number

.end:
	mov 	[sinal_size], di
    ret

plot_sinal_original:
	mov 	si, 0
.loop
	mov 	ax, si
	add 	ax, 66
	push 	ax
	mov 	al, byte[int_sinal_array+si]
	cbw
	imul 	ax, 7
	sar 	ax, 3
	add 	ax, 365
	push 	ax
	call 	plot_xy
	inc 	si
	cmp 	si, [sinal_size]
	jl 		.loop
	ret

plot_sinal_filtrado:
	mov 	si, 0
.loop
	mov 	ax, si
	add 	ax, 66
	push 	ax
	mov 	al, byte[sinal_filtrado+si]
	cbw
	imul 	ax, 20
	sar 	ax, 5
	add 	ax, 165
	push 	ax
	call 	plot_xy
	inc 	si
	cmp 	si, [sinal_size]
	jl 		.loop
	ret

calculate_convolution:
	mov 	cx, [filter_width]
	mov 	di, 0

.zeros_loop:
	mov 	byte[sinal_filtrado+di], 0
	inc 	di
	loop 	.zeros_loop

	mov 	cx, [sinal_size]
	
.calculate_element:
	mov 	bx, cx
	mov 	cx, [filter_width]
	mov 	dx, 0
	mov 	si, di
	dec 	si

.convolution_loop:
	mov 	al, [int_sinal_array+si]
	cbw
	dec 	si
	add 	dx, ax
	loop 	.convolution_loop

	mov 	ax, dx
	mov 	cx, [filter_width]
	idiv 	cl
	mov 	byte[sinal_filtrado+di], al

	inc 	di
	mov 	cx, bx
	loop 	.calculate_element

	ret

plot_histograma_original:
	ret

draw_menu_lines:
    mov		ax,639
    push	ax
    mov		ax,80
    push	ax
    mov		ax,0
    push	ax
    mov		ax,80
    push	ax
    call	line

    mov		ax,65
    push	ax
    mov		ax,160
    push	ax
    mov		ax,0
    push	ax
    mov		ax,160
    push	ax
    call	line

    mov		ax,65
    push	ax
    mov		ax,240
    push	ax
    mov		ax,0
    push	ax
    mov		ax,240
    push	ax
    call	line

    mov		ax,65
    push	ax
    mov		ax,320
    push	ax
    mov		ax,0
    push	ax
    mov		ax,320
    push	ax
    call	line

    mov		ax,65
    push	ax
    mov		ax,400
    push	ax
    mov		ax,0
    push	ax
    mov		ax,400
    push	ax
    call	line

    mov		ax,65
    push	ax
    mov		ax,0
    push	ax
    mov		ax,65
    push	ax
    mov		ax,479
    push	ax
    call	line

	mov		ax,65
    push	ax
    mov		ax,250
    push	ax
    mov		ax,639
    push	ax
    mov		ax,250
    push	ax
    call	line

	mov		ax,385
    push	ax
    mov		ax,479
    push	ax
    mov		ax,385
    push	ax
    mov		ax,80
    push	ax
    call	line
	ret

write_abrir:
	mov		dh,2
	mov		dl,2
	lea		bx,[Abrir]
	call	write_string
	ret

write_fir1:
	mov		dh,7
	mov		dl,2
	lea		bx,[FIR1]
	call	write_string
	ret

write_fir2:
	mov		dh,12
	mov		dl,2
	lea		bx,[FIR2]
	call	write_string
	ret

write_fir3:
	mov		dh,17
	mov		dl,2
	lea		bx,[FIR3]
	call	write_string
	ret

write_histograma:
	mov		dh,21
	mov		dl,0
	lea		bx,[Histogra]
	call	write_string
	mov		dh,22
	mov		dl,0
	lea		bx,[mas]
	call	write_string
	ret

write_sair:
	mov		dh,27
	mov		dl,2
	lea		bx,[Sair]
	call	write_string
	ret

write_nome:
	mov		dh,27
	mov		dl,12
	lea		bx,[Nome]
	call	write_string
	ret

video_setup:
    mov  	ah,0Fh
    int  	10h
    mov  	[modo_anterior],al   
    mov     al,12h
    mov     ah,0
    int     10h
	ret

video_close:
    mov    	ah,08h
    int     21h
    mov  	ah,0   			; set video mode
    mov  	al,[modo_anterior]   	; modo anterior
    int  	10h
    mov     ax,4c00h
    int     21h
	ret

cursor:
	pushf
	push 	ax
	push 	bx
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	mov     ah,2
	mov     bh,0
	int     10h
	pop		bp
	pop		di
	pop		si
	pop		dx
	pop		cx
	pop		bx
	pop		ax
	popf
	ret

caracter:
    pushf
    push 	ax
    push 	bx
    push	cx
    push	dx
    push	si
    push	di
    push	bp
    mov     ah,9
    mov     bh,0
    mov     cx,1
    mov     bl,[cor]
    int     10h
    pop		bp
    pop		di
    pop		si
    pop		dx
    pop		cx
    pop		bx
    pop		ax
    popf
    ret

write_string:
	mov		al,[bx]
	cmp		al,'$'
	je		.end
	call	cursor
	call	caracter
	inc		bx
	inc		dl
	jmp 	write_string
.end:
	ret
	
plot_xy:
    push	bp
    mov		bp,sp
    pushf
    push 	ax
    push 	bx
    push	cx
    push	dx
    push	si
    push	di
    mov     ah,0ch
    mov     al,[cor]
    mov     bh,0
    mov     dx,479
    sub		dx,[bp+4]
    mov     cx,[bp+6]
    int     10h
    pop		di
    pop		si
    pop		dx
    pop		cx
    pop		bx
    pop		ax
    popf
    pop		bp
    ret		4

circle:
	push 	bp
	mov	 	bp,sp
	pushf                        ;coloca os flags na pilha
	push 	ax
	push 	bx
	push	cx
	push	dx
	push	si
	push	di
	
	mov		ax,[bp+8]    ; resgata xc
	mov		bx,[bp+6]    ; resgata yc
	mov		cx,[bp+4]    ; resgata r
	
	mov 	dx,bx	
	add		dx,cx       ;ponto extremo superior
	push    ax			
	push	dx
	call 	plot_xy
	
	mov		dx,bx
	sub		dx,cx       ;ponto extremo inferior
	push    ax			
	push	dx
	call 	plot_xy
	
	mov 	dx,ax	
	add		dx,cx       ;ponto extremo direita
	push    dx			
	push	bx
	call 	plot_xy
	
	mov		dx,ax
	sub		dx,cx       ;ponto extremo esquerda
	push    dx			
	push	bx
	call 	plot_xy
		
	mov		di,cx
	sub		di,1	 ;di=r-1
	mov		dx,0  	;dx ser� a vari�vel x. cx � a variavel y
	
stay:				;loop
	mov		si,di
	cmp		si,0
	jg		inf       ;caso d for menor que 0, seleciona pixel superior (n�o  salta)
	mov		si,dx		;o jl � importante porque trata-se de conta com sinal
	sal		si,1		;multiplica por doi (shift arithmetic left)
	add		si,3
	add		di,si     ;nesse ponto d=d+2*dx+3
	inc		dx		;incrementa dx
	jmp		plotar
inf:	
	mov		si,dx
	sub		si,cx  		;faz x - y (dx-cx), e salva em di 
	sal		si,1
	add		si,5
	add		di,si		;nesse ponto d=d+2*(dx-cx)+5
	inc		dx		;incrementa x (dx)
	dec		cx		;decrementa y (cx)
	
plotar:	
	mov		si,dx
	add		si,ax
	push    si			;coloca a abcisa x+xc na pilha
	mov		si,cx
	add		si,bx
	push    si			;coloca a ordenada y+yc na pilha
	call 	plot_xy		;toma conta do segundo octante
	mov		si,ax
	add		si,dx
	push    si			;coloca a abcisa xc+x na pilha
	mov		si,bx
	sub		si,cx
	push    si			;coloca a ordenada yc-y na pilha
	call 	plot_xy		;toma conta do s�timo octante
	mov		si,ax
	add		si,cx
	push    si			;coloca a abcisa xc+y na pilha
	mov		si,bx
	add		si,dx
	push    si			;coloca a ordenada yc+x na pilha
	call 	plot_xy		;toma conta do segundo octante
	mov		si,ax
	add		si,cx
	push    si			;coloca a abcisa xc+y na pilha
	mov		si,bx
	sub		si,dx
	push    si			;coloca a ordenada yc-x na pilha
	call 	plot_xy		;toma conta do oitavo octante
	mov		si,ax
	sub		si,dx
	push    si			;coloca a abcisa xc-x na pilha
	mov		si,bx
	add		si,cx
	push    si			;coloca a ordenada yc+y na pilha
	call	 plot_xy		;toma conta do terceiro octante
	mov		si,ax
	sub		si,dx
	push    si			;coloca a abcisa xc-x na pilha
	mov		si,bx
	sub		si,cx
	push    si			;coloca a ordenada yc-y na pilha
	call 	plot_xy		;toma conta do sexto octante
	mov		si,ax
	sub		si,cx
	push    si			;coloca a abcisa xc-y na pilha
	mov		si,bx
	sub		si,dx
	push    si			;coloca a ordenada yc-x na pilha
	call 	plot_xy		;toma conta do quinto octante
	mov		si,ax
	sub		si,cx
	push    si			;coloca a abcisa xc-y na pilha
	mov		si,bx
	add		si,dx
	push    si			;coloca a ordenada yc-x na pilha
	call 	plot_xy		;toma conta do quarto octante
	
	cmp		cx,dx
	jb		fim_circle  ;se cx (y) est� abaixo de dx (x), termina     
	jmp		stay		;se cx (y) est� acima de dx (x), continua no loop
	
	
fim_circle:
	pop		di
	pop		si
	pop		dx
	pop		cx
	pop		bx
	pop		ax
	popf
	pop		bp
	ret		6

full_circle:
	push 	bp
	mov	 	bp,sp
	pushf                        ;coloca os flags na pilha
	push 	ax
	push 	bx
	push	cx
	push	dx
	push	si
	push	di

	mov		ax,[bp+8]    ; resgata xc
	mov		bx,[bp+6]    ; resgata yc
	mov		cx,[bp+4]    ; resgata r
	
	mov		si,bx
	sub		si,cx
	push    ax			;coloca xc na pilha			
	push	si			;coloca yc-r na pilha
	mov		si,bx
	add		si,cx
	push	ax		;coloca xc na pilha
	push	si		;coloca yc+r na pilha
	call 	line
	
		
	mov		di,cx
	sub		di,1	 ;di=r-1
	mov		dx,0  	;dx ser� a vari�vel x. cx � a variavel y
	
stay_full:				;loop
	mov		si,di
	cmp		si,0
	jg		inf_full       ;caso d for menor que 0, seleciona pixel superior (n�o  salta)
	mov		si,dx		;o jl � importante porque trata-se de conta com sinal
	sal		si,1		;multiplica por doi (shift arithmetic left)
	add		si,3
	add		di,si     ;nesse ponto d=d+2*dx+3
	inc		dx		;incrementa dx
	jmp		plotar_full
inf_full:	
	mov		si,dx
	sub		si,cx  		;faz x - y (dx-cx), e salva em di 
	sal		si,1
	add		si,5
	add		di,si		;nesse ponto d=d+2*(dx-cx)+5
	inc		dx		;incrementa x (dx)
	dec		cx		;decrementa y (cx)
	
plotar_full:	
	mov		si,ax
	add		si,cx
	push	si		;coloca a abcisa y+xc na pilha			
	mov		si,bx
	sub		si,dx
	push    si		;coloca a ordenada yc-x na pilha
	mov		si,ax
	add		si,cx
	push	si		;coloca a abcisa y+xc na pilha	
	mov		si,bx
	add		si,dx
	push    si		;coloca a ordenada yc+x na pilha	
	call 	line
	
	mov		si,ax
	add		si,dx
	push	si		;coloca a abcisa xc+x na pilha			
	mov		si,bx
	sub		si,cx
	push    si		;coloca a ordenada yc-y na pilha
	mov		si,ax
	add		si,dx
	push	si		;coloca a abcisa xc+x na pilha	
	mov		si,bx
	add		si,cx
	push    si		;coloca a ordenada yc+y na pilha	
	call	line
	
	mov		si,ax
	sub		si,dx
	push	si		;coloca a abcisa xc-x na pilha			
	mov		si,bx
	sub		si,cx
	push    si		;coloca a ordenada yc-y na pilha
	mov		si,ax
	sub		si,dx
	push	si		;coloca a abcisa xc-x na pilha	
	mov		si,bx
	add		si,cx
	push    si		;coloca a ordenada yc+y na pilha	
	call	line
	
	mov		si,ax
	sub		si,cx
	push	si		;coloca a abcisa xc-y na pilha			
	mov		si,bx
	sub		si,dx
	push    si		;coloca a ordenada yc-x na pilha
	mov		si,ax
	sub		si,cx
	push	si		;coloca a abcisa xc-y na pilha	
	mov		si,bx
	add		si,dx
	push    si		;coloca a ordenada yc+x na pilha	
	call	line
	
	cmp		cx,dx
	jb		fim_full_circle  ;se cx (y) est� abaixo de dx (x), termina     
	jmp		stay_full		;se cx (y) est� acima de dx (x), continua no loop
	
	
fim_full_circle:
	pop		di
	pop		si
	pop		dx
	pop		cx
	pop		bx
	pop		ax
	popf
	pop		bp
	ret		6

line:
    push	bp
    mov		bp,sp
    pushf                        ;coloca os flags na pilha
    push 	ax
    push 	bx
    push	cx
    push	dx
    push	si
    push	di
    mov		ax,[bp+10]   ; resgata os valores das coordenadas
    mov		bx,[bp+8]    ; resgata os valores das coordenadas
    mov		cx,[bp+6]    ; resgata os valores das coordenadas
    mov		dx,[bp+4]    ; resgata os valores das coordenadas
    cmp		ax,cx
    je		line2
    jb		line1
    xchg	ax,cx
    xchg	bx,dx
    jmp		line1
line2:		; deltax=0
    cmp		bx,dx  ;subtrai dx de bx
    jb		line3
    xchg	bx,dx        ;troca os valores de bx e dx entre eles
line3:	; dx > 
    push	ax
    push	bx
    call 	plot_xy
    cmp		bx,dx
    jne		line31
    jmp		fim_line
line31:		
	inc		bx
    jmp		line3
;deltax <>0
line1:
; comparar m�dulos de deltax e deltay sabendo que cx>ax
; cx > ax
    push	cx
    sub		cx,ax
    mov		[deltax],cx
    pop		cx
    push	dx
    sub		dx,bx
    ja		line32
    neg		dx
line32:		
    mov		[deltay],dx
    pop		dx

    push	ax
    mov		ax,[deltax]
    cmp		ax,[deltay]
    pop		ax
    jb		line5

; cx > ax e deltax>deltay
    push	cx
    sub		cx,ax
    mov		[deltax],cx
    pop		cx
    push	dx
    sub		dx,bx
    mov		[deltay],dx
    pop		dx

    mov		si,ax
line4:
    push	ax
    push	dx
    push	si
    sub		si,ax	;(x-x1)
    mov		ax,[deltay]
    imul	si
    mov		si,[deltax]		;arredondar
    shr		si,1
; se numerador (DX)>0 soma se <0 subtrai
    cmp		dx,0
    jl		ar1
    add		ax,si
    adc		dx,0
    jmp		arc1
ar1:		
	sub		ax,si
    sbb		dx,0
arc1:
    idiv	word [deltax]
    add		ax,bx
    pop		si
    push	si
    push	ax
    call	plot_xy
    pop		dx
    pop		ax
    cmp		si,cx
    je		fim_line
    inc		si
    jmp		line4

line5:		cmp		bx,dx
    jb 		line7
    xchg	ax,cx
    xchg	bx,dx
line7:
    push	cx
    sub		cx,ax
    mov		[deltax],cx
    pop		cx
    push	dx
    sub		dx,bx
    mov		[deltay],dx
    pop		dx



    mov		si,bx
line6:
    push	dx
    push	si
    push	ax
    sub		si,bx	;(y-y1)
    mov		ax,[deltax]
    imul	si
    mov		si,[deltay]		;arredondar
    shr		si,1
; se numerador (DX)>0 soma se <0 subtrai
    cmp		dx,0
    jl		ar2
    add		ax,si
    adc		dx,0
    jmp		arc2
ar2:		
	sub		ax,si
    sbb		dx,0
arc2:
    idiv	word [deltay]
    mov		di,ax
    pop		ax
    add		di,ax
    pop		si
    push	di
    push	si
    call	plot_xy
    pop		dx
    cmp		si,dx
    je		fim_line
    inc		si
    jmp		line6

fim_line:
    pop		di
    pop		si
    pop		dx
    pop		cx
    pop		bx
    pop		ax
    popf
    pop		bp
    ret		8


; funcao que aguarda um tempo pre-determinado
delay:
	push	cx
	mov 	cx, 200; Carrega o valor 3 no registrador cx (contador para loop)
del2:
	push 	cx; Coloca cx na pilha para usa-lo em outro loop
	mov 	cx, 0; Zera cx
del1:
	loop	del1; No loop del1, cx eh decrementado seguidamente ate que volte a ser zero
	pop 	cx; Recupera cx da pilha
	loop 	del2; No loop del2, cx eh decrementado seguidamente ate que seja zero
	pop 	cx
	ret


segment data
cor		db		branco_intenso
preto		equ		0
azul		equ		1
verde		equ		2
cyan		equ		3
vermelho	equ		4
magenta		equ		5
marrom		equ		6
branco		equ		7
cinza		equ		8
azul_claro	equ		9
verde_claro	equ		10
cyan_claro	equ		11
rosa		equ		12
magenta_claro	equ		13
amarelo		equ		14
branco_intenso	equ		15

modo_anterior	db		0
linha   	dw  		0
coluna  	dw  		0
deltax		dw		0
deltay		dw		0	

Abrir		db		'Abrir$'
FIR1		db		'FIR1$'
FIR2		db		'FIR2$'
FIR3		db		'FIR3$'
Histogra	db		'Histogra$'
mas			db		'mas$'
Sair		db		'Sair$'
Nome		db		'Breno Uliana de Angelo$'
filename 	db 		'sinalep1.txt', 0
handle		dw		0
sinal_array	resb	2048
teste 		db		'Um teste$'
int_sinal_array		resb	2048
sinal_size	dw		0
sinal_filtrado		resb	2048
filter_width	dw	0
aberto		db		0

segment stack stack
    resb 256
stacktop:
