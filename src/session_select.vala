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
     * Implements a dialog that let's the user choose whether he wants
     * to restore the saved browsing session or rather start a new one
     */
    class RestoreSessionDialog : Clutter.Actor {
        private const int BOX_SIZE = 200;
        private const int BOX_DISTANCE = 70;
        private const int RESTORE = 1;
        private const int NEWSESSION = 2;

        private int selected = 1;
        private Clutter.Actor layout_box;
        private Clutter.Actor restore_box;
        private Cairo.ImageSurface restore_icon;
        private Clutter.Actor restore_iconactor;
        private Clutter.Canvas restore_canvas;
        private Clutter.Text restore_text;
        private Clutter.Actor newsession_box;
        private Cairo.ImageSurface newsession_icon;
        private Clutter.Actor newsession_iconactor;
        private Clutter.Canvas newsession_canvas;
        private Clutter.Text newsession_text;

        /**
         * Creates a new RestorSessionDialog
         */
        public RestoreSessionDialog (Clutter.Actor stage) {
            this.visible = true;
            this.background_color = Clutter.Color.from_string(Config.c.colorscheme.tracklist);
            this.transitions_completed.connect(do_transitions_completed);

            this.add_constraint(
                new Clutter.BindConstraint(stage, Clutter.BindCoordinate.SIZE, 0)
            );

   
            this.restore_box = new Clutter.Actor();
            this.restore_box.background_color = Clutter.Color.from_string(Config.c.colorscheme.empty_track);
            this.restore_box.width = this.restore_box.height = BOX_SIZE;

            this.restore_text = new Clutter.Text.with_text("Sans Bold 16", _("restore\nsession"));
            this.restore_text.color = Clutter.Color.from_string("#eeeeee");
            this.restore_text.width = BOX_SIZE;
            this.restore_text.height = 65;
            this.restore_text.x = 56;
            this.restore_text.y = 145;
            this.restore_box.add_child(restore_text);

            var restore_iconpath = Application.get_data_filename("restore_session.png");
            stdout.printf(restore_iconpath+"\n");
            this.restore_icon = new Cairo.ImageSurface.from_png(restore_iconpath);
            this.restore_iconactor = new Clutter.Actor();
            this.restore_iconactor.x = (BOX_SIZE-128)/2;
            this.restore_iconactor.y = 20;
            this.restore_iconactor.height = this.restore_iconactor.width = 128;
            this.restore_canvas = new Clutter.Canvas();
            this.restore_canvas.set_size(128,128);
            this.restore_canvas.draw.connect((cr, w, h) => {
                cr.set_source_rgba(0,0,0,0);
                cr.set_operator(Cairo.Operator.SOURCE);
                cr.paint();
                cr.set_source_surface(this.restore_icon ,0, 0);
                cr.set_operator(Cairo.Operator.SOURCE);
                cr.paint();
                return true;
            });
            this.restore_iconactor.content = this.restore_canvas;
            this.restore_iconactor.content.invalidate(); 
            this.restore_box.add_child(this.restore_iconactor);
            this.restore_box.reactive=true;
            this.restore_box.enter_event.connect(()=>{this.select_restore(); return true;});
            var rca = new Clutter.ClickAction();
            rca.clicked.connect(()=>{this.selected = RESTORE; this.execute_selected(); });
            this.restore_box.add_action(rca);

            this.newsession_box = new Clutter.Actor(); 
            this.newsession_box.background_color = Clutter.Color.from_string(Config.c.colorscheme.empty_track); 
            this.newsession_box.width = this.newsession_box.height = BOX_SIZE; 

            this.newsession_text = new Clutter.Text.with_text("Sans Bold 16", _("new session"));
            this.newsession_text.color = Clutter.Color.from_string("#eeeeee");
            this.newsession_text.width = BOX_SIZE;
            this.newsession_text.height = 30;
            this.newsession_text.x = 30;
            this.newsession_text.y = 160;
            this.newsession_box.add_child(newsession_text);

            var newsession_iconpath = Application.get_data_filename("new_session.png"); 
            this.newsession_icon = new Cairo.ImageSurface.from_png(newsession_iconpath); 
            this.newsession_iconactor = new Clutter.Actor();
            this.newsession_iconactor.x = (BOX_SIZE-128)/2;
            this.newsession_iconactor.y = 20;
            this.newsession_iconactor.height = this.newsession_iconactor.width = 128;
            this.newsession_canvas = new Clutter.Canvas();
            this.newsession_canvas.set_size(128,128);
            this.newsession_canvas.draw.connect((cr, w, h) => {
                cr.set_source_rgba(0,0,0,0);
                cr.set_operator(Cairo.Operator.SOURCE);
                cr.paint();
                cr.set_source_surface(this.newsession_icon ,0, 0);
                cr.set_operator(Cairo.Operator.SOURCE);
                cr.paint();
                return true;
            });
            this.newsession_iconactor.content = this.newsession_canvas;
            this.newsession_iconactor.content.invalidate(); 
            this.newsession_box.add_child(this.newsession_iconactor);
            this.newsession_box.reactive = true;
            this.newsession_box.enter_event.connect(()=>{this.select_newsession(); return true;});
            var nca = new Clutter.ClickAction();
            nca.clicked.connect(()=>{this.selected = NEWSESSION; this.execute_selected(); });
            this.newsession_box.add_action(nca);

            this.layout_box = new Clutter.Actor();
            this.layout_box.width = 2*BOX_SIZE+BOX_DISTANCE;
            this.layout_box.height = BOX_SIZE;
            this.layout_box.add_constraint(
                new Clutter.AlignConstraint(this, Clutter.AlignAxis.BOTH, 0.5f)
            );

            this.layout_box.add_child(this.restore_box);
            this.layout_box.add_child(this.newsession_box);

            this.restore_box.x = 0;
            this.newsession_box.x = BOX_SIZE+BOX_DISTANCE;
            
            this.add_child(layout_box);
            this.select_restore();
        }

        /**
         * Focus the restore button and optically emphasize it
         */
        public void select_restore() {
            this.newsession_iconactor.save_easing_state();
            this.newsession_text.save_easing_state();
            this.restore_iconactor.save_easing_state();
            this.restore_text.save_easing_state();
            this.newsession_iconactor.opacity = 0x7f;
            this.newsession_text.opacity = 0x7f;
            this.restore_iconactor.opacity= 0xff;
            this.restore_text.opacity = 0xff;
            this.newsession_iconactor.restore_easing_state();
            this.newsession_text.restore_easing_state();
            this.restore_iconactor.restore_easing_state();
            this.restore_text.restore_easing_state();
            this.selected = RESTORE;
        }

        /**
         * Focus the new session button and optically emphasize it
         */
        public void select_newsession() {
            this.newsession_iconactor.save_easing_state();
            this.newsession_text.save_easing_state();
            this.restore_iconactor.save_easing_state();
            this.restore_text.save_easing_state();
            this.newsession_iconactor.opacity = 0xff;
            this.newsession_text.opacity = 0xff;
            this.restore_iconactor.opacity= 0x7f;
            this.restore_text.opacity = 0x7f;
            this.newsession_iconactor.restore_easing_state();
            this.newsession_text.restore_easing_state();
            this.restore_iconactor.restore_easing_state();
            this.restore_text.restore_easing_state();
            this.selected = NEWSESSION;
        }

        /**
         * Execute an action according to which button is selected
         */
        public void execute_selected() {
            if (this.selected == RESTORE)
                Application.S().restore_session();
            else
                Application.S().state = TracklistState.S();
        }

        /**
         * Fade in
         */
        public void emerge() {
            this.visible = true;
            this.save_easing_state();
            this.opacity = 0xE0;
            this.restore_easing_state();
        }

        /**
         * Fade out
         */
        public void disappear() {
            this.save_easing_state();
            this.opacity = 0x00;
            this.restore_easing_state();
        }

        private void do_transitions_completed() {
            if (this.opacity == 0x00) {
                this.visible = false;
            }
        }
    }
}
