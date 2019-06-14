#ifndef __IntelPowerGadgetPlugin__H__
#define __IntelPowerGadgetPlugin__H__

#include "IntelPowerGadgetLib.h"
#include <iostream>
#include <pthread.h>
#include <unistd.h>

#include <fstream>

#define NUMBER_PLUGINS 3

typedef enum
{
	MEASURES,
	RESULTS
} VERBOSE_MODE;

typedef struct 
{
	double energy_consumed;
	double time_elapsed;
} rapl_measures_t;


class IntelPowerGadgetPlugin
{
public:
	IntelPowerGadgetPlugin(pthread_mutex_t * mutex_ready_measure, pthread_cond_t * cond_ready_to_measure, int resolution_time, char * folder, char * test_name);
	~IntelPowerGadgetPlugin(void);

	void start();
	void stop(LARGE_INTEGER & start_command, LARGE_INTEGER & stop_command, rapl_measures_t * res_measure);
  void startMeasure();

private:
	bool isMeasuring();
  void appendParameters();
  void waitReadyToMeasure();

private:
	pthread_t measure_thread;
	pthread_mutex_t mutex_measure;

	pthread_mutex_t * mutex_ready_to_measure;
  pthread_cond_t * ready_to_measure;
  double  time_to_be_ready;
	int is_running;

	VERBOSE_MODE mode;
	CIntelPowerGadgetLib energyLib;
	int resolution_time;
  wchar_t log_filename[MAX_PATH];
};

#ifdef __cplusplus
extern "C" {
#endif

void *run_measures(void * plugin);

#ifdef __cplusplus
}
#endif

#endif
