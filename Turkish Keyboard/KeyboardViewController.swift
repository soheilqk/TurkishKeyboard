//
//  KeyboardViewController.swift
//  TestKeyboardExtension
//
//  Created by Soheil on 6/1/25.
//

import UIKit

class KeyboardViewController: UIInputViewController {

    private var keyboardView: UIView!
    private var isNumberSymbolMode = false  // Main mode: false = Persian, true = Numbers/Symbols
    private var isSymbolMode = false        // Sub-mode within Numbers/Symbols: false = Numbers, true = Symbols
    private var alternativesPopup: UIView?
    
    // Turkish keyboard layout
    private let turkishKeys = [
        ["ض", "ص", "ق", "ف", "غ", "ع", "ه", "خ", "ح", "ج", "چ"],
        ["ش", "س", "ی", "ب", "ل", "ا", "ت", "ن", "م", "ک", "گ"],
        ["ظ", "ط", "ز", "ر", "ذ", "د", "پ", "و", "ث", "delete"]
    ]
    
    // Updated number keys to match the screenshot
    private let turkishNumberKeys = [
        ["۱", "۲", "۳", "۴", "۵", "۶", "۷", "۸", "۹", "۰"],
        ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""],
        [".", ",", "?", "!", "'", "\"", "delete"]
    ]
    
    // Updated symbol keys to match the screenshot
    private let turkishSymbolKeys = [
        ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="],
        ["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•"],
        [".", ",", "?", "!", "'", "\"", "delete"]
    ]
    
    // Character alternatives dictionary
    private let characterAlternatives: [String: [String]] = [
        "ی": ["ئ", "ي","ؽ"],
        "ا": ["آ","ء", "أ", "إ"],
        "و": ["ؤ","ۆ","ۇ","وْ"],
        "ن": ["ن", "ں"],
        "ک": ["ک", "ك"],
        "ه": ["هٔ", "ه", "ة"],
        "◌َُِ": ["◌َ", "◌ِ", "◌ُ"], // Diacritical marks with dotted circle for visibility
    ]
    
    // Mapping from display alternatives to actual insertion characters
    private let alternativeInsertionMap: [String: String] = [
        "◌َ": "َ",  // Fatha
        "◌ِ": "ِ",  // Kasra
        "◌ُ": "ُ"   // Damma
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboard()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    private func setupKeyboard() {
        // Remove any existing keyboard view
        keyboardView?.removeFromSuperview()
        
        keyboardView = UIView()
        keyboardView.backgroundColor = UIColor.systemGray5
        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(keyboardView)
        
        // Native iOS keyboard height is typically around 216-260 points
        NSLayoutConstraint.activate([
            keyboardView.topAnchor.constraint(equalTo: view.topAnchor),
            keyboardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            keyboardView.heightAnchor.constraint(equalToConstant: 208)
        ])
        
        createKeyboardLayout()
    }
    
    private func createKeyboardLayout() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        keyboardView.addSubview(stackView)
        
        // Adjust margins for native iOS keyboard appearance
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: keyboardView.topAnchor, constant: 6),
            stackView.leadingAnchor.constraint(equalTo: keyboardView.leadingAnchor, constant: 3),
            stackView.trailingAnchor.constraint(equalTo: keyboardView.trailingAnchor, constant: -3),
            stackView.bottomAnchor.constraint(equalTo: keyboardView.bottomAnchor, constant: -6)
        ])
        
        if isNumberSymbolMode {
            if isSymbolMode {
                createSymbolKeyboard(in: stackView)
            } else {
                createNumberKeyboard(in: stackView)
            }
        } else {
            createTurkishKeyboard(in: stackView)
        }
    }
    
    private func createTurkishKeyboard(in stackView: UIStackView) {
        // Create rows for Turkish keyboard
        for (rowIndex, row) in turkishKeys.enumerated() {
            let rowStackView = UIStackView()
            rowStackView.axis = .horizontal
            rowStackView.distribution = .fillEqually
            rowStackView.spacing = 6
            
            // Set native iOS button height (42 points)
            rowStackView.heightAnchor.constraint(equalToConstant: 42).isActive = true
            
            // Create buttons for each key in the row
            for key in row {
                let keyButton = createKeyButton(title: key, isSpecial: key == "delete")
                rowStackView.addArrangedSubview(keyButton)
            }
            
            stackView.addArrangedSubview(rowStackView)
        }
        
        // Create bottom row with proper sizing
        createBottomRow(in: stackView, showABC: false)
    }
    
    private func createNumberKeyboard(in stackView: UIStackView) {
        // Create rows for number keyboard
        for (rowIndex, row) in turkishNumberKeys.enumerated() {
            let rowStackView = UIStackView()
            rowStackView.axis = .horizontal
            rowStackView.distribution = .fillEqually
            rowStackView.spacing = 6
            rowStackView.heightAnchor.constraint(equalToConstant: 42).isActive = true
            
            if rowIndex == 2 {
                // Special handling for third row - add toggle button first, then all original keys
                let toggleButton = createKeyButton(title: "#+=", isSpecial: true)
                toggleButton.addTarget(self, action: #selector(toggleSymbolsInNumberMode), for: .touchUpInside)
                rowStackView.addArrangedSubview(toggleButton)
                
                // Add all original keys from the third row
                for key in row {
                    let keyButton = createKeyButton(title: key, isSpecial: key == "delete")
                    rowStackView.addArrangedSubview(keyButton)
                }
            } else {
                // Normal handling for first and second rows
                for key in row {
                    let keyButton = createKeyButton(title: key, isSpecial: key == "delete")
                    rowStackView.addArrangedSubview(keyButton)
                }
            }
            
            stackView.addArrangedSubview(rowStackView)
        }
        
        // Create bottom row with proper sizing
        createBottomRow(in: stackView, showABC: true)
    }
    
    private func createSymbolKeyboard(in stackView: UIStackView) {
        // Create rows for symbol keyboard
        for (rowIndex, row) in turkishSymbolKeys.enumerated() {
            let rowStackView = UIStackView()
            rowStackView.axis = .horizontal
            rowStackView.distribution = .fillEqually
            rowStackView.spacing = 6
            rowStackView.heightAnchor.constraint(equalToConstant: 42).isActive = true
            
            if rowIndex == 2 {
                // Special handling for third row - add toggle button first, then all original keys
                let toggleButton = createKeyButton(title: "۱۲۳", isSpecial: true)
                toggleButton.addTarget(self, action: #selector(toggleNumbersInSymbolMode), for: .touchUpInside)
                rowStackView.addArrangedSubview(toggleButton)
                
                // Add all original keys from the third row
                for key in row {
                    let keyButton = createKeyButton(title: key, isSpecial: key == "delete")
                    rowStackView.addArrangedSubview(keyButton)
                }
            } else {
                // Normal handling for first and second rows
                for key in row {
                    let keyButton = createKeyButton(title: key, isSpecial: key == "delete")
                    rowStackView.addArrangedSubview(keyButton)
                }
            }
            
            stackView.addArrangedSubview(rowStackView)
        }
        
        // Create bottom row with proper sizing
        createBottomRow(in: stackView, showABC: true)
    }
    
    private func createBottomRow(in stackView: UIStackView, showABC: Bool) {
        // Create bottom row with special keys and proper sizing
        let bottomRowStackView = UIStackView()
        bottomRowStackView.axis = .horizontal
        bottomRowStackView.distribution = .fill
        bottomRowStackView.alignment = .center
        bottomRowStackView.spacing = 6
        bottomRowStackView.heightAnchor.constraint(equalToConstant: 42).isActive = true
        
        if showABC {
            // ABC button to return to Turkish mode
            let abcButton = createKeyButton(title: "ABC", isSpecial: true)
            abcButton.addTarget(self, action: #selector(toggleToTurkishMode), for: .touchUpInside)
            bottomRowStackView.addArrangedSubview(abcButton)
            abcButton.widthAnchor.constraint(equalToConstant: 65).isActive = true
        } else {
            // Number/Symbol toggle button for Turkish mode
            let numberButton = createKeyButton(title: "۱۲۳", isSpecial: true)
            numberButton.addTarget(self, action: #selector(toggleToNumberSymbolMode), for: .touchUpInside)
            bottomRowStackView.addArrangedSubview(numberButton)
            numberButton.widthAnchor.constraint(equalToConstant: 65).isActive = true
        }
        
        // Half space button
        let halfSpaceButton = createKeyButton(title: "|", isSpecial: false)
        halfSpaceButton.addTarget(self, action: #selector(insertHalfSpace), for: .touchUpInside)
        bottomRowStackView.addArrangedSubview(halfSpaceButton)
        halfSpaceButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        // Space bar (much wider)
        let spaceButton = createKeyButton(title: "بوْشلۇق", isSpecial: false)
        spaceButton.addTarget(self, action: #selector(insertSpace), for: .touchUpInside)
        bottomRowStackView.addArrangedSubview(spaceButton)
        
        // Diacritical marks button
        let diacriticsButton = createKeyButton(title: "◌َُِ", isSpecial: true)
        bottomRowStackView.addArrangedSubview(diacriticsButton)
        diacriticsButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        // Return key
        let returnButton = createKeyButton(title: "←", isSpecial: true)
        returnButton.addTarget(self, action: #selector(insertReturn), for: .touchUpInside)
        bottomRowStackView.addArrangedSubview(returnButton)
        returnButton.widthAnchor.constraint(equalToConstant: 75).isActive = true
        
        stackView.addArrangedSubview(bottomRowStackView)
    }
    
    private func createKeyButton(title: String, isSpecial: Bool) -> UIButton {
        let button = UIButton(type: .system)
        
        // Ensure consistent height for all buttons
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 42).isActive = true
        
        // Prevent button from stretching vertically
        button.setContentHuggingPriority(.required, for: .vertical)
        button.setContentCompressionResistancePriority(.required, for: .vertical)
        
        if title == "delete" {
            // Delete button with backspace symbol
            let image = UIImage(systemName: "delete.left")
            button.setImage(image, for: .normal)
            button.tintColor = .label
            // Ensure image scales properly within button bounds
            button.imageView?.contentMode = .scaleAspectFit
            button.contentVerticalAlignment = .center
            button.contentHorizontalAlignment = .center
            button.addTarget(self, action: #selector(deleteBackward), for: .touchUpInside)
        } else {
            button.setTitle(title, for: .normal)
            // Ensure text is centered and properly aligned
            button.contentVerticalAlignment = .center
            button.contentHorizontalAlignment = .center
            
            // Only add keyPressed action for actual character keys, not special function keys
            let specialFunctionKeys = ["۱۲۳", "#+=", "ABC", "بوْشلۇق","|", "←", "◌َُِ"]
            if !specialFunctionKeys.contains(title) {
                button.addTarget(self, action: #selector(keyPressed(_:)), for: .touchUpInside)
            }
        }
        
        // Add long press gesture for character alternatives (only for non-special keys)
        if (!isSpecial && title != "delete" && characterAlternatives[title] != nil) ||
           (title == "◌َُِ") {
            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            longPressGesture.minimumPressDuration = 0.5
            button.addGestureRecognizer(longPressGesture)
        }
        
        // Native iOS keyboard button styling
        if isSpecial {
            button.backgroundColor = UIColor.systemGray3
            button.setTitleColor(.label, for: .normal)
        } else {
            button.backgroundColor = UIColor.white
            button.setTitleColor(.label, for: .normal)
        }
        
        // Native iOS keyboard button appearance with font size based on button type
        let smallerFontButtons = ["۱۲۳", "#+=", "ABC", "بوْشلۇق"]
        if smallerFontButtons.contains(title) {
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        } else {
            button.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .regular)
        }
        button.titleLabel?.textAlignment = .center
        button.layer.cornerRadius = 5
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 0.5
        
        // Ensure consistent content insets for all buttons
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        
        // Add press animation
        button.addTarget(self, action: #selector(keyHighlight(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(keyUnhighlight(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        return button
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard let button = gesture.view as? UIButton,
              let title = button.title(for: .normal),
              let alternatives = characterAlternatives[title] else { return }
        
        switch gesture.state {
        case .began:
            showAlternativesPopup(for: button, with: alternatives)
        case .changed:
            // Handle finger movement to select alternatives
            handleAlternativeHover(gesture: gesture)
        case .ended:
            // Select the currently hovered alternative
            selectCurrentHoveredAlternative(gesture: gesture)
            hideAlternativesPopup()
        case .cancelled, .failed:
            hideAlternativesPopup()
        default:
            break
        }
    }
    
    private func handleAlternativeHover(gesture: UILongPressGestureRecognizer) {
        guard let popup = alternativesPopup else { return }
        
        let location = gesture.location(in: view)
        
        // Find which alternative button is being hovered
        if let stackView = popup.subviews.first as? UIStackView {
            for (index, subview) in stackView.arrangedSubviews.enumerated() {
                guard let altButton = subview as? UIButton else { continue }
                
                let buttonFrame = altButton.convert(altButton.bounds, to: view)
                
                if buttonFrame.contains(location) {
                    // Highlight this button
                    highlightAlternative(at: index, in: stackView)
                    return
                }
            }
        }
        
        // If no button is hovered, highlight the first one (original character)
        if let stackView = popup.subviews.first as? UIStackView {
            highlightAlternative(at: 0, in: stackView)
        }
    }
    
    private func highlightAlternative(at index: Int, in stackView: UIStackView) {
        // Reset all buttons to normal state
        for (buttonIndex, subview) in stackView.arrangedSubviews.enumerated() {
            guard let altButton = subview as? UIButton else { continue }
            
            if buttonIndex == index {
                // Highlight the selected alternative
                UIView.animate(withDuration: 0.1) {
                    altButton.backgroundColor = UIColor.systemBlue
                    altButton.setTitleColor(.white, for: .normal)
                    altButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                }
            } else {
                // Normal state for other buttons
                UIView.animate(withDuration: 0.1) {
                    altButton.backgroundColor = UIColor.clear
                    altButton.setTitleColor(.label, for: .normal)
                    altButton.transform = CGAffineTransform.identity
                }
            }
        }
        
        // Store the currently selected index
        stackView.tag = index
    }
    
    private func selectCurrentHoveredAlternative(gesture: UILongPressGestureRecognizer) {
        guard let popup = alternativesPopup,
              let alternativesString = popup.accessibilityLabel,
              let stackView = popup.subviews.first as? UIStackView else { return }
        
        let alternatives = alternativesString.components(separatedBy: ",")
        let selectedIndex = stackView.tag // Get the currently highlighted index
        
        if selectedIndex < alternatives.count {
            let selectedCharacter = alternatives[selectedIndex]
            // Check if this character has a mapped insertion value (for diacritical marks)
            if let insertionCharacter = alternativeInsertionMap[selectedCharacter] {
                textDocumentProxy.insertText(insertionCharacter)
            } else {
                textDocumentProxy.insertText(selectedCharacter)
            }
        }
    }
    
    private func showAlternativesPopup(for button: UIButton, with alternatives: [String]) {
        // Remove any existing popup
        hideAlternativesPopup()
        
        // Create popup container with iOS-native styling
        let popup = UIView()
        popup.backgroundColor = UIColor.systemBackground
        popup.layer.cornerRadius = 12
        popup.layer.borderWidth = 0.5
        popup.layer.borderColor = UIColor.separator.cgColor
        popup.layer.shadowColor = UIColor.black.cgColor
        popup.layer.shadowOffset = CGSize(width: 0, height: 4)
        popup.layer.shadowOpacity = 0.25
        popup.layer.shadowRadius = 12
        popup.translatesAutoresizingMaskIntoConstraints = false
        
        // Ensure popup appears above all other views
        popup.layer.zPosition = 1000
        
        // Create horizontal stack view for alternatives
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 4
        stackView.tag = 0 // Initialize with first alternative selected
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create buttons for each alternative
        for (index, alternative) in alternatives.enumerated() {
            let altButton = UIButton(type: .system)
            altButton.setTitle(alternative, for: .normal)
            altButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .medium)
            altButton.setTitleColor(.label, for: .normal)
            altButton.tag = index
            
            // Highlight the main character initially
            if index == 0 {
                altButton.backgroundColor = UIColor.systemBlue
                altButton.setTitleColor(.white, for: .normal)
                altButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            } else {
                altButton.backgroundColor = UIColor.clear
            }
            
            altButton.layer.cornerRadius = 8
            stackView.addArrangedSubview(altButton)
        }
        
        popup.addSubview(stackView)
        
        // Add popup to view and ensure it's not clipped
        view.addSubview(popup)
        view.clipsToBounds = false // Allow popup to extend beyond view bounds if needed
        popup.clipsToBounds = false
        
        alternativesPopup = popup
        
        // Setup constraints
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: popup.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: popup.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: popup.trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: popup.bottomAnchor, constant: -8),
            stackView.heightAnchor.constraint(equalToConstant: 42)
        ])
        
        // Always position popup above the button, but ensure it stays within keyboard bounds
        let buttonFrame = button.convert(button.bounds, to: view)
        let popupWidth = CGFloat(alternatives.count * 38 + (alternatives.count - 1) * 4 + 16) // Added padding
        let popupHeight: CGFloat = 58 // 42 + 16 padding
        
        // Calculate horizontal position to keep popup within screen bounds
        let idealCenterX = buttonFrame.midX
        let minX = popupWidth / 2 + 8 // 8px margin from edge
        let maxX = view.bounds.width - popupWidth / 2 - 8
        let adjustedCenterX = max(minX, min(maxX, idealCenterX))
        
        // Calculate vertical position - always above the button, but ensure it fits within keyboard bounds
        let idealBottomY = buttonFrame.minY - 10
        let minBottomY = popupHeight + 8 // Ensure popup doesn't go beyond top of keyboard
        let adjustedBottomY = max(minBottomY, idealBottomY)
        
        NSLayoutConstraint.activate([
            popup.centerXAnchor.constraint(equalTo: view.leadingAnchor, constant: adjustedCenterX),
            popup.widthAnchor.constraint(equalToConstant: popupWidth),
            popup.bottomAnchor.constraint(equalTo: view.topAnchor, constant: adjustedBottomY)
        ])
        
        // Animate popup appearance
        popup.alpha = 0
        popup.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        UIView.animate(withDuration: 0.2) {
            popup.alpha = 1
            popup.transform = CGAffineTransform.identity
        }
        
        // Store alternatives for selection
        popup.accessibilityLabel = alternatives.joined(separator: ",")
    }
    
    private func hideAlternativesPopup() {
        guard let popup = alternativesPopup else { return }
        
        UIView.animate(withDuration: 0.2, animations: {
            popup.alpha = 0
            popup.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            popup.removeFromSuperview()
            // Restore normal clipping behavior
            self.view.clipsToBounds = true
        }
        
        alternativesPopup = nil
    }
    
    @objc private func alternativeSelected(_ sender: UIButton) {
        // This method is no longer needed since we handle selection through hover
        guard let popup = alternativesPopup,
              let alternativesString = popup.accessibilityLabel else { return }
        
        let alternatives = alternativesString.components(separatedBy: ",")
        let selectedIndex = sender.tag
        
        if selectedIndex < alternatives.count {
            let selectedCharacter = alternatives[selectedIndex]
            // Check if this character has a mapped insertion value (for diacritical marks)
            if let insertionCharacter = alternativeInsertionMap[selectedCharacter] {
                textDocumentProxy.insertText(insertionCharacter)
            } else {
                textDocumentProxy.insertText(selectedCharacter)
            }
        }
        
        hideAlternativesPopup()
    }
    
    @objc private func keyPressed(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }
        textDocumentProxy.insertText(title)
    }
    
    @objc private func deleteBackward() {
        textDocumentProxy.deleteBackward()
    }
    
    @objc private func insertSpace() {
        textDocumentProxy.insertText(" ")
    }
    
    @objc private func insertReturn() {
        textDocumentProxy.insertText("\n")
    }
    
    @objc private func insertHalfSpace() {
        textDocumentProxy.insertText("\u{200C}")
    }
    
    @objc private func toggleToNumberSymbolMode() {
        // Reset all modes and set number/symbol mode
        isNumberSymbolMode = true
        isSymbolMode = false
        setupKeyboard()
    }
    
    @objc private func toggleSymbolsInNumberMode() {
        isNumberSymbolMode = true
        isSymbolMode = true
        setupKeyboard()
    }
    
    @objc private func toggleNumbersInSymbolMode() {
        isNumberSymbolMode = true
        isSymbolMode = false
        setupKeyboard()
    }
    
    @objc private func toggleToTurkishMode() {
        isNumberSymbolMode = false
        isSymbolMode = false
        setupKeyboard()
    }
    
    @objc private func keyHighlight(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            sender.backgroundColor = sender.backgroundColor?.withAlphaComponent(0.7)
        }
    }
    
    @objc private func keyUnhighlight(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform.identity
            if sender.backgroundColor == UIColor.systemGray3 {
                sender.backgroundColor = UIColor.systemGray3
            } else {
                sender.backgroundColor = UIColor.white
            }
        }
    }
    
    override func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        // The app has just changed the document's contents, the document context has been updated.
    }
}
