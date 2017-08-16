#!/bin/sh
read -r STREAMNUM < .testrepository/next-stream
STREAMNUM=$(( $STREAMNUM-1 ))
cat .testrepository/$STREAMNUM | subunit-1to2 | subunit2junitxml > junit.xml
