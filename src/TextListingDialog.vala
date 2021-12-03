/* TextListingDialog.vala
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

[GtkTemplate (ui = "/org/v1993/geohashingwikihelper/TextListingDialog.ui")]
public class TextListingDialog : Gtk.Dialog {
	[GtkChild]
	private unowned Gtk.TextBuffer textbuffer;

	public TextListingDialog (string text, Gtk.Window? parent) {
		set_transient_for(parent);
		textbuffer.text = text;
	}

	[GtkCallback]
	private void copy_to_clipboard() {
		var clipboard = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD);
		clipboard.set_text(textbuffer.text, textbuffer.text.length);
	}

	[GtkCallback]
	private void close_pressed() {
		response(Gtk.ResponseType.CLOSE);
	}
}
