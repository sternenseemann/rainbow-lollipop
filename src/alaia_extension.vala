[DBus (name = "de.grindhold.alaia")]
public class AlaiaExtension : Object {
    private WebKit.WebPage page;
    public bool needs_direct_input() {
        return true;
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
    AlaiaExtension aext = new AlaiaExtension();
    extension.page_created.connect(aext.on_page_created);
    Bus.own_name(BusType.SESSION, "org.example.DOMTest", BusNameOwnerFlags.NONE,
        aext.on_bus_aquired, null, () => { warning("Could not aquire name"); });
}

