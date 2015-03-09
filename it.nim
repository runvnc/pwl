import sockets, strutils, os, strtabs

var client: Socket

var html = ""

var outp = ""
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
    outp &= "\n"
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
    outp &= " "
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
        outp = outp & c
        if c != " ":
          lastDiv = false

proc process(html) =
  outp = ""
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

  if outp.len > 1:
    echo outp

proc conn()  =
  client = socket()

  client.connect(paramStr(1), Port(80))

  client.send("GET / HTTP/1.1\r\l")
  client.send("host: " & paramStr(1) & "\r\l")
  client.send("\r\l")

  var cont = true
  while cont:
    cont = client.recvLine(html)
    process(html)

conn()

