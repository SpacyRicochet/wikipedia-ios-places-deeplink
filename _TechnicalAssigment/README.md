# Introduction

This is a technical assignment, where we add a deeplink capability to the Wikipedia iOS app. The deeplink should open the Places tab and move it to the coordinates in the deeplink.
To prove this works, we make another tiny app which fetches a list of locations and allows the user to activate one to open the Wikipedia app at that location.

# Basic setup

* Main folder is based on the wikipedia-ios project, so we don't have to mess with any relative path shenanigans in the boot scripts.
* The _TechnicalAssessment folder will get any files that don't change the Wikipedia app.

# Log

## Exploring Wikipedia iOS

Since we're altering the Wikipedia app, we want to see what the app actually does, especially while it's starting up.
First off, it looks like we're getting an **onboarding experience**, which we can skip, so let's just do that.
After, it starts on the 'Explore' tab and loads the frontpage content.

If we then activate the 'Places' tab, we first get a location permission prompt. We can either 'Enable location' or skip this. For now, we select 'Enable location', since that could complicate moving to a coordinate in the app a bit and we should take that into account.
After giving our location permission, the app quickly zooms in to our current location and shows us an article about it and articles near it.

These prompts might be a potential issue, since they could obstruct moving and going to a specific location. Something to keep in mind.
## Getting started

### README.md

* Bootstrap scripts
  - Oh, Objective-C! Fun!
	- Project seems to run and test fine after using the script
	- Committing requires Ruby 3.0.5
* Looking through the app with a lot of 'Search project' for terms like 'universal link', 'deep link' and 'places'

Time spent: 30 minutes

## Adding coordinate support to deep links

Going through the app's code, it looks like there is already a specific user activity type for Places, which seems focused on a direct article link and is untested. 
Piggy-backing on this, we can add support and tests for a hypothetical Places deeplink that doesn't use an article link, but coordinates instead.

* We follow the convention for user info keys; `WMFLocation[Lat|Lon]`
* The `wikipedia://places` deeplink already goes to the Places tab
* Adding an article URL doesn't appear to do anything extra… maybe it's unimplemented, since it's also untested?
  - E.g. `wikipedia://places?WMFArticleURL=https://en.wikipedia.org/wiki/Leiderdorp`

- Time spent: 1h30m
- Commit: bb070f98dd8479690dd7ec05775d9fb11fcb4433

### Fight with pre-commit hook

There was a small struggle with the pre-commit hook, which assumes that homebrew installs stuff in the `/usr/local/bin`. Solved this by symlinking `clang-format` to the actual installation path.

Time spent: 15m

## Go to location coordinates

Doing a search on 'places' popped up the PlacesViewController and areas where it was called. Most notably, it showed how the view controller is called from the AppViewController when the Places activity is performed. 

In addition to the original activity with article URLs, we also check if there's a location in the activity. If so, we can call the PlacesViewController to show the map and immediately move to the specified location.
Some testing also shows that the app correctly handles any issues that might pop up during onboarding or when requesting location permission, so that's nice.

Apparently there are no tests for the WMFAppViewController, so we omit those from the assignment.

This feels like the work on the Wikipedia iOS app is finished. On towards making a Locations app!

* Side quest: to check is the article URL is added correctly to activity, we add a test.

- Time spent: 1h
- Commit: 6f4ed6da39f873f88e2793844acb56381e128f78
