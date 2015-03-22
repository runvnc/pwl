import os, threadpool, sdl, sdl_gfx, sdl_image, strutils, sdl_ttf, doc, it

var message: PSurface
var event: TEvent
var font: PFont
var startLine = 0
var document: Doc = @[]


var textColor = TColor(r: 20, g:20, b:20)
var linkColor = TColor(r: 250, g:10, b:60)

proc apply_surface(x,y:int16, source, destination: PSurface,
                    clip:PRect = nil ) =
  var offset = TRect(x:x, y:y)
  discard blitSurface(source, clip, destination, addr(offset))

discard sdl.init(INIT_EVERYTHING)
var screen = setvideomode(800,600,16,SWSURFACE)
discard sdl_ttf.init()
font = openFont("OpenSans-Regular.ttf", 18)

proc clean_up*() =
  freeSurface(message)
  closeFont(font)
  sdl_ttf.quit()
  sdl.quit()

proc drawText*(text:string, x, y:int16) =
  message = renderUTF8_Blended( font, text, textColor)
  apply_surface(x, y, message, screen)

proc drawLink(link:Link, x, y:int16) =
  message = renderUTF8_Blended( font, link.text, linkColor)
  apply_surface(x, y, message, screen)

var images: seq[PSurface] = @[]

var n:int16 = 0

proc drawLines() =
  discard screen.fillrect(nil, 0xffffff)
  var i: int16
  var n: int16
  
  var w:cint = 0
  var h:cint = 0  
  for i in startLine..document.len-1:
    let line: Line = document[i]
    var x:int16 = 0
    for node in line:
      case node.kind
      of nkText:
        discard sizeUTF8(font, node.text, w, h)
        drawText(node.text, x, n*30)
        x += cast[int16](w)
      of nkLink:
        discard sizeUTF8(font, node.link.text, w, h)
        drawLink(node.link, x, n*30)
        x += cast[int16](w)
      else:
        var dummy = 0
    n += 1
  #n = 0
  #for img in images:
  #  apply_surface(0,n*20,img,screen)
  #  n += 1
 
  discard screen.flip()

proc drawImage*(fname) =
  images.add(img_Load(fname))

var runGame = true

proc loop() =
  var
    evt: TEvent
    host = ""

  while runGame:
    var found = pollEvent(addr evt)

    if found != 0:
      #echo "found evt"
      case evt.kind:
      of KEYDOWN:
        #echo "key"
        var keyEvt = evKeyboard(addr evt)
        if keyEvt.keysym.sym == K_ESCAPE:
          runGame = false
          break
        elif keyEvt.keysym.sym == K_DOWN:
          startLine += 1
          drawLines()
        elif keyEvt.keysym.sym == K_BACKSPACE:
          host = host.substr(0, host.len-2)
          #echo host
        elif keyEvt.keysym.sym == K_RETURN:
          loadChan.send(host)
          host = ""
          
        else:
          if host == "":
            startLine = 0
            document = @[]
          #echo keyEvt.keysym.sym
          var ch = chr(keyEvt.keysym.sym)
          host &= $(ch)
          echo host
      else:
        var dummy = true
        #echo "event"

    while chan.peek() > 0:
      var newLine = tryRecv(chan)
      #echo "next"
      if newLine.dataAvailable:
        document.add(newLine.msg)
        #echo "drawing"
        drawLines()
        #echo "back from draw"

  system.quit()

drawLines()
spawn loadPage("")
loop()

