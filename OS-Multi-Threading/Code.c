#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>

int SharedVariable = 0;
pthread_mutex_t lock;

void SimpleThread(void* arg){
	int which = *(int*) arg;
	int num, val;

	for(num=0; num<20; num++){
		if(random() > RAND_MAX / 2) {
      		usleep(500);
    	}

		pthread_mutex_lock(&lock);
		val = SharedVariable;
		printf("***thread%d sees value %d\n", which, val);
		SharedVariable = val+1;
		pthread_mutex_unlock(&lock);



	}
	val = SharedVariable;
	printf("***thread%d sees final value %d\n", which, val);
}

int main(int argc, char **argv){	
	if (argc < 2) {
		printf("Usage: %s <num>\n", argv[0]);
		exit(-1);
	}
	int n = atoll(argv[1]);
	int thread_args[n];
	
	// Thread ID:
	pthread_t tids[n];

	// Create attributes for n threads
	for (int i = 0; i< n; i++){
		thread_args[i] = i;
		pthread_attr_t attr;
		pthread_attr_init(&attr);
		pthread_create(&tids[i], &attr, SimpleThread, (void *)&i);
	}

	// Wait until all threads are done
	for(int i = 0; i< n; i++){
		pthread_join(tids[i], NULL);
	}
	
}
