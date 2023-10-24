#[ 
-implement source-files-module to:
  -be accessible from all modules
  -to limt file-access
 ]#

import strutils, sequtils
import tables
import os
import fr_tools
import algorithm


type
  DataFileType* = enum
    datFileLanguage
    datFileSummary
    datFileAll

  FileSpecs = object of RootObj
    fsName: string
    fsVersion: float

  FilePhase = object of FileSpecs
    phaNameFull: string   # block-header-name
    phaSequenceNum: int   # order-num in phase-list
    phaNameCount: int     # should be 1
    phaItemCount: int     # preferably > 0
    phaHasEmptyItem: bool    # = zero-length line; must be false
    phaEndMarkerFound: bool   # must be true


var
  versionfl:float = 0.2
  textsourcefilesq: seq[string] = @["outer_html.html",
                                  "flashread.html"]

  textsourcefileta* = initTable[string, string]()
  sourcefilestatust*: string = ""
  faultsfoundbo: bool = false

  parse_file_phasesq = @[
        "PUNCTUATION OF SENTENCES TO HANDLE",
        "PUNCTUATION OF SENTENCE-PARTS TO HANDLE",
        "PRONOUNS TO HANDLE",
        "VERBS TO HANDLE",
        "LINK-WORDS TO HANDLE",
        "PREPOSITIONS TO HANDLE",
        "NOUN-ANNOUNCERS TO HANDLE",
        "NOUN-REPLACERS TO HANDLE",
        "AMBIGUOUS WORD-FUNCTIONS TO HANDLE"]

  summary_file_phasesq = @["SIGNAL-WORDS TO HANDLE"]



template withFile*(f, fn, mode, actions: untyped): untyped =
  var f: File
  if open(f, fn, mode):
    try:
      actions
    finally:
      close(f)
  else:
    quit("cannot open: " & fn)


proc addLanguageFilesToList() =
  # Dynamicly add the parse_language.dat files from the config-file 
  # to the list textsourcefilesq

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
    # textsourcefilesq.add(langst & ".dat")
    textsourcefilesq.add("parse_" & langst & ".dat")

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




proc writeFilePatternToSeq*(filestartwithst: string): seq[string] = 

#[ Write the files from pattern in the current dir to the sequence and
 return that]#

  var
    filelisq: seq[string]
    filenamest: string
  

  # walk thru the file-iterator and sequence the right file(names)
  for kind, path in walkDir(getAppDir()):
    if kind == pcFile:
      filenamest = extractFileName(path)
      if len(filenamest) > len(filestartwithst):
        if filenamest[0..len(filestartwithst) - 1] == filestartwithst:
          # log(filenamest)
          filelisq.add(filenamest)

  result = filelisq




proc evaluateDataFiles*(verbosebo: bool = false): string = 
  #[
    Validate the file-sets parse_*.dat and summary_*.dat
    Deviations / complaints are reported.
    The result are show at startup.
    ]#

  var
    parse_lang_filesq, summary_filesq, all_filesq: seq[string]
    file_reportta = initOrderedTable[string, FilePhase]()
    tablekeyst: string
    reportst: string = "<b>Validation of the datafiles (no comment = OK):</b>\p<br>"
    phasecountit, itemcountit: int
    inphasebo: bool = false
    endmarkerst: string = ">----------------------------------<"
    phasesq: seq[string]


  parse_lang_filesq = writeFilePatternToSeq("parse_")
  summary_filesq = writeFilePatternToSeq("summary_")
  all_filesq = concat(parse_lang_filesq, summary_filesq)

  # write the eval to a table (file_reportta) of objects (FilePhase)
  if true:
    for filest in all_filesq:
      phasecountit = 1
      # select correct phase-sequence
      case filest[0..4]
      of "parse":
        phasesq = parse_file_phasesq
      of "summa":
        phasesq = summary_file_phasesq

      for phasest in phasesq:
        tablekeyst = filest & "___" & phasest[0..phasest.len - 11]
        # preset objects for file
        file_reportta[tablekeyst] = FilePhase(
          fsName: filest,
          phaNameFull: phasest,
          phaNameCount: 0,
          phaSequenceNum: phasecountit,
          phaItemCount: 0,
          phaHasEmptyItem: false,
          phaEndMarkerFound: false
          )
        phasecountit += 1

      withFile(txt, filest, fmRead):
        for linest in txt.lines:
          if linest in phasesq:
            inphasebo = true
            itemcountit = 0
            # blockphase reached; update object
            tablekeyst = filest & "___" & linest[0..linest.len - 11]
            file_reportta[tablekeyst].phaNameCount += 1
          elif inphasebo:
            if linest == endmarkerst:
              file_reportta[tablekeyst].phaItemCount = itemcountit
              file_reportta[tablekeyst].phaEndMarkerFound = true
              inphasebo = false
            else:   # walking thru items
              if linest.len == 0:
                file_reportta[tablekeyst].phaHasEmptyItem = true
              file_reportta[tablekeyst].phaItemCount = itemcountit              
            itemcountit += 1


  # read the objects-table and create a basic html-report
  var 
    curfilest, formerfilest: string
    curphasest, formerphasest: string
    complaintst, endst, startst: string
    faultfoundbo: bool = false
    skip_othersbo: bool = false

  startst = "<br>\p"
  endst = "<br>\p"

  for keyst, valob in file_reportta:

    curfilest = valob.fsName
    curphasest = valob.phaNameFull
    if curfilest != formerfilest:
      reportst &= curfilest & endst

    complaintst = ""

    if valob.phaNameCount == 0:
      complaintst &= "---- This block-phase is not found (or mis-spelled)" & endst
      faultfoundbo = true
      skip_othersbo = true
    elif valob.phaNameCount > 1:
      complaintst &= "---- This block-phase occurs multiple times: " & $valob.phaNameCount & endst
      faultfoundbo = true
      skip_othersbo = true
    if not valob.phaEndMarkerFound:
      if not skip_othersbo:
        complaintst &= "---- This block-phase has no (valid) end-marker" & endst
        faultfoundbo = true
        skip_othersbo = true
    if valob.phaItemCount == 0:
      if not skip_othersbo:
        complaintst &= "---- This block-phase has NO items (no lines)" & endst
        faultfoundbo = true
    if valob.phaHasEmptyItem:
      if not skip_othersbo:
        complaintst &= "---- This block-phase has EMPTY items (zero-length lines)" & endst
        faultfoundbo = true

    formerfilest = valob.fsName

    if faultfoundbo or verbosebo:
      reportst &= "++ " & curphasest & endst
      reportst &= complaintst
      if verbosebo:
        reportst &= $valob & endst

    faultfoundbo = false
    skip_othersbo = false
  
  result = reportst


proc compareDataFiles(firstfilest, secfilest, formatst: string): string = 
    #[Compare files (for now only summary-files) and return 3 sorted lists:
    -equal words
    -words in first not second
    -words in second not first
    ]#

  var
    firstsq, secsq, bothsq, onlyfirstsq, onlysecsq: seq[string]
    blockphasebo: bool = false
    startmarkerst = "SIGNAL-WORDS TO HANDLE"
    endmarkerst = ">----------------------------------<"
    filear: array[0..1, string] = [firstfilest, secfilest]
    wordseqar: array[0..1, seq[string]] = [@[], @[]]
    lineseptst, outputst: string
    outputseqar: array[0..2, seq[string]]
    passit: int = 0


  # create sorted seqs from the files
  for it in 0..1:
    withFile(txt, filear[it], fmRead):
      for linest in txt.lines:
        if linest == startmarkerst:
          blockphasebo = true
        elif linest == endmarkerst:
          blockphasebo = false
        else:
          if blockphasebo:
            wordseqar[it].add(linest)
    sort(wordseqar[it])
    # echo wordseqar[it]


  # compare the seqs; create comparison-lists
  firstsq = wordseqar[0]
  secsq = wordseqar[1]

  for wordst in firstsq:
    if wordst in secsq:
      bothsq.add(wordst)
    else:
      onlyfirstsq.add(wordst)
  for wordst in secsq:
    if not (wordst in firstsq):
      onlysecsq.add(wordst)


  # report the results
  if formatst == "text":
    lineseptst = "\p"
  elif formatst == "html":
    lineseptst = "<br>"

  outputseqar = [bothsq, onlyfirstsq, onlysecsq]

  outputst = lineseptst & "---------------------------------------" & lineseptst
  outputst &= "First file: " & firstfilest & lineseptst
  outputst &= "Second file: " & secfilest & lineseptst
  
  for sq in outputseqar:
    if passit == 0:
      outputst &= lineseptst & "Words in both files:" & lineseptst
    elif passit == 1:
      outputst &= lineseptst & "Words only in FIRST file:" & lineseptst
    elif passit == 2:
      outputst &= lineseptst & "Words only in SECOND file:" & lineseptst

    for wordst in outputseqar[passit]:
      outputst &= wordst & lineseptst
    passit += 1

  result = outputst




addLanguageFilesToList()
loadTextSourceFiles()



when isMainModule:
  # echo textsourcefileta["dutch.dat"]
  # echo sourcefilestatust

  # echo evaluateDataFiles(datFileAll)
  echo compareDataFiles("summary_english_concise.dat", "summary_english_default.dat","text")



