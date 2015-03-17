namespace RainbowLollipop {
    class SearchWidget : Clutter.Actor {
        private Gtk.Entry entry;
        private Gtk.Button next;
        private Gtk.Button prev;
        private Gtk.Button close;

        private GtkClutter.Actor a_entry;
        private GtkClutter.Actor a_next;
        private GtkClutter.Actor a_prev;
        private GtkClutter.Actor a_close; 
        
        private Clutter.BoxLayout line_box_layout;

        private WebKit.FindController find_controller;

        public SearchWidget(Clutter.Actor webactor, WebKit.FindController fc) {
            // Create all necessary widgets
            this.find_controller = fc;
            this.next = new Gtk.Button.from_icon_name("go-down", Gtk.IconSize.MENU);
            this.prev = new Gtk.Button.from_icon_name("go-up", Gtk.IconSize.MENU);
            this.close = new Gtk.Button.from_icon_name("window-close", Gtk.IconSize.MENU);
            this.entry = new Gtk.Entry();

            this.a_next = new GtkClutter.Actor.with_contents(this.next);
            this.a_prev = new GtkClutter.Actor.with_contents(this.prev);
            this.a_entry = new GtkClutter.Actor.with_contents(this.entry);
            this.a_close = new GtkClutter.Actor.with_contents(this.close);

            // Layout the widgets

            var np_box = new Clutter.Actor();
            np_box.width = 40;
            np_box.height = 70;
            var np_box_layout = new Clutter.BoxLayout();
            np_box_layout.orientation = Clutter.Orientation.VERTICAL;
            np_box.set_layout_manager(np_box_layout);
            this.line_box_layout = new Clutter.BoxLayout();
            this.line_box_layout.orientation = Clutter.Orientation.HORIZONTAL;
            this.set_layout_manager(this.line_box_layout);

            np_box.add_child(this.a_prev);
            np_box.add_child(this.a_next);
            this.add_child(np_box);
            this.add_child(this.a_entry);
            this.add_child(this.a_close);

            this.background_color = Clutter.Color.from_string(Config.c.colorscheme.empty_track);
            this.height = 100;
            this.add_constraint(
                new Clutter.BindConstraint(webactor, Clutter.BindCoordinate.WIDTH, 0)
            );
            this.add_constraint(
                new Clutter.AlignConstraint(webactor, Clutter.AlignAxis.Y_AXIS, 1.0f)
            );
            this.a_entry.add_constraint(
                new Clutter.BindConstraint(this, Clutter.BindCoordinate.WIDTH, -100.0f)
            );
            this.a_close.add_constraint(
                new Clutter.AlignConstraint(this, Clutter.AlignAxis.X_AXIS, 0.98f)
            );

            // Make the overlay slightly transparent

            this.opacity = 0xAA;
            this.visible = false;

            // Wire everything up to the webkit code
            
            this.find_controller.failed_to_find_text.connect(() => {
                this.next.sensitive = false;
                this.prev.sensitive = false;
            });
            this.find_controller.found_text.connect(() => {
                this.next.sensitive = true;
                this.prev.sensitive = true;
            });
            this.next.clicked.connect(() => {
                this.find_controller.search_next();
            });
            this.prev.clicked.connect(() => {
                this.find_controller.search_previous();
            });
            this.entry.changed.connect(() => {
                this.find_controller.search(this.entry.get_text(), 0, 1000);
            });
            this.close.clicked.connect(() => {
                this.visible = false;
                this.entry.set_text("");
                this.find_controller.search_finish();
                (this.find_controller.web_view as TrackWebView).stop_search();
            });
        }
    }
}
