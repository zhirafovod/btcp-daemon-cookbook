#!/usr/bin/python
from btcp.btcp import BtCP
from optparse import OptionParser
import sys

usage = ''' usage: %prog [options] filename dataReceivers
  filename - path to or a file name, like /var/tmp/file.txt
  dataReceivers - a list of data receivers, enclosed in quotas like 'dev1-1, dev1-2, dev1-3' '''

parser = OptionParser(usage=usage)
parser.add_option('-m', '--mode', action='store_true', dest='mode', default = True, help='mode of running')
(options, args) = parser.parse_args()

if (len(args) < 2):
  parser.print_help()
  sys.exit(1)

f = args[0]
drs = args[1]

#standalone = True
b = BtCP(standalone = True)
r = b.copy(files=(f,),dr=drs)
r = b.saveBtdataFile(n=f)
