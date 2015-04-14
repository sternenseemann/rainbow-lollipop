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
     * Represents a loading bar on top of the screen 
     */
    class LoadingIndicator : Clutter.Actor {
        public LoadingIndicator(Clutter.Actor stage) {
            this.x = 0;
            this.y = 0;
            this.height = 3;
            this.background_color = Clutter.Color.from_string(Config.c.colorscheme.tracklist);
            this.add_constraint(
                new Clutter.BindConstraint(stage, Clutter.BindCoordinate.WIDTH, 0)
            );
            this.add_child(new LoadingIndicatorSlider(this));
        }
    }

    /**
     * Represents the moving portion of the loading bar
     */
    class LoadingIndicatorSlider : Clutter.Actor {
        private const int SLIDER_WIDTH = 200;
        private Clutter.Canvas c;

        /**
         * Constructs a new loading indicator slider
         */
        public LoadingIndicatorSlider(LoadingIndicator parent) {
            this.x = 0;
            this.y = 0;
            this.set_size(SLIDER_WIDTH,(int)roundf(parent.height));
            this.c = new Clutter.Canvas();
            this.c.set_size(SLIDER_WIDTH,(int)roundf(parent.height));
            this.content = c;
            this.c.draw.connect(do_draw);
            this.c.invalidate();
        }
        /**
         * Draws the slider as a linear gradient with colors depending on
         * The currently selected colorscheme
         */
        public bool do_draw(Cairo.Context cr, int w, int h) {
            double stops = (double)Config.c.colorscheme.tracks.size;
            cr.set_source_rgba(0,0,0,0);
            cr.set_operator(Cairo.Operator.SOURCE);
            cr.paint();
            
            cr.set_operator(Cairo.Operator.OVER);
            var grad = new Cairo.Pattern.linear(0,0,SLIDER_WIDTH,0);
            grad.add_color_stop_rgba(0.0, 0, 0, 0, 0);
            int count = 1;
            double step = 1.0d/(stops+2);
            foreach (string cs in Config.c.colorscheme.tracks) {
                var c = Clutter.Color.from_string(cs);
                grad.add_color_stop_rgba(count*step,
                            col_h2f(c.red),
                            col_h2f(c.green),
                            col_h2f(c.blue),
                            1.0);
                count++;
            }
            grad.add_color_stop_rgba(1.0, 0, 0, 0, 0);
            cr.set_source(grad);
            cr.rectangle(0,0,w,h);
            cr.fill();
            return true;
        }
    }

}
