using Gtk;
using GtkClutter;
using Clutter;
using WebKit;

namespace alaia {
    class TrackList : Clutter.Actor {
        public TrackList(Clutter.Actor stage) {
  //          super();
            this.add_constraint(
                new Clutter.BindConstraint(stage, Clutter.BindCoordinate.SIZE,0)
            );
//           this.set_color(Clutter.Color.from_string("#3338"));
            stage.add_child(this);
        }
    }

    class Application : Gtk.Application {
        private GtkClutter.Window win;
        private WebKit.WebView web;
        private GtkClutter.Actor webact;

        private TrackList tracklist;

        public Application()  {
            GLib.Object(
                application_id : "de.grindhold.alaia",
                flags: ApplicationFlags.HANDLES_COMMAND_LINE,
                register_session : true
            );
            
            this.web = new WebKit.WebView(); 
            this.webact = new GtkClutter.Actor.with_contents(this.web);

            this.win = new GtkClutter.Window();
            this.win.set_title("alaia");
            this.win.destroy.connect(this.do_delete);

            var stage = this.win.get_stage();
            this.webact.add_constraint(new Clutter.BindConstraint(
                stage, Clutter.BindCoordinate.SIZE, 0)
            );
            stage.add_child(this.webact);

            this.tracklist = new TrackList(stage);

            this.win.show_all();
            this.web.open("http://skarphed.org");
            Gtk.main();
        }
        
        public void do_delete() {
            Gtk.main_quit();
        }
        
        public static int main(string[] args) {
            if (GtkClutter.init(ref args) != Clutter.InitError.SUCCESS){
                stdout.printf("Could not initialize GtkClutter");
            }
            if (Clutter.init(ref args) != Clutter.InitError.SUCCESS){
                stdout.printf("Could not initialize Clutter");
            }
            Gtk.init(ref args);
            new Application();
            return 0;
        }
        
    }
}
