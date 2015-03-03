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
     * successfully completed IPC call including the callback itself
     * It is intended to be a universally applicable class but currently
     * it is only able to cover the needs_direct_input-usecase
     * TODO: Modify this wrapper and the code in general to be able
     *       To store arbitrary callback / parameter combinations
     */
    class IPCCallbackWrapper {
        private IPCCallback cb;
        private Gdk.EventKey e;
        private TrackWebView w;

        /**
         * Construct a new IPC Callback wrapper
         */
        public IPCCallbackWrapper(TrackWebView web, IPCCallback cb, Gdk.EventKey e) {
            this.cb = cb;
            this.e = e;
            this.w = web;
        }

        /**
         * Returns the callback function stored in this IPCCallbackWrapper
         */
        public IPCCallback get_callback() {
            return this.cb;
        }

        /**
         * Returns the Gdk.EventKey stored along this IPCCallbackWrapper
         */
        public Gdk.EventKey get_event() {
            return this.e;
        }

        /**
         * Returns the WebView associated with this IPCCallbackWrapper
         */
        public TrackWebView get_webview() {
            return this.w;
        }
    }

    /**
     * A callback that is called when an IPC call has finished sucessfully
     */
    public delegate void IPCCallback(Gdk.EventKey e);

    /**
     * The ZMQVent distributes ipc calls to each available WebExtension
     * It is a Vent in the sense of the libzmq workload distributor design
     * pattern with a little exception. Along with each call goes the id
     * Of a specific WebExtension and only this one Webextension will answer to
     * The call.
     *
     * TODO: Introduce reasonable timeouts to the calls.
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
            ZMQVent.ctx = new ZMQ.Context(1);
            ZMQVent.sender = ZMQ.Socket.create(ctx, ZMQ.SocketType.PUSH);
            ZMQVent.sender.bind("tcp://127.0.0.1:"+Config.c.ipc_vent_port.to_string());
        }

        /**
         * Sends a request to a WebView if this webview directly needs te input
         * from the Keyboard
         */
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
        private static Gee.HashMap<uint32, IPCCallbackWrapper> callbacks;
        private static ZMQ.Context ctx;
        private static ZMQ.Socket receiver;

        /**
         * Register a callback that is being mapped to a call id
         * When a answer to the call with the given call id arrives, the callback will
         * be executed
         */
        public static void register_callback(uint32 callid, IPCCallbackWrapper cbw) {
            ZMQSink.callbacks.set(callid, cbw);
        }

        /**
         * Initializes the sink
         */
        public static void init() {
            ZMQSink.callbacks = new Gee.HashMap<uint32, IPCCallbackWrapper>();
            ZMQSink.ctx = new ZMQ.Context(1);
            ZMQSink.receiver = ZMQ.Socket.create(ctx, ZMQ.SocketType.PULL);
            ZMQSink.receiver.bind("tcp://127.0.0.1:"+Config.c.ipc_sink_port.to_string());
            try {
                Thread.create<void*>(ZMQSink.run, true);
            } catch (ThreadError e) {
                stdout.printf("Sink broke down\n");
            }
        }

        /**
         * Thread-function to handle incoming responses
         */
        public static void* run() {
            while (true) {
                var input = ZMQ.Msg(); 
                receiver.recv(ref input);
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

    /**
     * Defines constant parts of the IPC Protocol
     */
    public class IPCProtocol : Object {
        public static const string NEEDS_DIRECT_INPUT = "ndi";
        public static const string NEEDS_DIRECT_INPUT_RET = "r_ndi";
        public static const string ERROR = "error";
        public static const string REGISTER = "reg";
        public static const string SEPARATOR = "-";
    }
}
