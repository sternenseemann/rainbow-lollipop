namespace alaia {
    class EmptyTrack : Track {
        private Gtk.Entry url_entry;
        private Gtk.Button enter_button;
        private Gtk.Grid hbox;
        private GtkClutter.Actor actor; 
        private TrackList tracklist;

        public EmptyTrack(TrackList tl) {
            base(tl);
            this.tracklist = tl;
            this.url_entry = new Gtk.Entry();
            this.enter_button = new Gtk.Button.with_label("Go");
            this.enter_button.clicked.connect(do_activate);
            this.hbox = new Gtk.Grid();
            this.hbox.add(this.url_entry);
            this.hbox.add(this.enter_button);
            this.url_entry.expand=true;
            this.url_entry.activate.connect(do_activate);
            this.url_entry.changed.connect(do_changed);
            this.actor = new GtkClutter.Actor.with_contents(this.hbox);
            this.actor.background_color = Clutter.Color.from_string(Config.c.colorscheme.empty_track);
            this.actor.height=26;
            this.actor.y = Config.c.track_height/2-this.actor.height/2;
            this.actor.x_expand=true;
            this.add_constraint(
                new Clutter.BindConstraint(tl, Clutter.BindCoordinate.WIDTH, 0)
            );
            this.actor.transitions_completed.connect(do_transitions_completed);
            this.hbox.show_all();
            this.actor.visible = false;
            var boxlayout = new Clutter.BoxLayout();
            boxlayout.orientation = Clutter.Orientation.VERTICAL;
            this.set_layout_manager(boxlayout);
            this.add_child(this.actor);
        }

        private string complete_url(string url) {
            if (!url.has_prefix("http://") && !url.has_prefix("https://")) {
                return "http://" + url;
            }
            return url; 
        }

        private void do_activate() {
            var url = this.complete_url(this.url_entry.get_text());
            this.tracklist.add_track_with_url(url);
            Application.S().hide_tracklist();
        }

        private void do_changed() {
            //Order new hints from hintproviders based on entry-text
            var new_hints = new Gee.ArrayList<AutoCompletionHint>();
            string fragment = this.url_entry.get_text();
            if (fragment.length > 0){
                new_hints.add_all(History.S().get_hints(fragment));
            }

            //Check which hints have to be dropped
            var to_delete = new Gee.ArrayList<AutoCompletionHint>();
            foreach (Clutter.Actor existing_hint in this.get_children()) {
                if (existing_hint != this.actor
                        && existing_hint is AutoCompletionHint
                        && !new_hints.contains((AutoCompletionHint)existing_hint)){
                    to_delete.add((AutoCompletionHint)existing_hint);
                }
            }

            // Add the new hints
            foreach (AutoCompletionHint new_hint in new_hints) {
                if (!this.contains(new_hint))
                    this.add_child(new_hint);
            }

            //Drop unnecessary hints
            foreach (AutoCompletionHint del_hint in to_delete) {
                this.remove_child(del_hint);
            }
        }

        public void clear_urlbar(){
            this.url_entry.set_text("");
        }

        private void do_transitions_completed() {
            if (this.actor.opacity == 0x00) {
                this.actor.visible=false;
            }
        }

        protected override int calculate_height(){
            return 26;
        }

        public new void emerge() {
            base.emerge();
            this.actor.visible = true;
            this.actor.save_easing_state();
            this.actor.opacity = 0xE0;
            this.actor.restore_easing_state();
            this.url_entry.grab_focus();
        }

        public new void disappear() {
            base.disappear();
            this.actor.save_easing_state();
            this.actor.opacity = 0x00;
            this.actor.restore_easing_state();
        }
    }

    interface IHintProvider {
        public abstract Gee.ArrayList<AutoCompletionHint> get_hints(string url);
    }

    class AutoCompletionHint : Clutter.Actor {
        protected string heading = "";
        protected string text = "";
        protected Cairo.Surface icon = null;

        private Clutter.Text a_heading;
        private Clutter.Text a_text;
        private Clutter.Canvas a_icon;

        public signal void execute(TrackList tl);

        public AutoCompletionHint(string heading, string text) {
            this.heading = heading;
            this.text = text;

            this.background_color = Clutter.Color.from_string(Config.c.colorscheme.tracklist);
            this.height = 100;
            this.x_expand = true;

            this.a_heading = new Clutter.Text.with_text("Sans 12", this.heading);
            this.a_heading.color=  Clutter.Color.from_string("#eeeeee");
            this.a_heading.x = 120;
            this.a_heading.y = 10;
            this.a_heading.height = 30;
            this.a_heading.x_expand = true;
            this.add_child(this.a_heading);

            this.a_text = new Clutter.Text.with_text("Sans 10", this.text);
            this.a_text.color=  Clutter.Color.from_string("#eeeeee");
            this.a_text.x = 120;
            this.a_text.y = 30;
            this.a_text.height = 30;
            this.a_text.x_expand = true;
            this.add_child(this.a_text);

            this.reactive = true;
            var clickaction = new Clutter.ClickAction();
            clickaction.clicked.connect(this.trigger_execute);
            this.add_action(clickaction);
        }

        public void trigger_execute(Clutter.Actor a){
            var tracklist = Application.S().tracklist;
            Application.S().hide_tracklist();
            (this.get_parent() as EmptyTrack).clear_urlbar();
            this.execute(tracklist);
        }
    }
}
