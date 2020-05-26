// Copyright © 2020 Oliver Lau <oliver@ersatzworld.net>

import UIKit

class SaveToLogViewController: UITableViewController {

    @IBOutlet weak var exercisePicker: UIPickerView!
    @IBOutlet weak var repsAndWeightLabel: UILabel!
    @IBOutlet weak var oneRMLabel: UILabel!
    @IBOutlet var starButton: [UIButton]!
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!

    var exercises: [Exercise] = []
    var exercise: Exercise? {
        didSet {
            UserDefaults.standard.set(exercise?.name, forKey: lastSavedExerciseKey)
        }
    }
    var date: Date? {
        didSet {
            UserDefaults.standard.set(date, forKey: lastSaveDateKey)
        }
    }
    var notes: String? {
        didSet {
            UserDefaults.standard.set(notes, forKey: lastSaveNotesKey)
        }
    }
    var rating: Int = 0 {
        didSet {
            UserDefaults.standard.set(rating, forKey: lastSaveRatingKey)
            for i in 0..<rating {
                starButton[i].setImage(UIImage(systemName: "star.fill"), for: .normal)
            }
            for i in rating..<starButton.count {
                starButton[i].setImage(UIImage(systemName: "star"), for: .normal)
            }
        }
    }
    var reps: Int = 0
    var massUnit: String = defaultMassUnit
    var weight: Double = 0
    var oneRM: Double = 0

    @IBAction func starButtonPressed(_ sender: Any) {
        guard let button = sender as? UIButton else { return }
        rating = (button.tag == 1 && rating == 1) ? 0 : button.tag
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        exercisePicker.delegate = self
        exercisePicker.dataSource = self
        for (idx, button) in starButton.enumerated() {
            button.tag = idx + 1
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        massUnit = UserDefaults.standard.string(forKey: massUnitKey) ?? defaultMassUnit
        exercises = LiftDataManager.shared.loadExercises()
        repsAndWeightLabel.text = "\(reps) × \(weight.rounded(toPlaces: 1)) \(massUnit)"
        oneRMLabel.text = "\(oneRM.rounded(toPlaces: 1)) \(massUnit)"
        if UserDefaults.standard.object(forKey: lastSavedExerciseKey) != nil {
            let lastSavedExercise = UserDefaults.standard.string(forKey: lastSavedExerciseKey)
            guard let idx = exercises.firstIndex(where: { $0.name == lastSavedExercise }) else { return }
            exercisePicker.selectRow(idx, inComponent: 0, animated: false)
            exercise = exercises[idx]
        }
        if UserDefaults.standard.object(forKey: lastSaveDateKey) != nil {
            guard let lastDate = UserDefaults.standard.object(forKey: lastSaveDateKey) as? Date else { return }
            datePicker.date = lastDate
        }
        if UserDefaults.standard.object(forKey: lastSaveNotesKey) != nil {
            guard let lastNotes = UserDefaults.standard.string(forKey: lastSaveNotesKey) else { return }
            notesTextView.text = lastNotes
        }
        if UserDefaults.standard.object(forKey: lastSaveRatingKey) != nil {
            rating = UserDefaults.standard.integer(forKey: lastSaveRatingKey)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        date = datePicker.date
        notes = notesTextView.text
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gotoLog" {
            guard let unit = LiftDataManager.shared.load(unitWithName: self.massUnit),
                !self.exercises.isEmpty else { return }
            let liftData = LiftData(
                date: self.datePicker.date,
                reps: Int16(self.reps),
                weight: self.weight,
                oneRM: self.oneRM,
                rating: Int16(self.rating),
                notes: self.notesTextView.text,
                exercise: self.exercise ?? self.exercises[0],
                unit: unit)
            try? LiftDataManager.shared.save(lift: liftData)
        }
    }

}

extension SaveToLogViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return exercises.count
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        exercise = exercises[row]
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return exercises[row].name
    }
}

extension SaveToLogViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
}
