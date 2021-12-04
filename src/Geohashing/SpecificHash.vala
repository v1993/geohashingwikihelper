/* SpecificHash.vala
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
 * Describes specific hash, that is, date and graticule.
 * Only accepts pre-created objects because of ton of parameters.
 * Consider encoding it as string or passing object around.
 */

namespace Geohashing {
	public class SpecificHash : Object {
		public Date date { get; construct set; }
		public Graticule graticule { get; construct set; }

		public SpecificHash(Date date, Graticule graticule)
		{
			Object(date: date, graticule: graticule);
		}

		public SpecificHash.from_string(string src) {
			string[] components = Regex.split_simple(" ", src, 0, 0);
			Date date = new Date.from_string(components[0]);
			Graticule gr;

			if (components.length == 2) {
				// Globalhash
				assert(components[1] == "global");
				gr = new Graticule.globalhash();
			} else {
				assert(components.length == 3);
				gr = new Graticule.from_components(components[1], components[2]);
			}

			this(date, gr);
		}

		public string to_string() {
			return @"$(date.to_string()) $(graticule.to_string())";
		}

		public string to_file_tags() {
			var tags = new StringBuilder();
			{
				tags.append("[[Category: Meetup on ");
				tags.append(date.to_string());
				tags.append("]]");
			}
			tags.append_c('\n');
			if (graticule.is_globalhash) {
				tags.append("[[Category: Globalhash]]");
			} else {
				tags.append("[[Category: Meetup in ");
				tags.append(graticule.to_string());
				tags.append("]]");
			}

			return tags.str;
		}
	}
}
