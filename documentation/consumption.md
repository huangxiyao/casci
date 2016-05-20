Consumption Model for CASCI
===========================

Goal
----

Be able to determine the percentage of usage of our assets per L2 (i.e. one level
below EG):

    EG: x%
    SW: y%
    ES: z%
    ??: a%


CASCI
-----

This includes only PRO

- Nexus
    - download/upload (PUT/GET)
    - storage being used by the artifacts
- Hudson
    - number of job runs (compute)
    - storage used by the jobs
- SVN
    - storage of active repositories only
- Sonar (Oracle)
    - nobody (except Brian!) is using it
    - probably nothing to measure here
    - Decomm candidate!

Formula per EPR ID =
    product of
        component weights (determined based on cost)
        with per-component percentage of use

Weights:
    distribution of a cost of storage for Nexus, storage for SVN and compute for Hudson
Per-component percentage of use:
    per-component - Nexus/Hudson/SVN, percentage - EPR ID use of that component compared to total use of that component


