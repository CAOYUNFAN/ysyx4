#include <common.h>
#include <memory.h>
using namespace std;

int main(int argc,char * argv[]) {
  Log("Hello, ysyx!");
  extern void initialize(int argc,char * argv[]);
  initialize(argc,argv);
  Log("Initialization completed!");
  extern void work();
  work();
  return 0;
}
