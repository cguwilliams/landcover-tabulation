##Land cover tabulation scripts##

These scripts were used to pull landcover values from four National Land Cover Data datasets, located [here](http://www.mrlc.gov/nlcd1992.php) (1992), [here](http://www.mrlc.gov/nlcd2001.php) (2001), [here](http://www.mrlc.gov/nlcd2006.php) (2006), and [here](http://www.mrlc.gov/nlcd2011.php) (2011).

They can be much improved and were the result of many hours of research in coding and GIS by one who knew nothing.

The greatest way that the tabulation script could be optimized would be to run the outside loop using parallel processing, which I haven't done yet. My solution has been to run four simultaneous sessions of RStudio, running four separate copies of the main script, each running 1/4 of the outside for-loop. Obviously parallelization would be better, as this is essentially what it would do.

If you make changes to the scripts that make them better, please feel free to submit the changes here, or email me if (like me) you don't really know much about github.

The scripts are written for a very specific dataset, but with hopefully minimal effort can be used for other datasets as well, or may have components that you may find useful.
