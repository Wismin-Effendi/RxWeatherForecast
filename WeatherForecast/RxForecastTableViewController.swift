//
//  RxForecastTableViewController.swift
//  WeatherForecast
//
//  Created by Wismin Effendi on 10/24/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class RxForecastTableViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    // pass in this value via segue
    var cityName: String!
    
    let disposeBag = DisposeBag()
    
    var forecasts = [Forecast]()
    var forecastsObservable: Observable<[Forecast]>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = cityName
        populateForecastsForCity()
        
    }
    
    
    private func populateForecastsForCity() {
        func getWeatherForecastData(urlString: String) {
            let url = URL(string: urlString)
            let task = URLSession.shared.dataTask(with: url!) {[weak self] (data, response, error) in
                guard error == nil else {
                    print(error!)
                    self?.showAlertErrorMessage(code: "1000", message: error!.localizedDescription)
                    return
                }
                DispatchQueue.main.async(execute: {
                    self?.populateForecasts(data!)
                })
            }
            task.resume()
        }
        
        let encodedString = Util.getUrlEncodedStringOf(cityName)
        let openWeatherURL = "http://api.openweathermap.org/data/2.5/forecast?q=\(encodedString)&appid=1d6c50963fee0c46f1648017dd3a9367"
        
        getWeatherForecastData(urlString: openWeatherURL)
    }
    
    private func populateForecasts(_ weatherData: Data) {
        do {
            let jsonDict = try JSONSerialization.jsonObject(with: weatherData, options: []) as! NSDictionary
            let returnCode = jsonDict.value(forKey: "cod") as! String
            guard returnCode == "200" else {
                let message = jsonDict.value(forKey: "message") as! String
                showAlertErrorMessage(code: returnCode, message: message)
                return
            }
            let timestamps = jsonDict.value(forKeyPath: "list.dt") as! [Double]
            let temperaturesInKelvin = jsonDict.value(forKeyPath: "list.main.temp") as! [Double]
            let weatherDescriptions = jsonDict.value(forKeyPath: "list.weather.description") as! [[String]]
            
            var tsIterator = timestamps.makeIterator()
            var kelvinIterator = temperaturesInKelvin.makeIterator()
            var descIterator = weatherDescriptions.makeIterator()
            
            while let timestamp = tsIterator.next(), let kelvinTemp = kelvinIterator.next(), let description = descIterator.next() {
                let forecast = Forecast(dateTime: Util.dateTimeStringFromUnixTimeStamp(timestamp), temperatureInKelvin: kelvinTemp, description: description.first!)
                forecasts.append(forecast)
            }
            forecastsObservable = Observable.of(forecasts)
        } catch {
            print(error)
        }
        
        forecastsObservable.asDriver(onErrorJustReturn: [])
            .drive(tableView.rx.items(cellIdentifier: "RxForecastCell")) { (_, forecast, cell) in
                cell.textLabel?.text = forecast.dateTime
                cell.detailTextLabel?.text = forecast.tempAndDescription
            }
            .disposed(by: disposeBag)
    }
    
    
    private func showAlertErrorMessage(code: String, message: String ) {
        let errorMessage = "Error \(code): \(message)"
        let alertError = UIAlertController(title: "Error", message: errorMessage, preferredStyle: UIAlertControllerStyle.alert)
        let dismissAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil)
        alertError.addAction(dismissAction)
        present(alertError, animated: true, completion: nil)
    }
    
//    // MARK: - Table view data source
//
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return 1
//    }
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return forecasts.count
//    }
//
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "ForecastCell", for: indexPath)
//
//        let forecast = forecasts[indexPath.row]
//        cell.textLabel?.text = forecast.dateTime
//        cell.detailTextLabel?.text = forecast.tempAndDescription
//
//        return cell
//    }

}
