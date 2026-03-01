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


