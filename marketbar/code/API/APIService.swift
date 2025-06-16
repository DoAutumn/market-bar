//
//  APIService.swift
//  marketbar
//
//  Created by Daniil Manin on 27.12.2020.
//

import Combine
import Foundation

typealias TickersResponse = Result<[Ticker], Error>

final class APIService {
	
	private var cancellable: AnyCancellable?
	private let endpoint: String = "https://hq.sinajs.cn?list="
	
	func add(tickerString: String, result: @escaping (TickersResponse) -> Void) {
		let ticker = Ticker(symbol: tickerString, name: "", price: 0.0, previousClose: 0.0)
		update(tickers: [ticker], result: result)
	}
	
	func update(tickers: [Ticker], result: @escaping (TickersResponse) -> Void) {
		guard !tickers.isEmpty else {
			result(.failure(APIError.emptyRequest))
			return
		}
	
		let urlString = tickers
			.map { $0.symbol + "," }
			.reduce(endpoint, +)
			.dropLast()
			.replacingOccurrences(of: "^", with: "%5E")

		request(to: URL(string: String(urlString)), result: result)
	}
	
	// MARK: - Private
	
	private func request(to url: URL?, result: ((TickersResponse) -> Void)?) {
		guard let url = url else {
			result?(.failure(APIError.invalidURL))
			return
		}
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("https://finance.sina.com.cn", forHTTPHeaderField: "Referer")
        
        cancellable = URLSession.shared.dataTaskPublisher(for: request)
            .map { String(data: $0.data, encoding: .ascii) ?? "" }
			.eraseToAnyPublisher()
			.receive(on: DispatchQueue.main)
			.sink(receiveCompletion: { completion in
				switch completion {
				case .finished: break
				case .failure(let error):
					NSLog(error.localizedDescription)
				}
			}, receiveValue: { responseString in
                let dataArray: [Double] = responseString.split(separator: ",").compactMap { str in
                    return Double(str)
                }
                let tickers: [Ticker] = [
                    Ticker(
                        symbol: "sz002212",
                        name: "Topsec",
                        price: dataArray[2],
                        previousClose: dataArray[1],
                        open: dataArray[0],
                        high: dataArray[3],
                        low: dataArray[4]
                    )
                ]
				result?(.success(tickers))
			})
	}
}
