	title	SERINT
;
;Interupt driven RS232 serial port routines.
; these routines replace the BIOS rs232 calls with a version that has
; interupt driven character receive, and can thus operate at considerably
;  higher speeds than the standard bios calls (int 14h).
;
;  Copyright 1983 by William E. Westfield.  All rights reserved.
;  MIT license
;

BUFSiz= 1024

XON=	1Fh		; ^_ for tops20, tenex
XOFF=	1Fh		; ^_ for tops20, tenex

STOPED=	1


Everything Segment public
assume cs:everything,es:everything,ss:everything
assume	ds: everything

org	30h
SerialCardVector	dd 0

org	14h*4
RS232vector	dd 0

org	100h
foo:	jmp start

org	0
db	bufsiz dup(?)
;use the space before 100h as part of the buffer

start:
	mov	bp,ds
	xor	ax,ax
	mov	ds,ax
	les	ax,SerialCardVector
	mov	cs:OthVec,ax
	mov	cs:OthVec+2,es
	les	ax,rs232vector
	mov	cs:biosint,ax
	mov	cs:biosint+2,es
	mov	word ptr SerialCardVector,OFFSET serint
	mov	word ptr SerialCardVector+2,cs
	mov	word ptr rs232vector,OFFSET rsint
	mov	word ptr rs232vector+2,cs

	mov	bx,cs
	mov	ds,bx
	xor	ax,ax
	mov	BUFTail,ax	; load place for interupt routine to put chars
	mov	BUFHead,ax	; load place for main routine to get chars

;	mov	ax,offset BUFFER	;computer segment containing the buffer
;	mov	cl,4		;by taking address, dividing by 16 to get
;	shr	ax,cl		;segment value.
;	add	ax,bx		; and then add current segment
;	inc	ax		; and round up.
;	mov	BUFSeg,ax

init3:	cli
init6:	in	al,021H		; Set up 8259 interupt controller
	and	al,0EFH		;  enabling INT4
	out	021H,al
	mov	dx,03F9H	; Interupt Enable register
	mov	al,1		; enable 'data available' serial interupt
	out	dx,al
	mov	dl,0FCH
	mov	al,0BH		; enable interupts from serial card
	out	dx,al
	sti			; enable CPU to receive interupts
	mov	dl,0F8H	;
	in	al,dx
	mov	dx,offset prgend+5	;note some slack...
	int	27h		;terminate but stay resident

BUFend=offset $-2


subttl 	********** serial port interupt routine **********
tflags	db	0
bufHead dw	0
BufTail dw	0
COUNT	dw	0

othvec	dd	0
biosint dd	0


rsint:	sti
	cmp	dx,0
	jne	notus
	cmp	ah,1
	je	sndchr
	jge	wedoit
notus:	jmp	cs:dword ptr BIOSint

wedoit:	cmp	ah,2			; receive a character ?
	 je	GETCHR
status:	pushf				;simulate interupt
	call	cs:dword ptr BIOSint
modsta:	cmp	cs:count,0
	je	nochars
	or	ah,1			;indicate data ready
nochars: iret

SNDCHR:	push	dx
	mov	dx,3FDh
	mov	ah,al
sndlp:	in	al,dx
	test	al,20h
	jz	sndlp
	mov	dl,0F8h
	xchg	al,ah
	out	dx,al
	pop	dx
	jmp	modsta
	

GETCHR:
TSTLP:	cmp	cs:COUNT,0
	jz	TSTLP
	cld
	push	si
	push	ds
	push	cs
	pop	ds
	mov	si,BUFHead
	cli
	lodsb
	cmp	si,offset BUFEND
	jb	GETCH2
	xor	si,si
GETCH2:	dec	COUNT
	test	tflags,STOPED
	je	GETCH3
	cmp	COUNT,100
	ja	GETCH3
	 mov	dx,3F8h
	 push	ax
	 mov	al,xon
	 out	dx,al
	 and	tflags,255-STOPED
	pop	AX
GETCH3:
	mov	BUFHead,si
	sti
	pop	ds
	pop	si
	mov	ah,0
	iret


serint:	push	dx
	push	ax
	push	es
	push	ds
	push	di
	cld
	mov	di,cs:BUFTail	;get registers we need
intlp:	mov	dx,03fdH	; asynch status port
	in	al,dx
	test	al,1		; see if data available
;	jz	retint
	jz	othint		;  no.
	mov	dl,0f8H	; yes, get it
	in	al,dx
	and	al,07fH	; take 7 bits
	jz	retint		; ignore nulls
	cmp	al,07fH	; rubout ?
	jz	retint		; yes, ignore it.
serin2:	push	cs
	pop	es
	stosb
	mov	ax,cs
	mov	ds,ax		; deal with global variables now...
	inc	COUNT		; increment count of characters in buffer
	cmp	di,offset BUFend ; does it loop around past end of the buffer ?
	jb	serin3
	 xor	di,di		; yes, reset to beginning.
serin3:	mov	BUFTail,di
	mov	ax,offset BUFend
	sub	ax,COUNT	; how much space is left ?
	cmp	ax,BUFSIZ/10	; less than a tenth left ?
	jae	serin5
	test	tflags,STOPED
	jne	serin4
	mov	dx,03F8H
	mov	al,xoff	; send character to stop output	
	out	dx,al
	or	tflags,STOPED
serin4:
serin5:
retint:	mov	al,064H
	out	020H,al		; send  End-Of-Interupt to 8259
	pop	di
	pop	ds
	pop	es
	pop	ax
	pop	dx
intret:	iret

othint:	;something we werent waiting for caused the interupt,
	; so pass it on to previous interupt vector
	cmp	cs:OTHVEC+2,0
	jz	retint
	pop	di
	pop	ds
	pop	es
	pop	ax
	pop	dx
	jmp	cs:dword ptr OTHVEC

prgend= $+2

everything ends

	end foo
