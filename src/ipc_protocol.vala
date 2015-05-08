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
     * Defines constant parts of the IPC Protocol
     */
    public class IPCProtocol : Object {
        public static const string NEEDS_DIRECT_INPUT = "ndi";
        public static const string NEEDS_DIRECT_INPUT_RET = "r_ndi";
        public static const string GET_SCROLL_INFO = "gsi";
        public static const string GET_SCROLL_INFO_RET = "r_gsi";
        public static const string ERROR = "error";
        public static const string REGISTER = "reg";
        public static const string SEPARATOR = "-";
    }
}
