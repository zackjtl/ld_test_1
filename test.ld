
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

