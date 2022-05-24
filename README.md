# The Linker Script

## I. The work of the linker
Say we have two C file, the first (xxx.c) with the main function and the another (yyy.c) have the function sub() called by the first file.

xxx.c
```C
extern int sub(int input);

static int g_var_bss;
int g_var_data = 0x111111F8;

int main()
{
	int var;
	g_var_bss = 0x222222F4;
	var = g_var_data + g_var_bss;
	var = sub(var);
	return var;
}
```
yyy.c:
```C
int sub(int input)
{
	return input-1;
}
```


First, compile the two files
```
$ gcc -c xxx.c yyy.c
$ ld xxx.o yyy.o
```

Then observe the disassembly file before link
```
$ objdump -S xxx.o
```
<img src="https://i.imgur.com/y7wkebx.png" alt="drawing" width="80%"/>

In the individual object file, there is the uncomplished portion that jump to the function not defeind in its own file, the real code is outside the file, so the compiler temporarily make a jump to itself.

<img src="https://i.imgur.com/cMS8xDu.png" alt="drawing" width="80%"/>

After linking, we get the result that the sections are combined in one file, and the symbols are found at the actual addresses.


## II. The basic of linker scripts

With a basci linker script, we arrange the sections placement and assign the code address (called VMA, Virtual Memeory Address), 
```
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
        .data 0x16000:
        {
                xxx.o(.data)
                yyy.o(.data)
        }
}
```
When linking, we select the above script file by -T argument
```
$ ld -T test.ld xxx.o yyy.o
```
Then we can observe where the code is located as well as the case in, we found that the function sub() is placed in address 0x3000.
```
$ objdump -S a.out

a.out:     file format elf64-x86-64

Disassembly of section .text1:

0000000000002000 <main>:
    2000:       f3 0f 1e fa             endbr64
    2004:       55                      push   %rbp
    2005:       48 89 e5                mov    %rsp,%rbp
    2008:       48 83 ec 10             sub    $0x10,%rsp
    200c:       c7 05 ee 3f 01 00 f4    movl   $0x222222f4,0x13fee(%rip)        # 16004 <g_var_bss>
    2013:       22 22 22
    2016:       8b 15 e4 3f 01 00       mov    0x13fe4(%rip),%edx        # 16000 <g_var_data>
    201c:       8b 05 e2 3f 01 00       mov    0x13fe2(%rip),%eax        # 16004 <g_var_bss>
    2022:       01 d0                   add    %edx,%eax
    2024:       89 45 fc                mov    %eax,-0x4(%rbp)
    2027:       8b 45 fc                mov    -0x4(%rbp),%eax
    202a:       89 c7                   mov    %eax,%edi
    202c:       e8 cf 0f 00 00          callq  3000 <sub>
    2031:       89 45 fc                mov    %eax,-0x4(%rbp)
    2034:       8b 45 fc                mov    -0x4(%rbp),%eax
    2037:       c9                      leaveq
    2038:       c3                      retq

Disassembly of section .text2:

0000000000003000 <sub>:
    3000:       f3 0f 1e fa             endbr64
    3004:       55                      push   %rbp
    3005:       48 89 e5                mov    %rsp,%rbp
    3008:       89 7d fc                mov    %edi,-0x4(%rbp)
    300b:       8b 45 fc                mov    -0x4(%rbp),%eax
    300e:       83 e8 01                sub    $0x1,%eax
    3011:       5d                      pop    %rbp
    3012:       c3                      retq
```
In our main code, we know that we have an initialized data g_var_data that is expected to be put in the .data section, we require the data section to be placed at address 0x16000 by the ld file. Additional, we have a uninitialized data g_var_bss, we expected it will be located at the .bss section, but we didn't descript where the bss section to be located. Don't worry, the linker will automatically arrange it for us.

We furthermore can dump the symbol table by objdump -t

```
$ objdump -t a.out

a.out:     file format elf64-x86-64

SYMBOL TABLE:
0000000000002000 l    d  .text1 0000000000000000 .text1
0000000000003000 l    d  .text2 0000000000000000 .text2
0000000000003018 l    d  .eh_frame      0000000000000000 .eh_frame
0000000000003070 l    d  .note.gnu.property     0000000000000000 .note.gnu.property
0000000000016000 l    d  .data  0000000000000000 .data
0000000000016004 l    d  .bss   0000000000000000 .bss
0000000000000000 l    d  .comment       0000000000000000 .comment
0000000000000000 l    df *ABS*  0000000000000000 xxx.c
0000000000016004 l     O .bss   0000000000000004 g_var_bss
0000000000000000 l    df *ABS*  0000000000000000 yyy.c
0000000000002000 g     F .text1 0000000000000039 main
0000000000016000 g     O .data  0000000000000004 g_var_data
0000000000003000 g     F .text2 0000000000000013 sub
```

As the result shown, we see the .data section is arranged at the address 0x16000, that match the requirement we descripted in linker script. Then .bss section is arranged from start address 0x16004, it's next to .data section, that's great, linker helps us make arrangements as compact as possible.

## III. VMA & LMA

上述的script給每個section定義了記憶體位址 .text 0x2000: {...}，該位址使得原本未定的符號、變數、function名稱有了固定的地址，這些地址在實際執行指令時，當參考到符號、變數時，就會呼叫這些位址，這就是VMA (Virtual Memory Address)。

當程式執行前，程式的text、bss、data等等資料必須在相應的記憶體位址上就定位，這需要仰賴boot loader的幫忙 (對於大大小小的系統而言，都有一支程式負責將起始程式碼搬移到執行位址，統稱為boot loader)。

我們可以在Linker Script中設定程式或資料一開始擺放的位址，稱為LMA (Loaded Memory Address)，有些解釋說成"程式被載入的位址"可能造成誤會，實際上程式是放在LMA而被載入到VMA上，而誰載入程式？可能是boot loader，或是boot loader載入後的起始程式，總之，該有人把程式或資料般移到設定的VMA上。

只有VMA會影響程式本身的內容(符號的reference位址)，LMA並不會，那LMA做什麼用? 實際上它只影響最終生成的二進位檔的布局。當我們沒有指定LMA時，它的LMA就等於VMA，而二進位檔的佈局就會如同程式在記憶體中的布局一樣。

從上面的例子中，我們知道程式的已初始化變數(.data)被放置在0x16000，那麼我們觀察輸出檔案真的是這樣嗎?
```
$ hexdump a.bin
0000000 ff3b bcfc f4ef 0246 2222 0050 f402 0e3c
0000010 0100 1c3c 0000 0c3c 0100 0188 81f0 01f0
0000020 0049 f007 81f0 01f0 0cec ff3b 84fc 9edd
0000030 0000 0000 0000 0000 0000 0000 0000 0000
*
0001000 f8ef 81f0 01f0 018e 08ec 9edd 0000 0000
0001010 0000 0000 0000 0000 0000 0000 0000 0000
*
0014000 1111 f811
0014004
```
可以看到變數g_var_data (0x111111F8)被放置在0x14000的位址，這是因為linker和objcopy都會刪去前面0x2000以前沒定義的空白部分。這裡可以看到輸出檔案的大小幾乎就是和VMA一模一樣。

這邊做個假設，假如我們希望.text1, .text2和.data在儲存位置中的擺放是趨於緊湊的，每個區段間都只間隔0x100，像是這樣：

| .text1 | .text2 | .data |
| -------- | -------- | -------- |
| 0x20000     | 0x20100     | 0x20300     |

只是當要執行時，boot loader會把.data區搬到較遠的0x2000, 0x3000和0x16000記憶體中，那麼我們怎麼做？

一個是載入這些code的載入器 (可能是一段code，或是一個硬體function)有能力將這些片段從很大的檔案中切割出來，擺放到儲存記憶體中(可能是Flash或ROM)。但假如載入器沒有這個能力 (只能整塊binary file複製過去)，那麼我們需要藉助LMA的幫助，使程式碼的布局符合我們儲存記憶體的配置。因此，基於上述需求的linker script就可以寫成：
```shell
SECTIONS
{
	.text1 0x2000: AT(0x20000)
	{ 
		xxx.o(.text)
	}
	.text2 0x3000: AT(0x20100)
	{ 
		yyy.o(.text)	
	}
	.data 0x16000: AT(0x20300)
	{ 
		xxx.o(.data) 
		yyy.o(.data)
	}
}
```
我們可以發現如此產生的binary檔非常的小：
```
$ ls -l
total 76
-rw-r--r-- 1 Administrator None   772 五月 24 15:20 a.bin
...
...
```
而程式片段也是按照我們的需求擺放：
```
$ hexdump a.bin
0000000 ff3b bcfc f4ef 0246 2222 0050 f402 0e3c
0000010 0100 1c3c 0000 0c3c 0100 0188 81f0 01f0
0000020 0049 f007 81f0 01f0 0cec ff3b 84fc 9edd
0000030 0000 0000 0000 0000 0000 0000 0000 0000
*
0000100 f8ef 81f0 01f0 018e 08ec 9edd 0000 0000
0000110 0000 0000 0000 0000 0000 0000 0000 0000
*
0000300 1111 f811
0000304
```
## Export Symbol
上面提到當程式和資料需要從儲存位址(LMA)被複製到執行位址(VMA)，一個方法是使用常數寫法：
```C
char *src = (char*)0x2000;
char *dst = (char*)0x20000;
/* ROM has data at end of text; copy it. */
for (int i = 0; i < 0x100; ++i) {
    *dst++ = *src++;
}
```
但假如希望程式可以重複使用在不同硬體上，每個硬體的位址定義可能不同，那常數顯然不是個好方法。其實我們可以linker script用變數的傳遞，將LMA或VMA帶進程式中
```shell
SECTIONS
{
    ...
    
    .data 0x16000: AT(0x20300)
    { 
        _text_lma = LOADADDR(.data)
        _text_vma = .
        xxx.o(.data) 
        yyy.o(.data)        
        _etext_vma = .        
    }
    
    ...
}
```
這段script會將.text的VMA起始位址載入_text_vma, 結束位址載入_etext_vma，而LMA位址載入_text_lma；在C程式碼中這些都會被視為變數，因此你不能重複定義相同的符號。當要從LMA複製.text區塊到VMA時，程式碼如下：

```c
extern int _text_lma, _text_vma, _etext_vma;
char *src = (char*)_text_lma;
char *dst = (char*)_text_vma;
/* ROM has data at end of text; copy it. */
while (dst < _etext_vma) {
    *dst++ = *src++;
}
```
