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
     * Used to wrap all the data that is necessary to call a callback to a
     * successfully completed IPC call including the callback itself.
     * It is intended to be a universally applicable class but currently
     * it is only able to cover the needs_direct_input-usecase.
     */
    class IPCCallbackContext : GLib.Object {
        protected IPCCallback cb;
        protected Gee.ArrayList<GLib.Value?> arguments = new Gee.ArrayList<GLib.Value?>();
        protected TrackWebView w;

        /**
         * Construct a new IPC Callback wrapper
         */
        public IPCCallbackContext(TrackWebView web, IPCCallback cb) {
            this.cb = cb;
            this.w = web;
        }

        /**
         * Adds an argument to the CallbackContext
         */
        public void add_argument(GLib.Value v) {
            this.arguments.add(v);
        }

        /**
         * Adds a list of arguments to the CallbackContext
         */
        public void add_arguments(GLib.Value[] vl) {
            foreach (GLib.Value v in vl)
                this.arguments.add(v);
        }

        /**
         * Implement this for the callbacks behaviour in case of success
         */
        public virtual void execute() {}

        /**
         * Implement this for the callbacks behaviour in case of failure
         * e.g. timeout
         */
        public virtual void failure() {}
    }

    /**
     * Wraps callback handling for calls to the needs_direct_input function
     * of webextensions
     */
    class NeedsDirectInputCC : IPCCallbackContext {
        public NeedsDirectInputCC(TrackWebView v, IPCCallback cb) {
            base(v,cb);
        }

        public override void execute() {
            int result = this.arguments[1].get_int();
            GLib.Value[] cb_args = {this.arguments[0]};

            if (result == 1) {
                GLib.Idle.add(() => {
                    this.w.key_press_event(this.arguments[0] as Gdk.EventKey);
                    return false;
                });
            } else {
                GLib.Idle.add(() => {
                    this.cb(cb_args);
                    return false;
                });
            }
        }

        public override void failure() {
            GLib.Value[] cb_args = {this.arguments[0]};
            GLib.Idle.add(() => {
                this.cb(cb_args);
                return false;
            });
        }
    }

    /**
     * Wraps callback handling for calls to get_scroll_info
     */
    class GetScrollInfoCC : IPCCallbackContext {
        public GetScrollInfoCC(TrackWebView v, IPCCallback cb) {
            base(v,cb);
        }

        public override void execute() {
            GLib.Value[] cb_args = {this.arguments[0], this.arguments[1]};
            this.cb(cb_args);
        }

        public override void failure() {
            long x = 0;
            long y = 0;
            GLib.Value[] cb_args = {x,y};
            this.cb(cb_args);
        }
    }

    /**
     * A callback that is called when an IPC call has finished successfully
     */
    public delegate void IPCCallback(GLib.Value[] argslist);

    /**
     * The ZMQVent distributes ipc calls to each available WebExtension.
     * It is a Vent in the sense of the libzmq workload distributor design
     * pattern with a little exception. Along with each call goes the id
     * of a specific WebExtension and only this one Webextension will answer to
     * the call.
     */
    class ZMQVent {
        private static uint32 callcounter = 0;
        private static ZMQ.Context ctx;
        private static ZMQ.Socket sender;

        private static uint32 _current_sites = 0;
        public static uint32 current_sites {get{return ZMQVent._current_sites;}}

        /**
         * Setup the ZMQVent
         */
        public static void init() {
            ZMQVent.ctx = new ZMQ.Context();
            ZMQVent.sender = ZMQ.Socket.create(ctx, ZMQ.SocketType.PUSH);
            ZMQVent.sender.bind("tcp://127.0.0.1:"+Config.c.ipc_vent_port.to_string());
        }

        /**
         * Sends a request to a WebView if this webview directly needs the input
         * from the Keyboard
         */
        public static async void needs_direct_input(TrackWebView w,IPCCallback cb, Gdk.EventKey e) {
            uint64 page_id = w.get_page_id();
            //Create Callback
            uint32 callid = callcounter++;
            var cbw = new NeedsDirectInputCC(w, cb);
            cbw.add_argument(e);
            ZMQSink.register_callback(callid, cbw);
            string msgstring = IPCProtocol.NEEDS_DIRECT_INPUT+
                               IPCProtocol.SEPARATOR+
                               "%lld".printf(page_id)+
                               IPCProtocol.SEPARATOR+
                               "%ld".printf(callid);
            for (int i = 0; i < ZMQVent.current_sites; i++) {
                var msg = ZMQ.Msg.with_data(msgstring.data);
                msg.send(sender);
            }
        }

        /**
         * Issues a request to the webviewextension of the given webview in which
         * it asks for the current scroll position of the page
         */
        public static async void get_scroll_info(TrackWebView w, IPCCallback cb) {
            uint64 page_id = w.get_page_id();
            uint32 callid = callcounter++;
            var cbw = new GetScrollInfoCC(w, cb);
            ZMQSink.register_callback(callid, cbw);
            string msgstring = IPCProtocol.GET_SCROLL_INFO+
                               IPCProtocol.SEPARATOR+
                               "%lld".printf(page_id)+
                               IPCProtocol.SEPARATOR+
                               "%ld".printf(callid);
            for (int i = 0; i < ZMQVent.current_sites; i++) {
                var msg = ZMQ.Msg.with_data(msgstring.data);
                msg.send(sender);
            }
        }

        /**
         * Tells the webprocess to to scroll its view
         * to a specific position
         */
        public static async void set_scroll_info(TrackWebView w, long x, long y) {
            uint64 page_id = w.get_page_id();
            string msgstring = IPCProtocol.SET_SCROLL_INFO+
                               IPCProtocol.SEPARATOR+
                               "%lld".printf(page_id)+
                               IPCProtocol.SEPARATOR+
                               "%li".printf(x)+
                               IPCProtocol.SEPARATOR+
                               "%li".printf(y);
            for (int i = 0; i < ZMQVent.current_sites; i++) {
                var msg = ZMQ.Msg.with_data(msgstring.data);
                msg.send(sender);
            }
        }

        /**
         * Increments the counter of the webextensions that have to be provided with messages
         */
        public static void register_site() {
            ZMQVent._current_sites++;
        }

        /**
         * Decrements the counter of webextensions
         */
        public static void unregister_site() {
            if (ZMQVent._current_sites > 0)
                ZMQVent._current_sites--;
        }
    }

    /**
     * Collects answers to IPC-Calls and causes the appropriate callbacks to be
     * executed.
     */
    class ZMQSink {
        private static Gee.HashMap<uint32, IPCCallbackContext> callbacks;
        private static ZMQ.Context ctx;
        private static ZMQ.Socket receiver;

        /**
         * Register a callback that is being mapped to a call id.
         * When an answer to the call with the given call id arrives, the callback will
         * be executed
         * Parallel to the callbacks registration a timeout will be scheduled.
         * If the sink does not receive any response in time, a default action will
         * be triggered and the callback will be forgotten
         */
        public static void register_callback(uint32 callid, IPCCallbackContext cbw) {
            ZMQSink.callbacks.set(callid, cbw);
            Timeout.add(500,()=>{
                IPCCallbackContext? _cbw = ZMQSink.callbacks.get(callid);
                if (_cbw != null) {
                    cbw.failure();
                    ZMQSink.callbacks.unset(callid);
                }
                return false;
            });
        }

        /**
         * Initializes the sink
         */
        public static void init() {
            ZMQSink.callbacks = new Gee.HashMap<uint32, IPCCallbackContext>();
            ZMQSink.ctx = new ZMQ.Context();
            ZMQSink.receiver = ZMQ.Socket.create(ctx, ZMQ.SocketType.PULL);
            ZMQSink.receiver.bind("tcp://127.0.0.1:"+Config.c.ipc_sink_port.to_string());
            try {
                new Thread<void*>.try(null,ZMQSink.run);
            } catch (GLib.Error e) {
                stdout.printf(_("Sink broke down\n"));
            }
        }

        /**
         * Thread-function to handle incoming responses
         */
        public static void* run() {
            while (true) {
                var input = ZMQ.Msg(); 
                input.recv(receiver);
                ZMQSink.handle_response((string)input.data);
            }
        }

        /**
         * Handles incoming responses and calls the stored callbacks accordingly
         */
        private static void handle_response(string input) {
            if (input.has_prefix(IPCProtocol.REGISTER)) {
                ZMQVent.register_site();
            }
            if (input.has_prefix(IPCProtocol.NEEDS_DIRECT_INPUT_RET)) {
                string[] splitted = input.split(IPCProtocol.SEPARATOR);
                int result = int.parse(splitted[2]);
                uint32 call_id = int.parse(splitted[3]);
                IPCCallbackContext? cbw = ZMQSink.callbacks.get(call_id);
                if (cbw == null) {
                    ZMQSink.callbacks.unset(call_id);
                    return;
                }
                cbw.add_argument(result);
                cbw.execute();
                ZMQSink.callbacks.unset(call_id);
            }
            if (input.has_prefix(IPCProtocol.GET_SCROLL_INFO_RET)) {
                string[] splitted = input.split(IPCProtocol.SEPARATOR);
                long x = long.parse(splitted[2]);
                long y = long.parse(splitted[3]);
                uint32 call_id = int.parse(splitted[4]);
                IPCCallbackContext? cbw = ZMQSink.callbacks.get(call_id);
                if (cbw == null) {
                    ZMQSink.callbacks.unset(call_id);
                    return;
                }
                cbw.add_argument(x);
                cbw.add_argument(y);
                cbw.execute();
                ZMQSink.callbacks.unset(call_id);
            }
            return;
        }

    }
}
