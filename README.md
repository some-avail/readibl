## Readibl Text Reformatter


Readibl Text Reformatter is a program to format normal text or html, so that it is easier to read and process mentally. The program was previously called FlashRead.
The program is written in the language Nim.


#### Installation on linux
-download latest linux-release (tar.gz).
-unpack, place it somewhere in your user-folder, and run the executable "flashread".
-to access the local web-server you just started, type: http://localhost:5050/flashread-form
-the portnumber can now be changed in the configuration-file: settings_flashread.conf

If the paths you see on the webpage dont match the location of the application, adjust and run the linux-script flashread_sh. If the app is started from the dir where the application resides, path-problems can be avoided.


#### Installation on windows
-download latest windows-release (.zip)
-unpack, place it somewhere in your user-folder, and run the executable "flashread".
-to access the local web-server you just started, type: http://localhost:5050/flashread-form


#### Usage
Then you get the user-interface in the browser. From there on you can use the clipboard-contents to either reformat a copied text, or use a copied web-address to process and reformat. Experiment with the switches.
In: settings_flashread.conf:
-the port-number can be adjusted
-interface-language can set (besides english only dutch for, but you can make you own language-file *translations.tra).
-possible processing text-languages; only english.dat en dutch.dat exist for now, but can make your own.



#### Installation by building
Developer with knowledge of nim can download the code and do the following:
-install external components:
> nimclipboard-lib:
on linux mint 19 you need to install folowing packages:
libx11-xcb-dev and/or xcb
in either one of those exists xbc.h, which is needed.
> moustachu
> jester

Run the command:
nim c -d:ssl -r flashread.nim

which will compile the code to an executable, which will then be executed. The running program then acts as a local  web-server, which can be invoked from a web-browser, by typing:
http://localhost:5050/flashread-form

The port-number can be adjusted in: settings_flashread.conf


Created by Joris Bollen.

