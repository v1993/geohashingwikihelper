/* Graticule.vala
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

namespace Geohashing {
	/**
	 * Represents graticule. Needs all this fancy handling because of simple
	 * reason: existence of negative zero graticules.
	 *
	 * Special flag is used to represent globalhashes. Ignore all other fields if it is set.
	 */
	public class Graticule : Object {
		public bool is_globalhash { get; construct set; default = false; }

		public bool negative_lat { get; construct set; }
		public int absolute_lat { get; construct set; }
		public bool negative_lon { get; construct set; }
		public int absolute_lon { get; construct set; }

		public Graticule(bool negative_lat, int absolute_lat, bool negative_lon, int absolute_lon)
		requires (absolute_lat >= 0 && absolute_lat < 90)
		requires (absolute_lon >= 0 && absolute_lon < 180)
		{
			// Now THIS is annoying
			Object(
				negative_lat: negative_lat,
				absolute_lat: absolute_lat,
				negative_lon: negative_lon,
				absolute_lon: absolute_lon
			);
		}

		public Graticule.globalhash() {
			Object(is_globalhash: true);
		}

		public Graticule.from_components(owned string latstr, owned string lonstr) {
			if (latstr[0] == '-') {
				negative_lat = true;
				latstr = latstr[1:];
			}
			absolute_lat = int.parse(latstr);
			assert(absolute_lat >= 0 && absolute_lat < 90);

			if (lonstr[0] == '-') {
				negative_lon = true;
				lonstr = lonstr[1:];
			}
			absolute_lon = int.parse(lonstr);
			assert(absolute_lon >= 0 && absolute_lon < 180);
		}

		public Graticule.from_string(string src) {
			string[] components = Regex.split_simple(" ", src, 0, 0);
			assert(components.length == 2);
			this.from_components(components[0], components[1]);
		}

		public string to_string() {
			if (is_globalhash) {
				return "global";
			} else {
				return @"$(negative_lat ? "-" : "")$(absolute_lat) $(negative_lon ? "-" : "")$(absolute_lon)";
			}
		}
	}
}
