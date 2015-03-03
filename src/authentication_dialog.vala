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

        private GtkClutter.Actor a_username_entry;
        private GtkClutter.Actor a_password_entry;
        private GtkClutter.Actor a_ok;
        private GtkClutter.Actor a_cancel;
        private Clutter.Actor frame;

        private Gtk.Entry username_entry;
        private Gtk.Entry password_entry;
        private Gtk.Button ok;
        private Gtk.Button cancel;
    
        /**
         * Construct a new AuthenticationDialog
         * TODO: Make stock-buttons
         */
        public AuthenticationDialog(Clutter.Actor stage, WebKit.AuthenticationRequest r) {
            this.request = r;
            this.background_color = Clutter.Color.from_string(Config.c.colorscheme.empty_track);
            this.add_constraint(
                new Clutter.BindConstraint(stage, Clutter.BindCoordinate.SIZE,0)
            );

            this.username_entry = new Gtk.Entry();
            this.password_entry = new Gtk.Entry();
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
            this.destroy();
        }

        /**
         * Execute Cancel on the AuthenticationRequest callback
         */
        public void do_cancel(Gtk.Widget b) {
            this.request.cancel();
            this.disappear();
            this.destroy();
        }

        /**
         * Fade in
         * TODO: implement if needed or remove this todo
         */
        public void emerge() {
        }

        /**
         * Fade out
         * TODO: implement if needed or remove this todo
         */
        public void disappear() {
        }
    }
}
