##Land cover tabulation scripts##

These scripts were used to pull landcover values from four National Land Cover Data datasets.

They can be much improved and were the result of many hours of research in coding and GIS by one who knew nothing.

The greatest way that this process could be optimized would be to run the outside loop using parallel processing, which I haven't done yet. My solution has been to run four simultaneous sessions of RStudio, running four separate copies of the main script, each with 1/4 of the outside for-loop. Obviously parallelization would be better, as this is essentially what it would do.

If you make changes to the scripts that make them better, please feel free to submit the changes here, or email me if (like me) you don't really know much about github.

The scripts are written for a very specific dataset, but with hopefully minimal effort can be used for other datasets as well, or may have components that you may find useful.
