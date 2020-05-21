import UIKit

class RootViewController: UIViewController {
    let status = UILabel()
    let label = UILabel()
    let textView = UITextView()

    var counter: Int = 0 {
        didSet {
            status.text = "\(counter)"
        }
    }

    @objc func decrCounter() {
        counter -= 1
    }

    @objc func incrCounter() {
        counter += 1
    }

    func updateLabel() {
        let respondable = canPerformAction(#selector(decrCounter), withSender: nil)
        label.text = "\(respondable ? "Can" : "Cannot") respond."
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(decrCounter) || action == #selector(incrCounter) {
            guard textView.isFirstResponder else { return false }
            return textView.text.count % 2 == 0
        }

        return super.canPerformAction(action, withSender: sender)
    }

    func configureKeyCommands() {
        let decrCommand = UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(decrCounter))
        decrCommand.title = "Decrease Counter"
        addKeyCommand(decrCommand)
        let incrCommand = UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(incrCounter))
        incrCommand.title = "Increase Counter"
        addKeyCommand(incrCommand)
    }

    func configureHierarchy() {
        view.backgroundColor = .systemBackground

        for child in [status, label, textView] {
            view.addSubview(child)
            child.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[view]-|", metrics: nil, views: ["view": child]))
        }

        status.font = .preferredFont(forTextStyle: .largeTitle)
        status.textAlignment = .center
        status.text = "0"

        label.font = .preferredFont(forTextStyle: .largeTitle)
        label.textAlignment = .center

        textView.font = .preferredFont(forTextStyle: .largeTitle)
        textView.text = """
            Move up and down arrow key to change the counter.
            It can respond only if the following are satisfied:
            - this text view has an even amount of characters;
            - this text view is in focus.
            """

        updateLabel()

        let views = [
            "status": status,
            "label": label,
            "text": textView
        ]

        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[status(==200)]-[label(==200)]-[text]-|", metrics: nil, views: views))
    }

    override func viewDidLoad() {
        configureKeyCommands()
        configureHierarchy()

        textView.delegate = self
    }
}

extension RootViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateLabel()
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        updateLabel()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        updateLabel()
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        updateLabel()
    }
}
