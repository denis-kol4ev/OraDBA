#!/bin/bash

if [[ $# -eq 0 ]]; then
    START_STEP=1
else 
    START_STEP=$1
fi

CURR_STEP=1
if [[ ${CURR_STEP} -eq ${START_STEP} ]]; then
    echo "Do work for step " ${CURR_STEP}
    ((START_STEP+=1))
else
    echo "Step " ${CURR_STEP} " skipped"
fi

CURR_STEP=2
if [[ ${CURR_STEP} -eq ${START_STEP} ]]; then
    echo "Do work for step " ${CURR_STEP}
    ((START_STEP+=1))
else
    echo "Step " ${CURR_STEP} " skipped"
fi

CURR_STEP=3
if [[ ${CURR_STEP} -eq ${START_STEP} ]]; then
    echo "Do work for step " ${CURR_STEP}
    ((START_STEP+=1))
else
    echo "Step " ${CURR_STEP} " skipped"
fi