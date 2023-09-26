#!/bin/sh

mkdir -p reframework/autorun
cp src/manual_flashlight.lua reframework/autorun/
zip -r manual_flashlight.zip reframework
rm -r reframework
