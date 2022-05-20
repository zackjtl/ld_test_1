# The Linker Script

## I. The work of the linker
Say we have two C file, the first (xxx.c) with the main function and the another (yyy.c) have the function sub() called by the first file.

First, compile the two files
```shell=x
$ gcc -c xxx.c yyy.c
$ ld xxx.o yyy.o
```

Then observe the disassembly file before link
```shell=x
$ objdump -S xxx.o
```

<img src="https://i.imgur.com/IVwPJWa.png" alt="drawing" width="80%"/>

In the individual object file, there is the uncomplished portion to call the function not defeind in its own C file, instead in the another file.

<img src="https://i.imgur.com/m7dK21g.png" alt="drawing" width="80%"/>

After linking, we get the result that the sections are combined in one file, and the unreference symbols are found the actual target addresses.


## II. The basic of linker scripts

With a basci linker script, we arrange the sections placement and assign the code address (called VMA, Virtual Memeory Address), 
```shell=
# test.ld
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
When linking, we select the above script file by -T argument
```shell=x
$ ld -T test.ld xxx.o yyy.o
```
The above command will make a.out file too.
```shell=x
$ objdump -S a.out
```

<img src="https://i.imgur.com/qX1heUS.png" alt="drawing" width="80%"/>

The objdump -S only shows the code sections, we furthermore need to know where were the variables placed. 

In our main code, we know that we have an initialized data g_var_data that is expected to be put in the .data section, we require the data section to be placed at address 0x8000 by the ld file. Additional, we have a uninitialized data g_var_bss, we expected it will be located at the .bss section, but we didn't descript where the bss section to be located. Don't worry, the linker will automatically arrange it for us.

For observe this, we use objdump -t. 

```shell=X
$ objdump -t a.out
```

<img src="https://i.imgur.com/7mjmD0d.png" alt="drawing" width="80%"/>

As the result shown, we see the .data section is arranged at the address 0x8000, that match the requirement we descripted in linker script. Then .bss section is arranged from start address 0x8004, it's next to .data section, that's great, linker helps us make arrangements as compact as possible.

## III. VMA & LMA
