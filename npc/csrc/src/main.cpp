#include <common.h>
#include <memory.h>
using namespace std;

int main(int argc,char * argv[]) {
  Log("Hello, ysyx!\n");
  extern void initialize(int argc,char * argv[]);
  initialize(argc,argv);
  Log("Initialization completed!\n");
  extern void work();
  work();
  return 0;
}
