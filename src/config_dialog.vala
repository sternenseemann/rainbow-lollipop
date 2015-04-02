/*******************************************************************
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
     * This class is a clutter actor that wraps a Gtk dialog that
     * enables the user to manipulate the values in the config.
     * The several options are categorized and available through a
     * gtk notebook which has those categories as tabs.
     * TODO: implement saving of the config to disk
     * TODO: prettify ui: center the options or make them use the full width
     */
    class ConfigDialog : Clutter.Actor {
        private GtkClutter.Actor dialog_container;

        private Gtk.Notebook notebook;

        private Gtk.Grid ui_box;

        private Gtk.Label track_height_label;
        private Gtk.Scale track_height_scale;

        private Gtk.Label track_spacing_label;
        private Gtk.Scale track_spacing_scale;

        private Gtk.Label track_opacity_label;
        private Gtk.Scale track_opacity_scale;

        private Gtk.Label node_height_label;
        private Gtk.Scale node_height_scale;

        private Gtk.Label node_spacing_label;
        private Gtk.Scale node_spacing_scale;

        private Gtk.Label favicon_size_label;
        private Gtk.Scale favicon_size_scale;

        private Gtk.Label connector_stroke_label;
        private Gtk.SpinButton connector_stroke_spinbutton;

        private Gtk.Label bullet_stroke_label;
        private Gtk.SpinButton bullet_stroke_spinbutton;

        private enum ConfigOption {
            TRACK_HEIGHT,
            TRACK_SPACING,
            TRACK_OPACITY,
            NODE_HEIGHT,
            NODE_SPACING,
            FAVICON_SIZE,
            CONNECTOR_STROKE,
            BULLET_STROKE
        }

        public ConfigDialog (Clutter.Actor stage) {
            this.background_color = Clutter.Color.from_string(Config.c.colorscheme.tracklist);
            this.add_constraint(
                new Clutter.BindConstraint(stage, Clutter.BindCoordinate.SIZE, 0)
            );
            this.transitions_completed.connect(do_transitions_completed);

            this.notebook = new Gtk.Notebook();

            this.ui_box = new Gtk.Grid();
            this.ui_box.expand = true;
            this.ui_box.column_spacing = this.ui_box.row_spacing = 10;
            this.ui_box.border_width = 20;

            this.track_height_label = new Gtk.Label(_("Track height"));
            this.track_height_scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL,0.0,127.0,1.0);
            this.track_height_scale.set_value(Config.c.track_height);
            this.track_height_scale.value_changed.connect(()=>{
                this.update_value(ConfigOption.TRACK_HEIGHT);
            });
            this.ui_box.attach(this.track_height_label,0,0,1,1);
            this.ui_box.attach(this.track_height_scale,1,0,1,1);
            
            this.track_spacing_label = new Gtk.Label(_("Track spacing"));
            this.track_spacing_scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL,0.0,127.0,1.0);
            this.track_spacing_scale.set_value(Config.c.track_spacing);
            this.track_spacing_scale.value_changed.connect(()=>{
                this.update_value(ConfigOption.TRACK_SPACING);
            });
            this.ui_box.attach(this.track_spacing_label,0,1,1,1);
            this.ui_box.attach(this.track_spacing_scale,1,1,1,1);

            this.track_opacity_label = new Gtk.Label(_("Track opacity"));
            this.track_opacity_scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL,0.0,127.0,1.0);
            this.track_opacity_scale.set_value(Config.c.track_opacity);
            this.track_opacity_scale.value_changed.connect(()=>{
                this.update_value(ConfigOption.TRACK_OPACITY);
            });
            this.ui_box.attach(this.track_opacity_label,0,2,1,1);
            this.ui_box.attach(this.track_opacity_scale,1,2,1,1);

            this.node_height_label = new Gtk.Label(_("Node height"));
            this.node_height_scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL,0.0,127.0,1.0);
            this.node_height_scale.set_value(Config.c.node_height);
            this.node_height_scale.value_changed.connect(()=>{
                this.update_value(ConfigOption.NODE_HEIGHT);
            });
            this.ui_box.attach(this.node_height_label,0,3,1,1);
            this.ui_box.attach(this.node_height_scale,1,3,1,1);

            this.node_spacing_label = new Gtk.Label(_("Node spacing"));
            this.node_spacing_scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL,0.0,127.0,1.0);
            this.node_spacing_scale.set_value(Config.c.node_spacing);
            this.node_spacing_scale.value_changed.connect(()=>{
                this.update_value(ConfigOption.NODE_SPACING);
            });
            this.ui_box.attach(this.node_spacing_label,0,4,1,1);
            this.ui_box.attach(this.node_spacing_scale,1,4,1,1);

            this.favicon_size_label = new Gtk.Label(_("Favicon size"));
            this.favicon_size_scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL,0.0,127.0,1.0);
            this.favicon_size_scale.set_value(Config.c.favicon_size);
            this.favicon_size_scale.value_changed.connect(()=>{
                this.update_value(ConfigOption.FAVICON_SIZE);
            });
            this.ui_box.attach(this.favicon_size_label,0,5,1,1);
            this.ui_box.attach(this.favicon_size_scale,1,5,1,1);

            this.connector_stroke_label = new Gtk.Label(_("Connector stroke width"));
            this.connector_stroke_spinbutton = new Gtk.SpinButton.with_range(1,10,0.1);
            this.connector_stroke_spinbutton.set_value(Config.c.connector_stroke);
            this.connector_stroke_spinbutton.value_changed.connect(()=>{
                this.update_value(ConfigOption.CONNECTOR_STROKE);
            });
            this.ui_box.attach(this.connector_stroke_label,0,6,1,1);
            this.ui_box.attach(this.connector_stroke_spinbutton,1,6,1,1);

            this.bullet_stroke_label = new Gtk.Label(_("Connector stroke width"));
            this.bullet_stroke_spinbutton = new Gtk.SpinButton.with_range(1,10,0.1);
            this.bullet_stroke_spinbutton.set_value(Config.c.bullet_stroke);
            this.bullet_stroke_spinbutton.value_changed.connect(()=>{
                this.update_value(ConfigOption.BULLET_STROKE);
            });
            this.ui_box.attach(this.bullet_stroke_label,0,7,1,1);
            this.ui_box.attach(this.bullet_stroke_spinbutton,1,7,1,1);

            this.notebook.append_page(this.ui_box, new Gtk.Label(_("UI")));

            this.dialog_container = new GtkClutter.Actor.with_contents(this.notebook);
            this.dialog_container.add_constraint(
                new Clutter.BindConstraint(this, Clutter.BindCoordinate.SIZE, -100)
            );
            this.dialog_container.x = this.dialog_container.y = 50;
            this.add_child(this.dialog_container);
            this.notebook.show_all();
            this.visible = false;
        }

        private void update_value(ConfigOption o) {
            switch (o) {
                case ConfigOption.TRACK_HEIGHT:
                    Config.c.track_height = (uint8)this.track_height_scale.get_value();
                    break;
                case ConfigOption.TRACK_SPACING:
                    Config.c.track_spacing = (uint8)this.track_spacing_scale.get_value();
                    break;
                case ConfigOption.TRACK_OPACITY:
                    Config.c.track_opacity = (uint8)this.track_opacity_scale.get_value();
                    break;
                case ConfigOption.NODE_HEIGHT:
                    Config.c.node_height = (uint8)this.node_height_scale.get_value();
                    break;
                case ConfigOption.NODE_SPACING:
                    Config.c.node_spacing = (uint8)this.node_spacing_scale.get_value();
                    break;
                case ConfigOption.FAVICON_SIZE:
                    Config.c.favicon_size = (uint8)this.favicon_size_scale.get_value();
                    break;
                case ConfigOption.CONNECTOR_STROKE:
                    Config.c.connector_stroke = this.connector_stroke_spinbutton.get_value();
                    break;
                case ConfigOption.BULLET_STROKE:
                    Config.c.bullet_stroke = this.bullet_stroke_spinbutton.get_value();
                    break;
                
            }
            this.get_stage().queue_redraw();
            //TODO: find out why the redraw call does not reach the nodes
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
