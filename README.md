# Redmine Extended Export plugin [![Build Status](https://travis-ci.org/efigence/redmine_extended_export.svg?branch=master)](https://travis-ci.org/efigence/redmine_extended_export)

#### Plugin which gives extended issue exporting functionalties:

* export issues to `xlsx` format
* export subtasks and related issues ( `xlsx`, `csv` and `pdf`)
* export comments to a separate column (in `xlsx` and `csv`)
* export timelog (time entries) to more formats (`xlsx` and `pdf` added)

## Requirements

Developed and tested on Redmine 3.0.1.

## Installation

1. Go to your Redmine installation's plugins/ directory.
2. `git clone https://github.com/efigence/redmine_extended_export`
3. Restart Redmine.

## Usage

##### Issues page

* Link to export to `xlsx` should show up next to the `atom`, `csv` and `pdf` links

##### Single issue page

* If any subtasks and/or related issues exist, you'll see export links under the list.

##### Timelog page

* Export to `xlsx` and `pdf` formats available now.

## License

    Redmine Extended Export plugin
    Copyright (C) 2015  efigence S.A.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
