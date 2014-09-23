from gi.repository import GtkClutter, Clutter, Gtk

import sys
import time

Clutter.init([])

class TrackColorSupply(object):
    C = 0
    A = 50
    COLORS = [
        Clutter.Color.new(255,0,0,A),
        Clutter.Color.new(255,255,0,A),
        Clutter.Color.new(0,255,0,A),
        Clutter.Color.new(0,255,255,A),
        Clutter.Color.new(0,0,255,A),
        Clutter.Color.new(255,0,255,A), 
    ]
    @classmethod
    def get_color(cls):
        c = cls.COLORS[cls.C%len(cls.COLORS)]
        cls.C+=1
        return c
        
class Track(object):
    def __init__(self,parent):
        self.tracklist = parent
        self.nodes = []
        self.a = Clutter.Rectangle.new()
        self.a.set_size(0,150)
        self.a.set_position(0,150*self.get_parent().count_tracks())
        const = Clutter.BindConstraint.new(self.get_parent().a, Clutter.BindCoordinate.WIDTH, 0)
        self.a.add_constraint(const)
        self.a.set_color(TrackColorSupply.get_color())
        self.a.set_reactive(True)
        self.a.connect("enter-event", self.do_enter_event)
        self.a.connect("leave-event", self.do_leave_event)
        self.get_stage().add_actor(self.a)
        self.a.animatev(Clutter.AnimationMode.EASE_OUT_CUBIC, 500,
                        ["y"],[self.a.get_position()[1]+150])

    def do_enter_event(self, event=None, data=None):
        print("event")
        nc = self.a.get_color()
        nc.alpha+=70
        self.a.set_color(nc)
    def do_leave_event(self, event=None, data=None):
        print("event")
        nc = self.a.get_color()
        nc.alpha-=70
        self.a.set_color(nc)

    def get_parent(self):
        return self.tracklist
    def get_stage(self):
        return self.get_parent().get_stage()

class TrackList(object):
    def __init__(self, stage):
        self.stage = stage
        self.tracks = []
        const = Clutter.BindConstraint.new(self.stage, Clutter.BindCoordinate.SIZE,0)
        self.a = Clutter.Rectangle.new()
        c = Clutter.Color.new(32,32,32,255)
        self.a.set_color(c)
        self.a.add_constraint(const)
        self.stage.add_actor(self.a)

    def count_tracks(self):
        return len(self.tracks)

    def createTrack(self):
        t = Track(self)
        self.tracks.append(t)

    def get_stage(self):
        return self.stage        

class Alaia(object):
    @staticmethod
    def run():
        a = Alaia()
        a.run()
    def printsize(self,widget=None, data=None):
        print(self.stage.get_size())
    def foo(self, widget=None, data=None):
        print("fofo")
    def __init__(self):
        print("foo")
        c = Clutter.Color.new(255,255,255,255)
        self.stage = Clutter.Stage()
        self.stage.set_size(800,400)
        self.stage.set_title("foobar")
        self.stage.set_color(c)
        self.stage.connect("destroy", lambda x : GtkClutter.main_quit())
        self.stage.connect("button-press-event", self.foo)
        self.stage.show_all()

        #webview = GtkClutter.Actor.new()
        #webview.contents = Gtk.Label("asdf")
        #webviewc = Clutter.BindConstraint.new(self.stage, Clutter.BindCoordinate.SIZE,0)
        #webview.add_constraint(webviewc)
        #self.stage.add_actor(webview)
    
        self.tl = TrackList(self.stage)
        self.tl.createTrack()
        self.tl.createTrack()
        self.tl.createTrack()
        Gtk.main()
