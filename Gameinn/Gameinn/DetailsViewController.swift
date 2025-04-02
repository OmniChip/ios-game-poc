//
//  DetailsViewController.swift
//  Gameinn
//
//  Created by Bartlomiej Burzec on 24/09/2020.
//  Copyright © 2020 Embiq. All rights reserved.
//

import UIKit
import CoreBluetooth

class DetailsViewController: GameBaseViewController {

    @IBOutlet weak var bandNameLabel: UILabel!

    @IBOutlet weak var accXLabel: UILabel!
    @IBOutlet weak var accYLabel: UILabel!
    @IBOutlet weak var accZLabel: UILabel!

    @IBOutlet weak var rotationXLabel: UILabel!
    @IBOutlet weak var rotationYLabel: UILabel!
    @IBOutlet weak var rotationZLabel: UILabel!

    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var calibrationLabel: UILabel!
    @IBOutlet weak var associationLabel: UILabel!

    @IBOutlet weak var playerNumberPickerView: UIPickerView!

    @IBOutlet var radioButtons: [UIButton]!
    @IBOutlet weak var resetButton: UIButton!

    var bandModel: Band!
    var previousVersionOfModel: Band!

    private var selectedPlayerIndex = 0

    var game: Game? {
        get {
            appDelegate?.game
        }
    }

    var players: [Player] {
        guard let players = game?.players else {
            return []
        }
        return players
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(false, animated: false)

        setup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.register()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.unregister()
    }

    override func receive(command: MediatorCommands, sender: AnyObject, contextObject: AnyObject?) {
        switch command {
        case .onBandsUpdated:
            updateBandInfo()
        case .onBandPeripheralDisconnected:
            if let peripheral = contextObject as? CBPeripheral, peripheral.identifier == bandModel.peripheral.identifier {
                goBack()
            }
        default:
            return
        }
    }

    var backgroundColorForResetButton: UIColor {
        get {
            return self.resetButton.isSelected ? .gray : .white
        }
    }

    func goBack() {
        self.navigationController?.popViewController(animated: true)
    }

    func setup() {
        self.title = "Band Assigment"
        self.playerNumberPickerView.delegate = self
        self.playerNumberPickerView.dataSource = self
        self.playerNumberPickerView.selectRow(0, inComponent: 0, animated: false)
        setupResetButton()
        setupRadioButtons()
        updateView()
        updateControls()
    }

    func updateView() {
        updateBandInfo()
    }

    func updateBandInfo() {
        self.bandNameLabel.text = bandModel.peripheral.name
        if let data = self.bandModel.lastData {
            self.accXLabel.text = String(data.ax)
            self.accYLabel.text = String(data.ay)
            self.accZLabel.text = String(data.az)

            self.rotationXLabel.text = String(data.gx)
            self.rotationYLabel.text = String(data.gy)
            self.rotationZLabel.text = String(data.gz)

            self.timestampLabel.text = String(data.timestamp)
        }
        self.associationLabel.text = bandModel.associationName()
        //TODO: check Android logic about calibration displayed text
        self.calibrationLabel.text = "Calibration: \(bandModel.calibrationStatus)"
    }

    func updateControls() {
        updateRadioButtons()
        updateUserPicker()
    }

    func updateRadioButtons() {
        self.radioButtons.forEach { (button) in
            if button.tag - 1 == self.bandModel.association {
                button.isSelected = true
                button.backgroundColor = .systemPink
            } else {
                button.isSelected = false
                button.backgroundColor = .white
            }
        }
    }

    func updateUserPicker() {
        var index = 0
        if let player = appDelegate?.game.getAssociatedPlayer(for: self.bandModel), let idx = players.firstIndex(where: { p -> Bool in p == player }) {
            index = idx + 1
        }

        self.playerNumberPickerView.selectRow(index, inComponent: 0, animated: true)
    }

    func setupResetButton() {
        self.resetButton.layer.borderWidth = 1.0
        self.resetButton.layer.borderColor = UIColor.gray.cgColor
        self.resetButton.isSelected = false
        self.resetButton.backgroundColor = backgroundColorForResetButton
    }

    func setupRadioButtons() {
        self.radioButtons.forEach { button in
            button.layer.borderColor = UIColor.gray.cgColor
            button.layer.borderWidth = 1.0
            button.layer.cornerRadius = 15.0
            button.isSelected = false
            button.backgroundColor = .white
        }
    }

    @IBAction func onRadioButtonPressed(_ sender: UIButton) {
        sender.isSelected = true
        sender.backgroundColor = .systemPink

        self.radioButtons.filter { button -> Bool in
            return button != sender
        }.forEach { button in
            button.isSelected = false
            button.backgroundColor = .white
        }
    }

    @IBAction func onResetCalibrationButtonPressed(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        sender.backgroundColor = backgroundColorForResetButton
        //TODO: store this info somewhere
        //TODO: check with Android logic
    }

    @IBAction func onSaveButtonPressed(_ sender: UIButton) {
        let selectedPlayerRow = self.playerNumberPickerView.selectedRow(inComponent: 0)
        let button = self.radioButtons.filter { (button) -> Bool in
            return button.isSelected
        }.first

        if selectedPlayerRow == 0 {
            self.bandModel.association = -1
            game?.unbindBandFromUser(self.bandModel)
        }

        if selectedPlayerRow != 0 {
            guard let selectedButton = button else {
                prepareAndShowAlert(with: "Cannot save changes without setting band position")
                return
            }

            let selectedUser = players[selectedPlayerRow - 1]
            if selectedUser.playerId != game?.getAssociatedPlayer(for: self.bandModel)?.playerId {
                game?.unbindBandFromUser(self.bandModel)
            }

            self.bandModel.association = selectedButton.tag - 1
            if game?.bindBandWithPlayer(self.bandModel, userId: selectedUser.playerId) == false {
                prepareAndShowAlert(with: "Error occurred while saving changes")
                return
            }
        }

        goBack()
    }

    func prepareAndShowAlert(with message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))

        self.present(alert, animated: true)
    }

    @IBAction func onRevertButtonPressed(_ sender: UIButton) {
        updateControls()
    }

}

extension DetailsViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 20.0
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row == 0 {
            return "None"
        }
        return "\(players[row - 1].playerId)"
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedPlayerIndex = row
    }
}

extension DetailsViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return players.count + 1
    }
}
