day_01:
	aarch64-linux-gnu-gcc day_01.s -static -nostdlib

run:
	qemu-aarch64 ./a.out

dump:
	aarch64-linux-gnu-objdump -d ./a.out

clean:
	rm -f a.out
