#NBSoundCloudActivity
***
NBSoundCloudActivity is a simple subclass of UIActivity that allows you to post audio content to SoundCloud via the UIActivityViewController introduced in iOS 6. It wraps the SoundCloud sharing SDK to display a posting user interface and to actually send the data.

#Setup
***
First, clone or download the Git repository to your local disk.

The sample project uses [CocoaPods](http://www.cocoapods.org) to manage dependencies, so you'll need to install it and run the following command within the project root directory to get the dependent code

	pod install

Now you're ready to open the sample project and run it. Make sure you open the NBSoundCloudActivity.xcworkspace in order to get the Pods dependencies. Once you're satisfied, you can copy the code in "Source" into your own project. Keep in mind you'll also need the [SoundCloud SDK](https://github.com/soundcloud/CocoaSoundCloudAPI) dependencies in your own project as well.

#Usage
***
Using NBSoundCloudActivity couldn't be easier. All you have to do is create an instance using your SoundCloud API Client ID and Secret and pass it along to an instance of UIActivityViewController along with an AVURLAsset object representing the audio file you'd like to share. 

    NSURL* sampleURL = [[NSBundle mainBundle] URLForResource:@"sample" withExtension:@"caf"];
    AVURLAsset* asset = [AVURLAsset assetWithURL:sampleURL];
    
    NBSoundCloudActivity* scActivity = [[NBSoundCloudActivity alloc] initWithClientId:kSoundCloudClientId
    											secret:kSoundCloudClientSecret 
    											redirectURL:[NSURL URLWithString:@"myapp://soundcloudlogin"]];
    
    UIActivityViewController* avc = [[UIActivityViewController alloc] initWithActivityItems:@[asset]
                                                                      applicationActivities:@[scActivity]];
    avc.excludedActivityTypes = @[ UIActivityTypePostToWeibo, UIActivityTypeMessage, UIActivityTypeCopyToPasteboard ];
    
    [self presentViewController:avc animated:YES completion:nil];

iOS will present the user with a standard activity view where the user can select "SoundCloud" as an option and be brought through the standard SoundCloud sharing UI. 

#Contact
##Creators
This library was created and is maintained by Nick Bonatsakis.

[Nick Bonatsakis](http://nickbona.com)

[@nickbona](http://twitter.com/nickbona)

##Feedback
Feedback via suggestions or pull requests is strongly encouraged. Please do not submit any pull requests without accompanying unit tests. 

#License

NBSoundCloudActivity is available under the MIT license. See the LICENSE file for more info.