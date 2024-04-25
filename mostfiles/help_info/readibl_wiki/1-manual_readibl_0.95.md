## 1 Manual for Readibl Text Reformatter
Readible is a program to format text coming from the clipboard, either as a chunk of text or as a web-link (to a html-text). After installation, the program must be started. Once started it works as a local webserver serving one page for now. It can then be accessed in any web-browser thru the weblink:
[http://localhost:5050/flashread-form](http://localhost:5050/flashread-form)

After start-up you get the following web-interface:

![Web-user-interface](https://github.com/some-avail/readibl/blob/main/screenshots/Readibl_startup_screen.png)

## Basic usage in stepped mode
To reformat a text or webpage do the following (stepped mode):
1. Copy a piece of text or a weblink.
2. Load or reload the page (http://127.0.0.1:5050/flashread-form) so that the state of the image arises.
3. Click the button choose-and-run repetitively to perform the actions from the radio-buttons below the main button. (web-servers that work without javascript have often only one button to Submit).
    1. The clipboard-text will be pasted to the box below.
    2. Case of:
        1. Clipboard-text. It will transferred to the right panel for initial assesment.
        2. Clipboard-weblink. The weblink will be copied to the textbox below. Also the corresponding website is retrieved and put in the first textbox (where the pasted item was). Also the retrieved text will be displayed on the right panel, still not reformatted.
    3. After another button-click the word-frequencies will be calculated, to give an impression of the content of the text.
    4. At the last click finally the text will be reformated, based on the chosen text-language and tag-list, which are the drop-down-boxes of right of the left panel.

## Advanced usage with jump-mode
If you have some experience with the user-interface you can check the check-box Jump-to-end-step. When clicking the button Choose-and-run, Readibl gives immediately the end-result without intermediate steps. This only works when the first radio-button is selected.

## Explanation of the controls

### Summary-dropdown element
By selecting a non-empty summary you can either (or both):
* highlight the words in the article that are listed in the summary.
* extract the sentences from the article in which the words occur. The summary-words in the extractions are also highlighted.

### Use multi-summary (checkbox)
With multi-summary checked you can use multiple summaries for either highlighting or extraction. You can inform Readibl about which summaries you want to use thru the file: data_files/list-of-summaries.lst

You can enter an ordered list of summaries between the list-separators. If the list-seps are changed or have no valid summaries between them, Readibl revert to using the normal single summary. A message is shown at the status-text. Below the separated list you can put previously used batches so that you can quickly copy them back if needed to.

You get up to six colors from each listed summary when they are used in the separated list. The different colors match the order of the summaries. As an example I like to use the journalistic set as follows:
1. generic
2. source
3. place
4. time

The (fixed) color-order is: ocre, green, blue, reddish, purplish, grey.


### Text-language (processing language) drowdown
Select the text-language dropdown matching the language of the text you want to reformat. For now only Dutch and English are implemented. Selecting a language will point Readibl to a definition-file, in which the processing-data is located. For now only the files parse_english.dat and parse_dutch.dat exist (parse_ prefix added since 0.94). However new files can be created, like for example parse_french.dat. You can model a new file french.dat after the file parse_english.dat. The existence of the file must be announced in settings_flashread.conf which is the general config-file for Readibl. Just add ",,french" without the quotes after the line starting with "text-language". The setup of the file parse_language.dat will be treated in another place. After creating a new file "parse_newlang.dat" you can evaluate / validate it by starting Readibl and looking at the validation-report (since 0.94).

### Tag-list dropdown
The tag-list dropdown allows you to pick which html-element(s) must be parsed for reformatting. Most content is stored the paragraph-element. In extraction-mode it usefull to extract the headings as well. If you want for example (un)ordered lists to be reformatted, you can "Full list".

### Jump to end (checkbox)
See above at Advanced mode.

### Summarize your text (checkbox)
Checking the summary-box will not extract the whole text but only sentences with the words listed in the file with the name summary_language_subject.dat, like summary_english_default.dat. The first few sentences will be extracted anyway, but after that, only the listed ones. The delivered summary-file is more of a scientific selection, but you can make you own or multiple summary-files, for like history, policy-science, journalism etc. For now you have to manually (re)name the files to keep them apart and select a specific one. The summarize-option works only in the extraction-mode or off-site-mode (see following option). After creating a new file "summary_somelang_subjectx.dat" you can evaluate / validate it by starting Readibl and looking at the validation-report (since 0.94).

### Contents-generation (experimental)
In case of off-site rendering (see below), contents-generation can be used. It works reasonably for sites like wikipedia, but for pasted texts it does not yet work that well.

### In-site reformatting (checkbox)
Until now the way to go was extract text from webpages, reformat it and put in the right panel (extraction or off-site mode). By checking this box (together with jump-to-end, and the first radio-button) you can format the text within the original website, thus keeping the format and pictures that belong to it. Most but not all sites can be reformatted this way. (some use obscure html-elements for example). For now you have to do the pasting thing to get the website reformatted. In an ideal situation one could navigate the reformatted website but that can not be done with Readibl. That would require a dedicated browser I think. 

### Open result in new tab (checkbox)
The above option reformats in the website itself, thus loading that website instead of Readibl. Hence the option to open a website in a new tab. There is however a little catch to reckon with. To make this option work, you must check the box and press the main button, so that the readible-server gets the info that new tabs must be created instead of loading in the current tab. After that this option is checked it will propagate in subsequent tabs. The other way around to disable this checkbox, you have to reload the main Readibl tab (or another one) by pressing enter in the address-bar of press F5.

## Special functions

### Data-file-validation
In the normal situation, when starting Readibl, the most important data-files are validated. These concern the parse-files and the summary-files. Things like incorrect section-separators, empty sections etc. are evaluated and listed at startup. Hence you can correct them if needed.

### Comparison of summary-files (CSF)
- since 0.95, CSF can be activated by entering the two summary-names in the options-file (settings_flashread.conf) at the relevant option.
- reload Readibl and the diffs are shown in the startup-screen.
- resetting the file-names to dummy-names will restore the generic data-file-validation on startup.

## Options in settings_flashread.conf

The file settings_flashread.conf holds all the options of Readibl. The top of the file gives a short description of its working:
- This is a configuration file for flashread / Readibl
- Every option uses one line (but it may line-wrapped in your editor)
- Per line there are four fields related to the option:
- name, value, description and value-list.
- The fields are separated by a triple underscore-sign
- The value-list-elements are separated by a double comma
- Please normally use lower case letters
- Options can disabled by prefixing a hash-sign

It is best to create a copy before tinkering with the file. Most options are self-explanatory following above pattern. 
I only want to add that checkbox-options are clustered in sets, whereby the startup-values can be entered thru the settings also for all items of the set. Currently there is one set of 5 elements, and one set of 1 element.
