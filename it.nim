import sockets, strutils, os, strtabs, render, httpclient

var client: Socket

var html = ""

var outp = ""
var readTag = false
var tag = ""
var outText = ""
var noTag = true
var inScript = false
var showText = false
var inQuotes = false
var inSpecial = false
var lastDiv = false

proc getimg(href:string) =
  var href2 = href
  if href[href.len-1] == '/':
    href2 = href[0..href.len-2]
  echo "Trying to download image from " & href2
  let parts = href2.split('/')
  let fname = parts[parts.len-1]
  try:
    writeFile(parts[parts.len-1], getContent(href2))
    drawImage(fname)
  except:
    echo "Problem downloading file"

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

proc getAttr(tokens, attr):string =
  var i = 0
  while tokens[i].find(attr) != 0:
    i += 1
  var parts = tokens[i].split('=')
  return parts[1].replace("\"","").replace("\'","")

proc foundTag() =
  outText = ""
  readTag = false
  let tokens = tag.split(' ')
  tag = tokens[0]
  if tag == "/div" or tag == "/p":
    nextLine()
    noTag = true
  elif tag == "img":
    var src = getAttr(tokens, "src")
    echo src
    if src[0..1] == "//":
      getimg "http:" & src
    elif src[0..2] == "htt":
      getimg src
    else:
      getimg "http://" & paramStr(1) & '/' & src

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
  outText = ""

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

var lines = @[""]

proc addLine(str) =
  var nl = str.split('\l')
  for l in nl:
    lines.add(l)
  drawLines(lines)

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
    addLine(outp)

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

