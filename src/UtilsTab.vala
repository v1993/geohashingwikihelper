/* UtilsTab.vala
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

[GtkTemplate (ui = "/org/v1993/geohashingwikihelper/UtilsTab.ui")]
class UtilsTab : Gtk.Box {
	[GtkCallback]
	void copy_geohash() {
		var hash_id = ((GHWHApplication)((MainWindow)get_toplevel()).application).current_hash.to_string();
		var clipboard = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD);
		clipboard.set_text(hash_id, hash_id.length);
	}

	[GtkCallback]
	void open_article() {
		var toplevel = (MainWindow)get_toplevel();
		var hash_id = ((GHWHApplication)toplevel.application).current_hash.to_string();
		// Works without replacement too, but let's be a good app
		hash_id = hash_id.replace(" ", "_");
		try {
			Gtk.show_uri_on_window(toplevel, @"https://geohashing.site/geohashing/$(hash_id)", Gdk.CURRENT_TIME);
		} catch(Error e) {
			// Probably just ignore it
		}
	}

	[GtkCallback]
	void open_file_uploader() {
		var toplevel = (MainWindow)get_toplevel();
		try {
			Gtk.show_uri_on_window(toplevel, "https://geohashing.site/geohashing/Special:Upload", Gdk.CURRENT_TIME);
		} catch(Error e) {
			// Probably just ignore it
		}
	}

	[GtkCallback]
	void copy_file_tags() {
		var hash_tags = ((GHWHApplication)((MainWindow)get_toplevel()).application).current_hash.to_file_tags();
		var clipboard = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD);
		clipboard.set_text(hash_tags, hash_tags.length);
	}
}
