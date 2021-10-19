#!/bin/bash

echo "You are wellcome!"
echo
read -p "Enter your name: " name
echo 
read -p "Enter your age: " age
echo
read -p "Enter your ale: " ale
echo 
echo $name
if [[ $age -lt 18 ]]
then
        let "X = 18 - $age"
        echo "Student"
        echo "At least $X years to become a worker"
elif [[ $age -ge 18 ]] && [[ $age -lt 65 ]]
then
        let "X = 65 - $age"
        echo "Worker"
        echo "$X years to retire."
elif [[ $age -ge 65 ]]
then
        let "X = $ale - $age"
        if [[ $age -lt $ale ]]
        then
                echo "Retire"
                echo "$X yesrs to die."
        else
                echo -ne '\007'
                echo "!!! Already died !!!"
                sleep 1
                clear
                sleep 1
                echo "!!! Already died !!!"
                sleep 1
                clear
                sleep 2
                echo "!!! Already died !!!"     
        fi
fi