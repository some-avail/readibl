#[
Load some definitions from webgui_def.nim with data 
from external sources, esp. the config-file:
settings_flashread.conf
]#


import webgui_def
import fr_tools
import strutils
import os
import tables


var versionfl = 0.2


# [("calledname", "somelabel", @[["first-value", "first shown value"], ["second-value", "second shown value"]]), 
# ("text-language", "Text-language:", @[["dutch", "Dutch"], ["english", "English"]]), 
# ("taglist", "Pick taglist:", @[["paragraph-only", "Paragraph only"], ["full-list", "Full list"]])]


proc loadTextLangsFromConfig() =
  
# Set the processing-languages of the dropdown "dropdownsta" of webgui_def.nim from the config-file

  var
    valuelist: string
    sourcelangsq:seq[string]
    langvaluelistsq: seq[array[2, string]]
    tbo: bool = false


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



proc setCheckboxSetFromConfig(setnamest: string) = 
  # Copy the default-values from the config file for checkboxset "setnamest" of webgui_def.nim

  var buttonsq: seq[tuple[name:string, description: string, boolean_state: bool]] = checkboxesta[setnamest]
  # var buttonsq = checkboxesta[setnamest]

  var
    valuelist: string
    valuesq: seq[string]
    tbo: bool = false
    countit: int = 0

  if tbo: echo buttonsq

  # get default-values from config-file
  valuelist = readOptionFromFile(setnamest, "value-list")

  if tbo: echo valuelist

  valuesq = valuelist.split(",,")

  # set the checkbox-values
  for buttontu in buttonsq:
    # buttonsq[countit][2] = parseBool(valuesq[countit])
    checkboxesta[setnamest][countit][2] = parseBool(valuesq[countit])
    countit += 1

  if tbo: echo buttonsq


loadTextLangsFromConfig()
setCheckboxSetFromConfig("fr_checkset1")

