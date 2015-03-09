import httpclient, strutils, os, streams, htmlparser, xmltree,
       strtabs

var html = getContent(paramStr(1))

var readTag = false
var tag = ""
var text = ""
var noTag = true
var inScript = false
var showText = false
var inQuotes = false
var inSpecial = false
var lastDiv = false

proc openTag() =
  tag = ""
  readTag = true

proc handleTag(tag: var string) =
  if tag == "script":
    inScript = true
  elif tag == "/script":
    inScript = false
  tag = ""

proc nextLine() =
  if not lastDiv:
    echo()
  lastDiv = true

proc foundTag() =
  text = ""
  readTag = false
  let tokens = tag.split(' ')
  tag = tokens[0]
  if tag == "/div" or tag == "/p":
    nextLine()
    noTag = true
  elif tag[0] == '/':
    write(stdout, " ")
    noTag = true
  else:
    noTag = false
  if tag.contains("script"):
    inScript = true
  if tag == "/script":
    inScript = false
    showText = true
  if not tag.contains("script") and
     tag != "style" and
     tag != "link" and (not inScript):
    showText = true
  else:
    showText = false  

proc closeTag() =
  handleTag(tag)
  tag = ""
  text = ""

proc add(c:string) =
  if showText:
    if not inScript:
      if inSpecial and c == ";":
        inSpecial = false
      elif c == "&":
        inSpecial = true
      elif not inSpecial and 
        c != "\r" and c != "\n" and
        c != "\t":
        write(stdout, c)
        if c != " ":
          lastDiv = false

echo html.len

for i,c in html:
  case c
  of '<' :
    if not inScript:
      openTag()
    elif html[i..i+7] == "<script":
      openTag()
  of '>' :
    if not inScript:
      foundTag()
    elif html[i-8..i] == "</script>":
      foundTag()
      inScript = false
  else:
    if readTag:
      tag &= $c
    else:
      add($c)

