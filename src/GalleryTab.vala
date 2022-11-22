/* Galery.vala
 *
 * Copyright 2021 v1993 <v19930312@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * 	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

/*
 * A simple class for resizable image preview. Apparently, GTK+3 lacks one.
 * GTK4 allows to do this with Gtk.Image.
 * TODO: sort out styling stuff, we want to use background of Gtk.Image.
 * Optionally, make it resize image in thread. Will make UI 100% smooth even for stupid big ones.
 * Right now, it's reasonably usable (abeit somewhat laggy) even for the biggest image I've found on geohashing wiki.
 */

// Resize pixbuf to make it fit into box of specific size.
// If calculated scale is equal to scale_ex, return null.
// Pass negative scale if you don't have any yet.
Gdk.Pixbuf? fit_image_to_box(Gdk.Pixbuf source_image, int w, int h, ref double scale_ex) {
	double scale_x = (double)w / (double)source_image.width;
	double scale_y = (double)h / (double)source_image.height;

	double scale = double.min(scale_x, scale_y);

	if (scale == scale_ex)
		return null;
	scale_ex = scale;

	int target_width = (int)(source_image.width * scale);
	int target_height = (int)(source_image.height * scale);

	return source_image.scale_simple(target_width, target_height, Gdk.InterpType.BILINEAR);
}

internal class SimplePreview : Gtk.DrawingArea {
	construct {
		size_allocate.connect(on_size_allocate);
		style_updated.connect(reload_theme);
		realize.connect(force_redraw);
	}

	private void reload_theme() {
		icon_theme = Gtk.IconTheme.get_default();
		if (source_image == null) {
			force_redraw();
		}
	}

	void on_size_allocate(Gtk.Allocation alloc) {
		prepare_resize(alloc.width, alloc.height);
	}

	private Gdk.Pixbuf? source_image_;
	private string? icon_;

	public string? icon {
		get { return icon_; }
		set {
			icon_ = value;
			source_image_ = null;
			force_redraw();
		}
	}

	public Gdk.Pixbuf? source_image {
		get { return source_image_; }
		set {
			source_image_ = value;
			icon_ = null;
			force_redraw();
		}
	}

	private void force_redraw() {
			scale_old = -1;
			prepare_resize();
			queue_draw();
	}

	private Gdk.Pixbuf? scaled_image;
	private double scale_old = -1;
	private Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default();

	private void prepare_resize(int w = get_allocated_width(), int h = get_allocated_height()) {
		if (source_image != null) {
			scaled_image = fit_image_to_box(source_image, w, h, ref scale_old) ?? scaled_image;
		} else {
			int size = int.min(w, h);
			try {
				scaled_image = icon_theme.load_icon(icon ?? "image-missing", size, 0);
			} catch(GLib.Error e) {
				// Not much we can do, really
				scaled_image = null;
			}
		}
	}

	public override bool draw (Cairo.Context cr) {
		if (scaled_image != null) {
			Gdk.cairo_set_source_pixbuf(cr, scaled_image,
				(get_allocated_width() - scaled_image.width) / 2,
				(get_allocated_height() - scaled_image.height) / 2
			);
			cr.paint();
		}
		return false;
	}
}

errordomain GalleryTabError {
	UPLOAD_ERROR,
}

enum UploadedListColumns {
	NAME,
	DESCRIPTION,
	WIKI_NAME,
	ICON
}

const int gallery_icon_size = 128;

enum GalleryDragTypes {
	TEXT_PLAIN,
	TEXT_URI_LIST,
}

[GtkTemplate (ui = "/org/v1993/geohashingwikihelper/GalleryTab.ui")]
public class GalleryTab : Gtk.Paned {
	[GtkChild]
	private unowned Gtk.Button upload_button;
	[GtkChild]
	private unowned Gtk.Container uploading_part_container;
	[GtkChild]
	private unowned Gtk.Entry filename;
	[GtkChild]
	private unowned Gtk.Entry description;
	[GtkChild]
	private unowned Gtk.FileChooserButton file_chooser;
	[GtkChild]
	private unowned Gtk.Stack preview_stack;

	[GtkChild]
	private unowned Gtk.ListStore uploaded_gallery_list;
	[GtkChild]
	private unowned Gtk.IconView uploaded_gallery;

	[GtkChild]
	private unowned Gtk.Button gallery_export_button;
	[GtkChild]
	private unowned Gtk.Button gallery_clear_button;

	private SimplePreview image_preview;

	private Bytes? image_file_data = null; //< File as loaded from disk
	private string? image_file_type = null;
	private Gdk.Pixbuf? image = null; // Content of current file, decoded

	public bool valid_image_selected { get; private set; }

	construct {
		image_preview = new SimplePreview();
		preview_stack.add(image_preview);
		image_preview.show();
		preview_stack.visible_child = image_preview;

		uploaded_gallery.text_column = UploadedListColumns.DESCRIPTION;
		uploaded_gallery.pixbuf_column = UploadedListColumns.ICON;
		uploaded_gallery.item_width = gallery_icon_size;

		notify["valid-image-selected"].connect(update_upload_button_sensitivity);

		var target_list = new Gtk.TargetList(null);
		target_list.add_uri_targets(GalleryDragTypes.TEXT_URI_LIST);
		target_list.add_text_targets(GalleryDragTypes.TEXT_PLAIN);
		Gtk.drag_dest_set(preview_stack, ALL, null, COPY);
		Gtk.drag_dest_set_target_list(preview_stack, target_list);

		preview_stack.drag_data_received.connect(preview_stack_drag_data_received);
	}

	private void preview_stack_drag_data_received(Gtk.Widget widget, Gdk.DragContext context, int x, int y, Gtk.SelectionData data, uint type, uint drag_time) {
		file_chooser.drag_data_received(context, x, y, data, type, drag_time);
	}

	[GtkCallback]
	private void update_upload_button_sensitivity() {
		upload_button.sensitive = valid_image_selected && filename.text_length > 0;
	}

	private void set_gallery_actions_sensitivity(bool sensitive) {
		gallery_export_button.sensitive = sensitive;
		gallery_clear_button.sensitive = sensitive;
	}

	async void load_image(File file) {
		try {
			var info = yield file.query_info_async("standard::content-type", GLib.FileQueryInfoFlags.NONE);
			image_file_type = info.get_content_type();
			image_file_data = yield file.load_bytes_async(null, null);
			var istream = new MemoryInputStream.from_bytes(image_file_data);
			image = yield new Gdk.Pixbuf.from_stream_async(istream);
		} catch (Error err) {
			image_file_type = null;
			image_file_data = null;
			image = null;
			image_preview.source_image = null;
			return;
		}
		// Success!
		valid_image_selected = true;
		image_preview.source_image = image;
	}

	[GtkCallback]
	private void file_selected(Gtk.FileChooserButton btn) {
		valid_image_selected = false;
		image_file_type = null;
		image_file_data = null;
		image = null;
		image_preview.icon = "view-refresh";
		load_image.begin(btn.get_file());
		filename.grab_focus();
	}

	private string? extension_from_mime_type(string mtype) {
		switch (mtype) {
			case "image/png":
				return "png";
			case "image/jpeg":
				return "jpg";
			default:
				return null;
		}
	}

	// true - success, txtres gets set to actual filename
	// false - warning, txtres gets set to filekey
	// throws error - failure
	// This API is horrible, I know.
	private bool checkUploadResult(Json.Node json, out string txtres) throws GLib.Error {
		var reader = new Json.Reader(json);

		// Step 1: check if there was an error
		{
			if (reader.read_member("error")) {
				string errinfo;
				if (reader.read_member("info")) {
					errinfo = reader.get_string_value();
				} else {
					errinfo = "unknown API error"; // FIXME: I18N
				}
				reader.end_member();
				throw new GalleryTabError.UPLOAD_ERROR(errinfo);
			}
			reader.end_member();
		}

		// Step 2: check for warnings
		string result;
		if (reader.read_member("upload")) {
			if (reader.read_member("result")) {
				result = reader.get_string_value();
			} else {
				throw new GalleryTabError.UPLOAD_ERROR("unable to parse upload result: `upload.result` missing"); // FIXME: I18N
			}
			reader.end_member();

			switch(result) {
				case "Success":
					if (reader.read_member("filename")) {
						txtres = reader.get_string_value();
					} else {
						throw new GalleryTabError.UPLOAD_ERROR("unable to parse upload result: `upload.filename` missing"); // FIXME: I18N
					}
					reader.end_member();
					return true;
				case "Warning":
					if (reader.read_member("filekey")) {
						txtres = reader.get_string_value();
					} else {
						throw new GalleryTabError.UPLOAD_ERROR("unable to parse upload result: `upload.filekey` missing"); // FIXME: I18N
					}
					reader.end_member();
					return false;
				default:
					throw new GalleryTabError.UPLOAD_ERROR("unable to parse upload result: unknown result '%s'", result);
			}
		} else {
			// What the hell?
			throw new GalleryTabError.UPLOAD_ERROR("unable to parse upload result: `upload` missing"); // FIXME: I18N
		}
		// Unreachable
		// reader.end_member();
	}

	[GtkCallback]
	private async void upload() {
		try {
			// Part 1: prepare and perform upload
			uploading_part_container.sensitive = false;
			var geohash = new GHWHApplication().current_hash;
			var wiki = new GHWHApplication().wiki;
			string filename = @"$(geohash.to_string()) $(filename.text).$(extension_from_mime_type(image_file_type))";

			var desc = new StringBuilder();
			// Website uploading adds this regardless of description presence. Just replicate its behavior.
			desc.append("== Summary ==\n");
			if (description.text != "") {
				desc.append(description.text);
				desc.append_c('\n');
			}
			desc.append(geohash.to_file_tags());

			// Uncomment this and comment out entire part 2 when testing
			// string wiki_filename = "WIKI_FILENAME.png";

			// Send request
			var json = yield wiki.upload_file(filename, image_file_type, image_file_data, desc.str);

			// Part 2: parse upload result
			string wiki_filename;
			{
				bool result = checkUploadResult(json, out wiki_filename);
				if (!result) {
					// Upload paused with a warning

					var dialog = new Gtk.MessageDialog((Gtk.Window)get_toplevel(),
								 Gtk.DialogFlags.DESTROY_WITH_PARENT,
								 Gtk.MessageType.WARNING,
								 Gtk.ButtonsType.YES_NO,
								 """Upload paused with a warning. It's most likely that this image was already uploaded, under the same or different name.
Are you sure you want to continue?""" // FIXME: I18N
					);

					var res = (Gtk.ResponseType)dialog.run();
					dialog.destroy();

					if (res == YES) {
						json = yield wiki.complete_stashed_upload(filename, wiki_filename, desc.str);
						assert(checkUploadResult(json, out wiki_filename));
					} else {
						return;
					}
				}
			}

			// Part 3: add file to the gallery
			{
				double scale = -1;
				var icon = fit_image_to_box(image_preview.source_image, gallery_icon_size, gallery_icon_size, ref scale);
				Gtk.TreeIter iter;
				uploaded_gallery_list.insert_with_values(out iter, -1,
														 UploadedListColumns.NAME, this.filename.text,
														 UploadedListColumns.DESCRIPTION, this.description.text,
														 UploadedListColumns.WIKI_NAME, wiki_filename,
														 UploadedListColumns.ICON, icon);
			}

			// Part final: reset all fields to indicate that upload was completed
			valid_image_selected = false;
			image_file_type = null;
			image_file_data = null;
			image = null;
			image_preview.source_image = null;
			file_chooser.unselect_all();
			this.filename.text = "";
			this.description.text = "";
			set_gallery_actions_sensitivity(true);
		} catch (GLib.Error e) {
			var dialog = new Gtk.MessageDialog((Gtk.Window)get_toplevel(),
							 Gtk.DialogFlags.DESTROY_WITH_PARENT,
							 Gtk.MessageType.ERROR,
							 Gtk.ButtonsType.OK,
							 "Upload error: %s", // FIXME: I18N?
							 e.message
			);
			dialog.run();
			dialog.destroy();
			return;
		} finally {
			uploading_part_container.sensitive = true;
		}
	}

	[GtkCallback]
	private void export() {
		var builder = new StringBuilder();
		uploaded_gallery_list.foreach((model, path, iter) => {
			string name, desc;
			model.@get(iter, UploadedListColumns.WIKI_NAME, out name, UploadedListColumns.DESCRIPTION, out desc);

			builder.append("Image:");
			builder.append(name);

			if (desc.length > 0) {
				builder.append(" | ");
				builder.append(desc);
			}

			builder.append_c('\n');

			return false;
		});

		var dialog = new TextListingDialog(builder.str, (Gtk.Window)get_toplevel());
		dialog.set_title("Gallery for export"); // FIXME: I18N
		dialog.run();
		dialog.destroy();
	}

	[GtkCallback]
	private void clear_gallery() {
		var dialog = new Gtk.MessageDialog((Gtk.Window)get_toplevel(),
					 Gtk.DialogFlags.DESTROY_WITH_PARENT,
					 Gtk.MessageType.WARNING,
					 Gtk.ButtonsType.YES_NO,
					 """Are you sure you want to clear gallery?
Note that it won't remove files from server side.""" // FIXME: I18N
		);

		var res = (Gtk.ResponseType)dialog.run();
		dialog.destroy();

		if (res == YES) {
			uploaded_gallery_list.clear();
			set_gallery_actions_sensitivity(false);
		}
	}
}
