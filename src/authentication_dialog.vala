/********************************************************************
# Copyright 2014 Daniel 'grindhold' Brendle
#
# This file is part of Rainbow Lollipop.
#
# Rainbow Lollipop is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later
# version.
#
# Rainbow Lollipop is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public
# License along with Rainbow Lollipop.
# If not, see http://www.gnu.org/licenses/.
*********************************************************************/

namespace RainbowLollipop {
    /**
     * Represents an Authentication Dialog that lets the user
     * enter credentials to log into e.g. an HTTP Basic Auth protected server
     * TODO: This is NONTESTED code and should be considered completely unfunctional
     *       Change this fact.
     * TODO: Create a heading that tells the user what just happens
     */
    class AuthenticationDialog : Clutter.Actor {
        private static const int FRAME_WIDTH = 300;
        private static const int FRAME_HEIGHT = 200;
        private static const int FRAME_PADDING = 20;
        private static const int BUTTON_WIDTH = 100;

        private WebKit.AuthenticationRequest request;

        private GtkClutter.Actor a_vbox;
        private GtkClutter.Actor a_ok;
        private GtkClutter.Actor a_cancel;
        private Clutter.Actor frame;

        private Gtk.Box vbox;
        private Gtk.Entry username_entry;
        private Gtk.Entry password_entry;
        private Gtk.Button ok;
        private Gtk.Button cancel;
    
        /**
         * Construct a new AuthenticationDialog
         * TODO: Make stock-buttons
         */
        public AuthenticationDialog(Clutter.Actor stage) {
            this.background_color = Clutter.Color.from_string(Config.c.colorscheme.empty_track);
            this.add_constraint(
                new Clutter.BindConstraint(stage, Clutter.BindCoordinate.SIZE,0)
            );

            this.vbox = new Gtk.Box(Gtk.Orientation.VERTICAL,0);
            this.username_entry = new Gtk.Entry();
            this.username_entry.placeholder_text = _("Username");
            this.password_entry = new Gtk.Entry();
            this.password_entry.placeholder_text = _("Password");
            this.ok = new Gtk.Button.with_label(_("OK"));
            this.cancel = new Gtk.Button.with_label(_("Cancel"));
            this.ok.clicked.connect(this.do_ok);
            this.cancel.clicked.connect(this.do_cancel);

            this.frame = new Clutter.Actor();
            this.frame.background_color = Clutter.Color.from_string(Config.c.colorscheme.tracklist);
            this.frame.width  = AuthenticationDialog.FRAME_WIDTH;
            this.frame.height = AuthenticationDialog.FRAME_HEIGHT;
            this.frame.add_constraint(
                new Clutter.AlignConstraint(this, Clutter.AlignAxis.BOTH, 0.5f)
            );

            this.vbox.add(this.username_entry);
            this.vbox.add(this.password_entry);
            this.a_vbox = new GtkClutter.Actor.with_contents(this.vbox);
            this.a_vbox.height = 26*2;
            this.a_vbox.width = FRAME_WIDTH-2*FRAME_PADDING;
            this.a_vbox.x = FRAME_PADDING;
            this.a_vbox.y = 50;

            this.a_ok = new GtkClutter.Actor.with_contents(this.ok);
            this.a_ok.width = BUTTON_WIDTH;
            this.a_ok.height = 26;
            this.a_ok.x = FRAME_WIDTH-FRAME_PADDING-BUTTON_WIDTH;
            this.a_ok.y = 120;

            this.a_cancel = new GtkClutter.Actor.with_contents(this.cancel);
            this.a_cancel.width = BUTTON_WIDTH;
            this.a_cancel.height = 26;
            this.a_cancel.x = FRAME_WIDTH-2*FRAME_PADDING-2*BUTTON_WIDTH;
            this.a_cancel.y = 120;

            this.frame.add_child(this.a_vbox);
            this.frame.add_child(this.a_ok);
            this.frame.add_child(this.a_cancel);

            this.username_entry.realize.connect(()=> {
                this.username_entry.grab_focus();
            });
            this.username_entry.show();
            this.password_entry.show();
            this.ok.show();
            this.cancel.show();
            this.add_child(this.frame);
            this.visible=false;
            stage.add_child(this);
        }

        /**
         * Sets the request the dialog should handle
         */
        public void set_request(WebKit.AuthenticationRequest r) {
            this.request = r;
            this.username_entry.text = "";
            this.password_entry.text = "";
        }

        /**
         * Execute OK on the AuthenticatonRequest callback
         * and pass the entered credentials to it.
         */
        public void do_ok(Gtk.Widget b) {
            var c = new WebKit.Credential(
                this.username_entry.get_text(),
                this.password_entry.get_text(),
                WebKit.CredentialPersistence.FOR_SESSION
            );
            this.request.authenticate(c);
            this.disappear();
            Application.S().state = NormalState.S();
        }

        /**
         * Execute Cancel on the AuthenticationRequest callback
         */
        public void do_cancel(Gtk.Widget b) {
            this.request.cancel();
            this.disappear();
            Application.S().state = NormalState.S();
        }

        /**
         * Fade in
         */
        public void emerge() {
            this.visible = true;
        }

        /**
         * Fade out
         */
        public void disappear() {
            this.visible = false;
        }
    }
}
