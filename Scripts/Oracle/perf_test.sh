#!/bin/bash
sqlplus -s /nolog @perf_test.sql @1 &
sqlplus -s /nolog @perf_test.sql $1 &
sqlplus -s /nolog @perf_test.sql $1 &
sqlplus -s /nolog @perf_test.sql $1 &
sqlplus -s /nolog @perf_test.sql $1 &
