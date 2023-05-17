/* Date.vala
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
	 * Simple class for storing date-only information.
	 * Used to avoid passing year/month/day as three numbers.
	 *
	 * Lucky us don't need to care about timezones!
	 * It's assumed that date corresponds to whatever timezone hash is at.
	 *
	 * Yes, there *is* GLib's Date structure, but it's annoying for us to use.
	 * I probably should provide conversion functions tho.
	 */
	public class Date : Object {
		public int year { get; construct set; }
		public int month { get; construct set; }
		public int day { get; construct set; }

		public Date(int year, int month, int day)
		requires (new DateTime.utc(year, month, day, 0, 0, 0) != null)
		{
			Object(
				year: year,
				month: month,
				day: day
			);
		}

		public Date.from_string(string src) {
			string[] components = Regex.split_simple("-", src, 0, 0);
			assert(components.length == 3);
			this(int.parse(components[0]), int.parse(components[1]), int.parse(components[2]));
		}

		public string to_string() {
			return "%d-%02d-%02d".printf(year, month, day);
		}

		public void get_all(out int year, out int month, out int day) {
			year = this.year;
			month = this.month;
			day = this.day;
		}
	}
}

