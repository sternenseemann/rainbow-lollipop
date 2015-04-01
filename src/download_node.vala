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
using Math;

namespace RainbowLollipop {
    /**
     * A form of Progress-Meter
     * Used by DownloadNodes to display the current progress of a download.
     */
    class ProgressBullet : Clutter.Actor {
        private Clutter.Canvas c;
        private DownloadNode parent;
        private double fraction = 50.0;

        /**
         * Returns a new ProgressBullet
         */
        public ProgressBullet(DownloadNode parent) {
            this.parent = parent;
            this.c = new Clutter.Canvas();
            this.x = 0;
            this.y = 0;
            this.content = c;
            this.set_size((int)roundf(parent.width), (int)roundf(parent.height));
            this.c.set_size((int)roundf(parent.width), (int)roundf(parent.height));
            this.c.draw.connect(do_draw);
            this.c.invalidate();
        }

        /**
         * Draws the bar
         */
        public bool do_draw(Cairo.Context cr, int w, int h) {
            cr.set_source_rgba(0,0,0,0);
            cr.set_operator(Cairo.Operator.SOURCE);
            cr.paint();
            cr.set_source_rgba(col_h2f(this.parent.color.red)*2,
                              col_h2f(this.parent.color.green)*2,
                              col_h2f(this.parent.color.blue)*2,
                              1);
            cr.set_operator(Cairo.Operator.OVER);
            cr.set_line_width(Config.c.bullet_stroke);
            cr.rectangle(Config.c.bullet_stroke,
                         Config.c.bullet_stroke,
                         Config.c.node_height-2*Config.c.bullet_stroke,
                         Config.c.node_height-2*Config.c.bullet_stroke);
            cr.stroke();
            cr.set_source_rgba(col_h2f(this.parent.color.red),
                              col_h2f(this.parent.color.green),
                              col_h2f(this.parent.color.blue),
                              1.0);
            cr.rectangle(5,5,this.fraction*(Config.c.node_height-10),Config.c.node_height-10);
            cr.fill();
            return true;
        }

        /**
         * Set the fraction to be displayed
         */
        public void set_fraction(double fraction) {
            this.fraction = fraction;
            this.c.invalidate();
        }
    }

    /**
     * A special kind of Node which represents a download and shows its progress
     */
    class DownloadNode : Node {
        private WebKit.Download dl;
        private bool finished=false;
        private ProgressBullet progress;
        private Clutter.Text text;

        /**
         * Returns a new Download node
         */
        public DownloadNode(HistoryTrack track, WebKit.Download download, Node? par) {
            base(track,par);
            this.dl = download;
            this.progress = new ProgressBullet(this);
            this.add_child(this.progress);
            this.text = new Clutter.Text.with_text("Monospace Bold 9", "0 %%");
            this.text.color = this.color.darken().darken().darken();
            this.text.x = Config.c.node_height/2-this.text.width/2;
            this.text.y = Config.c.node_height/2-this.text.height/2;
            this.add_child(this.text);
            
            this.opacity = 0x7F;
            this.background_color = this.color;
            this.dl.finished.connect(()=>{this.finished=true;});
            this.dl.failed.connect(()=>{this.finished=true;});
            this.clickaction.clicked.connect(do_clicked);
            GLib.Idle.add(this.update);
        }

        /**
         * Updates the state of the ProgressNode of this DownloadNode as long
         * as the download has not finished. Updating happens asynchronously
         * over the Gtk mainloop.
         */
        public bool update() {
            this.progress.set_fraction(this.dl.get_estimated_progress());
            double percent = this.dl.get_estimated_progress()*100;
            this.text.set_text("%d %%".printf((int)percent));
            this.text.x = Config.c.node_height/2-this.text.width/2;
            this.text.y = Config.c.node_height/2-this.text.height/2;
            if (!this.finished) {
                GLib.Idle.add(this.update);
            }
            return false;
        }

        /**
         * Returns true if the Node is marked as finished
         */
        public bool is_finished() {
            return this.finished;
        }

        /**
         * Determines which application should be used best to display the file
         * passed in, and launches it. Prints a warning if there is no success
         */
        private void open_path(File f) {
            try {
                var handler = f.query_default_handler(null);
                var arglist = new List<File>();
                arglist.append(f);
                handler.launch(arglist,null);
            } catch (GLib.Error e) {
                stderr.printf(_("Could not find a launcher for file: %s"), f.get_path());
            }
        }

        /**
         * Open the folder in which this downloads resides
         */
        public void open_folder() {
            var f = File.new_for_uri(this.dl.get_destination());
            this.open_path(f.get_parent());
        }

        /**
         * Open the download with an appropriate program.
         */
        public void open_download() {
            var f = File.new_for_uri(this.dl.get_destination());
            this.open_path(f);
        }

        /**
         * Pass clickevents up to the Node-class
         */
        private new void do_clicked(Clutter.Actor _) {
            base.do_clicked();
        }
    }
}
