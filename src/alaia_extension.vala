using Gee;

public class ZMQWorker {
    private static const string VENT = "tcp://127.0.0.1:26010";
    private static const string SINK = "tcp://127.0.0.1:26011";
    
    private AlaiaExtension aext;

    public ZMQWorker (AlaiaExtension e) {
        this.aext = e;
    }

    public void* run() {
        var ctx = new ZMQ.Context(1);
        var receiver = ZMQ.Socket.create(ctx, ZMQ.SocketType.PULL);
        var r = receiver.connect(ZMQWorker.VENT);
        if (r!=0) {
            stdout.printf("Could not connect to alaia vent");
        }

        var sender = ZMQ.Socket.create(ctx, ZMQ.SocketType.PUSH);
        r = sender.connect(ZMQWorker.SINK);

        var regmsg = ZMQ.Msg.with_data((ZMQWorker.REGISTER+"-"+(string)this.aext.get_page_id()));
        sender.send

        if (r!=0) {
            stdout.printf("Could not connect to alaia sink");
        }

        while (true) {
            var input = ZMQ.Msg();
            receiver.recv(ref input, 0);
            string in_data = (string)input.data;
            string out_data = this.handle_request(in_data);
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

    private string handle_request(string input) {
        // Needs direct input
        // Valid request example:
        //        ndi-5
        // Does the page with the id 5 need direct input?
        // Valid answer example:
        //        r_ndi5-1        means yes
        //        r_ndi5-0        means no
        if (input.has_prefix(ZMQWorker.NEEDS_DIRECT_INPUT)) {
            string[] splitted = input.split("-");
            uint64 pageid = (uint64)splitted[1];
            if (aext.get_page_id() == pageid) {
                if (aext.needs_direct_input())
                    return ZMQWorker.NEEDS_DIRECT_INPUT_RET+(string)pageid+"-1";
                else
                    return ZMQWorker.NEEDS_DIRECT_INPUT_RET+(string)pageid+"-0";
            } else {
                return null;
            }
        }
        return ZMQWorker.ERROR;
    }
}

public class AlaiaExtension : Object {
    private WebKit.WebPage page;

    private HashSet<string> direct_input_tags;

    public AlaiaExtension() {
        this.direct_input_tags = new HashSet<string>();
        this.direct_input_tags.add("INPUT");
        this.direct_input_tags.add("TEXTAREA");
        this.direct_input_tags.add("BUTTON");
        this.direct_input_tags.add("SUBMIT");
    }
    
    public uint64 get_page_id() {
        return this.page.get_id();
    }

    public bool needs_direct_input() {
        WebKit.DOM.Document doc = this.page.get_dom_document();
        WebKit.DOM.Element active = doc.active_element;
        stdout.printf(active.tag_name+"\n");
        return this.direct_input_tags.contains(active.tag_name);
    }

    public void on_page_created(WebKit.WebExtension extension, WebKit.WebPage page) {
        this.page = page;
    }
}

[CCode (cname = "G_MODULE_EXPORT webkit_web_extension_initialize", instance_pos = -1)]
void webkit_web_extension_initialize(WebKit.WebExtension extension) {
    stdout.printf("OHAI!\n");
    AlaiaExtension aext = new AlaiaExtension();
    extension.page_created.connect(aext.on_page_created);
    //TODO: migrate thread notation to non-deprecated constructor
    //      see compiler warning.
    var worker = new ZMQWorker(aext);
    try {
        unowned Thread<void*> worker_thread = Thread.create<void*>(worker.run, true);
    } catch (ThreadError e) {
        stdout.printf("Thread failed\n");
    }
}

