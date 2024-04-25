The reformatting is done by surrounding the words or word-parts of the text with html-markup-styling. For example, prepositions like the word "into" take on a green color:  
`<span style=color:limegreen> into </span>`

## Styling codes
In the definition-file "parse_english.dat" (or genericly "parse_language.dat") are categories (below in capitals) of words/strings listed that will get each their own style. Below are listed per category:
* categorial headers
* one sample string to be styled (a line in the definition-file)
* the html-styling code (the word "line" designates the stylable string)
* an explanation of the formatting string

PUNCTUATION OF SENTENCES TO HANDLE  
.  
Styling code: `line & "<br>&nbsp;&nbsp;&nbsp;&nbsp;"`  
Explanation:    After the dot a line-break is placed and then on the following line 4 non-breaking-spaces are placed so that an indent is created for each new line.  
  
PUNCTUATION OF SENTENCE-PARTS TO HANDLE  
,  
Styling code: `line & "<br>"`  
Explanation: After the comma only a line-break is placed so that each subsentence / clause gets a new line.
  
PRONOUNS TO HANDLE  
 that  
Styling code: `"<br>" & line`  
Explanation: A line-break is placed BEFORE the word "that" so that a subsentence is created on the following line starting with "that".

VERBS TO HANDLE  
 be  
Styling code: `<span style=color:magenta>" & line & "</span>`  
Explanation: the verb (or verb-part) is colored magenta; a pinkish color that is pretty strong highlighting because are so important in a sentence.  
  
SIGNAL-WORDS TO HANDLE  
princip  
Styling code:`<span style=color:#ff6600>" & line & "</span>`  
Explanation: Color is reddish orange. The current set of signal-words is used to highlight words that have a scientific relevance. Previously these words were also used to create the summary but the summary is now based on summary_language.dat (summary_english.dat for english). Of course you can adjust the list to create your own signal-words / highlights.  

LINK-WORDS TO HANDLE  
 and  
Styling code: `"<span style=color:red>" & line & "</span>"`  
Explanation: This group concerns words that compare or link sentence-parts but cannot be seen as a separate sentence.  

PREPOSITIONS TO HANDLE  
 on  
Styling code: `"<span style=color:limegreen>" & line & "</span>"`  
Explanation: Prepositions (green) are also usefull to separate word-groups.  
  
NOUN-ANNOUNCERS TO HANDLE  
The  
Styling code: `"<span style=color:#b35919>" & line & "</span>"`  
Explanation: The color is light-brown. These words announce a group of words with at least 1 noun in it. Also adverbs, adjectives and chained nouns can be part of this group.  
  
NOUN-REPLACERS TO HANDLE  
 I  
Styling code: `"<span style=color:darkturquoise>" & line & "</span>"`  
Explanation: These words replace or stand for nouns, hence they are also called pronouns.  
  
AMBIGUOUS WORD-FUNCTIONS TO HANDLE  
 to  
Styling code: `"<span style=color:#e6b800>" & line & "</span>"`  
Explanation: The color is ochre-yellow. These words indicate a verbs or some other function (because verbs are crucial to understand a sentence). The example " to " often announces a verb (I want to walk), but it can also be just a preposition (he goes to school).  
  

## Additional remarks
Summarizing, the stylable strings / line of the parse_language.dat file have one of the following characteristics:
* they are a punctuation, like "." or "?"
* they are either a word or a word-part; for example to identify the verbal past tense the string "ed " can be used.
* the strings can be prepended or postpended with a space like " be ". This is often needed to distinguish from other words. For example if you have "ed" you get past tense words, but also words like edict, edible etc. Therefore "ed " is preferred.

## False positives
Above we saw allready that false positives arise easily but must be avoided (or at least be indicated like in the ochre-yellow case). However they cannot be avoided totally. 

## Public lists
Until now I have myself compiled the parse_language.dat files. A possible future option is to use public lists of words with grammatical functions. However, the longer the list becomes, the slower the processing will become. Also I have not yet searched for these public options. Another option would be some library that can do natural language parsing, but I have not looked for those either (as far as they exist and are reliable).

## Non-ascii characters
I have not yet investigated if non-ascii or other exotic characters can be used for parsing. I will soon check that out.



