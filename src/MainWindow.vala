/* MainWindow.vala
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

[GtkTemplate (ui = "/org/v1993/geohashingwikihelper/MainWindow.ui")]
public class MainWindow : Gtk.ApplicationWindow {
	[GtkChild]
	private unowned Gtk.MenuButton curhash_button;
	[GtkChild]
	private unowned Gtk.Label curhash_label;
	[GtkChild]
	private unowned Gtk.MenuButton account_button;
	[GtkChild]
	private unowned Gtk.Notebook notebook;

	private HashPopover hash_popover;
	private AccountPopover account_popover;

	public MainWindow (Gtk.Application app) {
		Object (application: app);
		hash_popover = new HashPopover(curhash_button);
		account_popover = new AccountPopover(account_button);
		curhash_button.popover = hash_popover;
		account_button.popover = account_popover;

		notebook.append_page(new GalleryTab(), new Gtk.Label("Gallery")); // FIXME: I18N?
	}

	// Ask for confirmation, because a lot of data doesn't persist
	[GtkCallback]
	private bool confirm_exit() {
		var dialog = new Gtk.MessageDialog(this,
						 Gtk.DialogFlags.DESTROY_WITH_PARENT,
						 Gtk.MessageType.WARNING,
						 Gtk.ButtonsType.YES_NO,
						 "Are you sure you want to exit?"
		);

		var res = (Gtk.ResponseType)dialog.run();
		dialog.destroy();

		return res != YES;
	}

	public void on_hash_changed() {
		var hash = ((GHWHApplication)application).current_hash;
		if (hash != null) {
			notebook.sensitive = true;
			curhash_label.label = hash.to_string();
		} else {
			notebook.sensitive = false;
			curhash_label.label = "[not set]"; // FIXME: I18N
		}
	}
}

