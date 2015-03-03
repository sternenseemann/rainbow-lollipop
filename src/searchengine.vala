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
     * Represents the DuckDuckGo Searchengine as a hintprovider
     * See duckduckgo at https://duckduckgo.com
     */
    class DuckDuckGo : IHintProvider {
        private static DuckDuckGo instance;
        
        private DuckDuckGo(){}

        /**
         * Obtain the singleton instance of DuckDuckGo
         */
        public static DuckDuckGo S() {
            if (DuckDuckGo.instance == null)
                DuckDuckGo.instance = new DuckDuckGo();
            return DuckDuckGo.instance;
        }

        /**
         * Returns a hint that lets the user search the given fragment
         * via https://duckduckgo.com
         */
        public Gee.ArrayList<AutoCompletionHint> get_hints(string fragment){
            var ret = new Gee.ArrayList<AutoCompletionHint>();
            var hint = new AutoCompletionHint(
                        "Search %s".printf(fragment),
                        "Search for %s with DuckDuckGo".printf(fragment)
            );
            var icon_path = Application.get_data_filename("ddg.png");
            var surface = new Cairo.ImageSurface.from_png(icon_path);
            hint.set_icon(surface);
            hint.execute.connect((tl) => {
                tl.add_track_with_url("https://duckduckgo.com/?q=%s".printf(fragment));
            });
            ret.add(hint);
            return ret;
        }
    }
}
