#!/bin/bash

wget --append-output=log/cve.mitre.org -x https://cve.mitre.org/cve/request_id.html

#
# 130+ Meg files so split into 20k line chunks.
#
wget --append-output=log/cve.mitre.org -x https://cve.mitre.org/data/downloads/allitems.csv
cd cve.mitre.org/data/downloads/
split -l 20000 allitems.csv allitems.csv
rm -f allitems.csv
