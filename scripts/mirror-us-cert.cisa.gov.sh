#!/bin/bash

wget --append-output=log/us-cert.cisa.gov -m -np https://us-cert.cisa.gov/ncas/alerts
wget --append-output=log/us-cert.cisa.gov -m -np https://us-cert.cisa.gov/ncas/bulletins
