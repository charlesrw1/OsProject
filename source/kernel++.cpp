#include <cstdio>
#include <cstdlib>

class MyClass
{
public:
    MyClass()
    {
        printf("constructor");
        arr = (int*)malloc(10*sizeof(int));
        i = 10;
    }
    ~MyClass()
    {
        delete arr;
    }
    void myfunction(int a, int i) {
        arr[i]=a;
    }
    int i = 0;
    int* arr = nullptr;
};

struct MyStruct
{
    int a = 0;
    int b = 5;

    float f = 0.1;
};

MyClass staticMyClass;
MyStruct staticMyStruct;

int main()
{
    printf("start main");
    staticMyClass.myfunction(10,0);

    return 0;
}