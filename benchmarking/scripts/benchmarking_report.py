#!/usr/bin/python3

import time
import argparse
import os 
import re
import glob
import sys

path = '/cs/benchmarking/logs/'

#---
# date argument validation

def mkdate(datestr):
  try:
    return time.strptime(datestr, '%d%m%y')
  except ValueError:
    raise argparse.ArgumentTypeError(datestr + ' is not a proper date string')

parser=argparse.ArgumentParser()
parser.add_argument('DDMMYY',type=mkdate)
args=parser.parse_args()

date = sys.argv[1]

#---

def getListOfFiles(path):

    listOfFile = sorted(os.listdir(path))
    allFiles = list()

    for entry in listOfFile:
        fullPath = os.path.join(path, entry)

        if os.path.isdir(fullPath):
            allFiles = allFiles + getListOfFiles(fullPath)
        else:
            allFiles.append(fullPath)

    return allFiles        

def main():

    hosts = os.listdir(path)

    for host in hosts:
      hostpath = os.path.join(path, host)
      os.chdir(hostpath)
      tempfile = open(f'benchmarking_report.{date}.html',"w")
      os.chmod (f'benchmarking_report.{date}.html', 0o644)
    
      listOfFiles = getListOfFiles(hostpath)

      # report heading
      tempfile.write("<h1>")
      tempfile.write(host)
      tempfile.write(" benchmarking report")
      tempfile.write("\n</h1>")
      tempfile.write("<h3>Run date: ")
      tempfile.write(date)
      tempfile.write("\n</h3>")
      tempfile.write("<pre>")

      for elem in listOfFiles:
         if (date) in elem:
       
             f = open(elem,"r")

             benchmark = os.path.basename(elem).split('.', 2)[1]

             for line in f:
                 crowd_stop_match = re.search(r'Crowdstrike.*stopped',line)
                 crowd_start_match = re.search(r'Crowdstrike.*started',line)

                 if crowd_stop_match:
                    tempfile.write("<h2>")
                    tempfile.write("benchmark test: " + benchmark)
                    tempfile.write("</h2>")
                    tempfile.write("\n<pre>")
                    tempfile.write("<h3>crowdstrike stopped</h3>\n")

                 if crowd_start_match:
                    tempfile.write("\n<pre>")
                    tempfile.write("\n<h3>crowdstrike started</h3>\n")

                 tempfile.write(line)

if __name__ == '__main__':
    main()
