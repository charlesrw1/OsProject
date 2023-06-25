#include <stdio.h>
#include <stdlib.h>
#include <time.h>
float f2()
{
	srand(time(NULL));
	return (rand()%100)/100.f;
}

void function()
{
	printf("hello world\n");
}


int main()
{
	float f = f2();
	function();
	return 0;
}