#include <stdio.h>
int main() {

int a[5], b[5], c[5];

for(int i=1;i<5;i++) {

a[i] = 3;

b[i] = 6;

}

for(int i=0;i<5;i++) {

c[i] = a[i] + b[i];

}

printf("cse502");
return c[4];
//return 0;
}
