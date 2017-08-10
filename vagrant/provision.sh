#!/bin/bash

date | tee /tmp/date
whoami | tee -a /tmp/date
