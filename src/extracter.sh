#!/bin/sh

# Dump metadata
mysqldump AvA Meta_public > data/metadata_tmp.sql
sed 's/Meta_public/metadata/' data/metadata_tmp.sql > data/metadata.sql
rm data/metadata_tmp.sql

mysql --database=AvA -e "select * from Meta_public" > data/metadata.tsv
python -c "import pandas as pd; df=pd.read_csv('data/metadata.tsv', sep='\t'); df.to_hdf('data/metadata.h5', key='metadata')"
echo "Retrived metadata"

# Dump ARG mapping results
mysqldump AvA AVA_public > data/ARG_tmp.sql
sed 's/AVA_public/ARG_results/' data/ARG_tmp.sql > data/ARG.sql
rm data/ARG_tmp.sql

mysql --database=AvA -e "select * from AVA_public" > data/ARG.tsv
python -c "import pandas as pd; df=pd.read_csv('data/ARG.tsv', sep='\t'); df.to_hdf('data/ARG.h5', key='ARG')"

echo "Retrived ARG data"

Dump diversity results
mysqldump AvA Diversity > data/diversity.sql
mysql --database=AvA -e "select * from Diversity" > data/diversity.tsv
python -c "import pandas as pd; df=pd.read_csv('data/diversity.tsv', sep='\t'); df.to_hdf('data/diversity.h5', key='diversity')"

echo "Retrived diversity data"

# Dump ResFinder annotation
mysqldump AvA ResFinder_anno > data/ResFinder_anno.sql
mysql --database=AvA -e "select * from ResFinder_anno" > data/ResFinder_anno.tsv
python -c "import pandas as pd; df=pd.read_csv('data/ResFinder_anno.tsv', sep='\t'); df.to_hdf('data/ResFinder_anno.h5', key='ResFinder_anno')"

echo "Retrived ResFinder anno"

# Dump rRNA mapping results
mysqldump AvA Bac_public > data/rRNA_tmp.sql
sed 's/Bac_public/rRNA_results/' data/rRNA_tmp.sql > data/rRNA.sql
rm data/rRNA_tmp.sql

mysql --database=AvA -e "select * from Bac_public" > data/rRNA.tsv
python -c "import pandas as pd; df=pd.read_csv('data/rRNA.tsv', sep='\t'); df.to_hdf('data/rRNA.h5', key='rRNA')"

echo "Retrived rRNA data"

echo "EOF."
