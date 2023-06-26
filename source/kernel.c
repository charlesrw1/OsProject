
typedef struct
{
	int a;
	int b;

	char buffer[64];
} MyStructure;

char* welcome_str = "Hello there...";
static MyStructure astruct;
static MyStructure astruct2;

void print_hex(char* video_memory, int number);
void print_hex(char* video_memory, int number)
{
	char characters[10];
	int i;
	for(i=0;i<10 && number!=0;i++)
	{
		int a = number&0xf;
		if(a<=9) {
			characters[i]=a+'0';
		}
		else {
			characters[i]=a-10+'A';
		}
		number>>=4;
	}
	for(int j=i-1;j>=0;j--)
	{
		*video_memory=characters[j];
		video_memory+=2;
	}
}

typedef unsigned char bool;
#define true 1
#define false 0
#define NULL 0

void kmain()
{
	char* string = "Hello from C!!";
	char* video_memory = (char*) 0xb8000;

	int number = *(char*)(0x2000+1 + 0x10000);
	
	print_hex(video_memory,&welcome_str);

	for(;;){}
}