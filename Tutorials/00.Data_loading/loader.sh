#!/bin/bash

# instructions() {
#     echo "Load MySQL dump file(s) into a MySQL database" >&2
#     echo "Usage: $0 -db DATABASE -dir DIRECTORY"
# }

# while getopts db:dir:h option
# do
# case "${options}" in
# db) DATABASE=${OPTARG};;
# dir) DIRECTORY=${OPTARG};;
# h) instructions; exit 0;;
# \?)
#     echo "Option '-$OPTARG' is not a valid option-" >&2
#     instructions
#     exit 1
#     ;;
# :)
#     echo "Option '-$OPTARG' needs an argument." >&2
#     instructions
#     exit 1
#     ;;
# esac
# done

#!/bin/bash

instructions() {
    echo "Load MySQL dump file(s) into a MySQL database." >&2
    echo "Usage: $0 [-d DIRECTORY] [-n DATABASE] " >&2
    echo " -d Directory with dump files." >&2
    echo " -n Name of database to load tables into." >&2
}

while getopts d:n:h option
do
case "${option}" in
d) dumpdir=${OPTARG};;
n) dbname=${OPTARG};;
h) instructions; exit 0;;
\?)
    echo "Option '-$OPTARG' is not a valid option." >&2
    instructions
    exit 1
    ;;
:)
    echo "Option '-$OPTARG' needs an argument." >&2
    instructions
    exit 1
    ;;
esac
done


# find files
find $dumpdir -type f -name "*.sql" | while read dumpfile; do
    mysql $dbname < $dumpfile
    echo "Loaded $dumpfile into MysQL database $dbname." 
done