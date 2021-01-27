
proc old_applyDefinitionFileToText(input_tekst, languagest:string) :string =
  # applyDefinitionFileToText

  var 
    myfile: File
    blockheadar: seq[string] = @[
        "PUNCTUATION OF SENTENCES TO HANDLE",
        "PUNCTUATION OF SENTENCE-PARTS TO HANDLE",
        "PRONOUNS TO HANDLE",
        "VERBS TO HANDLE",
        "SIGNAL-WORDS TO HANDLE",
        "LINK-WORDS TO HANDLE",
        "PREPOSITIONS TO HANDLE"]
    blockphasest: string = ""
    blocklineit: int
    blockseparatorst = ">----------------------------------<"
    lastline: string
    all_argst: string
    argumentsq: seq[string] = @[]
    phasetekst:string = input_tekst
    def_filenamest:string = languagest & ".dat"
    use_custom_replacebo: bool = true



  if open(myfile, def_filenamest):    # try to open the def-file
    try:

      # walk thru the lines of the file
      echo "\n=====Begin processing===="
      for line in myfile.lines:
        lastline = line

        # check for block-header
        if line in blockheadar:
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
                                    false, "unique_occurrence", @[15])
              else:
                phasetekst = replace(phasetekst, line, line & "<br>&nbsp;&nbsp;&nbsp;&nbsp;")
            elif blockphasest == "PUNCTUATION OF SENTENCE-PARTS TO HANDLE":
              if use_custom_replacebo:
                phasetekst = customReplace(phasetekst, line, line & "<br>",
                                    false, "unique_occurrence", @[25])
              else:
                phasetekst = replace(phasetekst, line, line & "<br>")
            elif blockphasest == "PRONOUNS TO HANDLE":
              if use_custom_replacebo:
                phasetekst = customReplace(phasetekst, line, "<br>" & line,
                                      false, "", @[])
              else:
                phasetekst = replace(phasetekst, line, "<br>" & line)
            elif blockphasest == "VERBS TO HANDLE":
              if use_custom_replacebo:
                phasetekst = customReplace(phasetekst, line, "<span style=color:blue>" & line & "</span>",
                                      true, "", @[])
              else:
                phasetekst = replace(phasetekst, line, "<span style=color:blue>" & line & "</span>")
            elif blockphasest == "SIGNAL-WORDS TO HANDLE":
              if use_custom_replacebo:
                phasetekst = customReplace(phasetekst, line, "<span style=color:orange>" & line & "</span>",
                                      true, "", @[])
              else:
                phasetekst = replace(phasetekst, line, "<span style=color:orange>" & line & "</span>")
            elif blockphasest == "LINK-WORDS TO HANDLE":
              if use_custom_replacebo:
                phasetekst = customReplace(phasetekst, line, "<span style=color:crimson>" & line & "</span>",
                                      true, "", @[])
              else:
                phasetekst = replace(phasetekst, line, "<span style=color:crimson>" & line & "</span>")
            elif blockphasest == "PREPOSITIONS TO HANDLE":
              if use_custom_replacebo:
                phasetekst = customReplace(phasetekst, line, "<span style=color:limegreen>" & line & "</span>",
                                      true, "", @[])
              else:
                phasetekst = replace(phasetekst, line, "<span style=color:limegreen>" & line & "</span>")


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
        
    finally:
      close(myfile)
  else:
    echo "Could not open file:" & def_filenamest

  return phasetekst


proc old_handleTextPartsFromHtml*(webaddresst, typest, languagest:string): string =
  #[ 
  This procedure is a forth-development of extractTextPartsFromHtml.
  Based on the webaddress as input-parameter, the webpage is downloaded.
  
  if typest is extract (old procedure): 
  Then the html is parsed and pieces of readable text (aot markup-codes)
  are extracted, concatenated and returned to procedure.

  if typest is replace:
  Then the html is parsed and pieces of readable text (aot markup-codes)
  are cut out, reformatted and pasted back into their original location.
  Thus a reformatted webpage arizes and is returned.
   ]#

  var
    client = newHttpClient()
    websitest: string
    test:string
    # textpartsq:seq[string] = @[]
    textpartst, textallst:string
    substringcountit: int
    substringpossq: seq[int]
    posit, textstartit, textendit:int
    allfoundbo: bool = false
    proef:string
    pos2it:int
    reformatedst:string


  const
    allowedtagsar = ["a", "abbr", "b", "br", "em", "ins", "main", "mark", "q", "small", "span", "strong", "time", "wbr"]


  try:
    websitest = client.getContent(webaddresst)
    echo "charcount = " & $len(websitest)

    substringcountit = count(websitest, "<p>")
    echo "\ptagcount = " & $substringcountit

    posit = -1

    while not allfoundbo:   # not all paragraphs found yet
      posit = find(websitest, "<p", posit + 1)
      # echo posit
      # proef = websitest[posit .. posit + 5]
      # # echo proef
      test = websitest[posit + 2 .. posit + 2]
      # echo test & "---"

      if posit != -1:
        if test == " " or test == ">":   # not other tags starting with p like picture
          textstartit = posit      
          # proef = websitest[posit .. posit + 5]
          # echo proef
          # echo "posit=" & $posit
          # echo test
          # echo "found"
      else:
        # no paragraphs found anymore
        allfoundbo = true
        echo "allfound = true"

      if not allfoundbo:
        # search paragraph-end
        pos2it = posit
        pos2it = find(websitest, "</p>", pos2it + 1)

        if pos2it != -1:    # par. end found
          textendit = pos2it + 4
          echo "pos2it= " & $pos2it
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
            reformatedst = applyDefinitionFileToText(textpartst, languagest)
            posit += len(reformatedst) - 2
            websitest.insert(reformatedst, textstartit)

        else:
          echo "Tag </p> not found; paragraph unclosed"

    if typest == "extract":
      return textallst
    elif typest == "replace":
      return websitest

  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error ******* \p" 
    echo repr(errob) & "\p****End exception****\p"

