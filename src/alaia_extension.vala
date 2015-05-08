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

using Gee;
using RainbowLollipop;

/**
 * This Worker receives IPC-Calls from the main-thread, processes them and
 * returns appropriate answers.
 * The Worker only anwers if the page id of this webextension is the same as
 * the page id that the IPC-Call was issued for. Otherwise it will drop the request.
 */
public class ZMQWorker {
    private static const string VENT = "tcp://127.0.0.1:26010";
    private static const string SINK = "tcp://127.0.0.1:26011";
    
    private static AlaiaExtension aext;
    
    private static ZMQ.Socket receiver;
    private static ZMQ.Socket sender;

    /**
     * Initialize by storing a reference to the AlaiaExtension that this Worker handles
     */
    public static void init(AlaiaExtension e) {
        ZMQWorker.aext = e;
    }

    /**
     * Mainmethod of the IPC communication thread
     * Opens sockets for communication
     * Registers itself with the ZMQVent
     * Then starts an endless loop thread to wait for input from the ZMQVent, delegate the
     * calls to a handler and return the obtained results to the ZMQSink.
     */
    public static void* run() {
        var ctx = new ZMQ.Context();
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
        var msgstring = IPCProtocol.REGISTER+"-%lld".printf(page_id);
        var regmsg = ZMQ.Msg.with_data(msgstring.data);
        regmsg.send(ZMQWorker.sender);

        while (true) {
            var input = ZMQ.Msg();
            input.recv(receiver);
            string in_data = (string)input.data;
            string out_data = ZMQWorker.handle_request(in_data);
            if (out_data != null){
                var output = ZMQ.Msg.with_data(out_data.data);
                output.send(sender);
            }
        }
    }
 
    /**
     * Handles IPC-Requests.
     * Returns null if the requests page id does not correspond to
     * this webexension's page id.
     * Returns an error-message if the methods somehow fail
     *
     *    Needs direct input
     *    Valid request example:
     *           ndi-5-<callid>
     *    Does the page with the id 5 need direct input?
     *    Valid answer example:
     *           r_ndi-5-1-<callid>  means yes
     *           r_ndi-5-0-<callid>  means no
     */
    private static string? handle_request(string input) {
        if (input.has_prefix(IPCProtocol.NEEDS_DIRECT_INPUT)) {
            string[] splitted = input.split(IPCProtocol.SEPARATOR);
            uint64 pageid = uint64.parse(splitted[1]);
            uint32 callid = int.parse(splitted[2]);
            if (ZMQWorker.aext.get_page_id() == pageid) {
                if (ZMQWorker.aext.needs_direct_input()) {
                    return IPCProtocol.NEEDS_DIRECT_INPUT_RET+
                           IPCProtocol.SEPARATOR+
                           "%lld".printf(pageid)+
                           IPCProtocol.SEPARATOR+
                           "1"+
                           IPCProtocol.SEPARATOR+
                           "%u".printf(callid);
                } else {
                    return IPCProtocol.NEEDS_DIRECT_INPUT_RET+
                           IPCProtocol.SEPARATOR+
                           "%lld".printf(pageid)+
                           IPCProtocol.SEPARATOR+
                           "0"+
                           IPCProtocol.SEPARATOR+
                           "%u".printf(callid);
                }
            } else {
                return null;
            }
        }
        if (input.has_prefix(IPCProtocol.GET_SCROLL_INFO)) {
            string[] splitted = input.split(IPCProtocol.SEPARATOR);
            uint64 pageid = uint64.parse(splitted[1]);
            uint32 callid = int.parse(splitted[2]);
            if (ZMQWorker.aext.get_page_id() == pageid) {
                long x = ZMQWorker.aext.get_scroll_position(AlaiaExtension.Orientation.HORIZONTAL);
                long y = ZMQWorker.aext.get_scroll_position(AlaiaExtension.Orientation.VERTICAL);
                return IPCProtocol.GET_SCROLL_INFO_RET+
                       IPCProtocol.SEPARATOR+
                       "%lld".printf(pageid)+
                       IPCProtocol.SEPARATOR+
                       "%li".printf(x)+
                       IPCProtocol.SEPARATOR+
                       "%li".printf(y)+
                       IPCProtocol.SEPARATOR+
                       "%u".printf(callid);
            } else {
                return null;
            }
        }
        return IPCProtocol.ERROR;
    }
}

/**
 * The webextension class for a WebView
 */
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

    /**
     * Returns true if the currently active DOM-Element is
     * one of the input-requiring elements INPUT, TEXTAREA, BUTTON or SUBMIT
     */
    public bool needs_direct_input() {
        WebKit.DOM.Document doc = this.page.get_dom_document();
        WebKit.DOM.Element active = doc.active_element;
        if (active != null)
            return this.direct_input_tags.contains(active.tag_name);
        else
            return false;
    }

    /**
     * Enumerates either a vertical or a horizontal orientation
     */
    public enum Orientation {
        HORIZONTAL,
        VERTICAL
    }

    /**
     * Returns the current scroll position
     */
    public long get_scroll_position(Orientation o) {
        WebKit.DOM.Document doc = this.page.get_dom_document();
        if (o == Orientation.HORIZONTAL)
            return doc.default_view.scroll_x;
        else
            return doc.default_view.scroll_y;
    }

    /**
     * Returns the page_id of this webextension's page
     */
    public uint64 get_page_id() {
        return this.page_id;
    }

    /**
     * Starts the ZMQWorker to handle IPC requests as soon as the page has been
     * loaded sufficiently.
     */
    public void on_page_created(WebKit.WebExtension extension, WebKit.WebPage page) {
        this.page = page;
        this.ext = extension;
        this.page_id = page.get_id();
        try {
            new Thread<void*>.try(null, ZMQWorker.run);
        } catch (GLib.Error e) {
            stdout.printf("Thread failed\n");
        }
    }
}

/**
 * Starting point function for WebExtensions
 *
 * TODO: migrate thread notation to non-deprecated constructor
 *       see compiler warning.
 */
[CCode (cname = "G_MODULE_EXPORT webkit_web_extension_initialize", instance_pos = -1)]
void webkit_web_extension_initialize(WebKit.WebExtension extension) {
    AlaiaExtension aext = new AlaiaExtension();
    extension.page_created.connect(aext.on_page_created);
    ZMQWorker.init(aext);
}

