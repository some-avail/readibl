## Readibl Text Reformatter

![CNN_article_journalism_highlighting_2024.png](screenshots/CNN_article_journalism_highlighting_2024.png)

[See below for more screenshots](#more-screenshots)

[Go to downloadable releases for windows and linux](https://github.com/some-avail/readibl/releases "Downloads for Readible")

[Go to the user-manual / wiki-section](https://github.com/some-avail/readibl/wiki)

[See what is new / what-is-new.txt](mostfiles/what-is-new.txt)


Now Readibl 0.94 is available, 0.95 is forthcoming.
Readibl Text Reformatter is a program to format normal text or html, so that it is easier to read and process mentally. The program was previously called FlashRead.
The program is written in the language Nim.



#### Installation on linux
- download latest linux-release (tar.gz).
- unpack, place it somewhere in your user-folder.
- open a terminal and go to your Readibl-directory.
- run the executable "flashread" by entering: ./flashread
- to access the local web-server you just started, type: 
	http://localhost:5050/flashread-form
- the portnumber can now be changed in the configuration-file: settings_flashread.conf
- see also in the readibl-folder: help_info/help.txt

If the app is started from a dir where the application does NOT reside, path-problems will occur. In that case  adjust and run the linux-script flashread_sh. 


#### Installation on windows
- download latest windows-release (.zip)
- unpack, place it somewhere in your user-folder, and run the executable "flashread".
- start the app preferably from a terminal / powershell to view progress-info.
- to access the local web-server you just started, type: 
	http://localhost:5050/flashread-form


#### Usage
Then you get the user-interface in the browser. From there on you can use the clipboard-contents to either reformat a copied text, or use a copied web-address to process and reformat. Experiment with the switches.
In the config-file "settings_flashread.conf" you can change things like:
- the port-number can be adjusted
- interface-language can be set (besides english there is only dutch for now, but you can make you own language-file *translations.tra).
- possible processing text-languages; only english.dat en dutch.dat exist for now, but you can make your own.

Further info on settings: see the wiki.


#### Installation by building (for developers)
Developer with knowledge of nim can download the code and do the following:
- install external components:
	- nimclipboard library:
		> found at: https://github.com/genotrance/nimclipboard
		> follow the instructions
	- moustachu library:
		> found at: https://github.com/fenekku/moustachu
		> Nim 1.6 follow instructions
		> Nim 2.x follow the workaround given in the issues-section.
	- jester
		> found at: https://github.com/dom96/jester
		> run: nimble install jester


Go to the folder: mostfiles.
Run the command:
nim c -r -d:ssl --threads:off -d:release flashread.nim

which will compile the code to an executable, which will then be executed. The running program then acts as a local  web-server, which can be invoked from a web-browser, by typing:
http://localhost:5050/flashread-form

Created by Joris Bollen.


<a name="more-screenshots">More screenshots:</a>

Multi-color journalistic highlighting effect in dark mode (thanks to firefox add-on Dark Reader).
The summary / highlighting-order is generic, sources, places and times:
![CNN_journalism_highlighting_night-mode_2024.png](screenshots/CNN_journalism_highlighting_night-mode_2024.png)

Summarization example (1 of 2) with 3 extractions based a single summary-file:
![wiki_flower_summarized_1of2_2024.png](screenshots/wiki_flower_summarized_1of2_2024.png)

Summarization example (2 of 2) showing the extractions:
![wiki_flower_summarized_2of2_2024.png](screenshots/wiki_flower_summarized_2of2_2024.png)

Another multi-coloring example:
![wikipedia_flower_2024.png](screenshots/wikipedia_flower_2024.png)

*Some older stepped examples:*

Before application of readible reformatting:
![before_readible.png](screenshots/before_readible.png)

After application of readible reformatting:
![after_readibl.png](screenshots/after_readibl.png)

Word-frequencies can calculated to get a quick impression of the content.
![word-frequencies.png](screenshots/word-frequencies.png)


