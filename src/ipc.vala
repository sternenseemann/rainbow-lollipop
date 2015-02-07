namespace alaia {
    class IPCCallbackWrapper {
        private IPCCallback cb;
        private Gdk.EventKey e;
        private TrackWebView w;

        public IPCCallbackWrapper(TrackWebView web, IPCCallback cb, Gdk.EventKey e) {
            this.cb = cb;
            this.e = e;
            this.w = web;
        }

        public IPCCallback get_callback() {
            return this.cb;
        }
        public Gdk.EventKey get_event() {
            return this.e;
        }
        public TrackWebView get_webview() {
            return this.w;
        }
    }

    public delegate void IPCCallback(Gdk.EventKey e);

    class ZMQVent {
        private static uint32 callcounter = 0;
        private static ZMQ.Context ctx;
        private static ZMQ.Socket sender;

        private static uint32 _current_sites = 0;
        public static uint32 current_sites {get{return ZMQVent._current_sites;}}

        public static void init() {
            ZMQVent.ctx = new ZMQ.Context(1);
            ZMQVent.sender = ZMQ.Socket.create(ctx, ZMQ.SocketType.PUSH);
            ZMQVent.sender.bind("tcp://127.0.0.1:"+Config.c.ipc_vent_port.to_string());
        }

        public static async void needs_direct_input(TrackWebView w,IPCCallback cb, Gdk.EventKey e) {
            uint64 page_id = w.get_page_id();
            //Create Callback
            uint32 callid = callcounter++;
            var cbw = new IPCCallbackWrapper(w, cb, e);
            ZMQSink.register_callback(callid, cbw);
            string msgstring = IPCProtocol.NEEDS_DIRECT_INPUT+
                               IPCProtocol.SEPARATOR+
                               "%lld".printf(page_id)+
                               IPCProtocol.SEPARATOR+
                               "%ld".printf(callid);
            for (int i = 0; i < ZMQVent.current_sites; i++) {
                var msg = ZMQ.Msg.with_data(msgstring.data);
                sender.send(ref msg);
            }
        }

        public static void register_site() {
            ZMQVent._current_sites++;
        }

        public static void unregister_site() {
            if (ZMQVent._current_sites > 0)
                ZMQVent._current_sites--;
        }
    }

    class ZMQSink {
        private static Gee.HashMap<uint32, IPCCallbackWrapper> callbacks;
        private static ZMQ.Context ctx;
        private static ZMQ.Socket receiver;

        public static void register_callback(uint32 callid, IPCCallbackWrapper cbw) {
            ZMQSink.callbacks.set(callid, cbw);
        }

        public static void init() {
            ZMQSink.callbacks = new Gee.HashMap<uint32, IPCCallbackWrapper>();
            ZMQSink.ctx = new ZMQ.Context(1);
            ZMQSink.receiver = ZMQ.Socket.create(ctx, ZMQ.SocketType.PULL);
            ZMQSink.receiver.bind("tcp://127.0.0.1:"+Config.c.ipc_sink_port.to_string());
            try {
                unowned Thread<void*> worker_thread = Thread.create<void*>(ZMQSink.run, true);
            } catch (ThreadError e) {
                stdout.printf("Sink broke down\n");
            }
        }

        public static void* run() {
            while (true) {
                var input = ZMQ.Msg(); 
                receiver.recv(ref input);
                ZMQSink.handle_response((string)input.data);
            }
        }

        private static void handle_response(string input) {
            if (input.has_prefix(IPCProtocol.REGISTER)) {
                string[] splitted = input.split(IPCProtocol.SEPARATOR);
                ZMQVent.register_site();
            }
            if (input.has_prefix(IPCProtocol.NEEDS_DIRECT_INPUT_RET)) {
                string[] splitted = input.split(IPCProtocol.SEPARATOR);
                uint64 page_id = uint64.parse(splitted[1]);
                int result = int.parse(splitted[2]);
                uint32 call_id = int.parse(splitted[3]);
                IPCCallbackWrapper? cbw = ZMQSink.callbacks.get(call_id);
                if (result == 1) {
                    GLib.Idle.add(() => {
                        cbw.get_webview().key_press_event(cbw.get_event());
                        return false;
                    });
                } else {
                    GLib.Idle.add(() => {
                        cbw.get_callback()(cbw.get_event());
                        return false;
                    });
                }
                ZMQSink.callbacks.unset(call_id);
            }
            return;
        }

    }

    public class IPCProtocol : Object {
        public static const string NEEDS_DIRECT_INPUT = "ndi";
        public static const string NEEDS_DIRECT_INPUT_RET = "r_ndi";
        public static const string ERROR = "error";
        public static const string REGISTER = "reg";
        public static const string SEPARATOR = "-";
    }
}
