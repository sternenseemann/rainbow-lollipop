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
            this.background_color = Clutter.Color.from_string(Config.c.colorscheme.empty_track);
            this.hbox.add(this.url_entry);
            this.hbox.add(this.enter_button);
            this.url_entry.expand=true;
            this.url_entry.activate.connect(do_activate);
            this.actor = new GtkClutter.Actor.with_contents(this.hbox);
            this.actor.height=26;
            this.actor.y = Config.c.track_height/2-this.actor.height/2;
            this.actor.add_constraint(
                new Clutter.BindConstraint(this, Clutter.BindCoordinate.WIDTH, 0)
            );
            this.add_constraint(
                new Clutter.BindConstraint(tl, Clutter.BindCoordinate.WIDTH, 0)
            );
            this.actor.transitions_completed.connect(do_transitions_completed);
            this.hbox.show_all();
            this.actor.visible = false;
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

        private void do_transitions_completed() {
            if (this.actor.opacity == 0x00) {
                this.actor.visible=false;
            }
        }

        protected override int calculate_height(){
            return Config.c.track_height;
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
}
