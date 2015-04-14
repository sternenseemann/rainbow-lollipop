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

using Json;
using Clutter;
using FileUtils;

namespace RainbowLollipop {
    /**
     * Errors for the Config class
     */
    public errordomain ConfigError {
       INVALID_FORMAT // Dropped on config file JSON parse-error
    }

    /**
     * Errors for the Colorscheme class
     */
    public errordomain ColorschemeError {
        INVALID_FORMAT // Dropped on config file JSON parse-error
    }

    /**
     * The Config class holds all values that are definable by the user
     * The configuration is being read-in from a file in JSON format.
     */
    class Config : GLib.Object {
        /**
         * Defines, which prefix is used for files belonging to this
         * program in various subfolders. e.g. in xdg-relevant folders
         *   ~/.cache/<C>/file.json
         *   /usr/local/share/<C>/file.png
         * This constant is used by
         * Application.get_data_filename(string s) and
         * Application.get_cache_filename(string s).
         */
        public const string C = "/rainbow-lollipop/";

        /**
         * Name of subfolders in which the colorschemes reside
         */
        public const string C_COLORS = "colors/";

        /**
         * Holds a reference to the colorscheme that is currently in use
         */
        public Colorscheme colorscheme {get; set;}
        private string colorscheme_name = "";
        
        /**
         * Reference to a global instance of Config
         */
        public static Config c;

        /**
         * Height of the tracks in pixel
         * @deprecated
         */
        public uint8 track_height {get; set; default = 0x80;}
        /**
         * Distance between a track's top border and its topmost node and
         * distance between a track's bottom border and its bottommost node
         * in pixels
         */
        public uint8 track_spacing {get; set; default = 0x10;}
        /**
         * Alpha value of any Track
         * Valid values are 0x00-0xFF
         */
        public uint8 track_opacity {get; set; default = 0xE0;}
        /**
         * Size (width and height) of a single node in pixels
         */
        public uint8 node_height {get; set; default = 0x40;}
        /**
         * Space between two adjacent nodes in pixels
         */
        public uint8 node_spacing {get; set; default = 0x10;}
        /**
         * Size of the favicon that is being displayed inside a node in pixels
         */
        public uint8 favicon_size {get; set; default = 24;}
        /**
         * The multiplier that is used to brighten colors
         * @deprecated
         */
        public uint8 color_multiplier {get; set; default = 15;}
        /**
         * Thickness of the line that connects two nodes in pixels
         */
        public double connector_stroke {get; set; default = 2.0;}
        /**
         * Thickness of the line that frames a node
         */
        public double bullet_stroke {get; set; default = 5.0;}

        /**
         * Port of the ipc component, that delegates calls
         */
        public uint32 ipc_vent_port {get; set; default = 26010;}
        /**
         * Port of the ipc component, that collects answers to delegated calls
         */
        public uint32 ipc_sink_port {get; set; default = 26011;}

        /**
         * Maximum Amount of URL-hints, that are being shown to the user
         */
        public uint16 urlhint_limit {get; set; default = 10;}

        /**
         * Determines whether urls should be rewritten to HTTPS auto,matically if possible
         */
        public bool https_everywhere {get; set; default = true;}

        /**
         * Determines the input handler that should be used to process user input
         */
        public InputHandlerType input_handler {get; set; default=InputHandlerType.DEFAULT;}

        /**
         * Save the current config to the configfile
         */
        public void save() {
            var b = new Json.Builder();
            b.begin_object();

            b.set_member_name("track_height");
            b.add_int_value(this.track_height);
            b.set_member_name("track_spacing");
            b.add_int_value(this.track_spacing);
            b.set_member_name("track_opacity");
            b.add_int_value(this.track_opacity);
            b.set_member_name("node_height");
            b.add_int_value(this.node_height);
            b.set_member_name("node_spacing");
            b.add_int_value(this.node_spacing);
            b.set_member_name("favicon_size");
            b.add_int_value(this.favicon_size);
            b.set_member_name("connector_stroke");
            b.add_double_value(this.connector_stroke);
            b.set_member_name("bullet_stroke");
            b.add_double_value(this.bullet_stroke);

            b.set_member_name("ipc_vent_port");
            b.add_int_value(this.ipc_vent_port);
            b.set_member_name("ipc_sink_port");
            b.add_int_value(this.ipc_sink_port);

            b.set_member_name("urlhint_limit");
            b.add_int_value(this.urlhint_limit);

            b.set_member_name("https_everywhere");
            b.add_boolean_value(this.https_everywhere);

            b.set_member_name("input_handler");
            b.add_int_value(this.input_handler);

            b.end_object();

            var gen = new Json.Generator();
            gen.set_root(b.get_root());
            try {
                string configpath = "%s%sconfig.json".printf(GLib.Environment.get_user_config_dir(),C);
                FileUtils.set_contents(configpath, gen.to_data(null));
            } catch (FileError e) {
                warning(_("Could not save configuration."));
            }
        }

        /**
         * Parses the config values from JSON and stores them into the according
         * Class members
         */
        private void process(Json.Node n) throws ConfigError {
            if (n.get_node_type() != Json.NodeType.OBJECT) {
                throw new ConfigError.INVALID_FORMAT(_("Expected root Object. Got %s"), n.type_name());
            }
            unowned Json.Object root = n.get_object();
            foreach (unowned string name in root.get_members()) {
                unowned Json.Node item = root.get_member(name);
                switch(name){
                    case "track_height":
                        if (item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ConfigError.INVALID_FORMAT(_("%s must be Value"),name);
                        }
                        this.track_height = (uint8) item.get_int();
                        break;
                    case "track_spacing":
                        if (item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ConfigError.INVALID_FORMAT(_("%s must be Value"),name);
                        }
                        this.track_spacing = (uint8) item.get_int();
                        break;
                    case "track_opacity":
                        if (item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ConfigError.INVALID_FORMAT(_("%s must be Value"),name);
                        }
                        this.track_opacity = (uint8) item.get_int();
                        break;
                    case "node_height":
                        if (item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ConfigError.INVALID_FORMAT(_("%s must be Value"),name);
                        }
                        this.node_height = (uint8) item.get_int();
                        break;
                    case "node_spacing":
                        if (item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ConfigError.INVALID_FORMAT(_("%s must be Value"),name);
                        }
                        this.node_spacing = (uint8) item.get_int();
                        break;
                    case "favicon_size":
                        if (item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ConfigError.INVALID_FORMAT(_("%s must be Value"),name);
                        }
                        this.favicon_size = (uint8) item.get_int();
                        break;
                    case "color_multiplier":
                        if (item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ConfigError.INVALID_FORMAT(_("%s must be Value"),name);
                        }
                        this.color_multiplier = (uint8) item.get_int();
                        break;
                    case "connector_stroke":
                        if (item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ConfigError.INVALID_FORMAT(_("%s must be Value"),name);
                        }
                        this.connector_stroke = (double) item.get_double();
                        break;
                    case "bullet_stroke":
                        if (item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ConfigError.INVALID_FORMAT(_("%s must be Value"),name);
                        }
                        this.bullet_stroke = (double) item.get_double();
                        break;
                    case "colorscheme":
                        if (item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ConfigError.INVALID_FORMAT(_("%s must be Value"),name);
                        }
                        this.colorscheme_name = item.get_string();
                        break;

                    case "ipc_vent_port":
                        if(item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ConfigError.INVALID_FORMAT(_("%s must be Value"), name);
                        }
                        this.ipc_vent_port = (uint32) item.get_int();
                        break;
                    case "ipc_sink_port":
                        if(item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ConfigError.INVALID_FORMAT(_("%s must be Value"), name);
                        }
                        this.ipc_sink_port = (uint32) item.get_int();
                        break;

                    case "urlhint_limit":
                        if(item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ConfigError.INVALID_FORMAT(_("%s must be Value"), name);
                        }
                        this.urlhint_limit = (uint16) item.get_int();
                        break;
                    case "https_everywhere":
                        if(item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ConfigError.INVALID_FORMAT(_("%s must be Value"), name);
                        }
                        this.https_everywhere = item.get_boolean();
                        break;
                    case "input_handler":
                        if(item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ConfigError.INVALID_FORMAT(_("%s must be Value"), name);
                        }
                        switch (item.get_int()) {
                            case InputHandlerType.DEFAULT:
                                this.input_handler = InputHandlerType.DEFAULT;
                                break;
                            case InputHandlerType.VIM:
                                this.input_handler = InputHandlerType.VIM;
                                break;
                            case InputHandlerType.TABLET:
                                this.input_handler = InputHandlerType.TABLET;
                                break;
                            default:
                                this.input_handler = InputHandlerType.DEFAULT;
                                break;
                        }
                        break;
                    default:
                        break;
                }
            }
             
        }
        
        /**
         * Use the default config
         */
        private static void loadDefault() {
            stdout.printf(_("Using default config\n"));
            Config.c = new Config();
            Config.c.colorscheme = new Colorscheme.default();
        }

        /**
         * Try to load the users configfile. If the user has no own configfile
         * in his XDG-userconfig-folder, the method will attempt to copy the default
         * configfile to the user's configdir. If this fails, the method will fall back
         * to a hardcoded default configuration
         */
        public static void load() {
            string configdata;
            string configpath;
            try {
                configpath = "%s%sconfig.json".printf(GLib.Environment.get_user_config_dir(),C);
                FileUtils.get_contents(configpath, out configdata);
            } catch (GLib.FileError e) {
                try {
                    string def_cfg_data;
                    FileUtils.get_contents(
                        Application.get_data_filename("default_cfg.json"),
                        out def_cfg_data
                    );
                    DirUtils.create("%s%s".printf(GLib.Environment.get_user_config_dir(),C),0755);
                    FileUtils.set_contents(configpath, def_cfg_data);
                    configdata = def_cfg_data;
                } catch (GLib.FileError e) {
                    Config.loadDefault();
                    return;
                }
            }

            var p = new Json.Parser();
            try {
                p.load_from_data(configdata);
            } catch (GLib.Error e) {
                Config.loadDefault();
                return;
            }
            var config = new Config();
            try {
                config.process(p.get_root());
            } catch (ConfigError e) {
                Config.loadDefault();
                return;
            }
            config.colorscheme = Colorscheme.load(config.colorscheme_name);
            Config.c = config;
        }
    }
    /**
     * Represents a colorscheme. For now, the colorscheme mainly defines two
     * Colors for displaying several gui-elements like the tracklist and its
     * background. Further it features an array of colors which is used to
     * assign colors to the HistoryTrack, thereby making them optically discriminable
     * and aesthetically appealing.
     * Colors are noted in HTML-markup format (e.g #ff0000 for red or #f00 for red)
     * Theoretically, every notation that can be parsed by Clutter.Color.from_string(string s)
     * is valid.
     */
    class Colorscheme {
        /**
         * The background-color of the Tracklist
         */
        public string tracklist {get;set; default="#141414";}
        /**
         * The background-color of the Empty Track
         */
        public string empty_track {get;set; default="#505050";}

        public const string[] defaultcolors = {"#f00","#0f0"};

        /**
         * ArrayList that stores the colors that can be assigned to HistoryTracks
         */
        public Gee.ArrayList<string> tracks {get; set; default=new Gee.ArrayList<string>();}
        
        /**
         * Parses the value of an entry of "tracks"
         */
        private void process_tracks(Json.Array n) {
            foreach (unowned Json.Node tc in n.get_elements()) {
                if (tc.get_node_type() != Json.NodeType.VALUE) 
                    continue;
                this.tracks.add(tc.get_string());
            }
        }

        /**
         * Parses a Colorscheme JSON
         */
        private void process(Json.Node n) throws ColorschemeError {
            if (n.get_node_type() != Json.NodeType.OBJECT) {
                throw new ColorschemeError.INVALID_FORMAT(_("Expected Object"));
            }
            unowned Json.Object root = n.get_object();
            foreach (unowned string name in root.get_members()) {
                unowned Json.Node item = root.get_member(name);
                switch(name){
                    case "tracklist":
                        if (item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ColorschemeError.INVALID_FORMAT(_("Expected %s to be value"),name);
                        }
                        this.tracklist = item.get_string();
                        break;
                    case "empty_track":
                        if (item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ColorschemeError.INVALID_FORMAT(_("Expected %s to be value"),name);
                        }
                        this.empty_track = item.get_string();
                        break;
                    case "tracks":
                        if (item.get_node_type() != Json.NodeType.ARRAY) {
                            throw new ColorschemeError.INVALID_FORMAT(_("Expected tracks to be array"));
                        }
                        this.process_tracks(item.get_array());
                        break;
                    default:
                        break;
                }
            }
        }

        public Colorscheme() {
        }

        /**
         * Constructs a default Colorscheme
         */
        public Colorscheme.default() {
            this.tracks.add("#f00");
            this.tracks.add("#ff0");
            this.tracks.add("#0f0");
            this.tracks.add("#0ff");
            this.tracks.add("#00f");
            this.tracks.add("#f0f");
        }

        /**
         * Loads a colorscheme file. If it fails, it defaults to the default colorscheme.
         */
        public static Colorscheme load(string name) {
            string colorschemedata;
            try {
                FileUtils.get_contents(Application.get_data_filename(Config.C_COLORS+name+".json"),
                                       out colorschemedata);
            } catch (GLib.FileError e) {
                stdout.printf(_("Could not load colorscheme. Using default colorscheme\n"));
                return new Colorscheme.default();
            }
            var p = new Json.Parser();
            try {
                p.load_from_data(colorschemedata);
            } catch (GLib.Error e) {
                stdout.printf(_("Could not feed schemeparser. Using default colorscheme\n"));
                return new Colorscheme.default();
            }
            var cs = new Colorscheme();
            try {
                cs.process(p.get_root());
            } catch (ColorschemeError e) {
                stdout.printf(_("Could not parse scheme. Using default colorscheme\n"));
                return new Colorscheme.default();
            }
            return cs;
        }
    }
}
