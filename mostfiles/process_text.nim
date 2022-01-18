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
import os
import httpClient
import tables, algorithm, sequtils
import stringstuff
import source_files
import fr_tools


const 
  versionfl:float = 0.35

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
   ]#

  var
    starttagpositonssq, endtagpositionssq: seq[int]
    starttagposit, endtagposit: int
    resultst:string


  # echo "****************"
  # echo tekst
  # echo starttagst & " - " & endtagst
  starttagpositonssq = getSubstringPositions(tekst, starttagst)
  # echo "starttagpositonssq = " & $starttagpositonssq
  endtagpositionssq = getSubstringPositions(tekst, endtagst)
  # echo "/pendtagpositionssq = " & $endtagpositionssq

  starttagposit = starttagpositonssq[occurit]
  endtagposit = endtagpositionssq[occurit]
  
  # echo "/plength of textpart: " & $(endtagposit - starttagposit)
  # echo "/p"
  # echo starttagposit
  # echo endtagposit

#    resultst = tekst[tekst.index(starttagst), tekst.index(endtagst)]
  resultst = tekst[starttagposit + len(starttagst) .. endtagposit - 1]
  # echo "resultst = " & resultst
  
  return resultst



proc extractTextPartsFromHtml*(webaddresst:string = ""):string =
  #[ 
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
    argumentsq: seq[string] = @[]
    phasetekst:string = input_tekst
    def_filenamest:string
    use_custom_replacebo: bool = true
    deffilest:string


  if highlightbo == false:
    echo "text coloring...."
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
    echo "=============================="
    echo "highlighting..."
    def_filenamest = summaryfilest
    echo def_filenamest
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

          # echo "line = " & line
          
          if blockphasest == "PUNCTUATION OF SENTENCES TO HANDLE":
            if use_custom_replacebo:
              phasetekst = customReplace(phasetekst, line, line & "<br>&nbsp;&nbsp;&nbsp;&nbsp;",
                                  true, "unique_occurrence", @[15])
            else:
              phasetekst = replace(phasetekst, line, line & "<br>&nbsp;&nbsp;&nbsp;&nbsp;")
          elif blockphasest == "PUNCTUATION OF SENTENCE-PARTS TO HANDLE":
            if use_custom_replacebo:
              phasetekst = customReplace(phasetekst, line, line & "<br>",
                                  true, "unique_occurrence", @[25])
            else:
              phasetekst = replace(phasetekst, line, line & "<br>")
          elif blockphasest == "PRONOUNS TO HANDLE":
            if use_custom_replacebo:
              phasetekst = customReplace(phasetekst, line, "<br>" & line,
                                    true, "", @[])
            else:
              phasetekst = replace(phasetekst, line, "<br>" & line)
          elif blockphasest == "VERBS TO HANDLE":
            if use_custom_replacebo:
              phasetekst = customReplace(phasetekst, line, "<span style=color:magenta>" & line & "</span>",
                                    true, "", @[])
            else:
              phasetekst = replace(phasetekst, line, "<span style=color:magenta>" & line & "</span>")
          elif blockphasest == "SIGNAL-WORDS TO HANDLE":
            if use_custom_replacebo:
              phasetekst = customReplace(phasetekst, line, "<span style=background-color:#ffd280>" & line & "</span>",
                                    true, "", @[])
            else:
              phasetekst = replace(phasetekst, line, "<span style=background-color:#ffd280>" & line & "</span>")
          elif blockphasest == "LINK-WORDS TO HANDLE":
            if use_custom_replacebo:
              phasetekst = customReplace(phasetekst, line, "<span style=color:red>" & line & "</span>",
                                    true, "", @[])
            else:
              phasetekst = replace(phasetekst, line, "<span style=color:red>" & line & "</span>")
          elif blockphasest == "PREPOSITIONS TO HANDLE":
            if use_custom_replacebo:
              phasetekst = customReplace(phasetekst, line, "<span style=color:limegreen>" & line & "</span>",
                                    true, "", @[])
            else:
              phasetekst = replace(phasetekst, line, "<span style=color:limegreen>" & line & "</span>")
          elif blockphasest == "NOUN-ANNOUNCERS TO HANDLE":
            if use_custom_replacebo:
              phasetekst = customReplace(phasetekst, line, "<span style=color:#b35919>" & line & "</span>",
                                    true, "", @[])
            else:
              phasetekst = replace(phasetekst, line, "<span style=color:#b35919>" & line & "</span>")
          elif blockphasest == "NOUN-REPLACERS TO HANDLE":
            if use_custom_replacebo:
              phasetekst = customReplace(phasetekst, line, "<span style=color:darkturquoise>" & line & "</span>",
                                    true, "", @[])
            else:
              phasetekst = replace(phasetekst, line, "<span style=color:darkturquoise>" & line & "</span>")
          elif blockphasest == "AMBIGUOUS WORD-FUNCTIONS TO HANDLE":
            if use_custom_replacebo:
              phasetekst = customReplace(phasetekst, line, "<span style=color:#e6b800>" & line & "</span>",
                                    true, "", @[])
            else:
              phasetekst = replace(phasetekst, line, "<span style=color:#e6b800>" & line & "</span>")


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
  
  except RangeError:
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


proc applyDefinitionFileToTextOld(input_tekst, languagest:string): string =
  # reads now from preloaded textfilestring from module source_files

  var 
    blockheadersq: seq[string] = @[
        "PUNCTUATION OF SENTENCES TO HANDLE",
        "PUNCTUATION OF SENTENCE-PARTS TO HANDLE",
        "PRONOUNS TO HANDLE",
        "VERBS TO HANDLE",
        "SIGNAL-WORDS TO HANDLE",
        "LINK-WORDS TO HANDLE",
        "PREPOSITIONS TO HANDLE",
        "NOUN-ANNOUNCERS TO HANDLE",
        "NOUN-REPLACERS TO HANDLE",
        "AMBIGUOUS WORD-FUNCTIONS TO HANDLE"]

    blockphasest: string = ""
    blocklineit: int
    blockseparatorst = ">----------------------------------<"
    lastline: string
    all_argst: string
    argumentsq: seq[string] = @[]
    phasetekst:string = input_tekst
    def_filenamest:string = languagest & ".dat"
    use_custom_replacebo: bool = true

    filest:string = textsourcefileta[def_filenamest]

  try:
    # walk thru the lines of the file
    echo "\n=====Begin processing===="
    for line in filest.splitlines:
      lastline = line

      # check for block-header
      if line in blockheadersq:
        blockphasest = line
        echo blockphasest
        blocklineit = 0
      elif blockphasest != "":

        blocklineit += 1
        if line != blockseparatorst:   # block-separating string

          # echo "line = " & line
          
          if blockphasest == "PUNCTUATION OF SENTENCES TO HANDLE":
            if use_custom_replacebo:
              phasetekst = customReplace(phasetekst, line, line & "<br>&nbsp;&nbsp;&nbsp;&nbsp;",
                                  true, "unique_occurrence", @[15])
            else:
              phasetekst = replace(phasetekst, line, line & "<br>&nbsp;&nbsp;&nbsp;&nbsp;")
          elif blockphasest == "PUNCTUATION OF SENTENCE-PARTS TO HANDLE":
            if use_custom_replacebo:
              phasetekst = customReplace(phasetekst, line, line & "<br>",
                                  true, "unique_occurrence", @[25])
            else:
              phasetekst = replace(phasetekst, line, line & "<br>")
          elif blockphasest == "PRONOUNS TO HANDLE":
            if use_custom_replacebo:
              phasetekst = customReplace(phasetekst, line, "<br>" & line,
                                    true, "", @[])
            else:
              phasetekst = replace(phasetekst, line, "<br>" & line)
          elif blockphasest == "VERBS TO HANDLE":
            if use_custom_replacebo:
              phasetekst = customReplace(phasetekst, line, "<span style=color:magenta>" & line & "</span>",
                                    true, "", @[])
            else:
              phasetekst = replace(phasetekst, line, "<span style=color:magenta>" & line & "</span>")
          elif blockphasest == "SIGNAL-WORDS TO HANDLE":
            if use_custom_replacebo:
              phasetekst = customReplace(phasetekst, line, "<span style=background-color:#ffd280>" & line & "</span>",
                                    true, "", @[])
            else:
              phasetekst = replace(phasetekst, line, "<span style=background-color:#ffd280" & line & "</span>")
          elif blockphasest == "LINK-WORDS TO HANDLE":
            if use_custom_replacebo:
              phasetekst = customReplace(phasetekst, line, "<span style=color:red>" & line & "</span>",
                                    true, "", @[])
            else:
              phasetekst = replace(phasetekst, line, "<span style=color:red>" & line & "</span>")
          elif blockphasest == "PREPOSITIONS TO HANDLE":
            if use_custom_replacebo:
              phasetekst = customReplace(phasetekst, line, "<span style=color:limegreen>" & line & "</span>",
                                    true, "", @[])
            else:
              phasetekst = replace(phasetekst, line, "<span style=color:limegreen>" & line & "</span>")
          elif blockphasest == "NOUN-ANNOUNCERS TO HANDLE":
            if use_custom_replacebo:
              phasetekst = customReplace(phasetekst, line, "<span style=color:#b35919>" & line & "</span>",
                                    true, "", @[])
            else:
              phasetekst = replace(phasetekst, line, "<span style=color:#b35919>" & line & "</span>")
          elif blockphasest == "NOUN-REPLACERS TO HANDLE":
            if use_custom_replacebo:
              phasetekst = customReplace(phasetekst, line, "<span style=color:darkturquoise>" & line & "</span>",
                                    true, "", @[])
            else:
              phasetekst = replace(phasetekst, line, "<span style=color:darkturquoise>" & line & "</span>")
          elif blockphasest == "AMBIGUOUS WORD-FUNCTIONS TO HANDLE":
            if use_custom_replacebo:
              phasetekst = customReplace(phasetekst, line, "<span style=color:#e6b800>" & line & "</span>",
                                    true, "", @[])
            else:
              phasetekst = replace(phasetekst, line, "<span style=color:#e6b800>" & line & "</span>")


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

    # echo "===End of processing===="
  
  except IOError:
    echo "IO error!"
  
  except RangeError:
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



proc getBaseFromWebAddress(webaddresst: string): string = 

  # http://www.x.nl/a/b/c/blah.html  becomes  http://www.x.nl

  var 
    addressq: seq[string]
    basewebaddresst: string
    tbo: bool = true
    countit: int = 0

  # firstly chop the address up on the slashes
  addressq = webaddresst.split("/")
  if tbo: echo addressq

  # then restore it for the first 3 parts
  for partst in addressq:
    countit += 1
    if countit < 4:
      basewebaddresst &= partst & "/"
  basewebaddresst = basewebaddresst[0 .. len(basewebaddresst) - 2]

  return basewebaddresst



proc convertRelPathsToAbsolute(inputtekst, htmlbasepathst: string): string = 

  var intertekst, searchst, replacest: string

  # the double slash must not be replaced so put it on ice
  searchst = "href=\"//"
  replacest = "href=\"TEMPSTRING"
  intertekst = replace(inputtekst, searchst, replacest)

  # insert the web-address
  searchst = "href=\"/"
  replacest = "href=\"" & htmlbasepathst & "/"
  intertekst = replace(intertekst, searchst, replacest)

  # restore the double slash
  searchst = "href=\"TEMPSTRING"
  replacest = "href=\"//"
  intertekst = replace(intertekst, searchst, replacest)

  return intertekst



proc handleTextPartsFromHtml*(webaddresst, typest, languagest: string,
          taglist:string = "paragraph-only", summaryfilest: string = ""): string =

  #[ 
  This procedure is a forth-development of extractTextPartsFromHtml.
  Based on the webaddress as input-parameter, the webpage is downloaded.
  
  if typest is extract (old procedure): 
  Then the html is parsed and pieces of readable text (aot most markup-codes)
  are extracted, concatenated and returned to procedure.

  if typest is replace:
  Then the html is parsed and pieces of readable text (aot markup-codes)
  are cut out, reformatted and pasted back into their original location.
  Thus a reformatted webpage arizes and is returned.

  More precise flow:
  the procedure is a loop which:
  -searches for certain tags and handles (extracts or replaces) the elements 
  that go with it. These tags are placed in a sequence-variable that can be 
  expanded when needed.
  -cycles thru the tag-sequence seeking for the handlable tag that comes first, 
  seeking from a certain position, and moving on.
  -when the starting-part of this tag is found (like <p), then the 
  ending-part of it is searched for (like </p>).
  -when both are found the element / string is handled; that is either: 
  extracted and appended, or 
  cut, replaced and put back.

  ADAP HIS:
  -debug repetition of text-parts; repetition is caused by the website 
  itself! That is the article is repeted for different show-cases.

  ADAP NOW:

   ]#


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
    smallestindexit:int
    curtagsq:seq[string]
    curtagnamest, curtagstartst, curtagendst:string
    outerloopit:int = 0
    beginposit:int
    nosimilartagbo:bool
    tbo:bool = false   # enable or disable echo-statements for testing
    extractable_tagsq2:seq[seq[string]]
    bigassit = 100000000
    basewebaddresst: string


  if taglist == "paragraph-only":
    extractable_tagsq2 = @[
                    @["paragraph", "<p", "</p>", ""]
                  ]

  if taglist == "paragraph-with-headings":
    extractable_tagsq2 = @[
                    @["paragraph", "<p", "</p>", ""],
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
                    @["unordered_list", "<ul", "</ul>", ""],
                    @["ordered_list", "<ol", "</ol>", ""],
                    @["description_list", "<dl", "</dl>", ""],
                    @["block_quote", "<blockquote", "</blockquote>", ""],
                    @["font_html4", "<font", "</font>", ""]
                  ]


  elif taglist == "full-list-with-headings":
    extractable_tagsq2 = @[
                    @["paragraph", "<p", "</p>", ""],
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
                    @["font_html4", "<font", "</font>", ""]                                       
                  ]


  try:
    websitest = client.getContent(webaddresst)

    basewebaddresst = getBaseFromWebAddress(webaddresst)

    # adjust paths so that resource-files can be loaded (like css and pics)
    websitest = convertRelPathsToAbsolute(websitest, basewebaddresst)

    if tbo: echo "charcount = " & $len(websitest)

    # substringcountit = count(websitest, "<p>")
    # echo "\ptagcount = " & $substringcountit

    posit = -1

    while not allfoundbo:   # not all tags found yet
      outerloopit += 1
      if tbo: echo "----------------\pouterloopit = " & $outerloopit

      tagindexit = 0
      smallestposit = bigassit
      nosimilartagbo = false

      # walk thru the tags and determine the first one of them (smallest position)
      for tagsq in extractable_tagsq2:
        if tbo: echo "tagindexit = " & $tagindexit
        if (typest == "extract" and tagsq[3] == "extract-only") or tagsq[3] == "":
          tagstartst = tagsq[1]
          thisoccurit = find(websitest, tagstartst, posit + 1)
          if thisoccurit > -1:    # found
            if thisoccurit < smallestposit:
              smallestposit = thisoccurit
              # smallesttagst = tagnamest
              smallestindexit = tagindexit
              if tbo: echo "found tag"
        tagindexit += 1

      posit = smallestposit
      curtagsq = extractable_tagsq2[smallestindexit]
      curtagnamest = curtagsq[0]
      curtagstartst = curtagsq[1]
      curtagendst = curtagsq[2]
      if tbo: echo curtagnamest
      if tbo: echo "posit = " & $posit

      if smallestposit != bigassit:   # at least one tag found
        # test if it is not a similar tag, like <picture> for <p>
        test = websitest[posit + len(curtagstartst) .. posit + len(curtagstartst)]
        if tbo: echo test
        if test == " " or test == ">":
          nosimilartagbo = true
          textstartit = posit
      elif smallestposit == bigassit:
        # no tags found anymore
        allfoundbo = true
        if tbo: echo "allfound = true"

      if not allfoundbo and nosimilartagbo:
        # search tag-end
        pos2it = posit
        pos2it = find(websitest, curtagendst, pos2it + 1)

        if pos2it != -1:    # par. end found
          textendit = pos2it + 4
          if tbo: echo "pos2it= " & $pos2it
          # echo textstartit
          # echo textendit
          textpartst = websitest[textstartit .. textendit]

          if typest == "extract":
            textallst &= textpartst
            # echo "\p============processText=========================="
            # echo textpartst
            # echo "================================================="

          elif typest == "replace":
            websitest.delete(textstartit, textendit)
            highlightedst = applyDefinitionFileToText(textpartst, languagest, true, summaryfilest)
            reformatedst = applyDefinitionFileToText(highlightedst, languagest, false)
            posit += len(reformatedst) - 2
            websitest.insert(reformatedst, textstartit)

        else:
          echo "End-tag not found; tag unclosed"

    if typest == "extract":
      return textallst
    elif typest == "replace":
      return websitest

  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error ******* \p" 
    echo repr(errob) & "\p****End exception****\p"



proc extractSentencesFromText(input_tekst, languagest:string, 
                    summaryfilest: string = "") :string =
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
  -users may also use a custom-file for a specific subject 
  (for example for a history-text or a political text), for which separate 
  files must be reinstated, plus some selection-way.
  ]#


  var 
    deffile: File

    blockseparatorst = ">----------------------------------<"
    lastline: string
    phasetekst:string = input_tekst
    def_filenamest: string
    sentencesq: seq[string] = phasetekst.split(". ")
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
    stringsizeit:int = 1500
    linesq: seq[string] 


  def_filenamest = summaryfilest

  if tbo: echo sentencesq

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
              signal_strings_starting_pointit = deffile.getFilePos() + 1
            elif processingbo:

              if line != blockseparatorst:   # block-separating string; end of job

                # echo "line = " & line
                
                if sentencest.contains(line):
                  # echo line
                  if sentencest.len < stringsizeit:   # to skip long irrelevant lists
                    countit = count(sentencest, '.')
                    if countit == 0 or  countit > 1:
                      summarysq.add("<br>" & $sentencecountit & " ===============================" & "<br>")
                      summarysq.add(sentencest)

                    elif countit == 1:
                      summarysq.add("<br>" &  $sentencecountit & " ===============================" & "<br>")
                      linesq = sentencest.split('.')
                      leftpartst = linesq[0]
                      rightpartst = linesq[1]
                      if leftpartst.contains(line): summarysq.add(leftpartst)
                      if rightpartst.contains(line): summarysq.add(rightpartst)


                  # to prevent more adds for more extraction-words
                  break
              else:
                # stop because end-of-signalwords
                break

        sentencecountit += 1
        

      if tbo: echo "===End of extraction ===="

      if tbo: echo phasetekst

      # concatenate extracted sentences to text
      summaryst = ""
      for senst in summarysq:
        summaryst &= strip(senst, true, true) & ". "

    except IOError:
      echo "IO error!"
    
    except RangeError:
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



proc replaceInText*(input_tekst, languagest, preprocesst: string, 
                          summaryfilest: string = ""):string =

  var
    r1,r2, r3, r4: string


  r1 = replace(input_tekst, "\p", "<br>")
  if preprocesst == "summarize":
    r2 = extractSentencesFromText(r1, languagest, summaryfilest)
    r3 = applyDefinitionFileToText(r2, languagest, true, summaryfilest)
    r4 = applyDefinitionFileToText(r3, languagest, false)
    result = r4
  else:   # no summary requested
    r2 = applyDefinitionFileToText(r1, languagest, true, summaryfilest)
    r3 = applyDefinitionFileToText(r2, languagest, false)
    result = r3
  


# proc replaceInTextOld*(input_tekst, languagest, preprocesst:string):string =

#   var
#     r1,r2, r3:string

#   r1 = replace(input_tekst, "\p", "<br>")
#   if preprocesst == "summarize":
#     r2 = extractSentencesFromText(r1, languagest)
#     r3 = applyDefinitionFileToText(r2, languagest)
#   else:
#     r3 = applyDefinitionFileToText(r1, languagest)
#   return r3


proc getTitleFromWebsite*(webaddresst:string): string =

  var 
    client = newHttpClient()
    websitest, titlest:string
    tbo:bool = true

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
  echo replaceInText(testtekst_eng, "english", "")
  # echo handleTextPartsFromHtml("https://nl.wikipedia.org/wiki/Geschiedenis", "replace", "dutch")
  # echo new_handleTextPartsFromHtml("https://nl.wikipedia.org/wiki/Geschiedenis", "replace", "dutch")

  # echo handleTextPartsFromHtml("https://nl.wikipedia.org/wiki/Geschiedenis", "extract", "dutch", "paragraph-only")
  # echo "hoi"
  # echo getTitleFromWebsite("https://nl.wikipedia.org/wiki/Geschiedenis")
  # echo new_extractSentencesFromText(testtekst_eng, "english")
  # echo extractSentencesFromText(testtekst_eng, "english")

  # echo addresstekst
  # echo "------"
  # echo convertRelPathsToAbsolute(addresstekst, "http://www.iets.nl")
  # echo getBaseFromWebAddress("http://www.x.nl/a/b/c/blah.html")
