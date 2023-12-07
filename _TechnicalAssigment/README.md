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

## Time for locations!

We're creating a small app called 'Wikipedia Locations' to list all the relevant places we want to view.
For ease of use, we make this as simple as we can;

* SwiftUI
* Tests
* Some tests
* Dependencies
	* [PointFree's swift-navigation](https://github.com/pointfreeco/swift-navigation)
  * [PointFree's swift-dependencies](https://github.com/pointfreeco/swift-dependencies)

The app will consist of a simple 'Fetch locations' button, which will attempt to fetch the JSON file. If successful the locations are shown in a list, and if the user activates one, it will open the Wikipedia app and navigate to that location in Places.

We depend some on PointFree modules, since those allow us to avoid a lot of annoying boilerplate while still creating a testable and previewable app.

## Quick prototype

We start by making a SwiftUI app. For now, we dump everything in the ContentView file and we focus on the three states the app will have;

1. **Idle**; nothing loaded yet
2. **Fetching**; the app is currently fetching locations
3. **Success**; the fetching succeeded and the app has a (hopefully) non-empty list of locations

In the idle state, we present one big button that will start the fetching. We display a progress indicator while fetching the locations. When the fetch completes, we show a list of all fetched locations.

* Looking at the [locations' JSON file](https://raw.githubusercontent.com/abnamrocoesd/assignment-ios/main/locations.json), we see that each location has an optional name and its coordinates as `lat` and `lon`. Because we want to leverage automatic Decodable for we keep this naming for the `Location` model struct. But because we like nice things, we make the original coordinates private and create a more useful `coordinates` model to retrieve the exact locations.
* We'll drive this app through a ViewModel, making the View itself as dumb as possible. The ViewModel itself is in charge of keeping track of the app's state and kicking off any requests over the wire. This will make our app testable as well, since we focus on the behavior of the view model itself.
* For now, tapping the fetch button immediately shows some test data, as opposed to fetching the JSON file. Tapping any of the locations will open the Wikipedia app at that location!
* Wrangling with vanilla SwiftUI `List` was a bit of a struggle, since that has been awhile. But we're back up to speed again.

Time spent: 2h30m
Commit: db059a27c88ab96c0d658e1c7e83d61d5ff60ba2

## Fetch the locations

We need to create a client that can fetch the locations so they can be presented to our user. Since this will be an dependency that we would like to stub for testing, we'll create a separate client that we inject into our app. To do this, we'll use the `swift-dependencies` framework, which gives us a useful way of managing simple dependencies.

We also make use of concurrency, since that simplifies our code immensely by avoiding the need for completion handlers. So nice!

* We create some order in our project chaos and move our object out of ContentView to proper folders that follow the MVVM pattern.
* The locations are fetched in our LocationsClient, which has injection values for…
  * … **Testing**; All tests fail if you forget to override the dependency.
	* … **Previews**; Since we want our previews to perform predictably, which means that the preview that starts from 'Idle' actually functions.
	* … **Live**; In production, we perform an actual call to fetch the locations. Since this all happens through Apple's API's, we don't treat URLSession and JSONDecoder as their own dependencies, but just call them directly.
	
In principle, this finishes up our technical assignment! However, there are still some things that we can adjust to make the code better; accessibility and tests.

Time spent: 1h
Commit: 08debd00b3a6750795bb5795ffe43f627858db52

## Testing the ViewModel

Next up, we want to test our ViewModel. Now, we have made our job easier with the use of stubbable dependencies. However, we made our job a lot harder by using concurrency, which is about as testable as a house cat. Luckily, PointFree did some work on this and provided a specific framework `swift-concurrency-extras` that helps with this.

* We make `Location` equatable for just the tests. That's strictly not necessary, but the impact is minimal.
* Still a bunch of weird code to get it tested, but it does work quite well.
* With inspiration from this episode of PointFree on [Reliable Async Testing](https://www.pointfree.co/episodes/ep241-reliable-async-tests)

Time spent: 45m
Commit: 9427c2235dd711219b68e69888ffcf6e3d98bfdb

## Error state

While fetching the locations, something could have gone wrong. We should tell the user what went wrong, to avoid confusion and potentially give options to remedy the situation. To achieve this, we'll expand the view model with an extra alert state. We'll keep things simple and show a simple alert with the localized error message.

* Showing errors in vanilla SwiftUI is pretty annoying. The solution to create an impromptu binding beats keeping another `isAlertPresented` value in the view model, in my opinion.
* Showing errors in other options—e.g. using AlertState from `swiftui-navigation`—isn't much better, so we'll keep the above approach.
* Another option would be to create another LocationState case `.failure(errorMessage: String)`, which is also valid. But because we're using a system alert dialog, I prefer the separate view model property.
* We also learned that the closure of `.refreshable` isn't automatically wrapped in a Task, leading to an immediate cancellation. Fixed that.

Time spent: 45m
Commit: 2252ed1399f3d2585e8c8554d2d2f2806b92e525

## Bug fix

There's a weird glitch in the refresh control of the list, where it won't slide up gracefully and wait. This is because we set the location state to `.fetching`, which immediately refreshes the entire screen and plays badly with the refresh control.

Since iOS shows us a nice progress indicator, we don't need to show the manual `.fetching` progress view. Instead, we refactor the code to avoid the regular fetching state.

* Fixes the UI glitch when refreshing.
* Needs additional tests for the View Model.

Time spent: 30min
Commit: b0f8dd38cb0312b3db3f12bfe2d1582bd0d44bd9

## Accessibility 🔥♿️🦾 — VoiceOver

Now that everything is finished and tested, let's perform an accessibility audit. For this assignment, we'll focus mostly on VoiceOver.

### Idle

Opening the app brings up the initial idle state. Considering that the only visible control a single button with a describing call to action, we're fine here.

### Fetching

The `.fetching` state however doesn't really work. There is no announcement to the user that the app is currently fetching the data. Instead, it just announces the activated button again for some reason. After fetching the data, it does focus on the first item in the list of locations. That is excellent.

Ideally we announce the loading as well. However, posting a `.announcement` notification doesn't appear to announce anything. Using `.layoutChanged` or `.screenChanged`, which would both be valid does work. But if you use those, instead of focusing on the first location in the list after fetching succeeds, VoiceOver will focus on the navigation bar title. So we lose the nice focus on the location cell.

In the end, we don't announce anything, as it's quick enough that the user doesn't really notice and the focus works better in the default situation.

### Success

The location cells could use some work. While visually the cells make sense, VoiceOver reads the GPS coordinates out verbatim without mentioning that it's the place's coordinates. It does announce that the cell is a button, but not what it does. The location without a name could also be announced somewhat nicer.

* Weirdly enough, VoiceOver doesn't announce the accessibility hint when it first focuses on the list's cell. Only after you focus on it manually.
* Apparently you can refresh the content by focusing on the list and performing a three finger swipe down. Nice!

Time spent: 45m
Commit: 7ec2dd93f70df61c7c9c7b88a7f26b588f538e62

## Entering a custom location

Whoops, almost missed the requirement that the user should be able to enter their own custom location as well. Let's work on that. Since there's no requirement for how the user should be able to input this custom location, we use a MapView for this.

* The MapView uses a deprecated initializer, since we know for certain how to use that with a binding for the coordinate region.
* MapView and VoiceOver are an interesting combination. Traversing a map is pretty complicated, and we haven't explored how to make custom controls on top of the map discoverable to VoiceOver.
* We also add a 'Reset' button to easily get back to the app's initial state.
* Since the accessibility escape gesture on alerts only works on the cancel action, we set the role the error dialog's dismiss button to `.cancel`.

Time spent: 2h 30m
Commit: 2f5b0d18ff4e038ab0244507e0e8b72159b37d96
