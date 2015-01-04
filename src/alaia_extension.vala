using Gee;

[DBus (name = "de.grindhold.alaia")]
public class AlaiaExtension : Object {
    private WebKit.WebPage page;

    private HashSet<string> direct_input_tags;

    [DBus (visible = false)]
    public AlaiaExtension() {
        this.direct_input_tags = new HashSet<string>();
        this.direct_input_tags.add("INPUT");
        this.direct_input_tags.add("TEXTAREA");
        this.direct_input_tags.add("BUTTON");
        this.direct_input_tags.add("SUBMIT");
    }

    public bool needs_direct_input() {
        WebKit.DOM.Document doc = this.page.get_dom_document();
        WebKit.DOM.Element active = doc.active_element;
        stdout.printf(active.tag_name+"\n");
        return this.direct_input_tags.contains(active.tag_name);
    }

    [DBus (visible = false)]
    public void on_bus_aquired(DBusConnection connection) {
        stdout.printf("BUS AQUIRED\n");
        try {
            connection.register_object("/de/grindhold/alaia", this);
        } catch (IOError error) {
            warning("Could not register service: %s", error.message);
        }
    }

    [DBus (visible = false)]
    public void on_page_created(WebKit.WebExtension extension, WebKit.WebPage page) {
        this.page = page;
    }
}

[DBus (name = "de.grindhold.alaia")]
public errordomain AlaiaExtensionError {
    ERROR
}

[CCode (cname = "G_MODULE_EXPORT webkit_web_extension_initialize", instance_pos = -1)]
void webkit_web_extension_initialize(WebKit.WebExtension extension) {
    stdout.printf("OHAI!\n");
    AlaiaExtension aext = new AlaiaExtension();
    extension.page_created.connect(aext.on_page_created);
    Bus.own_name(BusType.SESSION, "de.grindhold.alaia", BusNameOwnerFlags.NONE,
        aext.on_bus_aquired, null, () => { warning("Could not aquire name"); });
}

