#[
Some tools like:
-options (config-file: settings_flashread.conf) 
-translation-proc
]#


import strutils

var 
  interfacelanguagestatust*: string = ""
  test: string



proc readOptionFromFile*(optnamest, typest: string):string =
  # Read from the settings-file based on the option-name either:
  # value, description or value-list

  var 
    filenamest: string = "settings_flashread.conf"
    clusterst: string
    optionsq: seq[string]
    optiondatast: string = ""
    myfile: File
    lastlinest: string
    tbo: bool = false


  if open(myfile, filenamest):    # try to open the file
    try:

      # walk thru the lines of the file
      if tbo: echo "\n=====Begin processing===="
      for line in myfile.lines:
        # echo line
        lastlinest = line
        if len(line) >= 5:        # exclude residual spaces
          if line[0 .. 0] != "#":     # exclude comments
            if line[0 .. 2] == ">>>":     # set cluster / subject
              # new cluster found
              clusterst = line[3 .. len(line) - 4]
              # echo clusterst
            else:                   # real options here
              optionsq = line.split("___")
              # echo optionsq
              if optionsq[0] == optnamest:    # option found
                if tbo: echo "------option found------"
                if tbo: echo optionsq
                if typest == "value":
                  optiondatast = optionsq[1]
                elif typest == "description":
                  optiondatast = optionsq[2]
                elif typest == "value-list":
                  optiondatast = optionsq[3]
                # exit loop when ready
                break

      if tbo: echo "\p===End of processing====\p"
    
    except IOError:
      echo "IO error!"
    
    except:
      let errob = getCurrentException()
      echo "\p******* Unanticipated error ******* \p" 
      echo "Last file-line read: " & lastlinest & "\p"
      echo repr(errob) & "\p****End exception****\p"

    finally:
      close(myfile)
  else:
    echo "File " & filenamest & " could not be opened."
    echo "Please check name and / or presence of file."

  return optiondatast



proc newlang*(englishtekst:string):string =
  # Read from the language-translation-file (*.tra) the
  # appropriate translation for the target-language 
  # and return that.

  var 
    filenamest: string
    clusterst: string
    translationsq: seq[string]
    transdatast: string = ""
    myfile: File
    lastlinest: string
    targetlangst:string
    translationfoundbo:bool = false

  targetlangst = readOptionFromFile("interface-language", "value")
  
  if targetlangst == "english":
    # no translation
    transdatast = englishtekst
  else:
    filenamest = targetlangst & "_translations.tra"

    if open(myfile, filenamest):    # try to open the file
      try:

        # walk thru the lines of the file
        echo "\n=====Begin processing===="
        for line in myfile.lines:
          # echo line
          lastlinest = line
          if len(line) >= 5:        # exclude residual spaces
            if line[0 .. 0] != "#":     # exclude comments
              if line[0 .. 2] == ">>>":     # set cluster / subject
                # new cluster found
                clusterst = line[3 .. len(line) - 4]
                # echo clusterst
              else:                   # real options here
                translationsq = line.split("___")
                # echo translationsq
                if translationsq[0] == englishtekst:    # option found
                  echo "------translation found------"
                  echo translationsq
                  translationfoundbo = true
                  transdatast = translationsq[1]
                  # elif typest == "description":
                  #   transdatast = translationsq[2]
                  # elif typest == "value-list":
                  #   transdatast = translationsq[3]

                  # exit loop when ready
                  break

        echo "\p===End of processing====\p"
      
      except IOError:
        echo "IO error!"
      
      except:
        let errob = getCurrentException()
        echo "\p******* Unanticipated error ******* \p" 
        echo "Last file-line read: " & lastlinest & "\p"
        echo repr(errob) & "\p****End exception****\p"

      finally:
        close(myfile)
    else:
      echo "File " & filenamest & " could not be opened."
      interfacelanguagestatust = filenamest & " could not be found. "

  if not translationfoundbo:
    transdatast = englishtekst

  return transdatast

test = newlang("something")

when isMainModule:
  echo readOptionFromFile("interface-language", "value-list")
  # echo newlang("not translated")

