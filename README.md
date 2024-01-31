# GSI-Monitor
GSI Monitoring Tools

These tools monitor the Gridpoint Statistical Interpolation (GSI) package's data assimiliation, detecting 
and reporting missing data sources, low observational counts, and high penalty values.  These machines 
are supported:  wcoss2, hera, orion, jet, s4.

Suite includes:
```
  ConMon   Conventional Monitor     
  MinMon   GSI Minimization Monitor 
  OznMon   Ozone Monitor            
  RadMon   Radiance Monitor         
```

To use any of the monitors first build the executables.  Navigate to GSI-monitor/ush and run build.sh.  
Then see the README file in the monitor(s) of interest in the GSI-monitor/src directory.  

Note that the higher level data extraction components for the MinMon, OznMon, and RadMon have been 
relocated to the global-workflow repository and must be run as part of the vrfy job step.  To run the 
data extraction within an experimental run set these switches to "YES" in your 
expdir/*/config.vrfy file:

```
export VRFYRAD="YES"              # Radiance data assimilation monitoring
export VRFYOZN="YES"              # Ozone data assimilation monitoring
export VRFYMINMON="YES"           # GSI minimization monitoring
```


PoC:  edward.safford@noaa.gov
