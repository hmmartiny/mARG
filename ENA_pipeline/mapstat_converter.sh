#!/bin/bash

loaded=$(module list)

if [[ ! "$loaded" == *"anaconda3/4.0.0"* ]] ; then
    module load anaconda3/4.0.0
fi

if [[ ! "$loaded" == *"mariadb/10.5.8"* ]]; then
    module load mariadb/10.5.8
fi

if [ -z $file ]; then
    file=$1
fi

# missing for table mapstat_data
# run_accession, db, db_version, run_date, kma_version

# columns for table mapstat_header
# run_accession, command, db, db_version, fragmentCount, run_date, method, method_version

if [ ! -e $file ]; then
    echo "$file does not exist!"
    exit 1
fi

mapstat_data_file=${file/\.mapstat/\.data\.mapstat}
mapstat_header_file=${file/\.mapstat/\.header\.mapstat}

> $mapstat_data_file

filename=$(echo $file | cut -d'/' -f10 | tr -d '[:blank:]')
db=$(echo $filename | cut -d'_' -f1 | tr -d '[:blank:]')
db_version=$(echo $filename | cut -d'_' -f2 | tr -d '[:blank:]')
run_accession=$(echo $filename | cut -d'_' -f4 | tr -d '[:blank:]')
run_accession=${run_accession/\.mapstat/}

date_line=$(grep "^## date" $file | cut -d' ' -f2)
run_date=$(echo ${date_line/date/} | tr -d '[:blank:]')

version_line=$(grep "^## version" $file | cut -d' ' -f2 )
kma_version=$(echo ${version_line/version/} | tr -d '[:blank:]')

command_line=$(grep "^## command" $file)
kma_command=${command_line/\#\# command/}
kma_command=$(echo $kma_command | xargs )

method='KMA'

fragmentCount_line=$(grep "^## fragmentCount" $file | cut -d' ' -f2)
fragmentCount=$(echo ${fragmentCount_line/fragmentCount/} | tr -d '[:blank:]')

data_str="$run_accession\t$db\t$db_version\t$run_date\t$kma_version\t"
col_str="run_accession\tdb\tdb_version\trun_date\tkma_version\t"
while read l; do
    if [[ ! $l =~ "##" ]]; then
        if [[ $l =~ "#" ]]; then
            oline="$col_str$l" 
            echo -e "$oline" >> $mapstat_data_file
        else
            oline="$data_str$l"
            echo -e "$oline" >> $mapstat_data_file
        fi
    fi
done < $file

echo -e "$run_accession\t$kma_command\t$db\t$db_version\t$fragmentCount\t$run_date\t$method\t$kma_version\n" > $mapstat_header_file

if [ -e $mapstat_data_file ]; then
    sed -i 's/\t/,/g' $mapstat_data_file
    mysql -e "LOAD DATA LOCAL INFILE '"$mapstat_data_file"' IGNORE INTO TABLE mapstat_data FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 ROWS;" 
    rm $mapstat_data_file
fi

if [ -e $mapstat_header_file ]; then
    sed -i 's/\t/,/g' $mapstat_header_file

    mysql -e "LOAD DATA LOCAL INFILE '"$mapstat_header_file"' IGNORE INTO TABLE mapstat_header FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n';" 
    rm $mapstat_header_file
fi
