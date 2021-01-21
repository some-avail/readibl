#[ 
UNIT INFO
Flashread is a browser-based program to format text
into a more readable format.
To use the clipboard extra installation is needed.

REQUIREMENTS
External components:
> nimclipboard-lib:
on linux mint 19 you need to install folowing packages:
libx11-xcb-dev and/or xcb
in either one of those exists xbc.h, which is needed.
> moustachu
> jester


VERSION-LINKS = CO-WORKING MODULES
flashread     process_text   webgui_def    jo_htmlgen    stringstuff  f*.css  source_files outer_html.h* flashread.h* settings*   fr_tools   loadgui
070           0.25            0.2           0.2           0.1
071           0.25/0.26       0.2           0.2           0.1           0.67
080           0.26            0.2           0.2           0.1           0.68
081           0.26            0.3           0.4           0.1           0.69
085           0.28            0.4           0.4           0.1           0.70    0.1           1.0             1.0         1.0
086           0.28            0.5           0.4           0.1           0.70    0.1           1.0             1.1         1.0
087           0.29
089           0.30            0.6           0.5           0.1           0.80    0.2           1.1             1.2         1.1         0.1       0.1



ADAP HIS
-moustachu invoeren

  -html aanpassen
-definitionize / variablize remaining controls
  v-setDropDownSelection to jo_htmlgen
  v-button-text
  v-loose texts
  x-textboxes
-multi-lingual support
-html-template als apart bestand plaatsen
-buitenkader en binnenkader invoeren
-implement source-files-module to:
  -be accessible from all modules
  -to limt file-access
-in situ omzetting (reformat a whole webpage); 
  -bevindingen
    -zolang de form in de innerhtml zit heb je beperkte 
      controle over de target self of blank
    -na de eerste herlading wordt het blank-target gekozen
    -css wordt soms wel en soms niet geladen
    -door de herformatering wordt soms ook stuurcode
      vernaggeld
  -oplossing A; 
    -verplaatst het form naar de outerhtml
    -doe toevoegen een knop voor target type
  v-oplossing B:
    -doe toevoegen een vinkvakje voor newtab
  -oplossing C;
    -javascript toepassen
-improve reformating in-situ
-update titel
-talen-info verhuizen van de broncode naar de tekstbestanden


ADAP NOW


ADAP FUT
-check if additional sources can be loaded like css and pictures
-prevalidate language-dat-file before running
-javascript toevoegen
-koppelingen externe website aanhangen aan eigen website
-web-redo, mogn:
  -inhoudsopgave
 ]#


import jester
import strutils
import httpcore
import process_text
import os
import jo_htmlgen
import nimclipboard/libclipboard
import moustachu
import source_files
import fr_tools
import loadgui
import times


var
  statustekst, statusdatast:string
  output_tekst:string
  filepathst: string
  newinnerhtmlst: string
  filestatusmessagest: string


const 
  versionfl:float = 0.90
  minimal_word_lengthit = 7
  appnamebriefst:string = "RD"
  appnamenormalst = "Readibl"
  appnamesuffikst = "Text Reformatter"


filepathst = "getappdir: " & getappdir() & " <br>" &
          "getcurrentdir: " & getcurrentdir() & " <br>"


filestatusmessagest = sourcefilestatust & interfacelanguagestatust
# check if thru source_files.nim if all files are loaded successfully
if sourcefilestatust != "":  
  statustekst = filestatusmessagest  
else:
  statustekst = newlang("Press button to paste the content of the clipboard.")


settings:
  # port = Port(5003)   # production
  port = Port(parseInt(readOptionFromFile("port-number", "value")))  # development


var 
  innervarob: Context = newContext()  # inner html insertions
  outervarob: Context = newContext()   # outer html insertions
  innerhtmlst:string

outervarob["version"] = $versionfl
outervarob["loadtime"] = newlang("Server-start: ") & $now()
outervarob["pagetitle"] = appnamenormalst
outervarob["namesuffix"] = newlang(appnamesuffikst)

proc getWebTitle():string = 
  var 
    clipob = clipboard_new(nil)
    past, inter_tekst:string

  past = $clipob.clipboard_text()

  if past[0 .. 3] == "http":   # pasted text is a link
    inter_tekst = getTitleFromWebsite(past)
  else:
    inter_tekst = past[0 .. 20]

  return appnamebriefst & "_" & inter_tekst


proc jump_to_end_step(languagest, preprocesst, taglist:string, typest:string =""): string =
  var 
    clipob = clipboard_new(nil)
    past, inter_tekst, resulttekst:string

  past = $clipob.clipboard_text()

  if past[0 .. 3] == "http":   # pasted text is a link
    inter_tekst = handleTextPartsFromHtml(past, "extract", languagest, taglist)
  else:
    inter_tekst = past

  if typest == "":
    resulttekst = replaceInText(inter_tekst, languagest, preprocesst)
  elif typest == "insite_reformating":
    resulttekst = handleTextPartsFromHtml(past, "replace", languagest, taglist)
  return resulttekst


proc showPage(custominnerhtmlst:string=""): string = 
  # aangepaste innerhtml als parameter
  if custominnerhtmlst == "":
    innerhtmlst = render(textsourcefileta["flashread.html"] , innervarob)    
  else:
    innerhtmlst = custominnerhtmlst

  outervarob["flashread_form"] = innerhtmlst
  return render(textsourcefileta["outer_html.html"] , outervarob)



routes:

  get "/flashread-form":
    # load initial form
    innervarob["statustext"] = newlang(statustekst)
    innervarob["statusdata"] = ""
    innervarob["pastedtext"] = ""
    innervarob["processedtext"] = filepathst
    innervarob["text_language"] = setDropDown("text-language", readOptionFromFile("text-language", "value"))
    innervarob["taglist"] = setDropDown("taglist", "paragraph-only")
    innervarob["radiobuttons_1"] = setRadioButtons("orders","")
    innervarob["urltext"] = ""
    innervarob["checkboxes_1"] = setCheckBoxSet("fr_checkset1", @["default"])
    innervarob["submit"] = newlang("Choose and run")
    innervarob["textbox-remark"] = newlang("Your item will be pasted here (text or web-link):")
    innervarob["newtab"] = "_self"

    resp showPage()


  get "/flashread-form/@errorst":
    # load error-form - not used
    innervarob["statustekst"] = @"errorst"
    innervarob["statusdata"] = ""
    innervarob["pastedtext"] = ""
    innervarob["processedtext"] = filepathst
    innervarob["text_language"] = setDropDown("text-language", readOptionFromFile("text-language", "value"))
    innervarob["taglist"] = setDropDown("taglist", "paragraph-only")    
    innervarob["radiobuttons_1"] = setRadioButtons("orders","")
    innervarob["urltext"] = ""
    innervarob["checkboxes_1"] = setCheckBoxSet("fr_checkset1", @["default"])
    innervarob["submit"] = newlang("Choose and run")
    innervarob["textbox-remark"] = newlang("Your item will be pasted here (text or web-link):")

    resp showPage()


  post "/flashread-form":
    if request.params["orders"] == "pasteclip":

      var clipob = clipboard_new(nil)
      var past = clipob.clipboard_text()

      if @"jump_to_end" == "":
        # copy the from clipboard to the textbox
        # move to next radiobutton transfer

        statustekst = "Pasted. Now transfer text from link or pasted text."
        statusdatast = @"jump_to_end"


        innervarob["statustext"] = newlang(statustekst)
        innervarob["statusdata"] = statusdatast
        innervarob["pastedtext"] = $past
        innervarob["processedtext"] = ""
        innervarob["text_language"] = setDropDown("text-language", @"text-language")
        innervarob["taglist"] = setDropDown("taglist", @"taglist")
        innervarob["radiobuttons_1"] = setRadioButtons("orders", "transfer")
        innervarob["urltext"] = ""
        innervarob["checkboxes_1"] = setCheckBoxSet("fr_checkset1", @[@"jump_to_end", @"summarize", 
                                      @"insite_reformating", @"newtab"])
        innervarob["submit"] = newlang("Choose and run")
        innervarob["textbox-remark"] = newlang("Your item will be pasted here (text or web-link):")
        if @"newtab" == "":
          innervarob["newtab"] = "_self"
        elif @"newtab" == "newtab":
          innervarob["newtab"] = "_blank"

        resp showPage()


      elif @"jump_to_end" == "jump_to_end":
        if @"insite_reformating" == "":
          output_tekst = jump_to_end_step(@"text-language", @"summarize", @"taglist")
          statustekst = "Output number of characters:"
          statusdatast = $len(output_tekst)
          innervarob["statustext"] = newlang(statustekst)
          innervarob["statusdata"] = statusdatast
          innervarob["pastedtext"] = $past
          innervarob["processedtext"] = output_tekst
          innervarob["text_language"] = setDropDown("text-language", @"text-language")
          innervarob["taglist"] = setDropDown("taglist", @"taglist")
          innervarob["radiobuttons_1"] = setRadioButtons("orders", "pasteclip")
          innervarob["urltext"] = ""
          innervarob["checkboxes_1"] = setCheckBoxSet("fr_checkset1", @[@"jump_to_end", @"summarize", 
                                                @"insite_reformating", @"newtab"])
          innervarob["submit"] = newlang("Choose and run")
          innervarob["textbox-remark"] = newlang("Your item will be pasted here (text or web-link):")
          if @"newtab" == "":
            innervarob["newtab"] = "_self"
          elif @"newtab" == "newtab":
            innervarob["newtab"] = "_blank"
            outervarob["pagetitle"] = getWebTitle()

          resp showPage()


        elif @"insite_reformating" == "insite_reformating":
          # output_tekst = jump_to_end_step(@"text-language", @"summarize")
          newinnerhtmlst = jump_to_end_step(@"text-language", @"summarize", @"taglist", @"insite_reformating")
          statustekst = "Output number of chickens:"
          statusdatast = $len(newinnerhtmlst)
          innervarob["statustext"] = newlang(statustekst)
          innervarob["statusdata"] = statusdatast
          innervarob["pastedtext"] = $past
          innervarob["processedtext"] = newinnerhtmlst
          innervarob["text_language"] = setDropDown("text-language", @"text-language")
          innervarob["taglist"] = setDropDown("taglist", @"taglist")          
          innervarob["radiobuttons_1"] = setRadioButtons("orders", "pasteclip")
          innervarob["urltext"] = ""
          innervarob["checkboxes_1"] = setCheckBoxSet("fr_checkset1", @[@"jump_to_end", @"summarize", 
                                      @"insite_reformating", @"newtab"])
          innervarob["submit"] = newlang("Choose and run")
          innervarob["textbox-remark"] = newlang("Your item will be pasted here (text or web-link):")
          if @"newtab" == "":
            innervarob["newtab"] = "_self"
          elif @"newtab" == "newtab":
            innervarob["newtab"] = "_blank"
            outervarob["pagetitle"] = getWebTitle()

          resp showPage(newinnerhtmlst)


    elif request.params["orders"] == "transfer":
      # transfer the text or link from input to the right column
      # determine type of pasted_text (text or link)
      if @"pasted_text"[0..3] == "http":   # pasted text is a link
        # output_tekst = extractTextPartsFromHtml(@"pasted_text")
        output_tekst = handleTextPartsFromHtml(@"pasted_text", "extract", @"text-language", @"taglist")
        # echo output_tekst
        
        statustekst = "Output number of characters:"
        statusdatast = $len(output_tekst)
        innervarob["statustext"] = newlang(statustekst)
        innervarob["statusdata"] = statusdatast
        innervarob["pastedtext"] = output_tekst
        innervarob["processedtext"] = output_tekst
        innervarob["text_language"] = setDropDown("text-language", @"text-language")
        innervarob["taglist"] = setDropDown("taglist", @"taglist")        
        innervarob["radiobuttons_1"] = setRadioButtons("orders", "frequencies")
        innervarob["urltext"] = @"pasted_text"
        innervarob["checkboxes_1"] = setCheckBoxSet("fr_checkset1", @[@"jump_to_end", @"summarize", 
                                      @"insite_reformating", @"newtab"])
        innervarob["submit"] = newlang("Choose and run")
        innervarob["textbox-remark"] = newlang("Your item will be pasted here (text or web-link):")
        if @"newtab" == "":
          innervarob["newtab"] = "_self"
        elif @"newtab" == "newtab":
          innervarob["newtab"] = "_blank"

        resp showPage()

      else:
        var converted_tekst:string = replace(@"pasted_text", "\p", "<br>")

        statustekst = "Text transferred to right column"
        innervarob["statustext"] = newlang(statustekst)
        innervarob["statusdata"] = ""
        innervarob["pastedtext"] = @"pasted_text"
        innervarob["processedtext"] = converted_tekst
        innervarob["text_language"] = setDropDown("text-language", @"text-language")
        innervarob["taglist"] = setDropDown("taglist", @"taglist")        
        innervarob["radiobuttons_1"] = setRadioButtons("orders", "frequencies")
        innervarob["urltext"] = ""
        innervarob["checkboxes_1"] = setCheckBoxSet("fr_checkset1", @[@"jump_to_end", @"summarize", 
                                        @"insite_reformating", @"newtab"])
        innervarob["submit"] = newlang("Choose and run")
        innervarob["textbox-remark"] = newlang("Your item will be pasted here (text or web-link):")
        if @"newtab" == "":
          innervarob["newtab"] = "_self"
        elif @"newtab" == "newtab":
          innervarob["newtab"] = "_blank"

        resp showPage()



    elif request.params["orders"] == "frequencies":
      output_tekst = calculateWordFrequencies(@"pasted_text", minimal_word_lengthit, true)
      statustekst = "Calculated frequencies for minimal word-length:"
      statusdatast = $minimal_word_lengthit
      innervarob["statustext"] = newlang(statustekst)
      innervarob["statusdata"] = statusdatast

      innervarob["pastedtext"] = @"pasted_text"
      innervarob["processedtext"] = output_tekst
      innervarob["text_language"] = setDropDown("text-language", @"text-language")
      innervarob["taglist"] = setDropDown("taglist", @"taglist")      
      innervarob["radiobuttons_1"] = setRadioButtons("orders", "process_text")
      innervarob["urltext"] = @"url_text"
      innervarob["checkboxes_1"] = setCheckBoxSet("fr_checkset1", @[@"jump_to_end", @"summarize", 
                                                @"insite_reformating", @"newtab"])
      innervarob["submit"] = newlang("Choose and run")
      innervarob["textbox-remark"] = newlang("Your item will be pasted here (text or web-link):")
      if @"newtab" == "":
        innervarob["newtab"] = "_self"
      elif @"newtab" == "newtab":
        innervarob["newtab"] = "_blank"

      resp showPage()


    if request.params["orders"] == "process_text":

      output_tekst = replaceInText(@"pasted_text", @"text-language", @"summarize")
      statustekst = "Output number of characters:"
      statusdatast = $len(output_tekst)
      innervarob["statustext"] = newlang(statustekst)
      innervarob["statusdata"] = statusdatast

      innervarob["pastedtext"] = @"pasted_text"
      innervarob["processedtext"] = output_tekst
      innervarob["text_language"] = setDropDown("text-language", @"text-language")
      innervarob["taglist"] = setDropDown("taglist", @"taglist")      
      innervarob["radiobuttons_1"] = setRadioButtons("orders", "pasteclip")
      innervarob["urltext"] = @"url_text"
      innervarob["checkboxes_1"] = setCheckBoxSet("fr_checkset1", @[@"jump_to_end", @"summarize", 
                                                    @"insite_reformating", @"newtab"])
      innervarob["submit"] = newlang("Choose and run")
      innervarob["textbox-remark"] = newlang("Your item will be pasted here (text or web-link):")
      if @"newtab" == "":
        innervarob["newtab"] = "_self"
      elif @"newtab" == "newtab":
        innervarob["newtab"] = "_blank"
        outervarob["pagetitle"] = getWebTitle()

      resp showPage()


    # elif request.params["orders"] == "process_link":
    #   output_tekst = extractTextPartsFromHtml(@"pasted_text")
    #   # echo output_tekst
    #   statust = "Output number of characters: " & $len(output_tekst)

    #   resp FLASHREAD_FORM.format(
    #         $versionfl,
    #         statust,
    #         @"pasted_text",
    #         output_tekst,
    #         setDropDownSelection(@"text-language"),
    #         setRadioButtons("orders", "process_link")
    #         )

    # else:
    #   discard
    #   # redirect "/flashread-form/$1".format("Error_Enter_text_to_proceed")


  get "/":
    resp "Goodbye"

