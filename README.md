# PhotoEditor

## Introduction

This feature of the BlaBlaCar iOS app enables the user to edit their profile photo in a very precise way. 
They can:
- rotate
- pinch (zoom in/out)
- move the photo to crop

## Installation

1. Download the source file
2. Set the configuration in the PhotoEditorConfig.h file :
  * PERCENT_SIZE_FOR_ROUND_INDICATOR constant to adjust the size of the crop zone
  * PERCENT_MIN_SCALE constant to adjust the minimum scale for zoom out
  * PERCENT_MAX_SCALE constant to adjust the maximum scale for zoom in
3. Add a UIView (with constraints to be more efficient ;))
4. Set the target class (PhotoEditorView)
5. Create an outlet of this view in your view controller
6. In the viewDidLoad method you can select the image to edit 

```
[self.photoEditorView setImage:myUIImageToEdit];
```

## Usage

### Rotation

```
[self.photoEditorView rotateToRight];
[self.photoEditorView rotateToLeft];
```

### Get the cropped image

```
UIImage *myFinalImage = [self.photoEditorView getFinalImage];
```
This will return a square image cropped from the original image according to the crop zone.


*N.B. The pinch and move functionalities are handled in the view itself. You don't need to override / implement delegate methods*