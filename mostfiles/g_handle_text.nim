import std/[strutils]




proc chopString*(inputtekst: string; words_per_chunkit: int): seq[string] = 

  # chop the input-text in chunks of about words_per_chunkit words.
  

  var 
    linewordcountit: int = 0
    chunkst: string = ""
    partsq, adjustedlinesq, hanlinesq: seq[string]


  # rework the lines to maximize linewordcount
  for linest in inputtekst.splitLines:
    linewordcountit = linest.split(' ').len
    #echo "linest.split(' ') = " & $linest.split(' ')
    if linewordcountit <= words_per_chunkit:
      adjustedlinesq.add(linest)
    else:   # linewordcountit > words_per_chunkit
  
      hanlinesq = linest.split(' ')
      #echo "hanlinesq = " & $hanlinesq
      while hanlinesq.len > words_per_chunkit:
        adjustedlinesq.add(hanlinesq[0..words_per_chunkit - 1].join(" "))
        hanlinesq = hanlinesq[words_per_chunkit..^1]

      if hanlinesq.len > 0:
        adjustedlinesq.add(hanlinesq.join(" "))


  # fill chunks with lines until they are full and then add them to partsq
  for linest in adjustedlinesq:
    if chunkst.len + linest.len <= words_per_chunkit:
      chunkst &= linest & "\p"
    else:   # chunkst.len + linest.len > words_per_chunkit
      partsq.add(chunkst)
      chunkst = linest

  partsq.add(chunkst)

  result = partsq




proc chopString2*(inputtekst: string; chars_per_chunkit: int): seq[string] = 

  # chop the input-text in chunks of chars_per_chunkit words.

  var 
    newtekst = inputtekst
    partsq: seq[string]


  while newtekst.len > chars_per_chunkit:
    partsq.add(newtekst[0..chars_per_chunkit - 1])
    newtekst = newtekst[chars_per_chunkit..^1]

  if newtekst.len > 0:
    partsq.add(newtekst)

  result = partsq



proc chopString3*(inputtekst: string; chars_per_chunkit: int): seq[string] = 

  #[ new algorithm that only separates on line-break, not mid-sentence.
  chop the input-text in chunks of about chars_per_chunkit words,
      but from the calculated border start searching for the first eol-char, 
      after which the separation is to be done.
  ]#


  var 
    chunktekst: string
    partsq: seq[string]

  var curposit: int = 0
  var newposit, prevposit: int
  let eofit = inputtekst.len  # end-of-file
  let chunksizeit = chars_per_chunkit
  var eof_reachedbo: bool = false

  # while eof - current-pos > chunk-size:
  while eofit - curposit > chunksizeit:
    prevposit = curposit
    # cur.pos = cur.pos + chunksize
    curposit += chunksizeit
    # search from cur.pos (the pre-calculated border-point) the first line-break
    newposit = inputtekst.find("\n", curposit)
    # if found it becomes the new cur.pos and becomes clip-point
    if newposit != -1:
      curposit = newposit
      # create chunktekst
      chunktekst = inputtekst[prevposit .. curposit]
    else:
      # else make a last chunk from the cur.pos to the eof
      chunktekst = inputtekst[prevposit .. eofit - 1]
      eof_reachedbo = true
    partsq.add(chunktekst)

  if not eof_reachedbo:
    # the last part that was smaller than a chunk
    if curposit < eofit - 1:
      partsq.add(inputtekst[curposit .. eofit - 1])

  result = partsq

