#include "IntelPowerGadgetPlugin.h"
#include <unistd.h>
#include <string> 
#include <sstream>
#include <cstdlib>


#define TIME_WAITING_MS 1000

wchar_t wsEnergy_Package_Processor[] = L"Processor";
wchar_t wsEnergy_Package_IA[] = L"IA";
wchar_t wsEnergy_Package_GT[] = L"GT";

typedef enum
{
	PACK_PROCESSOR = 0, // "Processor"
	PACK_IA, // "IA"
	PACK_GT, // "GT"
	NUM_PACKAGES
} PACKAGE;

typedef struct
{
	double power;
	double energy;
	double mwatth;
} energy_data_t;

typedef struct
{
	double tick;
	double frequency;
	energy_data_t energy_data[NUM_PACKAGES];
	double temperature;
	double hot;
	double power_limit;
} measure_t;

PACKAGE get_package(wchar_t * package_name)
{
	if (!wcscmp(wsEnergy_Package_Processor,package_name))
	{
		return PACK_PROCESSOR;
	}
	else if (!wcscmp(wsEnergy_Package_IA,package_name))
	{
		return PACK_IA;
	}
	else
	{
		return PACK_GT;
	}
}

void *run_measures(void * plugin)
{
	IntelPowerGadgetPlugin *power_gadget = reinterpret_cast<IntelPowerGadgetPlugin *> (plugin);

  power_gadget->startMeasure();
}

IntelPowerGadgetPlugin::IntelPowerGadgetPlugin(pthread_mutex_t * mutex_ready_measure, pthread_cond_t * cond_ready_to_measure, int res_time, char * folder, char * test_name) : energyLib()
{
  ready_to_measure = cond_ready_to_measure;
  mutex_ready_to_measure = mutex_ready_measure;
	resolution_time = res_time;

	pthread_mutex_init(&mutex_measure, NULL);

	// Initialize the driver & library
	if (energyLib.IntelEnergyLibInitialize() == false)
	{
		cout << "IntelEnergyLibInitialize failed" << endl;
		exit(1);
	}
  
  SYSTEMTIME st, lt;

	GetSystemTime(&st);

	// HMODULE hModule = GetModuleHandleW(NULL);
	// wchar_t path[MAX_PATH];
	// GetModuleFileNameW(hModule, path, MAX_PATH);

  // std::wstring wtest( strlen(test_name), L'#' );
  // mbstowcs( &wtest[0], test_name, strlen(test_name) );

  const size_t cFolder = strlen(folder)+1;
  wchar_t * wfolder = new wchar_t[cFolder];
  mbstowcs (wfolder, folder, cFolder);

  const size_t cTest = strlen(test_name)+1;
  wchar_t * wtest = new wchar_t[cTest];
  mbstowcs (wtest, test_name, cTest);

	swprintf(log_filename, L"%s\\%d_%d_%d--%d_%d_%d_%s.txt", wfolder, st.wYear,st.wMonth,st.wDay, st.wHour, st.wMinute, st.wSecond , wtest);

  delete wfolder;
  delete wtest;
}

IntelPowerGadgetPlugin::~IntelPowerGadgetPlugin()
{

}

bool IntelPowerGadgetPlugin::isMeasuring()
{
	pthread_mutex_lock (&mutex_measure);
	bool is_measuring = is_running;
	pthread_mutex_unlock (&mutex_measure);
	return is_measuring;
}

void IntelPowerGadgetPlugin::start()
{
	is_running = 1;
	int res = pthread_create(&measure_thread, NULL, &run_measures, this);
	if (res != 0)
	{
		cout << "pthread_create failed" << endl;
		exit(1);
	}
}

void IntelPowerGadgetPlugin::stop(LARGE_INTEGER & start_command, LARGE_INTEGER & stop_command, rapl_measures_t * res_measure)
{
	pthread_mutex_lock (&mutex_measure);
	is_running = 0;
	pthread_mutex_unlock (&mutex_measure);
  int res = pthread_join(measure_thread, NULL);

    char str[MAX_PATH];
	wcstombs(str, log_filename, MAX_PATH);

	std::ifstream logfile(str);

  double elapsed_time, cum_energy;
  string line;

  while(std::getline(logfile, line))
  {
    if (line.length() < 1)
      break;

    // Extract cum_energy at start_time and at stop_time
    string data;
    char * end;
    std::istringstream s(line);
    for (int i = 0 ; i < 6 ; i++)
    {
      std::getline(s, data, ',');
      if (i == 2)
      {
        elapsed_time = std::strtod(data.c_str(), &end);
      }
      if (i == 5)
      {
        cum_energy   = std::strtod(data.c_str(), &end);
      }
    }
  }

  // Write results measure
  // get ticks per second
  LARGE_INTEGER frequency;
  QueryPerformanceFrequency(&frequency);

  res_measure->energy_consumed = cum_energy;
  res_measure->time_elapsed = ((stop_command.QuadPart - start_command.QuadPart) * 1000.0) / frequency.QuadPart;

  // Append parameters to log file
	int maxTemp = 0, temp = 0;
	int currentNode = 0;

	std::ofstream outfile;

  outfile.open(str, std::ofstream::out | std::ofstream::app);
  outfile << "Parameters" << endl; 

	if (energyLib.GetMaxTemperature(currentNode, &maxTemp))
		outfile << "Max Temp = " << maxTemp << endl;

	int numNodes = 0; 
	if (energyLib.GetNumNodes(&numNodes))
		outfile << "number of nodes = " << numNodes << endl;

  int numMsrs = 0;
	if (energyLib.GetNumMsrs(&numMsrs))
		outfile << "number of msr = " << numMsrs << endl;

	outfile << "resolution time = " << resolution_time << endl;
  outfile << "time to be ready = " << time_to_be_ready << endl;
}

void IntelPowerGadgetPlugin::waitReadyToMeasure()
{
  bool is_ready_to_measure = false;
  int number_ticks_waiting = TIME_WAITING_MS / resolution_time;
  int numMsrs = 0;
	energyLib.GetNumMsrs(&numMsrs);

  measure_t measure;
  int counter = 0;
  int currentNode = 0;
  
	LARGE_INTEGER frequency;
  LARGE_INTEGER start_time;
  LARGE_INTEGER tick;
  QueryPerformanceFrequency(&frequency);
  QueryPerformanceCounter(&start_time);
  while (!is_ready_to_measure)
  {
		energyLib.ReadSample();
    for (int j = 0; j < numMsrs; j++)
	  {
      int funcID;
      energyLib.GetMsrFunc(j, &funcID);
      double data[3];
      int nData;
      wchar_t szName[512];
      
      energyLib.GetPowerData(currentNode, j, data, &nData);
      if (!energyLib.GetMsrName(j, szName))
      {
        wcout << "error" << endl;
        exit(1);
      }

      // Power
      if (funcID == 1)
      {
        PACKAGE p = get_package(szName);
        measure.energy_data[p].power = data[0];
        measure.energy_data[p].energy = data[1];
        measure.energy_data[p].mwatth = data[2];
      }
  	}
    if (measure.energy_data[PACK_PROCESSOR].power < 2)
    {
      counter++;
    }
    else if (counter > 0)
    {
      counter--;
    }

    Sleep(resolution_time);
    QueryPerformanceCounter(&tick);
    time_to_be_ready = ((tick.QuadPart - start_time.QuadPart) * 1000.0) / frequency.QuadPart; 
    if (counter > number_ticks_waiting || time_to_be_ready > 10 * TIME_WAITING_MS)
    {
      is_ready_to_measure = true;
    }
  }


	pthread_mutex_lock(mutex_ready_to_measure);
  pthread_cond_broadcast(ready_to_measure);
	pthread_mutex_unlock(mutex_ready_to_measure);
}

void IntelPowerGadgetPlugin::startMeasure()
{
  waitReadyToMeasure();

  energyLib.StartLog(log_filename);
  
	while(isMeasuring())
	{
		energyLib.ReadSample();
    Sleep(resolution_time);
	}

	energyLib.StopLog();
}
