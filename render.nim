import os, sdl, sdl_gfx, sdl_image, strutils, sdl_ttf

var message: PSurface
var event: TEvent
var font: PFont

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

proc drawLines*(lines) =
  discard screen.fillrect(nil, 0x000000)
  var i: int16
  i = 0
  for line in lines:
    drawText(line, 0, i*30)
    i += 1
  var n: int16
  n = 0
  for img in images:
    apply_surface(0,n*20,img,screen)
    n += 1
 
  discard screen.flip()

proc drawImage*(fname) =
  images.add(img_Load(fname))

