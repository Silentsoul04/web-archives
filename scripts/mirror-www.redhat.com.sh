#!/bin/bash

wget -x https://www.redhat.com/security/data/metrics/cve-metadata-from-bugzilla.xml
wget -x https://www.redhat.com/security/data/metrics/cve_dates.txt
wget -x https://www.redhat.com/security/data/metrics/release_dates.txt
wget -x https://www.redhat.com/security/data/metrics/rhsamapcpe.txt
wget -x https://www.redhat.com/security/data/metrics/cvemapcwe.txt
wget -x https://www.redhat.com/security/data/metrics/rpm-to-cve.xml
wget -x https://www.redhat.com/security/data/metrics/cpe-dictionary.xml

