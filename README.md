# Experiments about CocoaTouch and Catalyst.

This repository contains my experiments about CocoaTouch and Catalyst. It helps me to understand certain, *potentially poorly documented*, concepts. Feel free to use it if you find anything interesting.

Something to bear in mind:

- Since this is a collection of *self-contained* experiments, I avoid using any dependencies. If I must use one, I will always resort to Swift Packages.
- I use Catalyst whenever possible. Demos might not work properly on iOS simulators.
- I use AutoLayout almost exclusively. They are actually easy and fun, especially if you create them programmatically.
- I never use Storyboards. The default template I use is the single view app using SwiftUI. I will then changing the root view controller in the scene delegate.

## Dynamic Key Command

**Added**: 2020/05/21.

**Description**. The project helps me to explore the use of key commands, in particular mixing them with the Cocoa text input system.

Two commands are registered (Arrow Up and Down) to control a counter. They can only be used when a text view is in focus and the character count is even. The condition is maintained by overriding `canPerformAction`. 

**Result**. It works very well. When key commands are available, it will take precedence over the default caret navigation behavior. When they are not, one can manipulate the caret as usual.

