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
