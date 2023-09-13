#[ 
-implement source-files-module to:
  -be accessible from all modules
  -to limt file-access
 ]#

import strutils
import tables
import os
import fr_tools


var
  versionfl:float = 0.2
  textsourcefilesq: seq[string] = @["outer_html.html",
                                  "flashread.html"]

  textsourcefileta* = initTable[string, string]()
  sourcefilestatust*: string = ""
  faultsfoundbo: bool = false


proc addLanguageFiles() =
  # dynamicly add the language.dat files from the config-file
  var
    valuelist: string
    sourcelangsq:seq[string]
    tbo: bool = false


  # get the processing-languages from the config-file
  valuelist = readOptionFromFile("text-language", "value-list")
  sourcelangsq = valuelist.split(",,")
  if tbo: echo sourcelangsq


  # generate the new valuelist
  for langst in sourcelangsq:
    textsourcefilesq.add(langst & ".dat")

  if tbo: echo textsourcefilesq


proc loadTextSourceFiles() =
  try:

    for keyst in textsourcefilesq:
      if fileExists(keyst):
        textsourcefileta[keyst] = readFile(keyst)
      else:
        if faultsfoundbo:   # previous faults found
          sourcefilestatust &= keyst & "  "
        else:   # first fault found
          faultsfoundbo = true
          sourcefilestatust = "The following files could not be found: "
          sourcefilestatust &= keyst & "  "

  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error ******* \p" 
    echo repr(errob) & "\p****End exception****\p"


addLanguageFiles()
loadTextSourceFiles()

when isMainModule:
  # echo textsourcefileta["dutch.dat"]
  echo sourcefilestatust

