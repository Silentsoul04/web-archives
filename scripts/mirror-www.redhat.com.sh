#!/bin/bash

wget --append-output=log/www.redhat.com -x https://www.redhat.com/security/data/metrics/cve-metadata-from-bugzilla.xml
wget --append-output=log/www.redhat.com -x https://www.redhat.com/security/data/metrics/cve_dates.txt
wget --append-output=log/www.redhat.com -x https://www.redhat.com/security/data/metrics/release_dates.txt
wget --append-output=log/www.redhat.com -x https://www.redhat.com/security/data/metrics/rhsamapcpe.txt
wget --append-output=log/www.redhat.com -x https://www.redhat.com/security/data/metrics/cvemapcwe.txt
wget --append-output=log/www.redhat.com -x https://www.redhat.com/security/data/metrics/rpm-to-cve.xml
wget --append-output=log/www.redhat.com -x https://www.redhat.com/security/data/metrics/cpe-dictionary.xml

