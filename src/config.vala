using Json;
using Clutter;
using FileUtils;

namespace alaia {
    public errordomain ConfigError {
        INVALID_FORMAT
    }

    public errordomain ColorschemeError {
        INVALID_FORMAT
    }

    class Config {
        public const string C = "/alaia";
        public const string C_COLORS = "/colors";

        public Colorscheme colorscheme {get; set;}
        private string colorscheme_name = "";
        
        public static Config c;

        public uint8 track_height {get; set; default = 0x80;}
        public uint8 track_spacing {get; set; default = 0x10;}
        public uint8 track_opacity {get; set; default = 0xE0;}
        public uint8 node_height {get; set; default = 0x40;}
        public uint8 node_spacing {get; set; default = 0x10;}
        public uint8 favicon_size {get; set; default = 24;}
        public uint8 color_multiplier {get; set; default = 15;}
        public double connector_stroke {get; set; default = 2.0;}
        public double bullet_stroke {get; set; default = 5.0;}

        private void process(Json.Node n) throws ConfigError {
            if (n.get_node_type() != Json.NodeType.OBJECT) {
                throw new ConfigError.INVALID_FORMAT("Expected root Object. Got %s", n.type_name());
            }
            unowned Json.Object root = n.get_object();
            foreach (unowned string name in root.get_members()) {
                unowned Json.Node item = root.get_member(name);
                switch(name){
                    case "track_height":
                        if (item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ConfigError.INVALID_FORMAT("%s must be Value",name);
                        }
                        this.track_height = (uint8) item.get_int();
                        break;
                    case "track_spacing":
                        if (item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ConfigError.INVALID_FORMAT("%s must be Value",name);
                        }
                        this.track_spacing = (uint8) item.get_int();
                        break;
                    case "track_opacity":
                        if (item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ConfigError.INVALID_FORMAT("%s must be Value",name);
                        }
                        this.track_opacity = (uint8) item.get_int();
                        break;
                    case "node_height":
                        if (item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ConfigError.INVALID_FORMAT("%s must be Value",name);
                        }
                        this.node_height = (uint8) item.get_int();
                        break;
                    case "node_spacing":
                        if (item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ConfigError.INVALID_FORMAT("%s must be Value",name);
                        }
                        this.node_spacing = (uint8) item.get_int();
                        break;
                    case "favicon_size":
                        if (item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ConfigError.INVALID_FORMAT("%s must be Value",name);
                        }
                        this.favicon_size = (uint8) item.get_int();
                        break;
                    case "color_multiplier":
                        if (item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ConfigError.INVALID_FORMAT("%s must be Value",name);
                        }
                        this.color_multiplier = (uint8) item.get_int();
                        break;
                    case "connector_stroke":
                        if (item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ConfigError.INVALID_FORMAT("%s must be Value",name);
                        }
                        this.connector_stroke = (double) item.get_double();
                        break;
                    case "bullet_stroke":
                        if (item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ConfigError.INVALID_FORMAT("%s must be Value",name);
                        }
                        this.bullet_stroke = (double) item.get_double();
                        break;
                    case "colorscheme":
                        if (item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ConfigError.INVALID_FORMAT("%s must be Value",name);
                        }
                        this.colorscheme_name = item.get_string();
                        break;
                    default:
                        break;
                }
            }
             
        } 

        public static void load() {
            string configdata;
            try {
                FileUtils.get_contents(GLib.Environment.get_user_config_dir()+
                                       C+"/config.json", out configdata);
            } catch (GLib.FileError e) {
                stdout.printf("Could not load config. Using default config\n");
                Config.c = new Config();
                Config.c.colorscheme = new Colorscheme.default();
                return;
            }

            var p = new Json.Parser();
            try {
                p.load_from_data(configdata);
            } catch (GLib.Error e) {
                stdout.printf("Could not feed configparser. Using default config\n");
                Config.c = new Config();
                Config.c.colorscheme = new Colorscheme.default();
                return;
            }
            var config = new Config();
            try {
                config.process(p.get_root());
            } catch (ConfigError e) {
                stdout.printf("Invalid config format. Using default config\n");
                Config.c = new Config();
                Config.c.colorscheme = new Colorscheme.default();
                return;
            }
            config.colorscheme = Colorscheme.load(config.colorscheme_name);
            Config.c = config;
        }
    }

    class Colorscheme {
        public string tracklist {get;set; default="#141414";}
        public string empty_track {get;set; default="#505050";}

        public const string[] defaultcolors = {"#f00","#0f0"};

        public Gee.ArrayList<string> tracks {get; set; default=new Gee.ArrayList<string>();}
        
        private void process_tracks(Json.Array n) {
            foreach (unowned Json.Node tc in n.get_elements()) {
                if (tc.get_node_type() != Json.NodeType.VALUE) 
                    continue;
                this.tracks.add(tc.get_string());
            }
        }

        private void process(Json.Node n) throws ColorschemeError {
            if (n.get_node_type() != Json.NodeType.OBJECT) {
                throw new ColorschemeError.INVALID_FORMAT("Expected Object");
            }
            unowned Json.Object root = n.get_object();
            foreach (unowned string name in root.get_members()) {
                unowned Json.Node item = root.get_member(name);
                switch(name){
                    case "tracklist":
                        if (item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ColorschemeError.INVALID_FORMAT("Expected %s to be value",name);
                        }
                        this.tracklist = item.get_string();
                        break;
                    case "empty_track":
                        if (item.get_node_type() != Json.NodeType.VALUE) {
                            throw new ColorschemeError.INVALID_FORMAT("Expected %s to be value",name);
                        }
                        this.empty_track = item.get_string();
                        break;
                    case "tracks":
                        if (item.get_node_type() != Json.NodeType.ARRAY) {
                            throw new ColorschemeError.INVALID_FORMAT("Expected tracks to be array");
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

        public Colorscheme.default() {
            this.tracks.add("#f00");
            this.tracks.add("#ff0");
            this.tracks.add("#0f0");
            this.tracks.add("#0ff");
            this.tracks.add("#00f");
            this.tracks.add("#f0f");
        }

        public static Colorscheme load(string name) {
            string colorschemedata;
            try {
                FileUtils.get_contents(GLib.Environment.get_user_config_dir()+
                                       Config.C+Config.C_COLORS+"/"+name+".json", out colorschemedata);
            } catch (GLib.FileError e) {
                stdout.printf("Could not load colorscheme. Using default colorscheme\n");
                return new Colorscheme.default();
            }
            var p = new Json.Parser();
            try {
                p.load_from_data(colorschemedata);
            } catch (GLib.Error e) {
                stdout.printf("Could not feed schemeparser. Using default colorscheme\n");
                return new Colorscheme.default();
            }
            var cs = new Colorscheme();
            try {
                cs.process(p.get_root());
            } catch (ColorschemeError e) {
                stdout.printf("Could not parse scheme. Using default colorscheme\n");
                return new Colorscheme.default();
            }
            return cs;
            
        }
    }
}
