/* main.vala
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

[SingleInstance]
public class GHWHApplication : Gtk.Application {
	private Geohashing.SpecificHash? current_hash_real = null;
	public MediaWiki wiki;
	public GLib.File config_directory;
	public GLib.Settings settings;
	public MainWindow main_window;
	public Geohashing.SpecificHash? current_hash {
		get { return current_hash_real; }
		set {
			this.current_hash_real = value;
			main_window.on_hash_changed();
		}
	}

	public GHWHApplication() {
		Object(
			application_id: "org.v1993.geohashingwikihelper",
			flags: ApplicationFlags.FLAGS_NONE
		);
	}

	public override void startup() {
		base.startup();

		settings = new GLib.Settings(application_id);

		config_directory = GLib.File.new_build_filename(GLib.Environment.get_user_config_dir(), "GeohashingWikiHelper");
		try {
			config_directory.make_directory_with_parents();
		} catch (GLib.IOError.EXISTS e) {
			// Not an error
		} catch (GLib.Error e) {
			print(@"Warning: failed to create config directory: $(e.message)");
		}

		var cookie_jar = new Soup.CookieJarDB (config_directory.get_child("cookies.db").get_path(), false);
		wiki = new MediaWiki("https://geohashing.site/api.php", cookie_jar);
	}

	public override void activate() {
		if (main_window == null) {
			main_window = new MainWindow(this);
		}
		main_window.present();
	}
}

int main (string[] args) {
	var app = new GHWHApplication();
	return app.run(args);
}
