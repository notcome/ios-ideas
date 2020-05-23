import UIKit

let acceptableSizes: [CGFloat] = [50, 100, 150, 200]

class Size {
    var value: CGFloat = acceptableSizes[0]
    func step() {
        value = acceptableSizes.randomElement()!
    }
}

class Cell: UIView {
    var id: Int! {
        didSet {
            if let id = id {
                label.text = "\(id)"
            }
        }
    }
    var size: Size!
    var heightConstraint: NSLayoutConstraint!

    let label = UILabel()
    var labelConstraints: [NSLayoutConstraint]?

    override func updateConstraints() {
        if labelConstraints == nil {
            label.translatesAutoresizingMaskIntoConstraints = false
            var constraints = [NSLayoutConstraint]()
            constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", metrics: nil, views: ["view": label])
            constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", metrics: nil, views: ["view": label])
            NSLayoutConstraint.activate(constraints)
            labelConstraints = constraints
        }

        if let constraint = heightConstraint {
            constraint.constant = self.size.value
        } else {
            heightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: size.value)
            addConstraint(heightConstraint)
        }

        super.updateConstraints()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(label)
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .title1)
        backgroundColor = .systemPink
    }

    required init?(coder: NSCoder) {
        return nil
    }

    private var timer: Timer?

    func attach(id: Int, size: Size) {
        self.id = id
        self.size = size
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        print("Cell layout done for cell \(id!).")
    }
}

class RootViewController: UIViewController {
    let scrollView = UIScrollView()
    let listView = HackedView()
    let topView = UIView()
    let bottomView = UIView()
    var topHeightConstraint: NSLayoutConstraint!
    var bottomHeightConstraint: NSLayoutConstraint!

    func configureHierarchy() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        for view in [listView, topView, bottomView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(view)
        }

        let views = ["scroll": scrollView, "list": listView, "top": topView, "bottom": bottomView]
        var constraints = [NSLayoutConstraint]()
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[scroll]-|", metrics: nil, views: views)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|[scroll]|", metrics: nil, views: views)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[list]|", metrics: nil, views: views)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[top]|", metrics: nil, views: views)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[bottom]|", metrics: nil, views: views)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-[top][list][bottom]-|", metrics: nil, views: views)
        constraints.append(NSLayoutConstraint(item: scrollView, attribute: .width, relatedBy: .equal, toItem: listView, attribute: .width, multiplier: 1, constant: 0))
        NSLayoutConstraint.activate(constraints)

        scrollView.contentInsetAdjustmentBehavior = .never

        listView.axis = .vertical
        listView.alignment = .fill
        listView.distribution = .fill
        listView.spacing = 8

        topHeightConstraint = NSLayoutConstraint(item: topView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: 0)
        topView.addConstraint(topHeightConstraint)
        bottomHeightConstraint = NSLayoutConstraint(item: bottomView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: 0)
        bottomView.addConstraint(bottomHeightConstraint)
    }

    var sizes = (0..<100).map { _ in Size() }
    // Intentionally wrong initial estimates.
    var cachedSizes = Array(repeating: CGFloat(25), count: 100)
    var visibleCells = [Int: Cell]()
    var pool = Set<Cell>()

    func nextCell() -> Cell {
        if let first = pool.popFirst() {
            return first
        }
        return Cell()
    }

    var visualOffset: (Int, CGFloat)?

    func updateVisibleCells() {
        let top = scrollView.contentOffset.y
        let bottom = top + scrollView.bounds.height

        struct Changes {
            var invalidatedCachedSizes = [Int]()
            var insertedIndices = [Int]()
            var removedIndices = [Int]()

            var isEmtpy: Bool {
                invalidatedCachedSizes.count == 0 && insertedIndices.count == 0 && removedIndices.count == 0
            }
        }
        var changes = Changes()

        for (index, cell) in visibleCells {
            if cachedSizes[index] != cell.bounds.height {
                changes.invalidatedCachedSizes.append(index)
            }
            cachedSizes[index] = cell.bounds.height
        }

        var visibleIndices = [Int]()
        var current: CGFloat = 0
        for (i, size) in cachedSizes.enumerated() {
            let cellTop = current
            let cellBottom = current + size
            defer {
                current = cellBottom + 8
            }

            if cellTop > bottom {
                break
            }

            if cellBottom >= top && cellTop <= bottom {
                visibleIndices.append(i)
            }
        }

        let sortedIndicesToInsert = visibleIndices.filter { visibleCells[$0] == nil }
        changes.insertedIndices.append(contentsOf: sortedIndicesToInsert)

        visibleCells = visibleCells.filter { (index, cell) in
            guard !visibleIndices.contains(index) else { return true }
            changes.removedIndices.append(index)
            listView.removeArrangedSubview(cell)
            cell.removeFromSuperview()
            pool.insert(cell)
            return false
        }

        for index in sortedIndicesToInsert {
            let cell = nextCell()
            cell.attach(id: index, size: sizes[index])
            let indexInVisibleCells = visibleIndices.firstIndex(of: index)!
            listView.insertArrangedSubview(cell, at: indexInVisibleCells)
            visibleCells[index] = cell
        }

        func heightSum(for range: Range<Int>) -> CGFloat {
            var sum: CGFloat = 0
            for size in cachedSizes[range] {
                sum += size + 8
            }
            return sum
        }

        topHeightConstraint.constant = heightSum(for: 0..<visibleIndices.first!)
        bottomHeightConstraint.constant = heightSum(for: visibleIndices.last! + 1..<sizes.count)

        if !changes.isEmtpy {
            print("Following cells have sizes invalidated: \(changes.invalidatedCachedSizes)")
            print("Following cells are removed and inserted, respectively: \(changes.removedIndices), \(changes.insertedIndices)")
            print("Visible cells afterwards: \(visibleIndices).")
        }

        if let visualOffset = self.visualOffset {
            let (index, cellOffset) = visualOffset
            let before = heightSum(for: 0..<index)
            scrollView.contentOffset.y = cellOffset + before
        } else {
            let index = visibleIndices[0]
            let before = heightSum(for: 0..<index)
            let cellOffset = scrollView.contentOffset.y - before
            visualOffset = (index, cellOffset)
        }
    }

    var timer: Timer!

    override func viewDidLoad() {
        configureHierarchy()
        updateVisibleCells()

        scrollView.delegate = self

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            print("About to update cell sizes.")
            for cell in self.visibleCells.values {
                cell.size.step()
                cell.setNeedsUpdateConstraints()
            }
        }
    }
}

extension RootViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        visualOffset = nil
        let spaceLeft = scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.bounds.height
        print("Scrolled to \(scrollView.contentOffset.y), space left: \(spaceLeft)")
        updateVisibleCells()
    }

    override func viewDidLayoutSubviews() {
        updateVisibleCells()
    }
}

extension UIResponder {
    var rootViewController: RootViewController? {
        if let casted = self as? RootViewController {
            return casted
        }
        return next?.rootViewController
    }
}

class HackedView: UIStackView {
    override func layoutSubviews() {
        super.layoutSubviews()
        // A dirty way to notify the view controller.
        rootViewController?.view.setNeedsLayout()
    }
}
