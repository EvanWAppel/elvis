from typing import Any
import os

import polars as pl

import __init__ as variables

def SNHD_INSPECTIONS(

) -> pl.LazyFrame:
    lf:pl.LazyFrame = pl.scan_csv(
        variables.SNHD_INSPECTIONS,
        quote_char=None,
        infer_schema_length=None,
    )
    return lf

def FIRE_PREVENTION_INSPECTIONS(

) -> pl.LazyFrame:
    lf:pl.LazyFrame = pl.scan_csv(
        variables.FIRE_PREVENTION_INSPECTIONS,
        infer_schema_length=None,
    )
    return lf

def ART_WORK_POINTS(

) -> pl.LazyFrame:
    lf:pl.LazyFrame = pl.scan_csv(
        variables.ART_WORK_POINTS,
        infer_schema_length=None,
    )
    return lf

def EMPLOYEE_COMPENSATION(

) -> pl.LazyFrame:
    lf:pl.LazyFrame = pl.scan_csv(
        variables.EMPLOYEE_COMPENSATION,
        infer_schema_length=None,
    )
    return lf

def main(
        
) -> Any:
    ...

if __name__ == '__main__':
    main()