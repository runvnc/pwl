import sockets, strutils, os, strtabs, doc, httpclient

proc loadPage*(str:string) {.thread.} =
  var client: Socket
  var currLine:Line = @[]
  var currHref = ""
  var html = ""
  var host = ""
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

  var mydoc: Doc = @[]

  proc getimg(href:string) =
    var href2 = href
    if href[href.len-1] == '/':
      href2 = href[0..href.len-2]
    ##echo "Trying to download image from " & href2
    let parts = href2.split('/')
    let fname = parts[parts.len-1]
    #try:
    #3  writeFile(parts[parts.len-1], getContent(href2))
    #  # drawImage(fname)
    #except:
    #  #echo "Problem downloading file"

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

  proc endLink() =
    currLine.add(Node(kind:nkLink, link: (href:currHref, text:outp)))
    currHref = ""
    echo "/a"  

  proc foundTag() =
    outText = ""
    readTag = false
    let tokens = tag.split(' ')
    tag = tokens[0]
    if tag == "/div" or tag == "/p":
      nextLine()
      noTag = true
    elif tag == "/a":
      endLink()
      noTag = true
    elif tag == "a":
      currLine.add(Node(kind:nkText, text:outp))
      currHref = getAttr(tokens, "href")
      
    elif tag == "img":
      var src = getAttr(tokens, "src")
      #echo src
      if src[0..1] == "//":
        getimg "http:" & src
      elif src[0..2] == "htt":
        getimg src
      else:
        getimg "http://" & host & '/' & src

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
    if str.len > 0:
      currLine.add(Node(kind:nkText,text:str))
    if currLine.len > 0:
      chan.send(currLine)
      currLine = @[]
    #var nl = str.split('\l')
    #for l in nl:
    #  var toSend: Line
    #  toSend = @[Node(kind: nkText, text: l)]
    #  chan.send(toSend)

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
    echo "Waiting for hostname.."
    host = loadChan.recv()
    echo "Got host: " & host

    chan.send(@[Node(kind:nkText, text: "Connecting..")])
    client = socket()

    client.connect(host, Port(80))

    chan.send(@[Node(kind:nkText, text: "Connected.")])
    client.send("GET / HTTP/1.1\r\l")
    client.send("host: " & host & "\r\l")
    client.send("\r\l")

    var cont = true
    while cont:
      cont = client.recvLine(html)
      process(html)
    conn()

  conn()
