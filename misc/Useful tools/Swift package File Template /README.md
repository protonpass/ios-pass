#Template

This template was made to leverage the annoying base file templates of swift packages.

When creating a file in a swift package the basic template doesn't ask for a filename and just creates a `Files.swift` forcing us to rename it each time.

The following template overrides this problem and help create a named file in swift packages.

The template should be copied in the following folder:

```bash
~/Library/Developer/Xcode/Templates
```

If the `Templates` folders doesn't exist just create it and put the `xctemplate` folder in it.

Now when creating a new file in swift package just scroll down to the `Template` section and choose `Swift File`.

#Xcode Macro

There is also a `.plist` **configuration** to override Xcodes `FILEHEADER` `Text Macros` and set a custom header to your newly created files.

[Xcode Macros](https://help.apple.com/xcode/mac/9.0/index.html?localePath=en.lproj#/dev7fe737ce0)
The current macro references `Proton Pass` so you should tweak it if needed.

This plist can be used or not.
The following are some instruction on were to set it up depending on needs.

**Text Macro File Locations**

Once you have your new text macro file move it to the right location. 
You can override the text macros globally, or for an individual workspace or project. 
You can also decide to keep the macros for a single user or share it for all users.

The full list of locations that Xcode searches, in order of priority:

**Project - single user**
<ProjectName>.xcodeproj/xcuserdata/[username].xcuserdatad/

**Project - shared by all users**
<ProjectName>.xcodeproj/xcshareddata/

**Workspace - single user**
<WorkspaceName>.xcworkspace/xcuserdata/[username].xcuserdatad/

**Workspace - shared by all users**
<WorkspaceName>.xcworkspace/xcshareddata/

**Globally for Xcode**
~/Library/Developer/Xcode/UserData/

So you might create a default IDETemplateMacros.plist in ~/Library/Developer/Xcode/UserData/ and then override it with a project specific template created at the workspace or project level.

Note: You may need to create the xcshareddata folder if it does not already exist.
