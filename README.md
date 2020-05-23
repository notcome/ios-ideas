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

## Auto Layout Based Virtualized List

**Added**: 2020/05/23.

**Description**. A virtualized list is a list that only maintains a list of cells visible to the user. This brings significant performance boost to Cocoa, and even modern browsers can benefit from it when DOM nodes get too many. The project aims to produce such a list with:

- Auto Layout, so that we get self-sizing cells for free.
- No use of `systemLayoutSizeFitting`, which, according to WWDC 2018 talk “High Performance Auto Layout”, creates a new layout engine, computes the layout, and discards the engine.

**Setup**. For simplicity, I use a `UIStackView` to manage the list of cells on screen. Every one second, all visible cells get reassigned with a new random height. Two dummy views are added, one above and one below the stack view, with two height constraints attached to each. Whenever we need to layout subviews due to either a scroll event or cell size changes, contents inside the stack view are updated (unnecessary ones removed and missing ones inserted), and so are the two height constraints.

**Result**. The code mostly works, but I am not very confident if my approach is correct or has optimal performance.

When cell sizes change, I wait until stack view’s first layout pass is done before I update the list of visible cells, for otherwise we cannot get accurate latest cell bounds. To avoid unnecessary re-run the algorithm, I choose to override `layoutSubviews` for `UIStackView` and calls `setNeedsLayout` on the container view after `UIStackView` finishes its own work.

This might cause the list update algorithm to execute for a few times, but it should stabilize very soon. Here is one example:

```
About to update cell sizes.
Cell layout done for cell 8.
Cell layout done for cell 7.
Cell layout done for cell 6.
Cell layout done for cell 5.
Cell layout done for cell 4.
Cell layout done for cell 3.
Cell layout done for cell 2.
Cell layout done for cell 1.
Cell layout done for cell 0.
Following cells have sizes invalidated: [1, 5, 7, 2, 4, 6, 3, 8, 0]
Following cells are removed and inserted, respectively: [7, 6, 8], []
Visible cells afterwards: [0, 1, 2, 3, 4, 5].
About to update cell sizes.
```

Notice that since cells are removed, `UIStackView` will gets its `layoutSubviews` called again, but since there is no change to the list of visible cells, no log is produced, and we can confidently say that this thing stabilizes.

Here is one worrisome example, my guess is that 6 has a dirty size, which triggers itself to be immediately updated. I am slightly confused about why `layoutSubviews` for cell 6 is executed after any cell list update. My not-so-educated guess would be that cell 6 has its bounds updated already and this method merely layout its subviews.

```
About to update cell sizes.
Cell layout done for cell 5.
Cell layout done for cell 4.
Cell layout done for cell 3.
Cell layout done for cell 2.
Cell layout done for cell 0.
Following cells have sizes invalidated: [5, 4, 2, 3, 0]
Following cells are removed and inserted, respectively: [], [6]
Visible cells afterwards: [0, 1, 2, 3, 4, 5, 6].
Following cells have sizes invalidated: [6]
Following cells are removed and inserted, respectively: [], []
Visible cells afterwards: [0, 1, 2, 3, 4, 5, 6].
Cell layout done for cell 6.
```

