#!/bin/bash

Help()
{
   echo "Script for cloning a production database into a test environment."
   echo
   echo "Syntax: $0 [-h|-s|]"
   echo "options:"
   echo "-h   Print this Help."
   echo "-s   Start step at what should the script be run."
   echo
}
 
START_STEP=1

while getopts ":hs:" option; do
   case $option in
      h)
         Help
         exit;;
      s)
         START_STEP=$OPTARG;;
      :)
        echo "Error: option -$OPTARG requires an argument (integer)"
        exit;;
     \?)
         echo "Error: invalid option, use -h for help"
         exit;;
   esac
done

if ! [[ ${START_STEP} =~ ^[0-9]+$ ]]; then
    echo "Error: -s argument must be an integer"
    exit 1
fi

echo "Start script from step: ${START_STEP}"

CURR_STEP=1
if [[ ${CURR_STEP} -eq ${START_STEP} ]]; then
    echo "Do work for step " ${CURR_STEP}
    ((START_STEP+=1))
else
    echo "Step" ${CURR_STEP} "skipped"
fi

CURR_STEP=2
if [[ ${CURR_STEP} -eq ${START_STEP} ]]; then
    echo "Do work for step " ${CURR_STEP}
    ((START_STEP+=1))
else
    echo "Step" ${CURR_STEP} "skipped"
fi

CURR_STEP=3
if [[ ${CURR_STEP} -eq ${START_STEP} ]]; then
    echo "Do work for step " ${CURR_STEP}
    ((START_STEP+=1))
else
    echo "Step" ${CURR_STEP} "skipped"
fi
