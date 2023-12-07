# Introduction

This is a technical assignment, where we add a deeplink capability to the Wikipedia iOS app. The deeplink should open the Places tab and move it to the coordinates in the deeplink.
To prove this works, we make another tiny app which fetches a list of locations and allows the user to activate one to open the Wikipedia app at that location.

# Basic setup

* Main folder is based on the wikipedia-ios project, so we don't have to mess with any relative path shenanigans in the boot scripts.
* The _TechnicalAssessment folder will get any files that don't change the Wikipedia app.
  * The Wikipedia Locations app can be found in the folder with the same name.
	* [LOG.md](LOG.md) contains a comprehensive, chronological log on working through the assigment.

# Features

Following the assignment, the Wikipedia Locations app has the following features;

## Fetch locations

The app can fetch and show a list of locations from a specific, hardcoded URL.

// TODO: Drop video here

## Go to specific place in Wikipedia

Activating a location from the list will open the Wikipedia app on the 'Places' and zoom into the selected location.

// TODO: Drop video here

## Allow the user select a custom location

Using a map view, the user can select a custom location and open that in Wikipedia as well.

// TODO: Drop video here
