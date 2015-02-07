using Gee;

public class ZMQWorker {
    private static const string VENT = "tcp://127.0.0.1:26010";
    private static const string SINK = "tcp://127.0.0.1:26011";
    
    private static AlaiaExtension aext;
    
    private static ZMQ.Socket receiver;
    private static ZMQ.Socket sender;

    public static void init(AlaiaExtension e) {
        ZMQWorker.aext = e;
    }

    public static void* run() {
        var ctx = new ZMQ.Context(1);
        ZMQWorker.receiver = ZMQ.Socket.create(ctx, ZMQ.SocketType.PULL);
        var r = receiver.connect(ZMQWorker.VENT);
        if (r!=0) {
            stdout.printf("Could not connect to alaia vent\n");
        }

        ZMQWorker.sender = ZMQ.Socket.create(ctx, ZMQ.SocketType.PUSH);
        r = sender.connect(ZMQWorker.SINK);
        if (r!=0) {
            stdout.printf("Could not connect to alaia sink\n");
        }

        uint64 page_id = ZMQWorker.aext.get_page_id();
        var msgstring = ZMQWorker.REGISTER+"-%lld".printf(page_id);
        var regmsg = ZMQ.Msg.with_data(msgstring.data);
        ZMQWorker.sender.send(ref regmsg);

        while (true) {
            var input = ZMQ.Msg();
            receiver.recv(ref input, 0);
            string in_data = (string)input.data;
            string out_data = ZMQWorker.handle_request(in_data);
            if (out_data != null){
                var output = ZMQ.Msg.with_data(out_data.data);
                sender.send(ref output,0);
            }
        }
    }
 
    private static const string NEEDS_DIRECT_INPUT = "ndi";
    private static const string NEEDS_DIRECT_INPUT_RET = "r_ndi";
    private static const string ERROR = "error";
    private static const string REGISTER = "reg";
    private static const string SEPARATOR = "-";

    private static string? handle_request(string input) {
        // Needs direct input
        // Valid request example:
        //        ndi-5-<callid>
        // Does the page with the id 5 need direct input?
        // Valid answer example:
        //        r_ndi-5-1-<callid>  means yes
        //        r_ndi-5-0-<callid>  means no
        if (input.has_prefix(ZMQWorker.NEEDS_DIRECT_INPUT)) {
            string[] splitted = input.split("-");
            uint64 pageid = uint64.parse(splitted[1]);
            uint32 callid = int.parse(splitted[2]);
            if (ZMQWorker.aext.get_page_id() == pageid) {
                if (ZMQWorker.aext.needs_direct_input()) {
                    return ZMQWorker.NEEDS_DIRECT_INPUT_RET+
                           ZMQWorker.SEPARATOR+
                           "%lld".printf(pageid)+
                           ZMQWorker.SEPARATOR+
                           "1"+
                           ZMQWorker.SEPARATOR+
                           "%u".printf(callid);
                } else {
                    return ZMQWorker.NEEDS_DIRECT_INPUT_RET+
                           ZMQWorker.SEPARATOR+
                           "%lld".printf(pageid)+
                           ZMQWorker.SEPARATOR+
                           "0"+
                           ZMQWorker.SEPARATOR+
                           "%u".printf(callid);
                }
            } else {
                return null;
            }
        }
        return ZMQWorker.ERROR;
    }
}

public class AlaiaExtension : Object {
    private WebKit.WebPage page;
    private WebKit.WebExtension ext;
    private uint64 page_id;

    private HashSet<string> direct_input_tags;

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
        if (active != null)
            return this.direct_input_tags.contains(active.tag_name);
        else
            return false;
    }

    public uint64 get_page_id() {
        return this.page_id;
    }

    public void on_page_created(WebKit.WebExtension extension, WebKit.WebPage page) {
        this.page = page;
        this.ext = extension;
        this.page_id = page.get_id();
        try {
            Thread.create<void*>(ZMQWorker.run, true);
        } catch (ThreadError e) {
            stdout.printf("Thread failed\n");
        }
    }
}

[CCode (cname = "G_MODULE_EXPORT webkit_web_extension_initialize", instance_pos = -1)]
void webkit_web_extension_initialize(WebKit.WebExtension extension) {
    AlaiaExtension aext = new AlaiaExtension();
    extension.page_created.connect(aext.on_page_created);
    //TODO: migrate thread notation to non-deprecated constructor
    //      see compiler warning.
    ZMQWorker.init(aext);
}
