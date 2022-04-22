#include <common.h>
#include <memory.h>
using namespace std;

int main(int argc,char * argv[]) {
  printf("Hello, ysyx!\n");
  extern void initialize(int argc,char * argv[]);
  initialize(argc,argv);
  printf("Initialization completed!\n");
  extern void work();
  work();
  return 0;
}
