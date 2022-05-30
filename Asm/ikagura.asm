; a masm program to replicate famous STG, Ikagura
.386
.model flat, stdcall
option casemap :none

	printf			PROTO C :ptr sbyte, :vararg
	random			PROTO C
	getchar			PROTO C
include windows.inc
include user32.inc
include msvcrt.inc
include kernel32.inc
include gdi32.inc
include Comdlg32.inc

includelib gdi32.lib
includelib user32.lib
includelib kernel32.lib
includelib msvcrt.lib
includelib Comdlg32.lib

.const
WHITE			word	0
BLACK			word	1
_WIDTH			word	48
_HEIGHT			word	80
INTERVAL		word	20
INIT_X			word	24
INIT_Y			word	79

FMTCHAR			byte	"%c"

.data
; score
score			word	0

; player is white if playerColor is 0, otherwise black
playerColor		word	1

; player's HP
playerHP		word	1000

; restrict between two frames
bulletRes		word	1
moveRes			word	3

; energy of player's fighter, lowest 0, highest 300
; increase when hit by same color ememy bullet
; determine the level of fighter, 0-100 L1, 101-200 L2, 201-300 L3
; can consume 50 energy to release a bomb
playerEnergy	word	1

; TODO: use bit reduction to make map smaller?

; map size is 96w*160h, following is the same
; describe the position of player
playerX			word	48
playerY			word	159

; higher 8 bit describe enemy level and id, lower for current hp? Yes
; There are 3 types of enemy, like these
; small one
; V
; HP 1 00000001 00000001
; middle one
; \+/
;  V
; HP 2 00000010 00000010
; large one
; \---/
;  \+/
;   V
; HP 3 00000011 00000011
; They all have a core in their head, just like V
; Also, V is their position
enemyMap		word	15360 dup(0), 0

; hitbox of enemy boss
; can be divide into parts
bossMap			word	15360 dup(0), 0

; map of bullet
; number reflect bullet type
; 0 represents no bullet, 1 represents bullets
playerBulletMap	word	15360 dup(0), 0
enemyBulletMap	word	15360 dup(0), 0

; the final screen
screen			byte	15360 dup(0), 0

; curr operation
currOpr			byte	0

; 
tid				dword	0

; locks to sync
pmapLock		byte	1

.code
; get buffer offset by position
getPos proc px: word, py :word
			mov		ax, py
			imul	ax
			add		ax, px
			ret
getPos endp

; move console cursor to (x,y)
; now error?
cursorXY proc uses eax, px :dword, py: dword
			local	pos :COORD
			local	handle :HANDLE
			mov		eax, px
			mov		pos[0], eax
			mov		eax, py
			mov		pos[1], eax
			invoke	GetStdHandle, STD_OUTPUT_HANDLE
			mov		handle, eax
			invoke	SetConsoleCursorPosition, handle, addr pos
cursorXY endp

; hit check
checkEnemyHit proc
			mov		cx, _HEIGHT
			ret
checkEnemyHit endp

; hit check
checkPlayerHit proc
			ret
checkPlayerHit endp

; randomly generate enemy bullet(optional)
generateEBullet proc uses eax, ebx, edx
			local	randomNum : dword, i : dword, j : dword, off : dword
			mov		i, 0
			mov		j, 0
GEB1:
			mov		eax, i
			cmp 	eax, 158
			jz		GEB3
			mul		96
			add		eax, j
			mul		16
			mov		off, eax
			mov		ax, enemyMap[eax]
			cmp		ax, 0
			jz		GEB2
			; edx is a random number from 0 to 9
			invoke	random
			mov		ebx, 10
			div 	ebx
			mov		randomNum, edx
			; when edx <= 3, enemy can launch a bullet
			cmp		edx, 3
			ja		GEB2
			mov		eax, i
			inc		eax
			mul		96
			add		eax, j
			mul		16
			mov		enemyBulletMap[eax], 1
GEB2:
			inc		j
			mov		eax, j
			cmp		eax, 96
			jnz		GEB1
			inc		i
			mov		j, 0
			jmp		GEB1
GEB3:
			ret
generateEBullet endp

; randomly generate enemy
generateEnemy proc uses eax,ebx,ecx,edx,edi
			local	randomNum : dword
			xor		edx, edx
			invoke	random
			mov		ebx, 3
			idiv	ebx
			mov		randomNum, edx
GeneSgl:	mov		ecx, randomNum
			xor		edx, edx
			invoke	random
			idiv	48
			getPos	edx, 0
			mov		eax, edi
			invoke	random
			idiv	3
			shl		8
			mov		dl, 100
			mov		enemyMap[edi], dx
			dec		ecx
			mov		randomNum, ecx
			cmp		ecx, 0
			jne		GeneSgl
			ret
generateEnemy endp

; chech is there any bullet collision and remove collided bullets
checkBulletCollision proc uses eax,edx
			local	i : dword, j : dword, off : dword
			mov		i, 0
			mov 	j, 0
CBC1:
			mov 	eax, i
			cmp		eax, 159
			jz		CBC5
			mul		eax, 96
			add		eax, j
			mul		eax, 16
			mov		off, eax
			mov		ax, enemyBulletMap[eax]
			add		ax, playerBulletMap[off]
			cmp 	ax, 2
			jb		CBC2
			mov		enemyBulletMap[off], 0
			mov		playerBulletMap[off], 0
CBC2:
			inc		j
			mov		eax, j
			cmp		eax, 95
			jnz		CBC3
			inc 	i
			mov		j, 0
CBC3:
			ret
checkBulletCollision endp



; movement of all bullet
moveBullet proc uses eax,edx
			local 	i : dword, j : dword, off : dword
			mov 	i, 159
			mov		j, 0
MB1:
			mov		eax, i
			cmp 	eax, 0
			jb 		MB5
			mul		96
			add		eax, j
			mul		16
			mov		off, eax
			mov		ax, enemyBulletMap[eax]
			cmp 	ax, 0
			jz		MB3
			mov		eax, i
			cmp		eax, 159
			jz		MB2
			inc		eax
			mul 	eax, 96
			add		eax, j
			mul		16
			mov		dx, enemyBulletMap[off]
			mov		enemyBulletMap[eax], dx
MB2:
			mov		enemyBulletMap[off], 0
MB3:
			inc		j
			mov		eax, j
			cmp		eax, 96
			jz		MB4
			jmp		MB1
MB4:
			dec		i
			mov		j, 0
			jmp		ME1
MB5:
			invoke	checkBulletCollision
			mov		i, 0
			mov		j, 0
MB6:
			mov		eax, i
			cmp		eax, 160
			jz		MB8
			mul		96
			add		eax, j
			mul		16
			mov		off, eax
			mov		eax, playerBulletMap[eax]
			mov		eax, i
			cmp		eax, 0
			jz		MB7
			dec		eax
			mul		96
			add		eax, j
			mul		16
			mov		dx, playerBulletMap[off]
			mov		playerBulletMap[eax], dx
MB7:
			mov		playerBulletMap[off], 0
			inc		j
			mov		eax, j
			cmp		eax, 96
			jnz		MB6
			inc		i
			mov		j, 0
			jmp		MB6
MB8:
			ret
moveBullet endp

; movement of all enemy
moveEnemy proc uses eax,edx
			local	i : dword,j : dword,off : dword
			mov		i, 159
			mov		j, 0
ME1:
			mov 	eax, i
			cmp 	eax, 0
			jb		ME5
			mul		96
			add		eax, j
			mul 	16
			mov 	off, eax
			mov 	ax, enemyMap[eax]
			cmp 	ax, 0
			; judge if there is an enemy in Map[i][j]
			jz  	ME3
			mov		eax, i
			cmp		eax, 159
			; judge if i equals 159
			jz		ME2
			; in row 0~158, enemy will move to next row
			inc		eax
			mul		eax, 96
			add 	eax, j
			mul 	16
			mov 	dx, enemyMap[off]
			mov 	enemyMap[eax], dx
; i equals 159, enemy in this row will be destroyed
ME2:
			mov		enemyMap[off], 0
; no enemy in Map[i][j]
ME3:
			inc 	j
			mov 	eax, j
			cmp 	eax, 96
			jz		ME4
			jmp		ME1
ME4:
			dec		i
			mov		j, 0
			jmp		ME1
ME5:
			ret
moveEnemy endp

; reaction to player input
; param: input char
playerOperate proc uses eax, input :byte
			; TODO thread lock?
			invoke	printf, OFFSET FMTCHAR, input
			mov		al, 'a'
			cmp		al, input
			je		PLeft
			mov		al, 'd'
			cmp		al, input
			je		PRight
			mov		al, 's'
			cmp		al, input
			je		PBack
			mov		al, 'w'
			cmp		al, input
			je		PForward
			mov		al, 'j'
			cmp		al, input
			je		PShoot
			mov		al, 'k'
			cmp		al, input
			je		PBomb
			mov		al, 'p'
			cmp		al, input
			je		PPause
PLeft:
PRight:
PForward:	mov		cx, playerY
			cmp		cx, 0
			je		PRet
			dec		cx
			mov		playerY, cx
PBack:
PShoot:
PBomb:
PPause:
PRet:		ret
playerOperate endp

readOpr proc uses eax
LoopR:		invoke	getchar
			invoke	playerOperate, al
			jmp		LoopR
			ret
readOpr endp

; render bullet to screen buffer
renderBullet proc
			ret
renderBullet endp

; render enemy to screen buffer
renderEnemy proc
			ret
renderEnemy endp

; render boss to screen buffer
renderBoss proc
			ret
renderBoss endp

; render player to screen buffer
renderPlayer proc
			ret
renderPlayer endp

; lock restricts the bullets and moves player can perform during each frame
; when frame refresh, lock should be reset
resetLock proc
			mov		bulletRes, 1
			mov		moveRes, 3
			ret
resetLock endp

; initialize the game
initGame proc
			mov		ax, 1000
			mov		playerHP, ax
			xor		eax, eax
			mov		ax, INIT_X
			mov		playerX, ax
			mov		ax, INIT_Y
			mov		playerY, ax
			ret
initGame endp

; show the game screen to console(temporary)
showScreen proc
			mov		cx, 0
SL1:		cmp		cx, _HEIGHT
			je		SL6
			mov		dx, 0
SL2:		cmp		cx, playerY
			jne		SL3
			cmp		dx, playerX
			jne		SL3
			push	cx
			push	dx
			invoke	printf, offset FMTCHAR, 'A'
			pop		dx
			pop		cx
			jmp		SL4
SL3:		push	cx
			push	dx
			invoke	printf, offset FMTCHAR, ' '
			pop		dx
			pop		cx
SL4:		inc		dx
			cmp		dx, _WIDTH
			je		SL5
			jmp		SL2
SL5:		inc		cx
			push	cx
			push	dx
			invoke	printf, offset FMTCHAR, 10
			pop		dx
			pop		cx
			jmp		SL1
SL6:		; invoke	cursorXY, 0, 0
			ret
showScreen endp

; called when player dead
gameOver proc
			ret
gameOver endp

startMenu proc
			ret
startMenu endp

pauseMenu proc
			ret
pauseMenu endp

main proc
			local	frameCount :word
			mov		ax, 0
			mov		framCount, ax
			call	initGame
			invoke	CreateThread,
					NULL, 0,
					addr readOpr,
					NULL,
					NULL,
					offset tid
			; invoke StartProc to detect player button
GameLoop:	; update loop
			; sleep frame time
			mov		bx, frameCount
			inc		bx
			mov		frameCount, bx
			cmp		bx, 50
			jge		GL1
			idiv	bx, 5
			cmp		dx, 0
			je		GL2
			idiv	bx, 10
			cmp		dx, 0
			je		GL3
			jmp		GL4
GL1:		mov		bx, 0
			mov		frameCount, bx
GL2:		call	moveBullet
			call	moveEnemy
			; this line for test
GL3:			invoke	playerOperate, 'w'
GL4:		call	checkEnemyHit
			call	checkPlayerHit
			call	renderPlayer
			call	renderEnemy
			call	renderBullet
			call	showScreen
			call	resetLock
			mov		dx, playerHP
			cmp		dx, 0
			jle		GameOvr
			; sleep 20ms to make fps around 50? 233
			invoke	Sleep, 200
			jmp		GameLoop
GameOvr:	call	gameOver
			ret
main endp
end main