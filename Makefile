
obj=*.o
exe=a.bin
hex=a.out

all: $(exe)

$(exe): $(hex)
	objcopy -O binary a.out a.bin

a.out: xxx.o yyy.o
ifdef ldf
	echo ldf defined
	ld -T $(ldf) xxx.o yyy.o
else
	echo ldf undefined
	ld xxx.o yyy.o
endif
xxx.o: xxx.c
	gcc -c xxx.c

yyy.o: yyy.c
	gcc -c yyy.c

dump: a.out
	objdump -h a.out


.PHONY: clean
clean:
	rm *.o *.out *.bin
