#include "sdb.h"

#define NR_WP 32

typedef struct watchpoint {
  int NO;
  struct watchpoint *next;

  /* TODO: Add more members if necessary */
  word_t data;
  char exp[1000];
  bool success;
} WP;

static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;

void init_wp_pool() {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
  }

  head = NULL;
  free_ = wp_pool;
}

WP* new_wp(char *args){
	if(free_==NULL) assert(0);
	WP *ans=free_;
	free_=free_->next;
	ans->next=head;
	head=ans;
	
	strcpy(ans->exp,args);
	ans->success=1;
	ans->data=expr(args,&ans->success);

	Log("Watch point %d has been built.\n",ans->NO);
	return ans;
}

void free_wp(WP *wp){
	wp->next=free_;
	free_=wp;
	Log("Watch point %d has been freed.\n",wp->NO);
	return;
}

void show_checkpoints(){
	if(head==NULL){
		printf("Nothing to show.\n");
		return;
	}
	for(WP *now=head;now!=NULL;now=now->next){
		printf("chechpoint%d:\n  %s\n",now->NO,now->exp);
		if(now->success) printf("  data=%lu\n",now->data);
		else printf("  Cannot be calculated!\n");
	}
	return;
}

void checkpoint_del(int x){
	if(head!=NULL){
		if(head->NO==x){
			WP *temp=head;
			head=head->next;
			free_wp(temp);
			return;
		}
		for(WP *now=head;now->next!=NULL;now=now->next)
			if(now->next->NO==x){
				WP *temp=now->next;
				now->next=now->next->next;
				free_wp(temp);
				return;
			}
	}
	printf("Nothing to del!\n");
	return;
}

void new_WP(char *args){new_wp(args);return;}

bool watchpoint_check(){
	bool ans=0;
	for(WP * now=head;now!=NULL;now=now->next){
		bool success=1;
		word_t a=expr(now->exp,&success);
		if(success!=now->success||(success&&now->success&&a!=now->data)){
			ans=1;
			printf("Checkpoint NO.%d has been changed. Its expr:%s\n",now->NO,now->exp);
			if(!now->success) printf("Old value cannot be cacluated.\n");
			else printf("Old value=%lu\n",now->data);
			if(!success) printf("Now value cannot be cacluated.\n");
			else printf("Now value=%lu\n",a);
			now->success=success;
			now->data=a;
		}
	}
	return ans;
}


/* TODO: Implement the functionality of watchpoint */

