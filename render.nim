import os, threadpool, sdl, sdl_gfx, sdl_image, strutils, sdl_ttf, doc, it

var message: PSurface
var event: TEvent
var font: PFont
var startLine = 0
var document: Doc = @[]

var textColor = TColor(r: 255, g:255, b:255)

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
  message = renderText_Solid( font, text, textColor)
  apply_surface(x, y, message, screen)

var images: seq[PSurface] = @[]

proc drawLines() =
  discard screen.fillrect(nil, 0x000000)
  var i: int16
  var n: int16
  n = 0
  
  for i in startLine..document.len-1:
    let line: Line = document[i]
    let node = line[0]
    drawText(node.text, 0, n*30)
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
      echo "found evt"
      case evt.kind:
      of KEYDOWN:
        echo "key"
        var keyEvt = evKeyboard(addr evt)
        if keyEvt.keysym.sym == K_ESCAPE:
          runGame = false
          break
        elif keyEvt.keysym.sym == K_DOWN:
          startLine += 1
          drawLines()
        elif keyEvt.keysym.sym == K_RETURN:
          spawn loadPage(host)
          host = ""
        else:
          host &= $(cast[char](keyEvt.which))
      else:
        echo "event"

      var newLine = tryRecv(chan)
      if newLine.dataAvailable:
        document.add(newLine.msg)
        drawLines()

  system.quit()

loop()

