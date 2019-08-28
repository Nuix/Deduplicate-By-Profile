Deduplicate by Profile
======================

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0) ![This script was last tested in Nuix 8.0](https://img.shields.io/badge/Script%20Tested%20in%20Nuix-8.0-green.svg)

View the GitHub project [here](https://github.com/Nuix/Deduplicate-By-Profile) or download the latest release [here](https://github.com/Nuix/Deduplicate-By-Profile/releases).

# Overview

This script provides a way to create an item set which is deduplicated by generating an MD5 for each item based on the concatenation of values yielded by a MetadataProfile for each item.

When creating an item set in Nuix using the API, the API provides a way to provide a custom expression.  This expression can be thought of as a function that is provided an item and is expected to provide back a value relating to that item.  The value returned is then used in place of the MD5 digest Nuix would have originally calculated for the item at the time of processing.

This script leverages the [ProfileDigester](https://nuix.github.io/SuperUtilities/com/nuix/superutilities/misc/ProfileDigester.html) class of [SuperUtilities](https://github.com/Nuix/SuperUtilities) to generate a custom MD5 digest by using the concatenated values yielded by a provided metadata profile for each item.

**Technical Note:** A concatentation of values is not actually used, instead for a given item each metadata profile field is evaluated against that item and each resulting string value is converted to a byte array and successively used to update the digest.  See code for [ProfileDigester.generateMd5Bytes](https://github.com/Nuix/SuperUtilities/blob/master/Java/src/main/java/com/nuix/superutilities/misc/ProfileDigester.java#L196) for more detail.

# Getting Started

## Setup

Begin by downloading the latest release of this code.  Extract the contents of the archive into your Nuix scripts directory.  In Windows the script directory is likely going to be either of the following:

- `%appdata%\Nuix\Scripts` - User level script directory
- `%programdata%\Nuix\Scripts` - System level script directory

# Usage

![image](https://user-images.githubusercontent.com/11775738/63889058-13bd6480-c995-11e9-9b7d-bf20b532bcf7.png)

1.) Choose the metadata profile to use.  The fields present in the selected metadata profile dictate which values are used to generate the custom MD5 digest.
2.) Choose whether the item's content text should be included when generating the custom MD5 digest.
3.) Choose the name of the item set.  If no item set with the provided name exists, one will be created.  If an item set with the given name does exist, items will be added to that item set.  **Important:** Adding items to an existing item set in which items were previously added using any other means or with this script but different settings (such as a different metadata profile) will produce undefined results.  If adding to an existing item set, make sure to use this script and the same settings each time!
4.) Choose whether deduplication is performed per item or per family.

# Cloning this Repository

This script relies on code from [Nx](https://github.com/Nuix/Nx) to present a settings dialog and progress dialog.  This JAR file is not included in the repository (although it is included in release downloads).  If you clone this repository, you will also want to obtain a copy of Nx.jar by either:
1. Building it from [the source](https://github.com/Nuix/Nx)
2. Downloading an already built JAR file from the [Nx releases](https://github.com/Nuix/Nx/releases)

Once you have a copy of Nx.jar, make sure to include it in the same directory as the script.

This script also relies on code from [SuperUtilities](https://github.com/Nuix/SuperUtilities).  This JAR file is not included in the repository (although it is included in release downloads).  If you clone this repository, you will also want to obtain a copy of SuperUtilities.jar by either:
1. Building it from [the source](https://github.com/Nuix/SuperUtilities)
2. Downloading an already built JAR file from the [SuperUtilities releases](https://github.com/Nuix/SuperUtilities/releases)

Once you also have a copy of SuperUtilities.jar, make sure to include it in the same directory as the script.

# License

```
Copyright 2019 Nuix

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
