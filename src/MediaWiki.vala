/* MediaWiki.vala
 *
 * Copyright 2021 v1993 <v19930312@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

/*
 * This is a helper class to manage connection to MediaWiki.
 * It is by no means complete and is designed to fit our specific workflow. Copying it into another project is likely a horrible idea.
 * If someone will make mediawiki library that we can reasonably use, I'll be more than happy to throw this away.
 *
 * Known flaws (in implemented functionality):
 * 1. Login extensions are not supported, only user+password is (also, rememberMe).
 * 2. You can't ignore warnings when doing usual upload. This mirrors normal wiki flow.
 */

errordomain MediaWikiError {
	NETWORK_FAILURE,
	TOKEN_FAILURE,
	LOGIN_FAILURE,
}

private Json.Node? SimpleJSONQuery(string path, Json.Node root) throws GLib.Error {
	// This seems wrong. I know this is wrong. I'm so sorry.
	// FIXME: replace this overthinking with Json.Reader
	unowned var? array = Json.Path.query(path, root)?.get_array();
	return ((array != null) && (array.get_length() > 0)) ? array.get_element(0) : null;
}

public class MediaWiki : Object {
	private string endpoint; //< API endpoint of wiki we're working with, e.g. https://en.wikipedia.org/w/api.php
	private Soup.Session session; //< Soup session we're using for all of the wiki interaction

	// Accept session as parameter if we're going to add more web-related features (e.g. fetching DOW index).
	public MediaWiki(string endpoint_, Soup.CookieJar jar) {
		endpoint = endpoint_;
		session = new Soup.Session();

		session.user_agent = "GeohasingWikiHelper/0.1 (https://github.com/v1993/geohashingwikihelper, talk to vyo2003 in geohasing IRC about problems with it) libsoup-2.4";
		session.accept_language_auto = true;
		session.add_feature(jar);

		// Very useful for debugging communication stuff
		/*
		Soup.Logger logger = new Soup.Logger (Soup.LoggerLogLevel.HEADERS, -1);
		session.add_feature(logger);
		*/
	}

	private async Soup.Message do_request(owned Soup.Message msg) {
		Soup.Message response = null;
		SourceFunc callback = do_request.callback;
		session.queue_message(msg, (sess, mess) => {
			response = mess;
			callback();
		});
		yield;
		return response;
	}

	private Json.Node parse_message(Soup.Message msg) throws GLib.Error {
		if (msg.response_body.data == null) {
			throw new MediaWikiError.NETWORK_FAILURE("failed to reach API endpoint");
		}

		var parser = new Json.Parser();
		parser.load_from_data((string)msg.response_body.data, (ssize_t)msg.response_body.length);
		var root = parser.get_root();
		return (owned)root;
	}

	private void add_common_params(string action, GLib.HashTable<string, string> body) {
		body.insert("action", action);
		body.insert("format", "json");
	}

	private async Json.Node simple_api_request(string action, GLib.HashTable<string, string> body) throws GLib.Error {
		var msg = new Soup.Message("POST", endpoint);
		add_common_params(action, body);
		var encoded = Soup.Form.encode_hash(body);
		msg.set_request(Soup.FORM_MIME_TYPE_URLENCODED, Soup.MemoryUse.TEMPORARY, encoded.data);
		var resp = yield do_request(msg);
		return parse_message(resp);
	}

	private async string get_token(string type = "csrf") throws GLib.Error {
		var body = new GLib.HashTable<string, string>(str_hash, str_equal);
		body.insert("meta", "tokens");
		body.insert("type", type);
		var root = yield simple_api_request("query", body);
		var? token = SimpleJSONQuery("$.query.tokens.*", root)?.get_string();
		if (token == null) {
			throw new MediaWikiError.TOKEN_FAILURE(@"failed to obrain token of type $(type)");
		}
		return token;
	}

	public async string log_in(string user, string password) throws GLib.Error {
		string login_token = yield get_token("login");

		var body = new GLib.HashTable<string, string>(str_hash, str_equal);
		body.insert("logintoken", login_token);
		body.insert("username", user);
		body.insert("password", password);
		// User can always reset session if they want to log out
		body.insert("rememberMe", "1");
		// We don't handle redirects anyways, but API requires us to pass this
		body.insert("loginreturnurl", "https://example.com");

		var resp = yield simple_api_request("clientlogin", body);
		var? status = SimpleJSONQuery("$.clientlogin.status", resp)?.get_string();

		if (status != "PASS") {
			var error_message = SimpleJSONQuery("$.clientlogin.message", resp)?.get_string() ?? "unknow clientlogin API error";
			throw new MediaWikiError.LOGIN_FAILURE(error_message);
		}

		return SimpleJSONQuery("$.clientlogin.username", resp)?.get_string();
	}

	public async string? get_current_user() throws GLib.Error {
		var body = new GLib.HashTable<string, string>(str_hash, str_equal);
		body.insert("meta", "userinfo");
		var root = yield simple_api_request("query", body);

		// If we aren't logged in, name is set to IP address.
		// Check anon to ensure we actually are logged in.
		if (SimpleJSONQuery("$.query.userinfo.anon", root)?.get_string() == null) {
			return SimpleJSONQuery("$.query.userinfo.name", root)?.get_string();
		} else {
			return null;
		}
	}

	public void purge_session() {
		var jar = session.get_feature(typeof(Soup.CookieJar)) as Soup.CookieJar;
		assert_nonnull(jar);

		// Since we may share session with others in the future, only remove our own cookies.
		foreach (var cookie in jar.get_cookie_list(new Soup.URI(endpoint), true)) {
			jar.delete_cookie(cookie);
		}
	}

	public async Json.Node upload_file(string filename, uint8[] data, string description) throws GLib.Error {
		var token = yield get_token();
		var mpart = new Soup.Multipart("multipart/form-data");
		mpart.append_form_string("action", "upload");
		mpart.append_form_string("format", "json");
		mpart.append_form_string("filename", filename);
		mpart.append_form_string("token", token);
		mpart.append_form_string("text", description);

		var file_headers = new Soup.MessageHeaders(Soup.MessageHeadersType.MULTIPART);
		var urlencoded_filename = Soup.Form.encode("filename", filename);
		file_headers.set_content_disposition(@"form-data; name=\"file\"; $urlencoded_filename", null);
		var buffer = new Soup.Buffer.with_owner(data, null, null);
		mpart.append_part(file_headers, buffer);

		var message = Soup.Form.request_new_from_multipart(endpoint, mpart);
		return parse_message(yield do_request(message));
	}

	public async Json.Node complete_stashed_upload(string filename, string filekey, string description) throws GLib.Error {
		var token = yield get_token();
		var body = new GLib.HashTable<string, string>(str_hash, str_equal);
		body.insert("filename", filename);
		body.insert("token", token);
		body.insert("text", description);
		body.insert("ignorewarnings", "1");
		body.insert("filekey", filekey);
		return yield simple_api_request("upload", body);
	}
}

