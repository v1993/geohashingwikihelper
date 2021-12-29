/* HashPopover.vala
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

[GtkTemplate (ui = "/org/v1993/geohashingwikihelper/HashPopover.ui")]
public class HashPopover : Gtk.Popover {
	[GtkChild]
	private unowned Gtk.Calendar calendar;
	[GtkChild]
	private unowned Gtk.Switch globalhash_switch;
	[GtkChild]
	private unowned Gtk.Container latlon_container;
	[GtkChild]
	private unowned Gtk.CheckButton lat_neg;
	[GtkChild]
	private unowned Gtk.SpinButton lat_abs;
	[GtkChild]
	private unowned Gtk.CheckButton lon_neg;
	[GtkChild]
	private unowned Gtk.SpinButton lon_abs;

	public HashPopover (Gtk.Widget parent) {
		Object(relative_to: parent);
	}

	[GtkCallback]
	private void update_hash() {
		// Bastard calendar has months start from zero! Why?!
		var date = new Geohashing.Date(calendar.year, calendar.month + 1, calendar.day);
		Geohashing.Graticule graticule;
		if (globalhash_switch.active) {
			graticule = new Geohashing.Graticule.globalhash();
		} else {
			graticule = new Geohashing.Graticule(lat_neg.active, (int)lat_abs.value,
												 lon_neg.active, (int)lon_abs.value);
		}

		((GHWHApplication)((MainWindow)get_toplevel()).application).current_hash = new Geohashing.SpecificHash(date, graticule);

		hide();
	}

	public void load_defaults() {
		var settings = ((GHWHApplication)((MainWindow)get_toplevel()).application).settings;

		lat_neg.active = settings.get_boolean("lat-neg");
		lat_abs.value = settings.get_int("lat-abs");
		lon_neg.active = settings.get_boolean("lon-neg");
		lon_abs.value = settings.get_int("lon-abs");
	}

	[GtkCallback]
	private void save_defaults() {
		var settings = ((GHWHApplication)((MainWindow)get_toplevel()).application).settings;

		 settings.set_boolean("lat-neg", lat_neg.active);
		 settings.set_int("lat-abs", (int)lat_abs.value);
		 settings.set_boolean("lon-neg", lon_neg.active);
		 settings.set_int("lon-abs", (int)lon_abs.value);
	}

	[GtkCallback]
	private void globalhash_toggled() {
		latlon_container.sensitive = !globalhash_switch.active;
	}
}

