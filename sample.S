ld	s11,8(zero)
ld	t5,16(zero)
li	t4,0
li	s7,0
addi	t4,t4,1024
add	t4,t4,t4
add	t4,t4,t4
add	t4,t4,t4
add	t4,t4,t4
add	t4,t4,t4
add	s7,t4,t4
nop
nop
nop
nop
nop
nop
nop
sd	t5,0(t4)
sd	s11,0(s7)
sd	s11,0(zero)
nop
nop
nop
ret
