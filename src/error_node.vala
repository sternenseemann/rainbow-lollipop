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
     * This is a bullet that resembles a stopsign and renders
     * its parent stored errorcode as text.
     */
    class ErrorBullet : Clutter.Actor {
        private Clutter.Canvas c;
        private ErrorNode parent;

        /**
         * Initializes and returns a new ErrorBullet
         */
        public ErrorBullet (ErrorNode parent) {
            this.parent = parent;
            this.c = new Clutter.Canvas();
            this.x = this.y = 0;
            this.content = c;
            this.set_size((int)roundf(parent.width), (int)roundf(parent.height));
            this.c.set_size((int)roundf(parent.width), (int)roundf(parent.height));
            Config.c.notify.connect(config_update);
            this.c.draw.connect(do_draw);
            this.c.invalidate();
        }

        /**
         * Realizes the errornode on screen
         */
        public bool do_draw(Cairo.Context cr, int w, int h) {
            cr.set_source_rgba(0,0,0,0);
            cr.set_operator(Cairo.Operator.SOURCE);
            cr.paint();

            var nh = Config.c.node_height;
            var bs = Config.c.bullet_stroke;
            cr.set_operator(Cairo.Operator.OVER);
            cr.set_line_width(Config.c.bullet_stroke);

            cr.set_source_rgba(col_h2f(this.parent.color.red)*2,
                              col_h2f(this.parent.color.green)*2,
                              col_h2f(this.parent.color.blue)*2,
                              1);
            cr.move_to(nh / 3, bs);
            cr.line_to(nh / 3 * 2, bs);
            cr.line_to(nh-bs, nh / 3);
            cr.line_to(nh-bs, nh / 3 * 2);
            cr.line_to(nh / 3 * 2, nh-bs);
            cr.line_to(nh / 3, nh-bs);
            cr.line_to(bs, nh / 3 * 2);
            cr.line_to(bs, nh / 3);
            cr.line_to(nh / 3, bs);
            cr.stroke();

            cr.set_source_rgba(col_h2f(this.parent.color.red),
                              col_h2f(this.parent.color.green),
                              col_h2f(this.parent.color.blue),
                              0.5f);
            cr.move_to(nh / 3 - bs / 2, 0);
            cr.line_to(nh / 3 * 2 + bs / 2, 0);
            cr.line_to(nh, nh / 3 - bs / 2);
            cr.line_to(nh, nh / 3 * 2 + bs / 2);
            cr.line_to(nh / 3 * 2 + bs / 2, nh);
            cr.line_to(nh / 3 - bs / 2, nh);
            cr.line_to(0, nh / 3 * 2 + bs / 2);
            cr.line_to(0, nh / 3 - bs / 2);
            cr.line_to(nh / 3 - bs / 2, 0);
            cr.fill();

            return true;
        }

        /**
         * Handles configuration updates
         */
        private void config_update() {
            this.set_size((int)roundf(parent.width), (int)roundf(parent.height));
            this.c.set_size((int)roundf(parent.width), (int)roundf(parent.height));
            this.c.invalidate();
        }
    }

    /**
     * This class is a Node that will be used when HTTP-calls return
     * HTTP-errors. It resembles a traffic-stopsign and contains the
     * HTTP-errorcode as text.
     */
    class ErrorNode : Node {
        private uint e;
        private ErrorBullet bullet;
        private Clutter.Text text;

        /**
         * Creates and returns a new ErrorNode
         */
        public ErrorNode(HistoryTrack track, uint error, Node? par) {
            base(track, par);
            this.e = error;
            this.bullet = new ErrorBullet(this);
            this.add_child(this.bullet);
            this.text = new Clutter.Text.with_text("Monospace Bold 9", "%u".printf(this.e));
            this.text.color = this.color.darken().darken().darken();
            this.text.x = Config.c.node_height/2-this.text.width/2;
            this.text.y = Config.c.node_height/2-this.text.height/2;
            this.add_child(this.text);
        }
    }
}
