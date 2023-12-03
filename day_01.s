.global _start

_start:
    // Make enough room on the stack to store the entire file
    sub sp, sp, 0x5000
    sub sp, sp, 0x4e0

    // openat(AT_FDCWD, filename, O_RDONLY)
    mov x8, 0x38
    mov x0, -0x64
    adr x1, filename
    mov x2, 0
    svc 0

    cmp x0, 0
    blt error

    // read(x0, sp, filesize)
    mov x8, 0x3f
    mov x1, sp
    adr x2, filesize
    ldr x2, [x2]
    svc 0

    mov x1, x0
    mov x0, sp
    bl iterate
    bl print_decimal

end_start:
    add sp, sp, 0x4e0
    add sp, sp, 0x5000

    // exit(0)
    mov x8, 93
    mov x0, 0
    svc 0

// fn iterate(input: *u8, size: uint) -> u64
iterate:
    sub sp, sp, 0x50
    stp xzr, x30, [sp, 0x40] // sp[0x40] = cumulator; sp[0x48] = x30
    stp x19, x20, [sp, 0x30] // sp[0x30] = x19;       sp[0x38] = x20
    stp x0, x1, [sp, 0x20]   // sp[0x20] = input;     sp[0x28] = size
    stp xzr, xzr, [sp, 0x10] // sp[0x10] = first;     sp[0x18] = last
    stp xzr, xzr, [sp]       // sp[0] = char;         sp[8] = _
    mov x19, 0  // i
    mov x20, 1  // is_first

// for (x19 = 0, x19 < sp[0x28], x19++)
loop:
    ldr x9, [sp, 0x28]
    cmp x19, x9
    bge end_iterate

    ldr x0, [sp, 0x20]
    ldrb w0, [x0, x19]
    str x0, [sp]
    cmp x0, '\n'
    beq cumulate

    bl is_digit
    cbz x0, continue

    ldr x0, [sp]
    sub x0, x0, '0'
    str x0, [sp, 0x18]
    cbz x20, continue

    str x0, [sp, 0x10]
    mov x20, 0

continue:
    add x19, x19, 1
    b loop

end_iterate:
    ldp x0, x30, [sp, 0x40]
    ldp x19, x20, [sp, 0x30]
    add sp, sp, 0x50
    ret

// fn is_digit(x0: u8) -> u64
is_digit:
    cmp x0, '0'
    blt ret_false
    cmp x0, '9'
    bgt ret_false
    mov x0, 1
    ret

ret_false:
    mov x0, 0
    ret

// sp[0x40] += sp[0x10]*0xa + sp[0x18]
// sp[0x10] = 0; sp[0x18] = 0
cumulate:
    mov x20, 1
    ldr x9, [sp, 0x10]
    mov x10, 0xa
    mul x9, x9, x10
    ldr x10, [sp, 0x18]
    add x10, x9, x10
    ldr x9, [sp, 0x40]
    add x9, x9, x10
    str x9, [sp, 0x40]
    stp xzr, xzr, [sp, 0x10]
    b continue

// fn print_decimal(x0: u64)
print_decimal:
    sub sp, sp, 0x60
    stp x21, x30, [sp, 0x50]
    stp x19, x20, [sp, 0x40]
    mov x20, 0xa
    mov x21, 0x40

loop2:
    udiv x19, x0, x20 // x19 = x0 / x20
    msub x0, x19, x20, x0 // x0 -= x19*x20
    add x0, x0, '0'
    sub x21, x21, 1
    strb w0, [sp, x21]

    mov x0, x19
    cbz x0, end_print_decimal
    b loop2

end_print_decimal:
    mov x20, 0x40
    sub x1, x20, x21
    add x0, sp, x21
    bl puts

    ldp x21, x30, [sp, 0x50]
    ldp x19, x20, [sp, 0x40]
    add sp, sp, 0x60
    ret

// fn puts(x0: *u8, x1: u64)
puts:
    sub sp, sp, 0x10
    mov x8, 0x40
    mov x2, x1
    mov x1, x0
    mov x0, 1
    svc 0

    mov x0, '\n'
    str x0, [sp]
    mov x8, 0x40
    mov x0, 1
    mov x1, sp
    mov x2, 1
    svc 0
    add sp, sp, 0x10
    ret

error:
    // write(1, message, len)
    mov x8, 64
    mov x0, 1
    adr x1, message
    adr x2, len
    ldr x2, [x2]
    svc 0
    b end_start

filename:
    // .asciz "inputs/debug_01.txt"
    .asciz "inputs/day_01.txt"

filesize:
    // .dword 41
    .dword 21728

message:
    .asciz "File not found!\n"

len:
    .dword -message
