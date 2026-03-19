from typing import Any

import polars as pl

import __init__ as variables

def SNHD_INSPECTIONS(
        
) -> pl.LazyFrame:
    lf:pl.LazyFrame = pl.scan_csv(
        variables.SNHD_INSPECTIONS
    )
    return lf

def main(
        
) -> Any:
    ...

if __name__ == '__main__':
    main()