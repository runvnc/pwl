type
  Node* = ref NodeObj

  Link* = tuple
    href: string
    subs: ref Node

  NodeKind* = enum
    nkText,
    nkLink,
    nkImg

  NodeObj* = object
    case kind*: NodeKind
    of nkText: text*: string
    of nkLink: link*: Link
    of nkImg: src*: string

  NodeSeq = seq[Node]
 
  Line* = NodeSeq

  Doc* = seq[Line]

var n = Node(kind: nkText, text: "Hello")

type LineChannel = TChannel[Line]
var chan*: LineChannel

var loadChan*: TChannel[string]

loadChan.open()
chan.open()

