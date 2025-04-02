//
//  ViewController.swift
//  Gameinn
//
//  Created by Sebastian Kroszka on 05/08/2020.
//  Copyright © 2020 Embiq. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: GameBaseViewController  {
    @IBOutlet weak var loggerContainerView: UIView!
    @IBOutlet weak var loggerTableView: UITableView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var bandListContainerView: UIView!
    @IBOutlet weak var bandTableView: UITableView!
    
    private var logsForDisplay: [LogModel] = []
    private var bandsForDisplay: [Band]  {
        get {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return []
            }
            return appDelegate.game.bands
        }
    }
    private var selectedBand: Band?
    
    @IBOutlet weak var playerLabel: UILabel!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.mediator = appDelegate.gameMediator
        }
        self.loggerTableView.delegate = self
        self.loggerTableView.dataSource = self
        
        self.bandTableView.delegate = self
        self.bandTableView.dataSource = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.mediator?.register(participant: self)
        
        self.reloadBandsList()
        self.reloadLogsList()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    @IBAction func onStartButtonPressed(_ sender: Any) {
           self.mediator?.send(command: .startGame, sender: self, contextObject: nil)
    }
    
    override func receive(command: MediatorCommands, sender: AnyObject, contextObject: AnyObject?) {
        super.receive(command: command, sender: sender, contextObject: contextObject)
        
        switch command {
        case .onBandsUpdated:
            reloadBandsList()
        case.logEvent:
            guard let logString = contextObject as? NSString else {
                return
            }
            showNewLogEvent(LogModel(logContent: logString as String))
            
        default:
            return
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.mediator?.unregister(participant: self)
    }
    
    private func reloadBandsList() {
        self.bandTableView.reloadData()
    }
    
    private func reloadLogsList() {
        self.loggerTableView.reloadData()
    }
    
    private func showNewLogEvent(_ log: LogModel) {
        if self.logsForDisplay.count >= 30 {
            logsForDisplay.removeLast()
        }
        logsForDisplay.insert(log, at: 0)
        reloadLogsList()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "mainToDetailsSegue" {
            let detailsViewController = segue.destination as! DetailsViewController
            detailsViewController.bandModel = selectedBand
        }
    }
}

extension ViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == self.loggerTableView {
            return self.logsForDisplay.count;
        }
        
        if tableView == self.bandTableView {
            return self.bandsForDisplay.count;
        }
        
        return 0;
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == self.loggerTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoggerTableViewCell") as! LoggerTableViewCell
            cell.updateWithLogModel(self.logsForDisplay[indexPath.row])
            return cell
        }
        
        if tableView == self.bandTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "BandTableViewCell") as! BandTableViewCell
            cell.updateWithModel(self.bandsForDisplay[indexPath.row])
            return cell
        }

        return UITableViewCell()
    }
}

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let isGameStarted = appDelegate?.game.isGameStarted ?? false
        if !isGameStarted {
            if tableView == self.bandTableView {
                selectedBand = self.bandsForDisplay[indexPath.row]
                appDelegate?.game.vibeBand(band: selectedBand as! Band)
                self.performSegue(withIdentifier: "mainToDetailsSegue", sender: self)
            }
        }
    }
}
