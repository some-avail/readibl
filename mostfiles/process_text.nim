#[ 
BEWARE: compile https-stuff with switch -d:ssl

UNIT INFO

ADAP HIS
-adjust definition-code towards text-processing
-impl. word-frequency-counts
-create radio-buttons
-rearrange status-div above form-div
-color the top-header
-implement extracted text from url
  v-create radio buttons:
    -text from url
    -retext from text
-add summarizing function
-full-page reformating
  -handleTextPartsFromHtml
    -change applyDefinitionFileToText so that the 
    language-defs are only read ones from file on startup


ADAP NOW
-improve reformating:
  v-replace paragraph-handling for a whitelist-sequence like:
    [["<p", "</p>"], ["starttag", "endtag"]]
  -for ex-situ fmt use a different sequence


ADAP FUT
-extracted text-function (etf):
  -improve extraction:
    -test and improve normal text-extraction
    -add header-tags (h1, h2 etc.) to raw text
  -streamline the code
  -prepend header-tags as a contents-list
 ]#


import strutils
import httpClient
import tables, algorithm
import stringstuff
import source_files

# no longer used:
# import os, times, sequtils
# import fr_tools


type
  AddressPart* = enum
    addrBase
    addrParent
    addrGrandParent



var debugbo: bool = false

template log(messagest: string) =
  # replacement for echo that is only evaluated when debugbo = true
  if debugbo: 
    echo messagest


const 
  versionfl:float = 0.38

  input_tekst = "chimpansee noot mies een chimpansee is een leuk dier\pde chimpansee is het slimste dier naar het schijnt.\pmaar naast de chimpansee zijn er ook andere slimme \pdieren zoals de raaf, de dolfijn en de hond."
  tekst = "pietje staat. gister niet, maar toch. wat\pjantje. wimpie, onno\pkeesje.grietje,antje\pdirkje"
  meertekst = """
  De gezondheidscrisis waarvan Europa het epicentrum is geworden zet niet alleen de zorgsector onder zware druk: ook de Europese solidariteit vertoont scheuren.
Alle lelijke trekjes die de Europese politiek de afgelopen jaren vertoonde, kwamen de afgelopen weken weer pijnlijk aan de oppervlakte: het blokkeren van gezamenlijke besluiten, het weigeren van hulp en het maken van morele verwijten. Net als tijdens de kredietcrisis en de daaropvolgende eurocrisis. Donderdag overlegden Europese regeringsleiders op een videoconferentie over een gezamenlijke respons op de economische gevolgen. Maar dat het heikelste punt vooruit werd geschoven, toont vooral verdeeldheid.
  """

  testtekst_eng = """
  Testing-text here. The first principle is good. But then. Under
the condition of something. Not any more. sometekst. 
The first one is understood. what is up. The third and second are not. 

Point taken. You must do this. That is always good. 
Some other text without signalling words. And 
some abbreviations e.g. in the U.S., in the U.K.
But never here. Bye all rules....
"""

  testtekst_nl = """
Dit is een testtekst. Deze is heel belangrijk, maar niet heus....
Maar wat. Het is een voorwaarde toch? Of niet. Je kan alle kanten 
op. Wat is de conclusie dan. Dat sommige zinnen verdwijnen. En 
anderen blijven. Inhoeverre is er een verband? een beetje misschien.
Echter, het kan ook onzin zijn. Er zijn veel scenarios mogelijk.
Dus trek niet te snel een conclusie. Want dan gaat het mis.
Afko zoals m.b.t., i.g.v. worden niet meegenomen, toch? Of wel.
"""

  addresstekst = """
<title>NRC - Nieuws, achtergronden en onderzoeksjournalistiek</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="stylesheet" href="/static/front/build/css/main.accbd5b30.css">
<link rel="stylesheet" href="/static/front/build/css/split/dossier-themes.775140998.css">
<link rel="stylesheet" href="/static/front/build/css/split/selections-bar.-778058140.css">
<link rel="file" href="//www.liveinternet.iets"
  """


proc testWebSite() =
  var client = newHttpClient()
  var webaddresst:string

  try:
    echo "Webadres ingeven aub:"
    webaddresst = readLine(stdin)
    webaddresst = "http://" & webaddresst
    echo webaddresst
    echo client.getContent(webaddresst)

  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error ******* \p" 
    echo repr(errob) & "\p****End exception****\p"


proc getSubstringPositions(stringst, subst: string):seq[int] = 
  #[
  Return positions of all occurrences of the substring in the string 
  and put them in a list. Zero-based.
  ]#

#  echo stringst
#  echo subst

  var 
    subpositionsq: seq[int] = @[]
    fragmentsq: seq[string]
    occurit, posit: int


  fragmentsq = stringst.split(subst)
#  echo fragmentsq
  posit = 0    # needy for zero-basing
  occurit = stringst.count(subst)
#  echo "occurit= " & $occurit
  for i in 1 .. occurit:
  #  echo "i=" & $i
    posit += len(fragmentsq[i-1])
  #  echo "posit=" & $posit
    subpositionsq.add(posit)
    posit += len(subst)  
#  echo subpositionsq
  
  return subpositionsq




proc getDataBetweenTags(tekst, starttagst, endtagst:string,
                     occurit:int):string =
  #[ 

  UNIT INFO:
  xml-function; xml builds up and peels off like an onion.
  Get the data between the tag-pair starttag and endtag for 
  the occurit-th occurrence of the pair. (zero-based)
  The function raises an index-error if tags or occurrences 
  dont exist.

  call like: getDataBetweenTags(sometext, "<tr>", "</tr>", 2)
      to get the third table-row

  BUGGY: echo getDataBetweenTags("<>a<>b<><>d<>", ">", "<", 0)
        FAILS
   ]#

  var
    starttagpositonssq, endtagpositionssq: seq[int]
    starttagposit, endtagposit, nextit: int
    resultst:string
    invalid_stringbo: bool = false

  log("****************")
  log(tekst)
  log(starttagst & " - " & endtagst)
  starttagpositonssq = getSubstringPositions(tekst, starttagst)
  log("starttagpositonssq = " & $starttagpositonssq)
  endtagpositionssq = getSubstringPositions(tekst, endtagst)
  log("endtagpositionssq = " & $endtagpositionssq)

  starttagposit = starttagpositonssq[occurit]
  endtagposit = endtagpositionssq[occurit]

  nextit = 1
  while starttagposit > endtagposit:
    if (occurit + nextit) <= count(tekst, starttagst) - 1:
      endtagposit = endtagpositionssq[occurit + nextit]
      nextit += 1
    else:
      invalid_stringbo = true
      break

  log("length of textpart: " & $(endtagposit - starttagposit))

  log($starttagposit)
  log($endtagposit)

#    resultst = tekst[tekst.index(starttagst), tekst.index(endtagst)]
  if not invalid_stringbo:
    resultst = tekst[starttagposit + len(starttagst) .. endtagposit - 1]
  else:
    resultst = ""
  # echo "resultst = " & resultst
  
  return resultst



proc getInnerText(tekst: string): string =  
  # Concatenate all texts between ">" and "<" in
  # the string: "tekst"

  var 
    innertekst: string
    smallerit, biggerit: int

  innertekst = ""
  
  try:
    log "-------------------------------"
    biggerit = count(tekst, ">")
    for it in 0 .. (biggerit - 1):
      log($it)
      innertekst &= getDataBetweenTags(tekst, ">", "<", it) & " "
    log("tekst=" & tekst)
    log("innertekst=" & innertekst)
    result = innertekst

  
  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error ******* \p" 
    echo repr(errob) & "\p****End exception****\p"

  
proc myTest()=
  for x in 0..<3:
    log($x)



proc extractTextPartsFromHtml*(webaddresst:string = ""):string =
  #[ 
  Deprecated; see handleTextPa...
  Based on the webaddress as input-parameter, the webpage is downloaded.
  Then the html is parsed and pieces of readable text (aot markup-codes)
  are extracted, concatenated and returned to procedure.
   ]#

  var
    client = newHttpClient()
    websitest, test:string
    textpartsq:seq[string] = @[]
    textpartst, textallst:string
    substringcountit: int
    substringpossq: seq[int]
    posit, textstartit, textendit:int
    foundbo:bool = false
    allfoundbo: bool = false
    proef:string
    tellit:int
    pos2it:int

  const
    allowedtagsar=["a", "abbr", "b", "br", "em", "ins", "main", "mark", "q", "small", "span", "strong", "time", "wbr"]

  try:

    websitest = client.getContent(webaddresst)
    echo "charcount = " & $len(websitest)

    substringcountit = count(websitest, "<p>")
    echo "\ptagcount = " & $substringcountit

    posit = -1
    tellit = 0

    while not allfoundbo:
      while not foundbo: # no paragraph-start found yet
        tellit += 1
        # echo tellit
        posit = find(websitest, "<p", posit + 1)
        # echo posit
        # proef = websitest[posit .. posit + 5]
        # # echo proef
        test = websitest[posit + 2 .. posit + 2]
        # echo test & "---"

        if posit != -1:
          if test == " " or test == ">":   # <p with our without atrributes; search for >
            textstartit = posit      
            foundbo = true
            # proef = websitest[posit .. posit + 5]
            # echo proef
            # echo "posit=" & $posit
            # echo test
            # echo "found"
        else:
          # no paragraphs found anymore
          foundbo = true
          allfoundbo = true
          echo "allfound = true"

        # if tellit == 1000:
        #   foundbo = true
        #   allfoundbo = true
        #   echo "tellit= " & $tellit

      foundbo = false
      if not allfoundbo:
        # search paragraph-end
        pos2it = posit
        pos2it = find(websitest, "</p>", pos2it + 1)

        if pos2it != -1:
          textendit = pos2it + 4
          echo "pos2it= " & $pos2it
          # echo textstartit
          # echo textendit
          textpartst = websitest[textstartit .. textendit]
          textallst &= textpartst
          # echo "\p============processText=========================="
          # echo textpartst
          # echo "================================================="
        else:
          echo "Tag </p> not found; paragraph unclosed"

    return textallst

  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error ******* \p" 
    echo repr(errob) & "\p****End exception****\p"



proc calculateWordFrequencies*(input_tekst:string, wordlengthit:int,
                            useHtmlBreaksbo:bool):string = 

  var
    sentencesq, wordsq, allwordssq: seq[string]
    output_tekst:string
  
  sentencesq = splitlines(input_tekst)
  # echo sentencesq
  # echo "\p"
  for sentencest in sentencesq:
    wordsq = sentencest.split(" ")
    for wordst in wordsq:
      if len(wordst) >= wordlengthit:
        if not ("=" in wordst or ":" in wordst):
          allwordssq.add(wordst)

  # echo allwordssq
  # echo "\p"
  var wordcountta = toCountTable(allwordssq)
  wordcountta.sort()
  # echo wordcountta
  # echo "\p"

  for k, v in wordcountta.pairs:
    if useHtmlBreaksbo:
      output_tekst &= k & " - " & $v & "<br>"
    else:
      output_tekst &= k & " - " & $v & "\p"
  return output_tekst



proc applyDefinitionFileToText(input_tekst, languagest: string, 
                    highlightbo: bool, summaryfilest: string = ""): string =

  # Is now used in 2 cases / passes with separate arguments:
  # - signal-words-based hightlighting using the file 'summary_language_qualifier.dat'
  #     > so you get for example: 'summary_english_concise.dat'
  # - grammar-based text-coloring using the file 'language.dat'
  #     > reads from preloaded textfilestring from module source_files
  

  var 
    blockheadersq: seq[string]
    blockphasest: string = ""
    blocklineit: int
    blockseparatorst = ">----------------------------------<"
    lastline: string
    all_argst: string
    phasetekst:string = input_tekst
    def_filenamest:string
    use_custom_replacebo: bool = true
    deffilest:string

  phasetekst = replace(phasetekst, ".<", ". <")
  phasetekst = replace(phasetekst, ".\"", ". \"")
  
  
  if highlightbo == false:
    log("text coloring....")
    def_filenamest = languagest & ".dat"
    deffilest = textsourcefileta[def_filenamest]
    blockheadersq = @[
        "PUNCTUATION OF SENTENCES TO HANDLE",
        "PUNCTUATION OF SENTENCE-PARTS TO HANDLE",
        "PRONOUNS TO HANDLE",
        "VERBS TO HANDLE",
        "LINK-WORDS TO HANDLE",
        "PREPOSITIONS TO HANDLE",
        "NOUN-ANNOUNCERS TO HANDLE",
        "NOUN-REPLACERS TO HANDLE",
        "AMBIGUOUS WORD-FUNCTIONS TO HANDLE"]
  elif highlightbo == true:
    log("==============================")
    log("highlighting...")
    def_filenamest = summaryfilest
    log(def_filenamest)
    deffilest = readFile(def_filenamest)
    blockheadersq = @["SIGNAL-WORDS TO HANDLE"]
    use_custom_replacebo = true


  try:
    # walk thru the lines of the def-file
    echo "\n=====Begin processing===="
    for line in deffilest.splitlines:
      lastline = line

      # check for block-header
      if line in blockheadersq:
        blockphasest = line
        echo blockphasest
        blocklineit = 0
      elif blockphasest != "":

        blocklineit += 1
        if line != blockseparatorst:   # block-separating string

          #echo "line = " & line
          
          if blockphasest == "PUNCTUATION OF SENTENCES TO HANDLE":
            # if use_custom_replacebo:
            phasetekst = customReplace(phasetekst, line, line & "<br>&nbsp;&nbsp;&nbsp;&nbsp;",
                                  true, "unique_occurrence", @[15])
            # else:
            #   phasetekst = replace(phasetekst, line, line & "<br>&nbsp;&nbsp;&nbsp;&nbsp;")
          elif blockphasest == "PUNCTUATION OF SENTENCE-PARTS TO HANDLE":
            # if use_custom_replacebo:
            phasetekst = customReplace(phasetekst, line, line & "<br>",
                                  true, "unique_occurrence", @[25])
            # else:
            #   phasetekst = replace(phasetekst, line, line & "<br>")
          elif blockphasest == "PRONOUNS TO HANDLE":
            # if use_custom_replacebo:
            phasetekst = customReplace(phasetekst, line, "<br>" & line,
                                    true, "", @[])
            # else:
            #   phasetekst = replace(phasetekst, line, "<br>" & line)
          elif blockphasest == "VERBS TO HANDLE":
            # if use_custom_replacebo:
            phasetekst = customReplace(phasetekst, line, "<span style=color:magenta>" & line & "</span>",
                                    true, "", @[])
            # else:
            #   phasetekst = replace(phasetekst, line, "<span style=color:magenta>" & line & "</span>")
          elif blockphasest == "SIGNAL-WORDS TO HANDLE":
            # if use_custom_replacebo:
            phasetekst = customReplace(phasetekst, line, "<span style=background-color:#ffd280>" & line & "</span>",
                                    true, "", @[])
            # else:
            #   phasetekst = replace(phasetekst, line, "<span style=background-color:#ffd280>" & line & "</span>")
          elif blockphasest == "LINK-WORDS TO HANDLE":
            # if use_custom_replacebo:
            phasetekst = customReplace(phasetekst, line, "<span style=color:red>" & line & "</span>",
                                    true, "", @[])
            # else:
            #   phasetekst = replace(phasetekst, line, "<span style=color:red>" & line & "</span>")
          elif blockphasest == "PREPOSITIONS TO HANDLE":
            # if use_custom_replacebo:
            phasetekst = customReplace(phasetekst, line, "<span style=color:limegreen>" & line & "</span>",
                                    true, "", @[])
            # else:
            #   phasetekst = replace(phasetekst, line, "<span style=color:limegreen>" & line & "</span>")
          elif blockphasest == "NOUN-ANNOUNCERS TO HANDLE":
            # if use_custom_replacebo:
            phasetekst = customReplace(phasetekst, line, "<span style=color:#b35919>" & line & "</span>",
                                    true, "", @[])
            # else:
            #   phasetekst = replace(phasetekst, line, "<span style=color:#b35919>" & line & "</span>")
          elif blockphasest == "NOUN-REPLACERS TO HANDLE":
            # if use_custom_replacebo:
            phasetekst = customReplace(phasetekst, line, "<span style=color:darkturquoise>" & line & "</span>",
                                    true, "", @[])
            # else:
            #   phasetekst = replace(phasetekst, line, "<span style=color:darkturquoise>" & line & "</span>")
          elif blockphasest == "AMBIGUOUS WORD-FUNCTIONS TO HANDLE":
            # if use_custom_replacebo:
            phasetekst = customReplace(phasetekst, line, "<span style=color:#e6b800>" & line & "</span>",
                                    true, "", @[])
            # else:
            #   phasetekst = replace(phasetekst, line, "<span style=color:#e6b800>" & line & "</span>")


        else:
          # then the former block is completed
          blockphasest = ""
          # set arguments to none here:
          # somearg = none
      
          # remove superflous whitelines
          phasetekst = replace(phasetekst, ",<br><br><br>", ",<br>")
          phasetekst = replace(phasetekst, ",<br><br>", ",<br>")
          phasetekst = replace(phasetekst, ",<br> <br>", ",<br>")
          phasetekst = replace(phasetekst, ", <br><br><br>", ",<br>")
          phasetekst = replace(phasetekst, ", <br><br>", ",<br>")
          phasetekst = replace(phasetekst, ", <br> <br>", ",<br>")
          phasetekst = replace(phasetekst, "<br> <br>", "<br><br>")
          phasetekst = replace(phasetekst, "<br><br><br><br>", "<br><br>")
          phasetekst = replace(phasetekst, "<br><br><br>", "<br><br>")
          phasetekst = replace(phasetekst, "<br><p>", "<p>")

    echo "===End of processing===="
  
  except IOError:
    echo "IO error!"
  
  except RangeDefect:
    echo "\p\p+++++++ search-config not found +++++++++++\p"
    echo "You have probably entered a search-config that could not be found. \p" &
        "Re-examine you search-config. \p" &
        "The problem originated probably in the above EDIT FILE-block"
    let errob = getCurrentException()
    echo "\p******* Technical error-information ******* \p" 
    echo "block-phase: " & blockphasest & "\p"
    echo "Last def-file-line read: " & lastline & "\p"
    echo repr(errob) & "\p****End exception****\p"

  
  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error ******* \p" 
    echo "block-phase: " & blockphasest & "\p"
    echo "Last def-file-line read: " & lastline & "\p"
    echo repr(errob) & "\p****End exception****\p"

  return phasetekst


proc getBaseFromWebAddress2(webaddresst: string, expandparentbo: bool = false): string = 
#[ 
  Non-expanded full base: http://www.x.nl/a/b/c/blah.html  becomes  http://www.x.nl
  Expand to parent: http://www.x.nl/a/b/c/blah.html  becomes  http://www.x.nla/b/c
 ]#

  var 
    addressq: seq[string]
    basewebaddresst, expanded_addresst: string
    tbo: bool = false
    countit: int = 0

  # firstly chop the address up on the slashes
  addressq = webaddresst.split("/")
  # if tbo: echo addressq

  if not expandparentbo:
    # then restore it for the first 3 parts
    for partst in addressq:
      countit += 1
      if countit < 4:
        basewebaddresst &= partst & "/"
    basewebaddresst = basewebaddresst[0 .. len(basewebaddresst) - 2]
    result = basewebaddresst
  elif expandparentbo:
    # then restore it for all but the last part
    addressq.del(len(addressq) - 1)
    for partst in addressq:
      expanded_addresst &= partst & "/"
    expanded_addresst = expanded_addresst[0 .. len(expanded_addresst) - 2]
    result = expanded_addresst

  


proc convertWebLinksToAbsolute(childweblinkst, parentweblinkst: string): string = 
  #[ 
  Convert the relative child-weblink to absolute based on the given
  parent-link and the relativity-type.
   ]#

  var
    firstcharst, base_addresst, expanded_addresst: string

  base_addresst = getBaseFromWebAddress2(parentweblinkst)
  expanded_addresst = getBaseFromWebAddress2(parentweblinkst, true)

  if childweblinkst.len > 1:
    firstcharst = childweblinkst[0..1]

    case firstcharst:
    of "ht":    # allready absolute
      result = childweblinkst
    of "//":    # scheme-relative (current mode of http or https)
      result = replace(childweblinkst, "//", "https://")
    else:
      case firstcharst[0..0]:
      of "/":   # base-relative (abc.com)
        result = base_addresst & childweblinkst
      else:   # parent-relative (abc.com/something)
        result = expanded_addresst & "/" & childweblinkst
  else:
    result = childweblinkst




proc getBaseFromWebAddress(webaddresst: string): string = 

  # http://www.x.nl/a/b/c/blah.html  becomes  http://www.x.nl

  var 
    addressq: seq[string]
    basewebaddresst: string
    tbo: bool = false
    countit: int = 0

  # firstly chop the address up on the slashes
  addressq = webaddresst.split("/")
  # if tbo: echo addressq
  echo addressq

  # then restore it for the first 3 parts
  for partst in addressq:
    countit += 1
    if countit < 4:
      basewebaddresst &= partst & "/"
  basewebaddresst = basewebaddresst[0 .. len(basewebaddresst) - 2]

  return basewebaddresst



proc getPartFromWebAddress(webaddresst: string, addresspart: AddressPart): string = 
#[ 
  Non-expanded base: http://www.x.nl/a/b/c/blah.html  becomes  http://www.x.nl
  Expand to parent: http://www.x.nl/a/b/c/blah.html  becomes  http://www.x.nl/a/b/c
  Expand to grandparent: http://www.x.nl/a/b/c/blah.html  becomes  http://www.x.nl/a/b
 ]#

  var 
    addressq: seq[string]
    basewebaddresst, parent_addresst: string
    tbo: bool = false
    countit: int = 0

  # firstly chop the address up on the slashes
  addressq = webaddresst.split("/")
  # if tbo: echo addressq

  if addressq.len >= 4:

    case addresspart:
    of addrBase:
      # then restore it for the first 3 parts
      for partst in addressq:
        countit += 1
        if countit < 4:
          basewebaddresst &= partst & "/"
      basewebaddresst = basewebaddresst[0 .. len(basewebaddresst) - 2]
      result = basewebaddresst
    of addrParent:
      # then restore it for all but the last part
      addressq.del(len(addressq) - 1)
      for partst in addressq:
        parent_addresst &= partst & "/"
      parent_addresst = parent_addresst[0 .. len(parent_addresst) - 2]
      result = parent_addresst
    of addrGrandParent:
      if addressq.len == 4:
        # then restore it for the first 3 parts
        for partst in addressq:
          countit += 1
          if countit < 4:
            basewebaddresst &= partst & "/"
        basewebaddresst = basewebaddresst[0 .. len(basewebaddresst) - 2]
        result = basewebaddresst
      else:
        # then restore it for all but the last two parts
        addressq.del(len(addressq) - 1)
        addressq.del(len(addressq) - 1)
        for partst in addressq:
          parent_addresst &= partst & "/"
        parent_addresst = parent_addresst[0 .. len(parent_addresst) - 2]
        result = parent_addresst
  else:
    result = ""      



proc convertRelPathsToAbsolute(inputtekst, cur_addresst: string): string = 
#[
  Convert most relative paths to absolute (but see below)
  
  ADAP FUT:
  -parent-relatives; harder because they dont have a default prefix
]#

  var intertekst, searchst, replacest: string
  var basepathst, parentpathst, grandparentpathst: string
  
  basepathst = getPartFromWebAddress(cur_addresst, addrBase)
  #parentpathst = getPartFromWebAddress(cur_addresst, addrParent)
  grandparentpathst = getPartFromWebAddress(cur_addresst, addrGrandParent)

  intertekst = input_tekst
  
  for attribst in ["href=", "src="]:
  
    # the double slash for scheme-relatives
    searchst = attribst & "\"//"
    replacest = attribst & "\"https://"
    intertekst = replace(intertekst, searchst, replacest)
  
    # single slash for base-relatives
    searchst = attribst & "\"/"
    replacest = attribst & "\"" & basepathst & "/"
    intertekst = replace(intertekst, searchst, replacest)
  
    # double dot for grand-parents
    searchst = attribst & "\"../"
    replacest = attribst & "\"" & grandparentpathst & "/"
    intertekst = replace(intertekst, searchst, replacest)  
  
  return intertekst




proc handleTextPartsFromHtml*(webaddresst, typest, languagest: string,
          taglist:string = "paragraph-only", summaryfilest: string = "",
          generatecontentst: string, abbreviationsq: seq[string] = @[]): string =

  #[ 
  This procedure is a forth-development of extractTextPartsFromHtml.
  Based on the webaddress as input-parameter, the webpage is downloaded.
  
  if typest is extract (old procedure): 
  Then the html is parsed and pieces of readable text (aoto most markup-codes)
  are extracted, concatenated and returned to procedure.

  if typest is replace:
  Then the html is parsed and pieces of readable text (aoto markup-codes)
  are cut out, reformatted and pasted back into their original location.
  Thus a reformatted webpage arizes and is returned.

  More precise flow:
  the procedure is a loop which:
  -searches for certain tags, and handles (extracts or replaces) the elements 
  that go with it. These tags are placed in a sequence-variable that can be 
  expanded when needed.
  -cycles thru the tag-sequence seeking for the handlable tag that comes first, 
  seeking from a certain position, and moving on.
  -when the starting-part of this tag is found (like <p), then the 
  ending-part of it is searched for (like </p>).
  -when both are found the element / string is handled; that is either: 
  extracted and appended, or cut, replaced and put back.

  ADAP HIS:
  -debug repetition of text-parts; repetition is caused by the website 
  itself! That is the article is repeted for different show-cases.
  - increased bigassit with one 0
  - renamed smallestindexit to curtagindexit
  - removed evaluation for extract-only

  ADAP NOW:

  ADAP FUT:
  -add tags section and table
   ]#


  #var debugbo = false

  var
    client = newHttpClient()
    websitest: string
    test:string
    textpartst, textallst:string
    substringcountit: int
    posit, textstartit, textendit:int
    allfoundbo: bool = false
    proef:string
    pos2it:int
    reformatedst:string
    highlightedst: string
    tagstartst:string
    thisoccurit, smallestposit:int
    tagindexit:int
    curtagindexit:int
    curtagsq:seq[string]
    curtagnamest, curtagstartst, curtagendst:string
    outerloopit:int = 0
    beginposit:int
    nosimilartagbo:bool
    tbo:bool = false   # enable or disable echo-statements for testing
    extractable_tagsq2:seq[seq[string]]
    bigassit = 1000000000
    basewebaddresst: string
    headinglist: string
    headingdepthit: int
    indentst: string



  if taglist == "paragraph-only":
    extractable_tagsq2 = @[
                    @["paragraph", "<p", "</p>", ""],
                    @["paragcap", "<P", "</P>", ""]
                  ]

  if taglist == "paragraph-with-headings":
    extractable_tagsq2 = @[
                    @["paragraph", "<p", "</p>", ""],
                    @["paragcap", "<P", "</P>", ""],
                    @["heading1", "<h1", "</h1>", "extract-only"],
                    @["heading2", "<h2", "</h2>", "extract-only"],
                    @["heading3", "<h3", "</h3>", "extract-only"],
                    @["heading4", "<h4", "</h4>", "extract-only"],
                    @["heading5", "<h5", "</h5>", "extract-only"],
                    @["heading6", "<h6", "</h6>", "extract-only"]
                  ]


  elif taglist == "full-list":
    extractable_tagsq2 = @[
                    @["paragraph", "<p", "</p>", ""],
                    @["paragcap", "<P", "</P>", ""],
                    @["unordered_list", "<ul", "</ul>", ""],
                    @["ordered_list", "<ol", "</ol>", ""],
                    @["description_list", "<dl", "</dl>", ""],
                    @["block_quote", "<blockquote", "</blockquote>", ""],
                    @["font_html4", "<font", "</font>", ""],
                    @["table_data", "<td", "</td>", ""]
                  ]


  elif taglist == "full-list-with-headings":
    extractable_tagsq2 = @[
                    @["paragraph", "<p", "</p>", ""],
                    @["paragcap", "<P", "</P>", ""],
                    @["heading1", "<h1", "</h1>", "extract-only"],
                    @["heading2", "<h2", "</h2>", "extract-only"],
                    @["heading3", "<h3", "</h3>", "extract-only"],
                    @["heading4", "<h4", "</h4>", "extract-only"],
                    @["heading5", "<h5", "</h5>", "extract-only"],
                    @["heading6", "<h6", "</h6>", "extract-only"],                    
                    @["unordered_list", "<ul", "</ul>", ""],
                    @["ordered_list", "<ol", "</ol>", ""],
                    @["description_list", "<dl", "</dl>", ""],
                    @["block_quote", "<blockquote", "</blockquote>", ""] ,
                    @["font_html4", "<font", "</font>", ""],
                    @["table_data", "<td", "</td>", ""]
                  ]


  elif taglist == "exotic-list":
    extractable_tagsq2 = @[
                    @["paragraph", "<p", "</p>", ""],
                    @["paragcap", "<P", "</P>", ""],
                    @["unordered_list", "<ul", "</ul>", ""],
                    @["ordered_list", "<ol", "</ol>", ""],
                    @["description_list", "<dl", "</dl>", ""],
                    @["block_quote", "<blockquote", "</blockquote>", ""],
                    @["font_html4", "<font", "</font>", ""],
                    @["span-elem", "<span", "</span>", ""],
                    @["div-element", "<div", "</div>", ""],
                    @["section", "<section", "</section>", ""],
                    @["table_data", "<td", "</td>", ""]
                  ]


  elif taglist == "exotic-list-with-headings":
    extractable_tagsq2 = @[
                    @["paragraph", "<p", "</p>", ""],
                    @["paragcap", "<P", "</P>", ""],
                    @["heading1", "<h1", "</h1>", "extract-only"],
                    @["heading2", "<h2", "</h2>", "extract-only"],
                    @["heading3", "<h3", "</h3>", "extract-only"],
                    @["heading4", "<h4", "</h4>", "extract-only"],
                    @["heading5", "<h5", "</h5>", "extract-only"],
                    @["heading6", "<h6", "</h6>", "extract-only"],                    
                    @["unordered_list", "<ul", "</ul>", ""],
                    @["ordered_list", "<ol", "</ol>", ""],
                    @["description_list", "<dl", "</dl>", ""],
                    @["block_quote", "<blockquote", "</blockquote>", ""] ,
                    @["font_html4", "<font", "</font>", ""],
                    @["span-elem", "<span", "</span>", ""],
                    @["div-element", "<div", "</div>", ""],
                    @["section", "<section", "</section>", ""],
                    @["table_data", "<td", "</td>", ""]
                  ]



  try:
    # put website into string
    websitest = client.getContent(webaddresst)

    basewebaddresst = getBaseFromWebAddress(webaddresst)

    # adjust paths so that resource-files can be loaded (like css and pics)
    websitest = convertRelPathsToAbsolute(websitest, webaddresst)

    log("charcount = " & $len(websitest))

    # substringcountit = count(websitest, "<p>")
    # echo "\ptagcount = " & $substringcountit

    posit = -1

    while not allfoundbo:   # not all tags found yet
      outerloopit += 1
      log("----------------\pouterloopit = " & $outerloopit)

      tagindexit = 0
      smallestposit = bigassit
      nosimilartagbo = false

      # walk thru the tags and determine the first one of them (smallest position)
      for tagsq in extractable_tagsq2:
        log("tagindexit = " & $tagindexit)
        # if (typest == "extract" and tagsq[3] == "extract-only") or tagsq[3] == "":
        tagstartst = tagsq[1]
        thisoccurit = find(websitest, tagstartst, posit + 1)
        if thisoccurit > -1:    # found
          if thisoccurit < smallestposit:
            smallestposit = thisoccurit
            # smallesttagst = tagnamest
            curtagindexit = tagindexit
            log("found tag")
        tagindexit += 1

      posit = smallestposit
      curtagsq = extractable_tagsq2[curtagindexit]
      curtagnamest = curtagsq[0]
      curtagstartst = curtagsq[1]
      curtagendst = curtagsq[2]
      log(curtagnamest)
      log("posit = " & $posit)

      if smallestposit != bigassit:   # at least one tag found
        # test if it is not a similar tag, like <picture> for <p>
        test = websitest[posit + len(curtagstartst) .. posit + len(curtagstartst)]
        log(test)
        if test == " " or test == ">":
          nosimilartagbo = true
          textstartit = posit
      elif smallestposit == bigassit:
        # no tags found anymore
        allfoundbo = true
        log("allfound = true")

      if not allfoundbo and nosimilartagbo:
        # search tag-end
        pos2it = posit
        pos2it = find(websitest, curtagendst, pos2it + 1)

        if pos2it != -1:    # par. end found
          textendit = pos2it + len(curtagendst)
          log("pos2it= " & $pos2it)
          # echo textstartit
          # echo textendit
          textpartst = websitest[textstartit .. textendit]
          # de-dot abbreviations
          textpartst = stripSymbolsFromList(textpartst, abbreviationsq, ".")

          # Below code is meant to create a contents-area
          # but also much garbage is being caught beside the contents..
          # therefore it is experimental.
          # A linked code-line is on bottom of proc:

          if generatecontentst == "generate_contents":
            if "heading" in curtagnamest:
              headingdepthit = parseInt($curtagstartst[2])
              for i in 0..headingdepthit:
                indentst &= "&nbsp;&nbsp;&nbsp;&nbsp;"
              headinglist &= indentst & getInnerText(textpartst) & "<br>"
              indentst = ""

          if typest == "extract":
            textallst &= textpartst
            # echo "\p============processText=========================="
            # echo textpartst
            # echo "================================================="

          elif typest == "replace":
            websitest.delete(textstartit..textendit)
            highlightedst = applyDefinitionFileToText(textpartst, languagest, true, summaryfilest)
            reformatedst = applyDefinitionFileToText(highlightedst, languagest, false)
            posit += len(reformatedst) - 2
            websitest.insert(reformatedst, textstartit)

        else:
          echo "End-tag not found; tag unclosed"

    if typest == "extract":
      if generatecontentst == "generate_contents":
        textallst.insert(headinglist, 0)
      result = textallst

    elif typest == "replace":
      result = websitest

  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error ******* \p" 
    echo repr(errob) & "\p****End exception****\p"




proc extractSentencesFromText(input_tekst, languagest:string, 
              summaryfilest: string = "", generatecontentst: string) :string =

  #[ 
  Process the input-text by extracting sentences that have a certain 
  search-string in them, so that a summary arises.

  The summary-definition-files (like summary_english.dat) are used.

  The search-strings originate no more from the language-files (like english.dat),
  specifically the category SIGNAL-WORDS TO HANDLE.


  ADAP HIS
  -prune and correct the code

  ADAP NOW
  
  ADAP FUT
  
  ]#


  var 
    deffile: File

    blockseparatorst = ">----------------------------------<"
    lastline: string
    phasetekst: string = input_tekst
    def_filenamest: string

    part1sq, part2sq, part3sq, sentencesq: seq[string] = @[]
    sentencecountit: int = 0

    summarysq: seq[string] = @[]
    summaryst: string
    processingbo: bool
    # the number of lines always added from the introduction
    introductionit: int = 4
    signal_strings_starting_pointit:int64 = 0
    tbo = false
    countit: int
    leftpartst, rightpartst: string
    stringsizeit:int
    linesq: seq[string] 
    linecountit: int =0

  def_filenamest = summaryfilest


  # Old approach - created to big chunks:
  # sentencesq = phasetekst.split(". ")

  # new approach - chopping in smaller chunks
  part1sq = phasetekst.split(". ")
  for text1st in part1sq:
    part2sq = text1st.split(".</p>")
    for text2st in part2sq:
        part3sq = text2st.split("<br>")
        for text3st in part3sq:
          sentencesq.add(text3st)


  if generatecontentst == "":
    stringsizeit = 1500
  else:
    # make sure the contents-area is not seen as garbage
    stringsizeit = 15000

  #if tbo: echo sentencesq

  if open(deffile, def_filenamest):    # try to open the def-file
    try:

      if tbo: echo "\n=====Begin extraction===="

      # walk thru the sentences of the input-text
      for sentencest in sentencesq:
        if tbo: echo sentencest
        # add the first sentences always to the summary
        if sentencecountit <= introductionit:
          if sentencest.len < stringsizeit:
            summarysq.add(sentencest)
        else:
          processingbo = false  # header not yet reached

          if signal_strings_starting_pointit > 0:
            deffile.setFilePos(signal_strings_starting_pointit)
            processingbo = true

          # -----------walk thru the lines of the def-file------------
          for line in deffile.lines:
            lastline = line

            # check for block-header
            if line == "SIGNAL-WORDS TO HANDLE":
              processingbo = true
              signal_strings_starting_pointit = deffile.getFilePos()
            elif processingbo:

              if line != blockseparatorst:   # block-separating string; end of job

                if sentencest.contains(line):
                  linecountit += 1
                  #echo "sentence =" & sentencest
                  #echo "line = " &  line
                  # if sentencest.len < stringsizeit:   # to skip long irrelevant lists
                  if true:
                    countit = count(sentencest, '.')
                    if countit == 0 or  countit > 1:
                      summarysq.add("<br>" & $sentencecountit & " ===============================" & "<br><br>")
                      summarysq.add(sentencest & ".")

                    elif countit == 1:
                      summarysq.add("<br>" &  $sentencecountit & " ===============================" & "<br><br>")
                      linesq = sentencest.split('.')
                      leftpartst = linesq[0]
                      rightpartst = linesq[1]
                      if leftpartst.contains(line): summarysq.add(leftpartst & ".")
                      if rightpartst.contains(line): summarysq.add(rightpartst & ".")


                  # to prevent more adds for more extraction-words
                  break
              else:
                # stop because end-of-signalwords
                break

        sentencecountit += 1
        

      if tbo: echo "===End of extraction ===="

      if tbo: echo phasetekst

      # concatenate extracted sentences to text
      summaryst = "Number of extractions: " & $linecountit & "<br><br>"
      for senst in summarysq:
        summaryst &= strip(senst, true, true)

    except IOError:
      echo "IO error!"
    
    except RangeDefect:
      echo "\p\p+++++++ search-config not found +++++++++++\p"
      echo "You have probably entered a search-config that could not be found. \p" &
          "Re-examine you search-config. \p" &
          "The problem originated probably in the above EDIT FILE-block"
      let errob = getCurrentException()
      echo "\p******* Technical error-information ******* \p" 
      echo "Last def-file-line read: " & lastline & "\p"
      echo repr(errob) & "\p****End exception****\p"

    
    except:
      let errob = getCurrentException()
      echo "\p******* Unanticipated error ******* \p" 
      echo "Last def-file-line read: " & lastline & "\p"
      echo repr(errob) & "\p****End exception****\p"
        
    finally:
      close(deffile)
  else:
    echo "Could not open file!"

  return summaryst



# proc extractMatchesFromText_Old(input_tekst, languagest:string, 
#               summaryfilest: string = "", generatecontentst: string,
#               contextit: int = 120) :string =

#   #[ 
#   Process the input-text by extracting sentences that have a certain 
#   search-string in them, so that a summary arises.

#   The summary-definition-files (like summary_english.dat) are used.

#   The search-strings originate no more from the language-files (like english.dat),
#   specifically the category SIGNAL-WORDS TO HANDLE.


#   ADAP HIS
#   -prune and correct the code
#   pseudocode
#   -doorloop de signaalwoorden
#       voor ieder sigwoord vervang door extra merkstreng
#   doe zolang niet alle gevonden:
#       zoek de eerstvolgende merkstreng = posmerk
#           bereken de start vd uitsnede
#               als posmerk > aantal contexttekens
#                   uitsnee-start wordt (posmerk - aantal contexttekens)
#               anders posmerk = 0
#           bereken het einde vd uitsnede (posmerk + aantal contexttekens)

#           doe tot geen overlap meer:        
#               zoek de navolgende m-streng
#               als (volgende posmerk - context) < uitsnede-einde dan
#                   uitsnee-einde wordt v-posmerk + context
#               anders 
#                   geen overlap meer is waar
#           voeg de uitsnede toe aan de reeks met uitsnedes

#   ADAP NOW
#   -algorithm with marking-string prependance has undesired results.


#   ADAP FUT

#   ]#



#   var
#     deffile: File
#     phasetekst:string = input_tekst    
#     blockseparatorst = ">----------------------------------<"
#     processingbo: bool
#     markingst: string = "~*~"
#     allfoundbo: bool = false
#     posit, cutstartit, cutendit, extendedposit: int
#     overlapbo: bool
#     inputtextlengthit: int
#     summarysq: seq[string] = @[]
#     summaryst, cutoutst: string


#   log(phasetekst)
#   log("---------------")
#   if open(deffile, summaryfilest):    # try to open the def-file / summary-file
#     try:
#       # walk thru the signal-words and and for each sigword 
#       # prepend in the input-text a marking string by doing a 
#       # replacement.
#       for line in deffile.lines:

#         # check for block-header
#         if line == "SIGNAL-WORDS TO HANDLE":
#           processingbo = true
#         elif processingbo:
#           if line != blockseparatorst:   # block-separating string; end of job
#             phasetekst = replace(phasetekst, line, markingst & line)
#           else:
#             # stop because end-of-signalwords
#             break
      
#       log(phasetekst)


#       inputtextlengthit = len(phasetekst)

#       # Cut out all signal-words with certain context and add those 
#       # cutouts to a sequence.
#       posit = 0
#       while not allfoundbo:

#         # find the next marking string
#         posit = find(phasetekst, markingst, posit)
#         if posit >= 0:
#           # retrieve cutout-boundaries
#           if posit > contextit:
#             cutstartit = posit - contextit
#           else:
#             cutstartit = 0
#           if (posit + contextit) < inputtextlengthit:
#             cutendit = posit + contextit
#           else:
#             cutendit = inputtextlengthit


#           # Test if the context-area of the previous match overlaps with 
#           # the context-area of the next match and if yes then extend the 
#           # cutout. Start assuming that it does overlap.
#           overlapbo = true
#           while overlapbo:
#             if posit < inputtextlengthit:
#               extendedposit = posit + 1
#               extendedposit = find(phasetekst, markingst, extendedposit)
#               if (extendedposit - contextit) < cutendit and extendedposit >= 0:
#                 cutendit = extendedposit + contextit
#                 posit = extendedposit
#               else:
#                 overlapbo = false

#           posit += 1
#           cutoutst = phasetekst[cutstartit..cutendit]
#           cutoutst = replace(cutoutst, markingst, "")
#           # summarysq.add("<br>" & "Word-position: " & $posit & " ===============================")
#           # summarysq.add("\p\p")
#           summarysq.add(cutoutst)
#         else:
#           allfoundbo = true

#       # concatenate extracted sentences to text
#       summaryst = ""
#       for cutout in summarysq:
#         # summaryst &= cutout & "<br>"
#         summaryst &= "\p" & cutout


#     except IOError:
#       echo "IO error!"
    
#     except RangeError:
#       echo "\p\p+++++++ search-config not found +++++++++++\p"
#       echo "You have probably entered a search-config that could not be found. \p" &
#           "Re-examine you search-config. \p"
#       let errob = getCurrentException()
#       echo "\p******* Technical error-information ******* \p" 
#       echo repr(errob) & "\p****End exception****\p"

    
#     except:
#       let errob = getCurrentException()
#       echo "\p******* Unanticipated error ******* \p" 
#       echo repr(errob) & "\p****End exception****\p"
        
#     finally:
#       close(deffile)
#   else:
#     echo "Could not open file!"

#   return summaryst



# proc extractMatchesFromText(input_tekst, languagest:string, 
#               summaryfilest: string = "", generatecontentst: string,
#               contextit: int = 120) :string =

#   #[ 
#   Process the input-text by extracting sentences that have a certain 
#   search-string in them, so that a summary arises.

#   The summary-definition-files (like summary_english.dat) are used.

#   The search-strings originate no more from the language-files (like english.dat),
#   specifically the category SIGNAL-WORDS TO HANDLE.


#   ADAP HIS
#   -prune and correct the code

#   ADAP NOW
  
  
#   ADAP FUT

#   ]#



#   var
#     deffile: File
#     phasetekst:string = input_tekst    
#     blockseparatorst = ">----------------------------------<"
#     processingbo: bool
#     markingst: string = "~*~"
#     allfoundbo: bool = false
#     posit, cutstartit, cutendit, extendedposit: int
#     overlapbo: bool
#     inputtextlengthit: int
#     summarysq: seq[string] = @[]
#     summaryst, cutoutst: string
#     sigwordsq: seq[string] = @[]
#     sigwordst: string


#   log(phasetekst)
#   log("---------------")
#   if open(deffile, summaryfilest):    # try to open the def-file / summary-file
#     try:
#       # walk thru the signal-words and and for each sigword 
#       # prepend in the input-text a marking string by doing a 
#       # replacement.
#       for line in deffile.lines:

#         # check for block-header
#         if line == "SIGNAL-WORDS TO HANDLE":
#           processingbo = true
#         elif processingbo:
#           if line != blockseparatorst:   # block-separating string; end of job
#             sigwordsq.add(line)
#           else:
#             # stop because end-of-signalwords
#             break
      

#       # ------------------------------------


#       inputtextlengthit = len(phasetekst)
#       posit = -1

#       # Cut out all signal-words with certain context and add those 
#       # cutouts to a sequence.
#       while not allfoundbo:   # not all sigwords found yet

#         smallestposit = bigassit

#         # walk thru the sigwords and determine the first one of them (smallest position)
#         for sigwordst in sigwordsq:
#           thisoccurit = find(phasetekst, sigwordst, posit + 1)
#           if thisoccurit > -1:    # found
#             if thisoccurit < smallestposit:
#               smallestposit = thisoccurit
#               firstsigwordst = sigwordst
#               log("found sigword")

#         posit = smallestposit

#         if posit >= 0:
#           # retrieve cutout-boundaries
#           if posit > contextit:
#             cutstartit = posit - contextit
#           else:
#             cutstartit = 0
#           if (posit + contextit) < inputtextlengthit:
#             cutendit = posit + contextit
#           else:
#             cutendit = inputtextlengthit


#           # Test if the context-area of the previous match overlaps with 
#           # the context-area of the next match and if yes then extend the 
#           # cutout. Start assuming that it does overlap.
#           overlapbo = true
#           while overlapbo:
#             if posit < inputtextlengthit:
#               extendedposit = posit + 1
#               extendedposit = find(phasetekst, markingst, extendedposit)
#               if (extendedposit - contextit) < cutendit and extendedposit >= 0:
#                 cutendit = extendedposit + contextit
#                 posit = extendedposit
#               else:
#                 overlapbo = false

#           posit += 1
#           cutoutst = phasetekst[cutstartit..cutendit]
#           cutoutst = replace(cutoutst, markingst, "")
#           # summarysq.add("<br>" & "Word-position: " & $posit & " ===============================")
#           # summarysq.add("\p\p")
#           summarysq.add(cutoutst)
#         else:
#           allfoundbo = true

#       # concatenate extracted sentences to text
#       summaryst = ""
#       for cutout in summarysq:
#         # summaryst &= cutout & "<br>"
#         summaryst &= "\p" & cutout


#     except IOError:
#       echo "IO error!"
    
#     except RangeError:
#       echo "\p\p+++++++ search-config not found +++++++++++\p"
#       echo "You have probably entered a search-config that could not be found. \p" &
#           "Re-examine you search-config. \p"
#       let errob = getCurrentException()
#       echo "\p******* Technical error-information ******* \p" 
#       echo repr(errob) & "\p****End exception****\p"

    
#     except:
#       let errob = getCurrentException()
#       echo "\p******* Unanticipated error ******* \p" 
#       echo repr(errob) & "\p****End exception****\p"
        
#     finally:
#       close(deffile)
#   else:
#     echo "Could not open file!"

#   return summaryst



proc formatText*(input_tekst, languagest, preprocesst: string, 
          summaryfilest: string = "", generatecontentst: string):string =
  
  # To apply html-formatting (coloring and highlighting), 
  # possibly after summarization

  var
    r1,r2, r3: string

  # r1 = replace(input_tekst, "\p", "<br>")
  r1 = input_tekst

  if preprocesst == "summarize":
    r2 = extractSentencesFromText(r1, languagest, summaryfilest, 
                                    generatecontentst)
    r3 = applyDefinitionFileToText(r2, languagest, true, summaryfilest)
    result = applyDefinitionFileToText(r3, languagest, false)

  else:   # no summary requested
    r2 = applyDefinitionFileToText(r1, languagest, true, summaryfilest)
    result = applyDefinitionFileToText(r2, languagest, false)



proc replaceInPastedText*(pastedtekst, generatecontentst: string): string =
  # To ensure correct conversion from text-format to html-format

  var 
    lengthit: int = 25
    newtekst, contentst: string


  for linest in pastedtekst.splitlines:
    if len(linest) < lengthit:
      if linest.len > 0:
        if not linest.endsWith("."):
          if generatecontentst != "":
            contentst.add(linest & "<br>")
          newtekst.add("<b>" & linest & "</b><br>")
        else:
          newtekst.add(linest & "<br><br>")

    elif len(linest) > lengthit:
      if linest.endsWith("."):
        newtekst.add(linest & "<br><br>")
      else:
        newtekst.add(linest & " ")

  contentst.add("<br>---------------------------------------------------<br><br>")
  if generatecontentst != "":
    newtekst.insert(contentst, 0)

  result = newtekst



proc getTitleFromWebsite*(webaddresst:string): string =

  var 
    client = newHttpClient()
    websitest, titlest:string


  try:
    websitest = client.getContent(webaddresst)
    titlest = getDataBetweenTags(websitest, "<title>", "</title>", 0)

  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error ******* \p" 
    echo repr(errob) & "\p****End exception****\p"

  return titlest


proc testConversion()=

  var webaddresst: string = "http://www.x.nl/a/b/c/blah.html"
  var basewebaddresst: string
  
  basewebaddresst = getBaseFromWebAddress(webaddresst)

  # # adjust paths so that resource-files can be loaded (like css and pics)
  # websitest = convertRelPathsToAbsolute(websitest, basewebaddresst)


# proc funcWrapper() = 
#   var x: string = handleTextPartsFromHtml("https://nl.wikipedia.org/wiki/Geschiedenis", 
#         "extract", "dutch", "paragraph-only", "summary_dutch.nl", "generate_contents")




when isMainModule:
  # echo processText(tekst)
  # echo chopText(tekst, "\p", "<br>")
  # echo addBreaksToText(tekst,@["\p",".",","])
  # echo replaceInText(meertekst, "dutch")

  # const streng = "12>3456<789"
  # const sub = ">"
  # const endsub = "<"

  # # echo getSubstringPositions(streng, sub)
  # echo getDataBetweenTags(streng, sub, endsub, 0)

  # echo extractTextPartsFromHtml("https://nl.wikipedia.org/wiki/Geschiedenis")
  # echo calculateWordFrequencies(input_tekst, 3)

  # echo extractSentencesFromText(testtekst_nl, "dutch")
  # echo extractSentencesFromText(testtekst_eng, "english")
  # echo replaceInText(testtekst_eng, "english", "")
  # echo handleTextPartsFromHtml("https://nl.wikipedia.org/wiki/Geschiedenis", "replace", "dutch")
  # echo new_handleTextPartsFromHtml("https://nl.wikipedia.org/wiki/Geschiedenis", "replace", "dutch")

  # ----------------
  # var st: string = ""
  # let t0 = cpuTime()
  # st = handleTextPartsFromHtml("https://nl.wikipedia.org/wiki/Computer", "replace", "dutch", 
  #         "paragraph-only", "summary_dutch.dat", "")
  # echo "Execution-time = " & $formatFloat(cpuTime() - t0, ffDecimal, precision = 3)
  # echo st.len
  # ----------------

  # echo "hoi"
  # echo getTitleFromWebsite("https://nl.wikipedia.org/wiki/Geschiedenis")
  # echo new_extractSentencesFromText(testtekst_eng, "english")
  # echo extractSentencesFromText(testtekst_eng, "english")

  # echo addresstekst
  # echo "------"
  # echo convertRelPathsToAbsolute(addresstekst, "http://www.iets.nl")
  # echo getBaseFromWebAddress("http://www.x.nl/a/b/c/blah.html")
  # echo getInnerText("<>a<>b<><>d<>")
  # echo getInnerText(">tekst<")
  # echo getDataBetweenTags("<>a<>b<><>d<>", ">", "<", 5)
  # myTest()  

  echo "***********************"
  echo extractMatchesFromText(testtekst_eng, "", "summary_english_default.dat", "", 5)
