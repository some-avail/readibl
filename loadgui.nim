#[
Load some definitions from webgui_def.nim with data 
from external sources.
]#

import webgui_def
import fr_tools
import strutils
import os

var versionfl = 0.1


# [("calledname", "somelabel", @[["first-value", "first shown value"], ["second-value", "second shown value"]]), 
# ("text-language", "Text-language:", @[["dutch", "Dutch"], ["english", "English"]]), 
# ("taglist", "Pick taglist:", @[["paragraph-only", "Paragraph only"], ["full-list", "Full list"]])]


proc loadTextLangsFromConfig() =
  var
    valuelist: string
    sourcelangsq:seq[string]
    langvaluelistsq: seq[array[2, string]]
    tbo: bool = true


  # get the processing-languages from the config-file
  valuelist = readOptionFromFile("text-language", "value-list")
  sourcelangsq = valuelist.split(",,")
  if tbo: echo sourcelangsq

  # generate the new valuelist

  for langst in sourcelangsq:
    if fileExists(langst & ".dat"):
      langvaluelistsq.add([langst, capitalizeAscii(langst)])

  if tbo: echo langvaluelistsq
  if tbo: echo "=========="

  # locate and reset the languages from dropdownsta
  if tbo: echo dropdownsta[1]
  dropdownsta[1][2] = langvaluelistsq
  if tbo: echo dropdownsta[1]




loadTextLangsFromConfig()

when isMainModule:
  loadTextLangsFromConfig()
  
