namespace alaia {
    class AuthenticationDialog : Clutter.Actor {
        private static const int FRAME_WIDTH = 300;
        private static const int FRAME_HEIGHT = 200;
        private static const int FRAME_PADDING = 20;
        private static const int BUTTON_WIDTH = 100;

        private WebKit.AuthenticationRequest request;

        private GtkClutter.Actor a_username_entry;
        private GtkClutter.Actor a_password_entry;
        private GtkClutter.Actor a_ok;
        private GtkClutter.Actor a_cancel;
        private Clutter.Actor frame;
        private Clutter.Text heading;

        private Gtk.Entry username_entry;
        private Gtk.Entry password_entry;
        private Gtk.Button ok;
        private Gtk.Button cancel;
    
        public AuthenticationDialog(Clutter.Actor stage, WebKit.AuthenticationRequest r) {
            this.request = r;
            this.background_color = Clutter.Color.from_string(Config.c.colorscheme.empty_track);
            this.add_constraint(
                new Clutter.BindConstraint(stage, Clutter.BindCoordinate.SIZE,0)
            );

            this.username_entry = new Gtk.Entry();
            this.password_entry = new Gtk.Entry();
            //TODO: Make stock-buttons
            this.ok = new Gtk.Button.from_icon_name("action-ok", Gtk.IconSize.MENU);
            this.cancel = new Gtk.Button.from_icon_name("action-cancel", Gtk.IconSize.MENU);
            this.ok.clicked.connect(this.do_ok);
            this.cancel.clicked.connect(this.do_cancel);

            this.frame = new Clutter.Actor();
            this.frame.background_color = Clutter.Color.from_string(Config.c.colorscheme.tracklist);
            this.frame.width  = AuthenticationDialog.FRAME_WIDTH;
            this.frame.height = AuthenticationDialog.FRAME_HEIGHT;
            this.frame.add_constraint(
                new Clutter.AlignConstraint(this, Clutter.AlignAxis.BOTH, 0.5f)
            );
            
            this.a_username_entry = new GtkClutter.Actor.with_contents(this.username_entry);
            this.a_username_entry.height = 26;
            this.a_username_entry.width = FRAME_WIDTH-2*FRAME_PADDING;
            this.a_username_entry.x = FRAME_PADDING;
            this.a_username_entry.y = 50;

            this.a_password_entry = new GtkClutter.Actor.with_contents(this.password_entry);
            this.a_password_entry.height = 26;
            this.a_password_entry.width = FRAME_WIDTH-2*FRAME_PADDING;
            this.a_password_entry.x = FRAME_PADDING;
            this.a_password_entry.y = 80;

            this.a_ok = new GtkClutter.Actor.with_contents(this.ok);
            this.a_ok.width = BUTTON_WIDTH;
            this.a_ok.height = 26;
            this.a_ok.x = FRAME_WIDTH-FRAME_PADDING-BUTTON_WIDTH;
            this.a_ok.y = 100;

            this.a_cancel = new GtkClutter.Actor.with_contents(this.cancel);
            this.a_cancel.width = BUTTON_WIDTH;
            this.a_cancel.height = 26;
            this.a_cancel.x = FRAME_WIDTH-2*FRAME_PADDING-2*BUTTON_WIDTH;
            this.a_ok.y = 100;

            this.frame.add_child(this.a_username_entry);
            this.frame.add_child(this.a_password_entry);
            this.frame.add_child(this.a_ok);
            this.frame.add_child(this.a_cancel);
        }

        public void do_ok(Gtk.Widget b) {
            var c = new WebKit.Credential(
                this.username_entry.get_text(),
                this.password_entry.get_text(),
                WebKit.CredentialPersistence.FOR_SESSION
            );
            this.request.authenticate(c);
            this.disappear();
            this.destroy();
        }

        public void do_cancel(Gtk.Widget b) {
            this.request.cancel();
            this.disappear();
            this.destroy();
        }

        public void emerge() {
        }

        public void disappear() {
        }
    }
}
