# The Linker Script

### I. Basic work of a linker
Say we have two C file, the first (xxx.c) with the main function and the another (yyy.c) have the function sub() called by the first file.

First, compile the two files
```shell=x
$ gcc -c xxx.c yyy.c
```
Then observe the object file before link
```shell=x
$ objdump -S xxx.o
```
<img src="https://i.imgur.com/w2JPDv7.png" alt="drawing" width="70%"/>
There is the uncomplished portion to call the function not defeind in its own C file, instead in the another file.

With the linker script, we arrange the sections placement and assign VMA..
```shell=
# mysc.ld
SECTIONS
{
        .text1 0x2000:
        {
                xxx.o(.text)
        }
        .text2 0x3000:
        {
                yyy.o(.text)
        }
        .data 0x8000:
        {
                xxx.o(.data)
                yyy.o(.data)
        }
}
```
```shell=x
$ ld -T mysc.ld xxx.o yyy.o
```
The above command will make a.out file
#### The out file after linking
```shell=x
$ objdump -S a.out
```
The callee function could be found at the practice address 0x3000, which we defined it's VMA in the .ld file.
<img src="https://i.imgur.com/hxb61Rz.png" alt="drawing" width="70%"/>

These are what linker work for us. Which combines section in the input object files, redirect inter-file symbols and sometimes, might add so-called 'ELF Header' if the target is an executable file for particular platform.

