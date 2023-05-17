/* AccountPopover.vala
 *
 * Copyright 2021 v1993
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
 */

[GtkTemplate (ui = "/org/v1993/geohashingwikihelper/AccountPopover.ui")]
public class AccountPopover : Gtk.Popover {
	[GtkChild]
	private unowned Gtk.Entry username;
	[GtkChild]
	private unowned Gtk.Entry password;
	[GtkChild]
	private unowned Gtk.Container main_container;
	[GtkChild]
	private unowned Gtk.Label status;
	[GtkChild]
	private unowned Gtk.Button login_btn;

	public AccountPopover (Gtk.Widget parent) {
		Object(relative_to: parent);
		fetch_status.begin();
	}

	private void set_user_label(string? uname) {
		// FIXME: I18N
		status.label = uname != null ? @"logged in as $uname" : "not logged in";
	}

	[GtkCallback]
	private void focus_password() {
		password.grab_focus();
	}

	[GtkCallback]
	private void creds_changed() {
		login_btn.sensitive = username.text_length > 0 &&
							  password.text_length > 0;
	}

	[GtkCallback]
	private void logout() {
		new GHWHApplication().wiki.purge_session();
		set_user_label(null);
	}

	// Obtain login status by querying wiki
	private async void fetch_status() {
		status.label = "fetching..."; // FIXME: I18N

		try {
			set_user_label(yield new GHWHApplication().wiki.get_current_user());
		} catch(GLib.Error e) {
			status.label = @"error: $(e.message)"; // FIXME: I18N
			GLib.Timeout.add(2500, () => {
				fetch_status.begin();
				return false;
			});
		}
	}

	[GtkCallback]
	private async void login() {
		try {
			main_container.sensitive = false;

			string uname = username.text;
			string pswd = password.text;

			var wiki = new GHWHApplication().wiki;
			wiki.purge_session();
			status.label = "logging in..."; // FIXME: I18N

			string uname_corrected = yield wiki.log_in(uname, pswd);
			set_user_label(uname_corrected);
			hide();
		} catch (GLib.Error e) {
			set_user_label(null);

			var dialog = new Gtk.MessageDialog(new GHWHApplication().main_window,
											   Gtk.DialogFlags.DESTROY_WITH_PARENT,
											   Gtk.MessageType.ERROR,
											   Gtk.ButtonsType.OK,
											   "Login error: %s", // FIXME: I18N?
											   e.message
			);
			dialog.run();
			dialog.destroy();
		} finally {
			username.text = "";
			password.text = "";
			main_container.sensitive = true;
			username.grab_focus();
		}
	}
}

